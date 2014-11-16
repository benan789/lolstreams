require 'bundler'
Bundler.require
require 'sinatra'
require "sinatra/cookies"
require 'sinatra/assetpack'
require 'redis'
require 'oauth2'
require 'json'
require 'unirest'
require 'dotenv'
Dotenv.load
require './models/streamer.rb'
require './models/champion.rb'

Mongoid.load!("./mongoid.yml")
