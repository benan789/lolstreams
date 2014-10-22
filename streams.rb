require 'oauth2'
require 'json'
require 'unirest'

class Streams < Sinatra::Base

	get '/' do
		send_file 'index.html'
	end

	get "/callback" do
		begin
		client = OAuth2::Client.new('hl2vdk3gyh2w2j61q2ot7mu7kyf6ody', '89gvk7vvn8x4k8xr6qsh9lfiytqdgbu', :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')

		redirect client.auth_code.authorize_url(:redirect_uri => 'http://localhost:9292/callback')
		# => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"
		
		rescue Exception => e
		"Sdf"
		end		
	end

	get "/callback" do
		client = OAuth2::Client.new('hl2vdk3gyh2w2j61q2ot7mu7kyf6ody', '89gvk7vvn8x4k8xr6qsh9lfiytqdgbu', :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')
		token = client.auth_code.get_token(params[:code], :redirect_uri => 'http://localhost:9292/callback')
		# => OAuth2::Response
	end

	get "/streams/?" do
		content_type :json
		response = Unirest.get "https://api.twitch.tv/kraken/streams?game=league+of+legends&limit=100&?client_id=hl2vdk3gyh2w2j61q2ot7mu7kyf6ody"	
		streams = response.body['streams'].to_json
		# response2 = Unirest.get "https://community-league-of-legends.p.mashape.com/api/v1.0/NA/summoner/retrieveInProgressSpectatorGameInfo/#{stream['channel']['name']}",
		# headers:{
	 	# "X-Mashape-Key" => "LcnBPFSAykmshFMnK4hZ8MnYfdGrp1A2JIRjsn9J2VnbfKUfl9"
	end

	get "/streams/:name/?" do
		content_type :json
		response = Unirest.get "https://api.twitch.tv/kraken/streams/#{params[:name]}?client_id=hl2vdk3gyh2w2j61q2ot7mu7kyf6ody"
		stream = response.body['stream'].to_json
	end
end