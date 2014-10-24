require './config.rb'
require 'open-uri'

redis = Redis.new
redis.flushdb
response = Unirest.get "https://api.twitch.tv/kraken/streams?game=league+of+legends&limit=100&?client_id=#{ENV['CLIENT_ID']}"	
streams = response.body['streams']

streams.each do |stream|
	stream['streamer'] = Streamer.find_or_create_by({name: stream['channel']['name']})
	begin
		regions = stream['streamer']['summoner_names'].keys
		regions.each do |region|
			begin
				summoner = stream['streamer']['summoner_names'][region]
				response = Unirest.get "https://community-league-of-legends.p.mashape.com/api/v1.0/#{region}/summoner/retrieveInProgressSpectatorGameInfo/#{URI::encode(summoner)}",
				headers:{
				  "X-Mashape-Key" => ENV['MASHAPE']
				}
				summoner_info = response.body['game']['playerChampionSelections']['array'].find {|x| x['summonerInternalName'] == summoner}
				if champion = Champion.find_by(champion_id: summoner_info['championId'])
					puts champion.name
					stream['champion'] = champion.name
					break
				end
			rescue
				stream['champion'] = "Not in game."
			end
		end
	rescue
		stream['champion'] = "Not in game."
	end
end

redis.set "streams", streams.to_json