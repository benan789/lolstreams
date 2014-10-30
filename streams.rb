require './config.rb'
require 'redis'

class Streams < Sinatra::Base
	helpers Sinatra::Cookies
	set :cookie_options, :domain => nil
	enable :method_override
	redis = Redis.new
	get '/' do
		send_file 'index.html'
	end

	get "/auth" do
		begin
		client = OAuth2::Client.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')

		redirect client.auth_code.authorize_url(:redirect_uri => 'http://localhost:9292/auth/callback',  :scope => 'user_read')
		# => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"
		
		rescue Exception => e
		"Sdf"
		end		
	end

	get "/auth/callback" do
		content_type :json
		client = OAuth2::Client.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')
		token = client.auth_code.get_token(params[:code], :redirect_uri => 'http://localhost:9292/auth/callback')
		if token
			token = JSON.parse(token.to_json)
			cookies[:twitch] = token['access_token']
			# response = Unirest.get "https://api.twitch.tv/kraken/streams/followed?oauth_token=#{}"
			# response.to_json
			redirect back
		end
	end

	get "/streams/?" do
		content_type :json
		streams = JSON.parse(redis.get('streams'))
		streams.to_json
	end

	get "/favorites/?" do
		response = Unirest.get "https://api.twitch.tv/kraken/streams/followed?oauth_token=#{cookies[:twitch]}"
		favstreams = response.body['streams']
		favstreams.to_json
	end

	get "/streams/:name/?" do
		content_type :json
		response = Unirest.get "https://api.twitch.tv/kraken/streams/#{params[:name]}?client_id=#{ENV['CLIENT_ID']}"
		stream = response.body['stream'].to_json
	end
	
	get '/:name' do
		@token = token
		erb :show
	end

	get '/:name/edit' do
		@streamer = Streamer.find_by(name: params[:name])
		erb :edit
	end

	put '/:name/edit' do
		@streamer = Streamer.find_by(name: params[:name])
		if @streamer.update_attributes(params[:streamer])
			redirect '/'
		end
	end
end