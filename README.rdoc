= Mongoid::Rateable

Provides fields and methods for the *rating* manipulation on Mongoid documents

{<img src="https://secure.travis-ci.org/proton/mongoid_rateable.png" />}[http://travis-ci.org/proton/mongoid_rateable]

Lastest version of Mongoid:Rateable requires mongoid 3, 4, 5, 6 and 7.

If you need a mongoid 2 support, look at mongoid_rateable 0.1.7.

== Support us


{<img src="http://api.flattr.com/button/flattr-badge-large.png" />}[https://flattr.com/submit/auto?user_id=proton&url=https://github.com/proton/mongoid_rateable/&title=MongoidRateable&language=&tags=github&category=software] or https://www.patreon.com/_proton

== Installation

Add to Gemfile:

    gem 'mongoid_rateable'

== Getting Started


Simply use the `rateable` macro from any class that is a Mongoid Document.

This macro will include `Mongoid::Rateable` into the class and configure the rating functionality using the options hash. For any option not present, the default option value will be used.

    class Post
      include Mongoid::Document

      rateable range: (-5..7), raters: [User, Admin]
    end

You can also set the `default_rater`

    class Post
      include Mongoid::Document

      # will simply call the 'owner' method to find the default rater
      # if no rater given when rating

      rateable range: (-5..7), raters: [User, Admin], default_rater: 'owner'
    end

    class Post
      include Mongoid::Document

      # if given a block, this will be used as a dynamic way to find
      # the a rater in case no rater is passed in as the 2nd argument to
      # the rate method

      rateable range: (-5..7), raters: [User, Admin] do
        # will by default be rated by the last user
        # who made a comment to this post!
        comments.last.user
      end
    end

Note: For even more control over the configuration, see the `ClassMethods` module code in `rateable.rb`.

== Cast Rates

You can rate by passing an integer and a rater model to the "rate" method:

    @post = Post.first
    @user = User.where(:name => 'Bill') # or more likely, current_user

    @post.rate 1, @user     # I like this!
    @post.rate -1, @user    # I don't like this!
    @post.rate 5, @user     # I LOVE this!
    @post.rate -10, @user   # Delete it from the Internet!

    # Many users love this!
    @post.rate 5, @users     # They LOVIN' it!

Rates have weight (1 by default)

    @post.rate 5, @user, 3     # Rate @post with weight 3 (@user has high karma)
    @post.rate 3, @user, 1     # Rate @post with weight 1 (@user has low karma)

You can unrate by using "unrate" method:

    @post.unrate @user

And don't forget to save rateable object:

    @post.save

Sure, you can rate and save in one function:

    @post.rate_and_save(3, @user)
    @post.unrate_and_save(@user)

== Additional Functionality

You'll often want to know if a user already rated post.  Simple:

    @post.rated_by? @user   # True if it rated by user

And if someone rated it:

    @post.rated?            # True if it rated by someone

You can get user mark:

    @post.user_mark(@user)  # Mark or nil (if not rated by user)

Or marks:

    @post.user_marks([@user1, @user2])  # Hash {user.id => mark}

You can also get a tally of the number of rates cast:

    @post.rate_count        # Just one so far!

You can get a total weight of post rates:

    @post.rate_weight        # Just one so far!

And you can get the average rating:

    @post.rating            # rates / rate_weight

And you can get the average rating without weights (It calculates realtime, so it can be slow):

    @post.unweighted_rating # rates without weights / rate_count

And you can get the previous rating and delta:

    @post.previous_rating
    @post.rating_delta      # rating - previous_rating

== Scopes

You can get rated or unrated posts:

    Post.rated
    Post.unrated

You can get posts rated by someone:

    Post.rated_by(@user)

You can get posts with some rating:

    Post.with_rating(2..5)
    Post.with_rating(0..10)
    Post.with_rating(-2..2)

You can get most rated and highest rated posts:
(Sorry, this method doesn't work with embedded documents)

    Post.highest_rated      # 10 (or less) highest rated posts
    Post.highest_rated(5)   # 5 (or less) highest rated posts

== Contributing to Mongoid::Rateable

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

== Copyright

Copyright (c) 2011 Peter Savichev (proton). See LICENSE.txt for
further details.
