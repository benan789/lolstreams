require './config.rb'
require 'open-uri'

redis = Redis.new
response = Unirest.get "https://api.twitch.tv/kraken/streams?game=league+of+legends&limit=100&?client_id=#{ENV['CLIENT_ID']}"	
streams = response.body['streams']

streams.each do |stream|
	stream['streamer'] = Streamer.find_or_create_by({name: stream['channel']['name']})
	begin
		regions = stream['streamer']['summoner_names'].keys
		regions.each do |region|
			
			summoners = stream['streamer']['summoner_names'][region]
			begin
			summoners.values.each do |summoner|
				begin
				puts summoner
				response = Unirest.get "https://community-league-of-legends.p.mashape.com/api/v1.0/#{region}/summoner/retrieveInProgressSpectatorGameInfo/#{URI::encode(summoner)}",
				headers:{
				  "X-Mashape-Key" => ENV['MASHAPE']
				}
				summoner_info = response.body['game']['playerChampionSelections']['array'].find {|x| x['summonerInternalName'] == summoner}
				summoner_info2 = response.body['game']['teamOne']['array'].find {|x| x['summonerInternalName'] == summoner} || summoner_info2 = response.body['game']['teamTwo']['array'].find {|x| x['summonerInternalName'] == summoner}

				rank_response = Unirest.get "https://na.api.pvp.net/api/lol/na/v2.5/league/by-summoner/#{summoner_info2["summonerId"]}/entry?api_key=#{ENV['LOL_SECRET']}"
				rank = JSON.parse(rank_response.body.to_json)
				rank = rank[summoner_info2["summonerId"].to_s][0]['tier']
				stream['rank'] = rank

				if champion = Champion.find_by(champion_id: summoner_info['championId'])
					puts champion.name
					stream['champion'] = champion.name
					break
				end
				rescue
				end
			end

			rescue
				stream['champion'] = "Not in game."
				puts "sdf"
			end
			
		end
	rescue
		stream['champion'] = "Not in game."
	end
end

redis.set "streams", streams.to_json