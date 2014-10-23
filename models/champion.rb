class Champion
	include Mongoid::Document

	field :champion_id, type: Integer
	field :title, type: String
	field :name, type: String
	field :key, type: String
end