require './config.rb'

class Streams < Sinatra::Base
	helpers Sinatra::Cookies
	set :cookie_options, :domain => nil
	enable :method_override

	register Sinatra::AssetPack

	assets do
		js :application, [
			'/js/*.js'
		]

		css :application, [
			'/css/*.css'
		]

		js_compression :jsmin
		css_compression :css
	end

	redis = Redis.new

	get '/' do
		send_file 'index.html'
	end

	get '/riot.html' do
		send_file 'riot.html'
	end

	get "/auth" do
		begin
		client = OAuth2::Client.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')

		redirect client.auth_code.authorize_url(:redirect_uri => 'http://lolstreams.tv/auth/callback',  :scope => 'user_read user_follows_edit')
		# => "https://example.org/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"
		
		rescue Exception => e
		"Sdf"
		end		
	end

	get "/auth/callback" do
		content_type :json
		client = OAuth2::Client.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'], :authorize_url => 'https://api.twitch.tv/kraken/oauth2/authorize', :token_url => 'https://api.twitch.tv/kraken/oauth2/token')
		token = client.auth_code.get_token(params[:code], :redirect_uri => 'http://lolstreams.tv/auth/callback')
		if token
			token = JSON.parse(token.to_json)

			cookies[:twitch] = token['access_token']
			
			redirect back
		else
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
		streams = JSON.parse(redis.get('streams'))
		stream = streams.find { |x| x['channel']['name'] == params[:name] }
		stream.to_json
	end

	get "/user/?" do 
		response_user = Unirest.get "https://api.twitch.tv/kraken/user?oauth_token=#{cookies[:twitch]}"
		user = response_user.body
		user['user_id'] = cookies[:twitch]
		user.to_json
	end

	get '/:name/bleh' do
		@streamer = Streamer.find_by(name: params[:name])
		@streamer.summoner_names ||= {}
		@streamer.summoner_names['NA'] ||= ""
		@streamer.summoner_names['EUW'] ||= ""
		@streamer.summoner_names['EUNE'] ||= ""
		@streamer.summoner_names['TR'] ||= ""
		@streamer.summoner_names['RU'] ||= ""
		@streamer.summoner_names['OCE'] ||= ""
		@streamer.summoner_names['LAS'] ||= ""
		@streamer.summoner_names['LAN'] ||= ""
		@streamer.summoner_names['BR'] ||= ""
		@streamer.summoner_names['PBE'] ||= ""
		erb :edit
	end

	put '/:name/bleh' do
		@streamer = Streamer.find_by(name: params[:name])
		if params[:password] == ENV['PASSWORD']
			
			if @streamer.update_attributes(params[:streamer])
				
				@streamer.summoner_names.each do |region, names|
					names.each do |account, name|
						if name == ""
							@streamer.summoner_names[region].delete(account)
						else
							@streamer.summoner_names[region][account] = name.delete(" ").downcase
						end
					end

					if names == {}
						@streamer.summoner_names.delete(region)
					end

				end
				@streamer.save
				redirect '/'
			end
		end
	end

	put '/follow' do
		data = JSON.parse(request.body.read)
		Unirest.put "https://api.twitch.tv/kraken/users/#{data['user']}/follows/channels/#{data['stream']}?oauth_token=#{cookies[:twitch]}"
	end

	put '/unfollow' do
		data = JSON.parse(request.body.read)
		Unirest.delete "https://api.twitch.tv/kraken/users/#{data['user']}/follows/channels/#{data['stream']}?oauth_token=#{cookies[:twitch]}"
	end

	put '/logout' do
		cookies.delete('twitch')
	end

end