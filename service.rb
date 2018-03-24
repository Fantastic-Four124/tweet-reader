# server.rb
require 'sinatra'
require 'mongoid'
require 'json'
require 'byebug'
require_relative 'models/tweet'

# DB Setup
Mongoid.load! "mongoid.config"

#set binding
enable :sessions

set :bind, '0.0.0.0' # Needed to work with Vagrant
set :port, 8090
# These are still under construction.

get '/api/v1/tweets/:user_id' do # Get tweets by :user_id
  #byebug
  tweets = Tweet.where(user_id: params[:id]).desc(:date_posted).limit(50).to_json
end

get '/api/v1/tweets/recent' do # Get 50 random tweets
  tweets = Tweet.desc(:date_posted).limit(50).to_json
end

get '/api/v1/tweets/:tweet_id/hashtags' do # Get hashtags associated with the tweet
  Tweet.find_by(params[:tweet_id]).hashtags.to_json
end

get '/api/v1/tweets/:tweet_id/mentions' do # Get mention associated with the tweet
  Tweet.find_by(params[:tweet_id]).mentions.to_json
end
