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

		def item_data feed_position
			item_ids = redis.zrevrange("feed:#{@feeds[feed_position]["URI"]}:items", 0, -1)
			item_ids.map do |item_id|
				item = redis.hgetall("item:#{item_id}")
				item["item_id"] = item_id
				item
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
		@items = item_data 0
		haml :index
	end

	get '/:pos' do |pos|
		@items = item_data Integer(pos)
		haml :index
	end
end




#feeds = %w[http://www.xkcd.com/rss.xml]
#feeds = %w[http://feeds.feedburner.com/thechangelog]
#feeds = %w[http://feeds.feedburner.com/geeksAreSexyTechnologyNews]
