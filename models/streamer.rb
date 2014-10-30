class Streamer
	include Mongoid::Document

	field :name, type: String
	field :summoner_names, type: Hash
	field :gender, type: Integer
	field :team, type: String
	field :rank, type: String
end