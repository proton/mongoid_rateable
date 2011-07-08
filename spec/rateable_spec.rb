require "spec_helper"

describe Post do

  before(:each) do
    @bob = User.create :name => "Bob"
    @alice = User.create :name => "Alice"
    @sally = User.create :name => "Sally"
    @post = Post.create :name => "Announcement"
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
  it { should respond_to :rating_marks }

  describe "#rates" do
    it "should be proper Mongoid field" do
      @post.fields['rates'].should be_an_instance_of Mongoid::Field
    end
  end

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

      it "should limit #rates by user properly" do
        @post.rate 5, @bob
        @post.rates.should eql 5
      end

      #TODO: Rewrite for random values
      describe "when using negative values" do
        it "should work properly for -1" do
          @post.rate -1, @sally
          @post.rates.should eql 0
        end
        it "should work properly for -2" do
          @post.rate -3, @sally
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
        @post.rating.should eql 2.5
      end

      it "should calculate the average rate if the result is zero" do
        @post.rate -1, @sally
        @post.rating.should eql 0.0
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
      specify { @finded_post.rating.should eql -1.0 }
    end
  end

  describe "#rate_and_save" do
    before (:each) do
      @post.rate_and_save 8, @bob
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

    it "should have #rates equal -2" do
			@finded_post.rates.should eql -2
    end

    it "should have #rate_count equal 2" do
			@finded_post.rate_count.should eql 2
    end

    it "should have #rating equal -1.0" do
			@finded_post.rating.should eql -1.0
    end

    describe "#unrate_and_save" do
			before (:each) do
				@post.unrate_and_save @sally
				@finded_post = Post.where(:name => "Announcement").first
			end

			describe "#rated?" do
				it "should be #rated? by Bob" do
					@finded_post.rated_by?(@bob).should be_true
				end

				it "should be not #rated? by Sally" do
					@finded_post.rated_by?(@sally).should be_false
				end

				it "should be #rated?" do
					@finded_post.rated?.should be_true
				end
			end

			it "should have #rates equal 8" do
				@finded_post.rates.should eql 8
			end

			it "should have #rate_count equal 1" do
				@finded_post.rate_count.should eql 1
			end

			it "should have #rating equal 8.0" do
				@finded_post.rating.should eql 8.0
			end
    end
  end
end