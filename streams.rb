require './config.rb'

class Streams < Sinatra::Base

	get '/' do
		send_file 'index.html'
	end

	get "/auth" do
		begin
		client = OAuth2::Client.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')

		redirect client.auth_code.authorize_url(:redirect_uri => 'http://localhost:9292/auth/callback')
		# => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"
		
		rescue Exception => e
		"Sdf"
		end		
	end

	get "/auth/callback" do
		client = OAuth2::Client.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')
		token = client.auth_code.get_token(params[:code], :redirect_uri => 'http://localhost:9292/auth/callback')
		# => OAuth2::Response
	end

	get "/streams/?" do
		content_type :json
		response = Unirest.get "https://api.twitch.tv/kraken/streams?game=league+of+legends&limit=10&?client_id=#{ENV['CLIENT_ID']}"	
		streams = response.body['streams']
		streams.each do |stream|
			stream['streamer'] = Streamer.find_or_create_by({name: stream['channel']['name']})
		end
		streams.to_json
	end

	get "/streams/:name/?" do
		content_type :json
		response = Unirest.get "https://api.twitch.tv/kraken/streams/#{params[:name]}?client_id=#{ENV['CLIENT_ID']}"
		stream = response.body['stream'].to_json
	end

end