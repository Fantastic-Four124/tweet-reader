require 'minitest/autorun'
require 'rack/test'
require 'rake/testtask'
require 'json'
require 'rest-client'
require_relative '../service.rb'

class ReaderTest < Minitest::Test

  include Rack::Test::Methods

  # Setup
  #---------------------------------------------#

  def app
    Sinatra::Application
  end

  def flush_all
    $tweet_redis.delete("recent")
    $tweet_redis.delete("userA_feed")
    $tweet_redis.delete("userB_feed")
    $follow_redis.delete("userA")
    $follow_redis.delete("userB")
  end

  # Tests
  #--------------------------------------------#

  def read_recent_empty
  end

  def read_recent_tweets
  end

  def read_cached_recent_tweets
  end

  def read_username_tweets
  end

  def unauthorized_read_from_feed
  end

  def read_from_feed
  end

  def read_cached_feed
  end

  def read_cached_username_tweets
  end

  def unauthorized_read_timeline
  end

  def read_from_timeline
  end

  def search_by_hashtag
  end

  def empty_hashtag_search
  end

  def search_by_terms
  end

  def empty_search_terms
  end

end
