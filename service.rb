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

set :bind, '0.0.0.0' # Needed to work with Vagrant
set :port, 8090

set :allow_origin, '*'
set :allow_methods, 'GET,HEAD,POST'
set :allow_headers, 'accept,content-type,if-modified-since'
set :expose_headers, 'location,link'

configure do
  uri = URI.parse("redis-19695.c8.us-east-1-3.ec2.cloud.redislabs.com:19695")
  user_uri = URI.parse(ENV['USER_REDIS_URL'])
  follow_uri = URI.parse('redis://rediscloud:eMSO1kcjbzvlmtlMqtWesW7qCjbAAhbx@redis-14823.c15.us-east-1-2.ec2.cloud.redislabs.com:14823')
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  $user_redis = Redis.new(:host => user_uri.host, :port => user_uri.port, :password => user_uri.password)
  $follow_redis = Redis.new(:host => follow_uri.host, :port => follow_uri.port, :password => follow_uri.password)
  PREFIX = '/api/v1'
end

get '/loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt' do
  send_file 'loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt'
end


get PREFIX + '/tweets/:username/username' do # Get tweets by :username
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

get PREFIX + '/tweets/:tweet_id/tweet_id' do
  Tweet.find_by(params[:tweet_id]).to_json
end

get PREFIX + '/tweets/recent' do # Get 50 random tweets
  tweets = Tweet.desc(:date_posted).limit(50)
  tweetJSON = Array.new
  tweets.each do |tweet|
    tweetJSON <<  {
      contents: tweet.contents,
      createdAt: tweet.date_posted.to_f * 1000,
      id: tweet.id,
      user: {
        username: tweet.username,
        id: tweet.user_id
      }
    }
  end
  tweetJSON.to_json
end


get PREFIX + '/:token/users/:id/feed' do
  session = $user_redis.get params['token']
  if session
    user = JSON.parse session
    tweets = Tweet.where(user_id: user['id']).desc(:date_posted).limit(50)
    tweetJSON = Array.new
    tweets.each do |tweet|
      tweetJSON <<  {
        contents: tweet.contents,
        createdAt: tweet.date_posted.to_f * 1000,
        id: tweet.id,
        user: {
          username: tweet.username,
          id: tweet.user_id
        }
      }
    end
    return tweetJSON.to_json
  end
  {err: true}.to_json
end

get PREFIX + '/:token/users/:id/timeline' do
   session = $user_redis.get params['token']
   if session
     tweets = []
     leader_list = $follow_redis.get("#{id} leaders").keys
     leader_list.each do |l|
      l_hash = JSON.parse($user_redis.get(l))
      l_tweets = Tweet.where(user_id: l.to_i).to_json
        l_tweets.each do |t|
          t['user'] = l_hash
          t['createdAt'] = t.delete('created_at').to_f * 1000
        end
        tweets.concat(l_tweets)
      end
      return tweets.sort! {|t1, t2| t2['createdAt'] <=> t1['createdAt']}.to_json
    end
    {err: true}.to_json
end

get PREFIX + '/hashtags/:term' do
  Tweet.full_text_search(params[:label]).desc(:date_posted).limit(50).to_json
end

get PREFIX + '/searches/:term' do
  # byebug
  Tweet.full_text_search(params[:word]).desc(:date_posted).limit(50).to_json
end
