# server.rb
require 'sinatra'
require 'mongoid'
require_relative 'models/tweet'

# DB Setup
Mongoid.load! "mongoid.config"

#set binding
enable :sessions

set :bind, '0.0.0.0' # Needed to work with Vagrant

# These are still under construction.

get '/api/v1/tweets/:user_id' do # Get tweets by :user_id
  #tweets = Tweet.where(user_id: params[:user_id]).desc(:date_posted).limit(50).to_h
  #redirect '/api/v1/{route}'
end

get '/api/v1/tweets/recent' do # Get 50 random tweets
  #tweets = Tweet.desc(:date_posted).limit(50).to_h
  #redirect '/api/v1/{route}'
end

get '/api/v1/tweets/:tweet_id/hashtags' do # Get hashtags associated with the tweet
  #hashtags = Array.new
  #tweets = Tweet.find_by(params[:tweet_id]).each do |tweet| #Should only execute once
    #hastags = tweet.hashtags
  #redirect '/api/v1/{route}'
end

get '/api/v1/tweets/:tweet_id/mentions' do # Get mention associated with the tweet
  #mentions = Array.new
  #tweets = Tweet.find_by(params[:tweet_id]).each do |tweet| #Should only execute once
    #hastags = tweet.mentions
  #redirect '/api/v1/{route}'
end
