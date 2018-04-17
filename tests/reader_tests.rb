require 'minitest/autorun'
require 'rack/test'
require 'rake/testtask'
require 'json'
require 'rest-client'
require_relative '../service.rb'

class ReaderTest < Minitest::Test

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def flush_all
    $tweet_redis.delete("recent")

  end

  def flush
  end

end
