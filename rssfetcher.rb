require 'feedzirra'
require 'redis'

def update_feed_data feed_url, feed
	data = {}
	data["title"] = feed.title
	data["feed_url"] = feed.feed_url
	data["url"] = feed.url
	data["last_modified"] = feed.last_modified
	data["description"] = feed.description
	$redis.hmset("feed:#{feed_url}", *data.each_pair.to_a)
end

def update_feed feed_url
	feed = Feedzirra::Feed.fetch_and_parse(feed_url)
	update_feed_data feed_url, feed
	puts "#{feed.title}"
	feed.entries.each do |entry|
		key = "entry:#{entry.entry_id}"
		next if $redis.exists key
		puts "adding #{key}"
		$redis.zadd("feed:#{feed_url}:entries", entry.published.to_i, entry.entry_id)
		$redis.hmset(key, "title", entry.title, "url", entry.url, "published", entry.published, "content", entry.content)
	end
end



$redis = Redis.new
feeds = $redis.smembers("feeds")
p feeds

feeds.each do |feed_url|
	feed = $redis.hgetall("feed:#{feed_url}")
	p feed
	update_feed feed_url
end

__END__


feed = Feedzirra::Feed.fetch_and_parse("http://martinfowler.com/feed.atom")
1.9.2p290 :017 > feed.feed_url
 => "http://martinfowler.com/feed.atom" 
1.9.2p290 :018 > feed.last_modified
 => 2013-04-01 20:27:23 +0200 
1.9.2p290 :019 > feed.title
 => "Martin Fowler" 
1.9.2p290 :020 > feed.description
 => "Master feed of news and updates from martinfowler.com" 
 entry = feed.entries.first
1.9.2p290 :037 > entry.url
 => "http://martinfowler.com/photos/43.html" 
1.9.2p290 :038 > entry.entry_id
 => "tag:martinfowler.com,2013-03-25:photostream-43" 
1.9.2p290 :039 > entry.published
 => 2013-03-25 14:59:00 UTC 
1.9.2p290 :040 > entry.title
 => "photostream 43" 
1.9.2p290 :041 > entry.content
 => "\n<p><a href = 'http://martinfowler.com/photos/43.html'><img src = 'http://martinfowler.com/photos/43.jpg'></img></a></p>\n\n<p></p>\n\n<p>Martindale, Cumbria, England</p>\n" 
