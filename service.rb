# server.rb
require 'sinatra'
require 'mongoid'
require 'mongoid_search'
require 'json'
require 'byebug'
require 'sinatra/cors'
require_relative 'models/tweet'
require 'redis'

# DB Setup
Mongoid.load! "config/mongoid.yml"

#set binding
enable :sessions

set :bind, '0.0.0.0' # Needed to work with Vagrant
set :port, 8090

set :allow_origin, '\*'
set :allow_methods, 'GET,HEAD,POST'
set :allow_headers, 'accept,content-type,if-modified-since'
set :expose_headers, 'location,link'

configure do
  uri = URI.parse("redis-19695.c8.us-east-1-3.ec2.cloud.redislabs.com:19695")
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

# get '/loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt' do
#   send_file 'loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt'
# end

get '/api/v1/tweets/:username' do # Get tweets by :username
  #byebug
  tweets = Tweet.where(username: params[:name]).desc(:date_posted).limit(50).to_json
  # Choo implementation
  # tweetJSON = Array.new
  # tweets.each do |tweet|
  #   tweetJSON <<  {
  #     contents: tweet.contents,
  #     createdAt: tweet.date_posted,
  #     id: tweet.id,
  #     user: {
  #       username: tweet.username,
  #       id: tweet.user_id
  #     }
  #   }
  # end
  # tweetJSON.to_json
end

get '/api/v1/tweets/:tweet_id' do
  Tweet.find_by(params[:tweet_id]).to_json
end

get '/api/v1/tweets/recent' do # Get 50 random tweets
  tweets = Tweet.desc(:date_posted).limit(50).to_json
  # Choo implementation
  # tweetJSON = Array.new
  # tweets.each do |tweet|
  #   tweetJSON <<  {
  #     contents: tweet.contents,
  #     createdAt: tweet.date_posted,
  #     id: tweet.id,
  #     user: {
  #       username: tweet.username,
  #       id: tweet.user_id
  #     }
  #   }
  # end
  # tweetJSON.to_json
end

get '/api/v1/hashtags/:term' do
  Tweet.full_text_search(params[:label]).desc(:date_posted).limit(50).to_json
end

get '/api/v1/searches/:term' do
  # byebug
  Tweet.full_text_search(params[:word]).desc(:date_posted).limit(50).to_json
end
