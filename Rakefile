task :environment do 
	require './config.rb'
end

task :seed => :environment do
	seed_file = './db/seeds.rb'
	if File.exists?(seed_file)
		load seed_file
	end
end