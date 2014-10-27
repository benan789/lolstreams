require './config.rb'
require 'redis'

class Streams < Sinatra::Base
	enable :method_override
	redis = Redis.new
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
		streams = JSON.parse(redis.get('streams'))
		streams.to_json
	end

	get "/streams/:name/?" do
		content_type :json
		response = Unirest.get "https://api.twitch.tv/kraken/streams/#{params[:name]}?client_id=#{ENV['CLIENT_ID']}"
		stream = response.body['stream'].to_json
	end
	
	get '/:name' do
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