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
  user_uri = URI.parse(ENV["USER_REDIS_URL"])
  follow_uri = URI.parse(ENV["FOLLOW_REDIS_URL"])
  reader_uri = URI.parse(ENV["READER_REDIS_URL"])
  $user_redis = Redis.new(:host => user_uri.host, :port => user_uri.port, :password => user_uri.password)
  $follow_redis = Redis.new(:host => follow_uri.host, :port => follow_uri.port, :password => follow_uri.password)
  $reader_redis = Redis.new(:host => reader_uri.host, :port => reader_uri.port, :password => reader_uri.password)

end

helpers do
  def authorized? token
    return !$user_redis[token].nil?
end

get '/loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt' do
  send_file 'loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt'
end

get '/api/v1/:apitoken/tweets/:username' do # Get tweets by :username
  #byebug
  if authorized? params[:apitoken]
    # if $reader_redis.get(params[:user_id] + "_feed").nil?
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
    # $reader_redis.lpush(params[:user_id] + "_feed", tweetJSON)
    # end
    # tweetJSON.to_json
    # else $reader_redis.get(params[:user_id] + "_feed").to_json
  else
    {err: true}.to_json
  end
end

get '/api/v1/:apitoken/tweets/:tweet_id' do
  if authorized? params[:apitoken]
    Tweet.find_by(params[:tweet_id]).to_json
  else
    {err: true}.to_json
  end
end

get '/api/v1/:apitoken/tweets/recent' do # Get 50 random tweets
  if authorized? params[:apitoken]
    # if $reader_redis.get("recent").nil?
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
    # $reader_redis.lpush(tweetJSON)
    # end
    # tweetJSON.to_json
    # else return $reader_redis.get("recent").to_json
  else
    {err: true}.to_json
  end
end

get '/api/v1/:apitoken/hashtags/:term' do
  if authorized? params[:apitoken]
    Tweet.full_text_search(params[:label]).desc(:date_posted).limit(50).to_json
  else
    {err: true}.to_json
  end
end

get '/api/v1/searches/:term' do
  if authorized? params[:apitoken]
    Tweet.full_text_search(params[:word]).desc(:date_posted).limit(50).to_json
  else
    {err: true}.to_json
  end
end
