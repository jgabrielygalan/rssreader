require 'rss'
require 'open-uri'
require 'redis'
require 'date'

$redis = Redis.new

def get_content item
	"#{item.description}<br/>#{item.content_encoded}"
end

def get_guid item
	(item.guid && item.guid.content) || item.link
end

def update_channel_data feed_id, feed
	$redis.hmset("feed:#{feed_id}", "title", feed.channel.title, "link", feed.channel.link, "description", feed.channel.description)
end

def update_feed feed_id, feed_data
	feed = RSS::Parser.parse(open(feed_data["URI"])).to_feed("rss2.0")
	update_channel_data feed_id, feed
	puts "#{feed.channel.title}"
	feed.items.each do |item|
		guid = get_guid item
		exists = $redis.exists("item:#{guid}")
		return if exists
		puts "adding item:#{guid}"
		$redis.zadd("feed:#{feed_id}:items", item.pubDate.to_i, guid)
		$redis.hmset("item:#{guid}", "title", item.title, "URI", item.link, "pubDate", item.pubDate, "content", get_content(item))
	end
end



feeds = $redis.smembers("feeds")
p feeds

feeds.each do |feed_id|
	feed = $redis.hgetall("feed:#{feed_id}")
	p feed
	update_feed(feed_id, feed)
end

