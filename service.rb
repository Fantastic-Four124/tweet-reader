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
  tweet_uri = URI.parse(ENV["TWEET_REDIS_URL"])
  user_uri = URI.parse(ENV['USER_REDIS_URL'])
  follow_uri = URI.parse(ENV['FOLLOW_REDIS_URL'])
  tweet_uri_spare = URI.parse(ENV['TWEET_REDIS_SPARE_URL'])
  $tweet_redis_spare = Redis.new(:host => tweet_uri_spare.host, :port => tweet_uri_spare.port, :password => tweet_uri_spare.password)
  $tweet_redis = Redis.new(:host => tweet_uri.host, :port => tweet_uri.port, :password => tweet_uri.password)
  $user_redis = Redis.new(:host => user_uri.host, :port => user_uri.port, :password => user_uri.password)
  $follow_redis = Redis.new(:host => follow_uri.host, :port => follow_uri.port, :password => follow_uri.password)
  PREFIX = '/api/v1'
end

get '/loaderio-16864484b2fbdbe95495f6268aad2f2b.txt' do
  send_file 'loaderio-16864484b2fbdbe95495f6268aad2f2b.txt'
end

get '/loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt' do
  send_file 'loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt'
end



get PREFIX + '/tweets/:username/username' do # Get tweets by :username
  tweets = Tweet.where('user.username' => params['username'].to_i).limit(50).to_json
end

get PREFIX + '/tweets/:tweet_id/tweet_id' do
  Tweet.find_by(params[:tweet_id]).to_json
end
#
get PREFIX + '/tweets/recent' do # Get 50 random tweets
  #choo_tweets = Array.new
  if $tweet_redis.llen("recent") > 0
    # $tweet_redis.lrange("recent", 0, -1).each do |tweet|
    #   #choo_tweets << JSON.parse(tweet)
    #   choo_tweets << tweet
    # end
    # return choo_tweets.to_json
    if rand(2) == 1
      return $tweet_redis.lrange("recent", 0, -1).to_json
    else
      return $tweet_redis_spare.lrange("recent", 0, -1).to_json
    end
  else
    Tweet.desc(:date_posted).limit(50).to_json
  end
end


get PREFIX + '/:token/users/:id/feed' do
  session = $user_redis.get params['token']
  if session
    #desc(:date_posted)
    if $tweet_redis.llen(params['id'].to_s + "_feed") > 0
      if rand(2) == 1
        return $tweet_redis.lrange(params['id'].to_s + "_feed", 0, -1).to_json
      else
        return $tweet_redis_spare.lrange(params['id'].to_s + "_feed", 0, -1).to_json
      end
    else
      tweets = Tweet.where('user.id' => params['id'].to_i).desc(:date_posted).limit(50)
      return tweets.to_json
    end
  end
  {err: true}.to_json
end

get PREFIX + '/:token/users/:id/timeline' do
   session = $user_redis.get params['token']
   if session
     tweets = []
     if !$follow_redis.get("#{params['id']} leaders").nil?
       leader_list = JSON.parse($follow_redis.get("#{params['id']} leaders")).keys
       leader_list.each do |l|
         l_hash = JSON.parse($user_redis.get(l))
         l_tweets = JSON.parse(Tweet.where('user.id' => l.to_i).desc(:date_posted).to_json)
         l_tweets.each do |t|
           t['user'] = l_hash
         end
         tweets.concat(l_tweets)
       end
       return tweets.to_json
     else
       return Array.new.to_json
     end
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
