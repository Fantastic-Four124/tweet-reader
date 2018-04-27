# server.rb
require 'sinatra'
require 'mongoid'
require 'mongoid_search'
require 'json'
require 'byebug'
require 'sinatra/cors'
require_relative 'models/tweet'
require 'rest-client'
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
  $follow_service = "https://fierce-garden-41263.herokuapp.com"
  tweet_uri = URI.parse(ENV["TWEET_REDIS_URL"])
  user_uri = URI.parse(ENV['USER_REDIS_URL'])
  follow_uri = URI.parse(ENV['FOLLOW_REDIS_URL'])
  tweet_uri_spare = URI.parse(ENV['TWEET_REDIS_SPARE_URL'])
  tweet_uri_3 = URI.parse(ENV['TWEET_REDIS_3'])
  $tweet_redis_spare = Redis.new(:host => tweet_uri_spare.host, :port => tweet_uri_spare.port, :password => tweet_uri_spare.password)
  $tweet_redis = Redis.new(:host => tweet_uri.host, :port => tweet_uri.port, :password => tweet_uri.password)
  $tweet_redis_3 = Redis.new(:host => tweet_uri_3.host, :port => tweet_uri_3.port, :password => tweet_uri_3.password)
  $user_redis = Redis.new(:host => user_uri.host, :port => user_uri.port, :password => user_uri.password)
  $follow_redis = Redis.new(:host => follow_uri.host, :port => follow_uri.port, :password => follow_uri.password)
  PREFIX = '/api/v1'
end

helpers do
  def cache_translate(struct)
    choo_tweets = Array.new
    if $tweet_redis.llen("recent") > 0
      $tweet_redis.lrange("recent", 0, -1).each do |tweet|
        choo_tweets << tweet #JSON.parse(tweet)
      end
    else
      Tweet.desc(:date_posted).limit(50).each do |tweet|
        $tweet_redis.lpush("recent", tweet.as_json)
        $tweet_redis_spare.lpush("recent", tweet.as_json)
        $tweet_redis_3.lpush("recent", tweet.as_json)
        choo_tweets << JSON.parse(tweet.as_json)
      end
    end
    choo_tweets.to_json
  end
end

get '/loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt' do
  send_file 'loaderio-e30c4c1f459b4ac680a9e6cc226a3199.txt'
end

get '/loaderio-16864484b2fbdbe95495f6268aad2f2b.txt' do
  send_file 'loaderio-16864484b2fbdbe95495f6268aad2f2b.txt'
end

get PREFIX + '/tweets/:tweet_id/tweet_id' do
  Tweet.find_by(params[:tweet_id]).as_json
end

get PREFIX + '/tweets/recent' do # Get 50 random tweets
  choo_tweets = Array.new
  if $tweet_redis.llen("recent") > 0
    if rand(2) == 1
      return $tweet_redis.lrange("recent", 0, -1).to_json
    else
      return $tweet_redis_spare.lrange("recent", 0, -1).to_json
    end
  else
    choo_tweets = get_tweets_from_database(2,'recent')
    choo_tweets.each do |tweet|
      $tweet_redis.lpush("recent", tweet)
      $tweet_redis_spare.lpush("recent", tweet)
      $tweet_redis_3.lpush("recent", tweet)
    end
    return choo_tweets.to_json
  end
  {err: true}.to_json
end


get PREFIX + '/:token/users/:id/feed' do
  session = $user_redis.get params['token']
  session = true if params['token'] == 'testuser'
  if session
    #desc(:date_posted)
    if $tweet_redis.llen(params['id'].to_s + "_feed") > 0
      if rand(2) == 1
        return $tweet_redis.lrange(params['id'].to_s + "_feed", 0, -1).to_json
      else
        return $tweet_redis_spare.lrange(params['id'].to_s + "_feed", 0, -1).to_json
      end
    else
      choo_tweets = get_tweets_from_database(1,params['id'])
      choo_tweets.each do |tweet|
        $tweet_redis.lpush(params['id'].to_s + "_feed", tweet)
        $tweet_redis_spare.lpush(params['id'].to_s + "_feed", tweet)
        $tweet_redis_3.lpush(params['id'].to_s + "_feed", tweet)
      end
      return choo_tweets.to_json
    end
  end
  {err: true}.to_json
end

