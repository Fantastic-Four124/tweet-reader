require 'minitest/autorun'
require 'rack/test'
require 'rake/testtask'
require 'json'
require 'rest-client'
require_relative '../service.rb'
require_relative '../models/tweet.rb'

class WriterTest < Minitest::Test

  include Rack::Test::Methods

  # Setup
  #---------------------------------------------#

  def app
    Sinatra::Application
  end

  @apitoken = "a3432kp97453r5702m345z432q34342f"

  def flush_all
    $tweet_redis.delete("recent")
    $tweet_redis_spare.delete("recent")
    $tweet_redis.delete("175_feed") # userA
    $tweet_redis.delete("180_feed") # userB
    $tweet_redis_spare.delete("175_feed") # userA
    $tweet_redis_spare.delete("180_feed") # userB
    $user_redis.delete(@apitoken)
    $follow_redis.delete("175 followers")
    Tweet.delete_all(contents: "I am a test_tweet")
  end

  def create_apitoken
    $user_redis.set({username: "userA", id: 175}.to_json)
  end

  # Tests
  #--------------------------------------------#

  def read_recent_tweets
    flush_all
    assert $tweet_redis.get("recent").nil? && $tweet_redis_spare.get("recent").nil?
    get PREFIX + '/tweets/recent', {}, "CONTENT_TYPE" => "application/json"
    assert last_response.ok? && assert last_response.include?('test')
    flush_all
  end

  def read_cached_recent_tweets
    RestClient.post('https://nt-tweet-writer.herokuapp.com/api/v1/tweets/:username')
    assert !$tweet_redis.get("recent").nil? && !$tweet_redis_spare.get("recent").nil?
    get PREFIX + '/tweets/recent', {}, "CONTENT_TYPE" => "application/json"
    assert last_response.ok? && assert last_response.include?('test')
    flush_all
  end

  def unauthorized_read_from_feed
    get PREFIX + "/not_a_token/users/175/feed", {}, "CONTENT_TYPE" => "application/json"
    assert last_response.include?(JSON.parse({err: true}.to_json))
    flush_all
  end

  def read_from_feed
    get PREFIX + "/#{@apitoken}/users/175/feed", {}, "CONTENT_TYPE" => "application/json"
  end

  def read_cached_feed
    get PREFIX + "/#{@apitoken}/users/175/feed", {}, "CONTENT_TYPE" => "application/json"
  end

  def unauthorized_read_timeline
    get PREFIX + "/not_a_token/users/180/timeline", {}, "CONTENT_TYPE" => "application/json"
    assert last_response.include?(JSON.parse({err: true}.to_json))
  end

  def read_from_timeline
    get PREFIX + "/not_a_token/users/180/timeline", {}, "CONTENT_TYPE" => "application/json"
  end

  def search_by_terms
    get PREFIX + "/hashtags/test", {}, "CONTENT_TYPE" => "application/json"
    last_response.include?('ewiroskasdnvksdla;rjea')
  end

  def empty_search_terms
    get PREFIX + "/hashtags/ewiroskasdnvksdla;rjea", {}, "CONTENT_TYPE" => "application/json"
    assert !last_response.include?('ewiroskasdnvksdla;rjea')
  end

end
