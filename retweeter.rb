require_relative 'tweet_presenter'

class Retweeter
  DAY = 86400
  THREE_MONTHS = 90 * DAY

  def initialize(twitter)
    @twitter = twitter
  end

  def retweet_new_tweets
    puts "Retweeting..."
    tweets = load_home_timeline
    tweets.select(&:retweetable?).each { |t| retweet(t) }
  end

  def print_retweetable_tweets
    puts "./bot retweet would retweet these tweets:"
    tweets = load_home_timeline
    tweets.select(&:retweetable?).each { |t| p t }
  end

  def fetch_all_users_json(options = {})
    users = followed_users
    users |= options[:extra_users] if options[:extra_users]
    days = options[:days]

    tweets_json = users.map { |u| load_user_timeline(u, days).map(&:attrs) }

    Hash[users.zip(tweets_json)]
  end

  def followed_users
    @twitter.following.map(&:screen_name).sort
  end

  def load_home_timeline
    load_timeline(:home_timeline)
  end

  def load_user_timeline(login, days = nil)
    interval = days ? (days * DAY) : THREE_MONTHS
    starting_date = Time.now - interval

    $stderr.print "@#{login} ."
    tweets = load_timeline(:user_timeline, login)

    while tweets.last.created_at > starting_date
      $stderr.print '.'
      batch = load_timeline(:user_timeline, login, :max_id => tweets.last.id - 1)
      break if batch.empty?
      tweets.concat(batch)
    end

    $stderr.puts

    tweets.reject { |t| t.created_at < starting_date }
  end

  def load_timeline(timeline, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    tweets = @twitter.send(timeline, *args, { :count => 200, :include_rts => false }.merge(options))
    tweets.map { |t| TweetPresenter.new(t) }
  end

  def retweet(tweet)
    @twitter.retweet(tweet.id)
  end
end
