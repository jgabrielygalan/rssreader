require 'sinatra'
require 'redis'
require 'haml'


class RssReader < Sinatra::Base

	set :redis, Redis.new
	set :author, "Jesus Gabriel y Galan"

	helpers do
		def redis
			settings.redis
		end

		def entry_data feed
			entry_ids = redis.zrevrange("feed:#{feed["feed_url"]}:entries", 0, -1)
			entry_ids.map do |entry_id|
				entry = redis.hgetall("entry:#{entry_id}")
				entry["entry_id"] = entry_id
				entry
			end
		end
	end

	before do
		feeds = redis.smembers("feeds")
		@feeds = feeds.map do |feed|
			redis.hgetall("feed:#{feed}")
		end
	end

	get '/' do
		@entries = entry_data @feeds.first
		haml :index
	end

	get '/entries/:pos' do |pos|
		@entries = entry_data @feeds[Integer(pos)]
		haml :index
	end
end




#feeds = %w[http://www.xkcd.com/rss.xml]
#feeds = %w[http://feeds.feedburner.com/thechangelog]
#feeds = %w[http://feeds.feedburner.com/geeksAreSexyTechnologyNews]
