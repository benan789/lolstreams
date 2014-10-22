require 'oauth2'
require 'json'
require 'unirest'

Mongoid.load!("mongoid.yml")

class Streamer
	include Mongoid::Document

	field :name, type: String
	field :summoner_names, type: Hash
	field :gender, type: Integer
	field :team, type: String
end

class Champion
	include Mongoid::Document

	field :id, type: Integer
	field :title, type: String
	field :name, type: String
	field :key, type: String
end

	get '/' do
		send_file 'index.html'
	end

	get "/callback" do
		begin
		client = OAuth2::Client.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')

		redirect client.auth_code.authorize_url(:redirect_uri => 'http://localhost:9292/callback')
		# => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"
		
		rescue Exception => e
		"Sdf"
		end		
	end

	get "/callback" do
		client = OAuth2::Client.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')
		token = client.auth_code.get_token(params[:code], :redirect_uri => 'http://localhost:9292/callback')
		# => OAuth2::Response
	end

	get "/streams/?" do
		content_type :json
		response = Unirest.get "https://api.twitch.tv/kraken/streams?game=league+of+legends&limit=100&?client_id=#{ENV['CLIENT_ID']}"	
		streams = response.body['streams'].to_json
	end

	get "/streams/:name/?" do
		content_type :json
		response = Unirest.get "https://api.twitch.tv/kraken/streams/#{params[:name]}?client_id=#{ENV['CLIENT_ID']}"
		stream = response.body['stream'].to_json
	end