def get_tweets_from_database(flag,key_word)
  choo_tweets = []
  tweets = []
  queue_name = flag == 1? key_word.to_s + "_feed" : "recent"
  if flag == 1
    tweets = Tweet.where('user.id' => key_word.to_i).desc(:date_posted).limit(50)
  else
    tweets = Tweet.desc(:date_posted).limit(50)
  end
  tweets.each do |tweet|
    $tweet_redis.lpush(queue_name,tweet.as_json)
    $tweet_redis_spare.lpush(queue_name,tweet.as_json)
    $tweet_redis_3.lpush(queue_name,tweet.as_json)
    choo_tweets << tweet.as_json
  end
  return choo_tweets
end

get PREFIX + '/:token/users/:id/timeline' do
  session = $user_redis.get params['token']
  session = true if params['token'] == 'testuser'
  if session
    if $tweet_redis.llen(params['id'] + "_timeline") > 0
      if rand(2) == 1
        return $tweet_redis.lrange(params['id'] + "_timeline", 0, -1).to_json
      else
        return $tweet_redis_spare.lrange(params['id'] + "_timeline", 0, -1).to_json
      end
    else
      tweets = get_timeline_manually(params['id'])
      return tweets.to_json
    end
  end
  {err: true}.to_json
end

def get_timeline_manually(user_id)
  leader_list = get_leader_list(user_id)
  leaders_tweet_list = generate_potential_tweet_list(leader_list)
  assemble_timeline(leaders_tweet_list,user_id)
end

def get_leader_list(user_id)
  leader_list = []
  if !$follow_redis.get("#{user_id} leaders").nil?
    leader_list = JSON.parse($follow_redis.get("#{user_id} leaders")).keys
  else
    follow_list_link = $follow_service + "/leaders/#{user_id}"
    leader_list = JSON.parse(RestClient.get(follow_list_link))
  end
  leader_list
end

def generate_potential_tweet_list(leader_list)
  leaders_tweet_list = []
  if leader_list != "[]".to_json
    leader_list.each do |leader_id|
      leaders_tweet_list << get_new_leader_feed(leader_id)
    end
  end
  leaders_tweet_list
end

def get_new_leader_feed(leader_id)
  new_leader_feed = []
  if $tweet_redis.llen(leader_id+ "_feed") > 0
      $tweet_redis.lrange(leader_id+ "_feed", 0, -1).each do |tweet|
        new_leader_feed << JSON.parse(tweet)
      end
  else
    new_leader_feed  = Tweet.where('user.id' => leader_id).desc(:date_posted).limit(50)
  end
  new_leader_feed
end

def assemble_timeline (leaders_tweet_list,user_id)
    tweets = []
    count = 0
    empty_list_set = Set.new

    while (count < 50 && empty_list_set.size < leaders_tweet_list.size)
      temp_tweet = nil
      index = -1
      for i in 0..leaders_tweet_list.size - 1 do
        next if check_empty_list(leaders_tweet_list,i,empty_list_set)
        if (temp_tweet.nil? || leaders_tweet_list[i][0][:date_posted] > temp_tweet[:date_posted])
          temp_tweet = leaders_tweet_list[i][0]
          index = i
        end
      end
      push_tweet_to_redis(tweets,leaders_tweet_list,user_id,temp_tweet,index) if !temp_tweet.nil?
    end
    tweets
  end

def check_empty_list(leaders_tweet_list,i,empty_list_set)
  if leaders_tweet_list[i].empty?
    empty_list_set.add(i)
    return true
  end
  return false
end

def push_tweet_to_redis(tweets,leaders_tweet_list,user_id,temp_tweet,index)
  tweets << temp_tweet.as_json
  $tweet_redis.lpush(user_id + "_timeline",temp_tweet.as_json)
  $tweet_redis_spare.lpush(user_id + "_timeline",temp_tweet.as_json)
  $tweet_redis_3.lpush(user_id + "_timeline",temp_tweet.as_json)
  leaders_tweet_list[index].shift if index >= 0
end


get PREFIX + '/hashtags/:term' do
  #Tweet.full_text_search(params[:label]).limit(50).desc(:date_posted).to_json
  # swtich to where search
  Tweet.where({"$text" => {"$search" => params[:term]}}).as_json
end

get PREFIX + '/searches/:term' do
  # byebug
  Tweet.where({"$text" => {"$search" => params[:term]}}).as_json
end
