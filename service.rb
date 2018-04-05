# server.rb
require 'sinatra'
require 'mongoid'
require 'mongoid_search'
require 'json'
require 'byebug'
require_relative 'models/tweet'

# DB Setup
Mongoid.load! "config/mongoid.yml"

#set binding
enable :sessions

set :bind, '0.0.0.0' # Needed to work with Vagrant
set :port, 8090
# These are still under construction.

get '/api/v1/tweets/:username' do # Get tweets by :username
  #byebug
  tweets = Tweet.where(username: params[:name]).desc(:date_posted).limit(50).to_json
end

get '/api/v1/tweets/:tweet_id' do
  Tweet.find_by(params[:tweet_id]).to_json
end

get '/api/v1/tweets/recent' do # Get 50 random tweets
  tweets = Tweet.desc(:date_posted).limit(50).to_json
end

get '/api/v1/hashtags/:term' do
  Tweet.full_text_search(params[:label]).desc(:date_posted).limit(50).to_json
end

get '/api/v1/searches/:term' do
  # byebug
  Tweet.full_text_search(params[:word]).desc(:date_posted).limit(50).to_json
end
