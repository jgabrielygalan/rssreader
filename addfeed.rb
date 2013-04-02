require 'redis'

$redis = Redis.new

feed_url = ARGV[0]
if $redis.exists "feed:#{feed_url}"
	puts "That feed already exists"
	exit
end

$redis.sadd("feeds", feed_url)
$redis.hset("feed:#{feed_url}", "URI", feed_url)
puts "feed added"
