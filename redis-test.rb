require 'redis'

uri = URI.parse("redis-19695.c8.us-east-1-3.ec2.cloud.redislabs.com:19695")
$redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
$redis.set("foo", "bar")
puts $redis.get('foo')
