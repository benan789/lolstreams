require './config.rb'
require 'open-uri'

begin
	streams = []
	while streams == []
		response = Unirest.get "https://api.twitch.tv/kraken/streams?game=league+of+legends&limit=100&?client_id=#{ENV['CLIENT_ID']}"	
		streams = response.body['streams']
	end

	redis = Redis.new

	streams_cache = JSON.parse(redis.get('streams'))

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
										
										response = Unirest.get "https://spectator-league-of-legends-v1.p.mashape.com/lol/#{region.downcase}/v1/spectator/by-name/#{URI::encode(summoner)}",
				  							headers:{
											  "X-Mashape-Key" => ENV['MASHAPE']
											}

										if response.body['data']['ECODE'] == "GAMENOTFOUND_PATH"
											stream['champion'] = "Not in game."
											stream['status'] = "Not in game."
											next
										end
									
										if response.body['data']['error'] == "Game is not observable"
											stream['status'] = "Champion select."
											stream['rank'] = "Champion Select"
											stream['region'] = region
											break
										end

										if response.body['data']['success'] == false
											cache_stream = streams_cache.find {|x| x['channel']['name'] == stream['channel']['name']}
											if cache_stream == nil
												stream['champion'] = "Not in game."
												stream['status'] = "Not in game."
											else
												stream['champion'] = cache_stream['champion']
												stream['championname'] = cache_stream['championname']
												stream['status'] = cache_stream['status']
												stream['region'] = cache_stream['region']
												stream['division'] = cache_stream['division']
												stream['lp'] = cache_stream['lp']
												stream['rank'] = cache_stream['rank']
											end
										else

											summoner_info = response.body['data']['game']['playerChampionSelections'].find {|x| x['summonerInternalName'] == summoner}
											summoner_info2 = response.body['data']['game']['teamOne'].find {|x| x['summonerInternalName'] == summoner} || summoner_info2 = response.body['data']['game']['teamTwo'].find {|x| x['summonerInternalName'] == summoner}
										
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
												stream['lp'] = division['leaguePoints']
												stream['rank'] = rank
											rescue
												if rank_response.code == 404
													stream['rank'] = "UNRANKED"
												else
													begin
														cache_stream = streams_cache.find {|x| x['channel']['name'] == stream['channel']['name']}
														stream['division'] = cache_stream['division']
														stream['lp'] = cache_stream['lp']
														stream['rank'] = cache_stream['rank']
													rescue
													end
												end
											end

											if champion = Champion.find_by(champion_id: summoner_info['championId'])
												stream['champion'] = champion.key
												stream['championname'] = champion.name
												stream['region'] = region
												stream['status'] = "In game."
												break
											end
										end
										break if stream['status'] == "Champion select." || stream['status'] == "In game." || stream['status'] == "Spectating."
									end
								rescue
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
				puts "#{stream['champion']} #{stream['region']} #{stream['status']} #{stream['rank']} #{stream['division']} #{stream['lp']}"

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
	redis.set "streams", streams.to_json
				
rescue
end