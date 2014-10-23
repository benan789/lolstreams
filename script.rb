require './config.rb'
require 'redis'
require 'open-uri'

redis = Redis.new
streams = Unirest.get 'http://localhost:9292/streams'

streams.body.each do |stream|
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
					redis.set summoner, champion.champion_id
					break
				end
			rescue
				puts "#{summoner} is not in game"
			end
		end
	rescue
	end
end