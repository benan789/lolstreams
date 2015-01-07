require './config.rb'
require 'open-uri'

begin

	response = Unirest.get "https://api.twitch.tv/kraken/streams?game=league+of+legends&limit=100&?client_id=#{ENV['CLIENT_ID']}"	
	streams = response.body['streams']

	if streams != []

		threads = Array.new(2)
		work_queue = SizedQueue.new(2)
		threads.extend(MonitorMixin)
		threads_available = threads.new_cond
		sysexit = false

		consumer_thread = Thread.new do
			loop do
				break if sysexit && work_queue.length == 0
				found_index = nil
				threads.synchronize do
					threads_available.wait_while do
						threads.select { |thread| thread.nil? || thread.status == false || thread['finished'].nil? == false }.length == 0
					end
					found_index = threads.rindex { |thread| thread.nil? || thread.status == false || thread['finished'].nil? == false }				
				end
				stream = work_queue.pop
				
				threads[found_index] = Thread.new(stream) do
					stream['streamer'] = Streamer.find_or_create_by({name: stream['channel']['name']})
					if stream['streamer']['gender'] != 3 && stream['streamer']['gender'] != 4
						begin
							regions = stream['streamer']['summoner_names'].keys
							regions.each do |region|
								summoners = stream['streamer']['summoner_names'][region]
								summoners.values.each do |summoner|
									begin
										if summoner != ""
											puts summoner
											
											response = Unirest.get "https://community-league-of-legends.p.mashape.com/api/v1.0/#{region}/summoner/retrieveInProgressSpectatorGameInfo/#{URI::encode(summoner)}",
												headers:{
												  "X-Mashape-Key" => ENV['MASHAPE']
												}

											puts response.body												

											if response.body['error'] == "Game has not started"
												stream['status'] = "Champion select."
												stream['rank'] = "Champion Select"
												stream['region'] = region
												break
											elsif response.body['error'] != nil
												stream['champion'] = "Not in game."
												stream['status'] = "Not in game."
												next
											end

											summoner_info = response.body['game']['playerChampionSelections']['array'].find {|x| x['summonerInternalName'] == summoner}
											summoner_info2 = response.body['game']['teamOne']['array'].find {|x| x['summonerInternalName'] == summoner} || summoner_info2 = response.body['game']['teamTwo']['array'].find {|x| x['summonerInternalName'] == summoner}
											puts summoner_info
											if summoner_info == nil
												stream['status'] = "Spectating."
												stream['rank'] = "Spectating"
												stream['region'] = region
												break
											end

											begin
												rank_response = Unirest.get "https://#{region.downcase}.api.pvp.net/api/lol/#{region.downcase}/v2.5/league/by-summoner/#{summoner_info2["summonerId"]}?api_key=#{ENV['LOL_SECRET']}"
												rank_info = JSON.parse(rank_response.body.to_json)
												summoner_id = summoner_info2["summonerId"].to_s
												rank = rank_info[summoner_id][0]['tier']
												division = rank_info[summoner_id][0]['entries'].find { |x| x['playerOrTeamId'] == summoner_id}
												stream['division'] = division['division']
												stream['rank'] = rank
											rescue
												puts "Rate Limit Reached"
											end

											if champion = Champion.find_by(champion_id: summoner_info['championId'])
												stream['champion'] = champion.key
												stream['championname'] = champion.name
												stream['region'] = region
												stream['status'] = "In game."
												break
											end
										end
									rescue
										stream['champion'] = "Not in game."
										stream['status'] = "Not in game."
									end
								end
								break if stream['status'] == "Champion select." || stream['status'] == "In game." || stream['status'] == "Spectating."
							end
						rescue
							stream['champion'] = "No info."
							stream['status'] = "Not in game."
							stream['rank'] = "No info."
						end
					elsif stream['streamer']['gender'] == 3
						stream['rank'] = "Tournament"
					else 
						stream['rank'] = "Podcast"
					end
					puts stream['champion']
					puts stream['region']
					puts stream['rank']
					puts stream['status']
					puts "======"
					
					Thread.current['finished'] = true

					threads.synchronize do 
						threads_available.signal
					end

				end
			end
		end

		producer_thread = Thread.new do 
			streams.each do |stream|
				work_queue << stream
				threads.synchronize do 
					threads_available.signal
				end
			end
			sysexit = true
		end

		producer_thread.join
		consumer_thread.join

		threads.each do |thread|
			thread.join unless thread.nil?
		end

		puts streams.length
		redis = Redis.new
		redis.set "streams", streams.to_json
				
	end

rescue
end