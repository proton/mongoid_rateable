require "spec_helper"

describe Post do

  before(:each) do
    @bob = User.create :name => "Bob"
    @alice = User.create :name => "Alice"
    @sally = User.create :name => "Sally"
    @post = Post.create :name => "Announcement"
    @article = Article.create :name => "Article"
  end

  it "should have Mongoid::Rateable module" do
    #TODO: Refactor this
    @post.class.const_get("Mongoid").const_get("Rateable").should be_true
  end

  subject { @post }
  it { should respond_to :rate }
  it { should respond_to :unrate }
  it { should respond_to :rate_and_save }
  it { should respond_to :unrate_and_save }
  it { should respond_to :rated? }
  it { should respond_to :rate_count }
  it { should respond_to :rates }
  it { should respond_to :rating }
  it { should respond_to :previous_rating }
  it { should respond_to :rating_delta }
  it { should respond_to :unweighted_rating }
  it { should respond_to :rating_marks }

  describe "#rating_marks" do
    it "should be proper Mongoid field" do
      @post.rating_marks.should be_an_instance_of Array
    end
  end

  context "when rated" do
    before (:each) { @post.rate 1, @bob }

    describe "#rate" do
      it "should track #rates properly" do
        @post.rate 1, @sally
        @post.rates.should eql 2
      end
      it "should track weighted #rates properly" do
        @post.rate 1, @alice, 4
        @post.rates.should eql 5
      end

      it "should limit #rates by user properly" do
        @post.rate 5, @bob
        @post.rates.should eql 5
      end

      it "should not raise exception if rate_value in RATING_RANGE" do
        lambda { @article.rate 1, @sally }.should_not raise_error
      end

      it "should raise exception if rate_value not in RATING_RANGE" do
        lambda { @article.rate 7, @sally }.should raise_error(ArgumentError)
      end

      #TODO: Rewrite for random values
      describe "when using negative values" do
        it "should work properly for -3" do
          @post.rate -3, @sally
          @post.rates.should eql -2
        end
        it "should work properly for -1 with weight 3" do
          @post.rate -1, @sally, 3
          @post.rates.should eql -2
        end
      end
    end

    describe "#rated?" do
      describe "for anyone" do
        specify { @post.rated?().should be_true }
      end

      describe "for Bob" do
        specify { @post.rated_by?(@bob).should be_true }
      end

      describe "when rated by someone else" do
        before { @post.rate 1, @alice }

        describe "for Alice" do
          specify { @post.rated_by?(@alice).should be_true }
        end
      end

      describe "when not rated by someone else" do
        describe "for Sally" do
          specify { @post.rated_by?(@sally).should be_false }
        end
      end
    end

    describe "#unrate" do
      before { @post.unrate @bob }

      it "should have null #rate_count" do
        @post.rate_count.should eql 0
      end

      it "should have null #rates" do
        @post.rates.should eql 0
      end

      it "should be unrated" do
        @post.rated?.should be_false
      end
    end

    describe "#rate_count" do
      it "should know how many rates have been cast" do
        @post.rate 1, @sally
        @post.rate_count.should eql 2
      end
    end

    describe "#rating" do
      it "should calculate the average rate" do
        @post.rate 4, @sally
        @post.rating.should eq 2.5
      end

      it "should calculate the average rate if the result is zero" do
        @post.rate -1, @sally
        @post.rating.should eq 0.0
      end
    end

    describe "#previous_rating" do
      it "should store previous value of the average rate" do
        @post.rate 4, @sally
        @post.previous_rating.should eq 1.0
      end

      it "should store previous value of the average rate after two changes" do
        @post.rate -1, @sally
        @post.rate 4, @sally
        @post.previous_rating.should eq 0.0
      end
    end

    describe "#rating_delta" do
      it "should calculate delta of previous and new ratings" do
        @post.rate 4, @sally
        @post.rating_delta.should eq 1.5
      end

      it "should calculate delta of previous and new ratings" do
        @post.rate -1, @sally
        @post.rating_delta.should eq -1.0
      end
    end

    describe "#unweighted_rating" do
      it "should calculate the unweighted average rate" do
        @post.rate 4, @sally
        @post.unweighted_rating.should eq 2.5
      end

      it "should calculate the unweighted average rate if the result is zero" do
        @post.rate -1, @sally
        @post.unweighted_rating.should eq 0.0
      end
    end
  end

  context "when not rated" do
    describe "#rates" do
      specify { @post.rates.should eql 0 }
    end

    describe "#rating" do
      specify { @post.rating.should be_nil }
    end

    describe "#previous_rating" do
      specify { @post.previous_rating.should be_nil }
    end

    describe "#rating_delta" do
      specify { @post.rating_delta.should eq 0.0 }
    end

    describe "#unweighted_rating" do
      specify { @post.unweighted_rating.should be_nil }
    end

    describe "#unrate" do
      before { @post.unrate @sally }

			it "should have null #rate_count" do
        @post.rate_count.should eql 0
      end

			it "should have null #rates" do
        @post.rates.should eql 0
      end
    end
  end

  context "when saving the collection" do
    before (:each) do
      @post.rate 8, @bob
      @post.rate -10, @sally
      @post.save
      @finded_post = Post.where(:name => "Announcement").first
    end

    describe "#rated_by?" do
      describe "for Bob" do
        specify { @finded_post.rated_by?(@bob).should be_true }
      end

      describe "for Sally" do
        specify { @finded_post.rated_by?(@sally).should be_true }
      end

      describe "for Alice" do
        specify { @finded_post.rated_by?(@alice).should be_false}
      end
    end

    describe "#rates" do
      specify { @finded_post.rates.should eql -2 }
    end

    describe "#rate_count" do
      specify { @finded_post.rate_count.should eql 2 }
    end

    describe "#rating" do
      specify { @finded_post.rating.should eq -1.0 }
    end

    describe "#previous_rating" do
      specify { @finded_post.previous_rating.should eq 8.0 }
    end

    describe "#rating_delta" do
      specify { @post.rating_delta.should eq -9.0 }
    end

    describe "#unweighted_rating" do
      specify { @finded_post.unweighted_rating.should eq -1.0 }
    end
  end

  describe "#rate_and_save" do
    before (:each) do
      @post.rate_and_save 8, @bob, 2
      @post.rate_and_save -10, @sally
      @finded_post = Post.where(:name => "Announcement").first
    end

    describe "#rated?" do
			it "should be #rated? by Bob" do
				@finded_post.rated_by?(@bob).should be_true
			end

			it "should be #rated? by Sally" do
				@finded_post.rated_by?(@sally).should be_true
			end

			it "should be not #rated? by Alice" do
				@finded_post.rated_by?(@alice).should be_false
			end
    end

    it "should have #rates equal 6" do
			@finded_post.rates.should eql 6
    end

    it "should have #rate_count equal 2" do
			@finded_post.rate_count.should eql 2
    end

    it "should have #rate_weight equal 3" do
			@finded_post.rate_weight.should eql 3
    end

    it "should have #rating equal 2.0" do
      @finded_post.rating.should eq 2.0
    end

    it "should have #previous_rating equal 8.0" do
      @finded_post.previous_rating.should eq 8.0
    end

    it "should have #rating_delta equal -6.0" do
      @finded_post.rating_delta.should eq -6.0
    end

    it "should have #unweighted_rating equal 2.0" do
      @finded_post.unweighted_rating.should eq -1.0
    end

    describe "#unrate_and_save" do
			before (:each) do
				@post.unrate_and_save @bob
				@finded_post = Post.where(:name => "Announcement").first
			end

			describe "#rated?" do
				it "should be #rated? by Sally" do
					@finded_post.rated_by?(@sally).should be_true
				end

				it "should be not #rated? by Bob" do
					@finded_post.rated_by?(@bob).should be_false
				end

				it "should be #rated?" do
					@finded_post.rated?.should be_true
				end
			end

			it "should have #rates equal -10" do
				@finded_post.rates.should eql -10
			end

			it "should have #rate_count equal 1" do
				@finded_post.rate_count.should eql 1
			end

			it "should have #rate_weight equal 1" do
				@finded_post.rate_weight.should eql 1
			end

      it "should have #rating equal -10.0" do
        @finded_post.rating.should eq -10.0
      end

      it "should have #previous_rating equal 2.0" do
        @finded_post.previous_rating.should eq 2.0
      end

      it "should have #rating_delta equal -12.0" do
        @finded_post.rating_delta.should eq -12.0
      end

      it "should have #unweighted_rating equal -10.0" do
        @finded_post.unweighted_rating.should eq -10.0
      end
    end
  end

  describe "#scopes" do
		before (:each) do
			@post.delete
			@post1 = Post.create(:name => "Post 1")
			@post2 = Post.create(:name => "Post 2")
			@post3 = Post.create(:name => "Post 3")
			@post4 = Post.create(:name => "Post 4")
			@post5 = Post.create(:name => "Post 5")
			@post1.rate_and_save 5, @sally
			@post1.rate_and_save 3, @bob
			@post4.rate_and_save 1, @sally
		end

    describe "#unrated" do
			it "should return proper count of unrated posts" do
				Post.unrated.size.should eql 3
			end
		end

    describe "#rated" do
			it "should return proper count of rated posts" do
				Post.rated.size.should eql 2
			end
		end

    describe "#rated_by" do
			it "should return proper count of posts rated by Bob" do
				Post.rated_by(@bob).size.should eql 1
			end

			it "should return proper count of posts rated by Sally" do
				Post.rated_by(@sally).size.should eql 2
			end
		end

    describe "#with_rating" do
			before (:each) do
				@post1.rate_and_save 4, @alice
				@post2.rate_and_save 2, @alice
				@post3.rate_and_save 5, @alice
				@post4.rate_and_save 2, @alice
			end

			it "should return proper count of posts with rating 4..5" do
				Post.with_rating(4..5).size.should eql 2
			end

			it "should return proper count of posts with rating 0..2" do
				Post.with_rating(0..2).size.should eql 2
			end

			it "should return proper count of posts with rating 0..5" do
				Post.with_rating(0..5).size.should eql 4
			end
		end

    describe "#highest_rated" do
			it "should return proper count of posts" do
				#mongoid has problems with returning count of documents (https://github.com/mongoid/mongoid/issues/817)
				posts_count = 0
				Post.highest_rated(1).each {|x| posts_count+=1 }
				posts_count.should eql 1
			end

			it "should return proper count of posts" do
				#mongoid has problems with returning count of documents (https://github.com/mongoid/mongoid/issues/817)
				posts_count = 0
				Post.highest_rated(10).each {|x| posts_count+=1 }
				posts_count.should eql 5
			end

			it "should return proper document" do
				Post.highest_rated(1).first.name.should eql "Post 1"
			end
		end
  end
end