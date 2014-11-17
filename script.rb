require './config.rb'
require 'open-uri'

redis = Redis.new
response = Unirest.get "https://api.twitch.tv/kraken/streams?game=league+of+legends&limit=100&?client_id=#{ENV['CLIENT_ID']}"	
streams = response.body['streams']

streams.each do |stream|
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
							begin
								response = Unirest.get "https://community-league-of-legends.p.mashape.com/api/v1.0/#{region}/summoner/retrieveInProgressSpectatorGameInfo/#{URI::encode(summoner)}",
								headers:{
								  "X-Mashape-Key" => ENV['MASHAPE']
								}
								if response.body['error'] == "Game has not started"
									stream['status'] = "Champion select."
									stream['rank'] = "Champion Select"
									break
								end
								summoner_info = response.body['game']['playerChampionSelections']['array'].find {|x| x['summonerInternalName'] == summoner}
								summoner_info2 = response.body['game']['teamOne']['array'].find {|x| x['summonerInternalName'] == summoner} || summoner_info2 = response.body['game']['teamTwo']['array'].find {|x| x['summonerInternalName'] == summoner}
							rescue
								puts "MASHAPE rate limit?"
							end
							
							begin
								rank_response = Unirest.get "https://#{region.downcase}.api.pvp.net/api/lol/#{region.downcase}/v2.5/league/by-summoner/#{summoner_info2["summonerId"]}?api_key=#{ENV['LOL_SECRET']}"
								rank = JSON.parse(rank_response.body.to_json)
								rank = rank[summoner_info2["summonerId"].to_s][0]['tier']
								stream['rank'] = rank
							rescue
								puts "Rate Limit Reached"
							end

							if champion = Champion.find_by(champion_id: summoner_info['championId'])
								stream['champion'] = champion.key
								stream['region'] =  region
								stream['status'] = "In game."
								break
							end
						end
					rescue
						stream['champion'] = "Not in game."
						stream['status'] = "Not in game."
					end
				end		
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
end

redis.set "streams", streams.to_json

