require "spec_helper"

describe Post do

	before(:each) do
		@bob = User.create :id => 1, :name => "Bob"
		@alice = User.create :id => 2, :name => "Alice"
		@sally = User.create :id => 3, :name => "Sally"
		@post = Post.create :name => "Announcement"
		@article = Article.create :name => "Article"
	end

	it "should have Mongoid::Rateable module" do
		#TODO: Refactor this
		@post.class.const_get("Mongoid").const_get("Rateable").should_not be nil
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
	it { should respond_to :user_mark }

	describe "#rating_marks" do
		it "should be proper Mongoid field" do
			@post.rating_marks.should be_an_instance_of Array
		end
	end

	context "when rated" do
		before (:each) do
			@post.rate 1, @bob
		end

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

			context "when rate_value in rating range" do
				it { expect { @article.rate 1, @sally }.not_to raise_error }
			end

			context "when rate_value not in rating range" do
				it { expect { @article.rate 7, @sally }.to raise_error(ArgumentError) }
			end

			describe "when using negative values" do
				let(:num) { -rand(1..100) }

				it { expect { @post.rate num, @sally }.to change { @post.rates }.by(num) }
				it { expect { @post.rate -1, @sally, -num }.to change { @post.rates }.by(num) }
			end
		end

		describe "#rated?" do
			describe "for anyone" do
				specify { @post.rated?().should be true }
			end
			describe "for anyone" do
				specify { @article.rated?().should be false }
			end

			describe "for Bob" do
				specify { @post.rated_by?(@bob).should be true }
			end
			describe "for Bob" do
				specify { @article.rated_by?(@bob).should be false }
			end

			describe "when rated by someone else" do
				before do
					@post.rate 1, @alice
				end

				describe "for Alice" do
					specify { @post.rated_by?(@alice).should be true }
				end
			end

			describe "when not rated by someone else" do
				describe "for Sally" do
					specify { @post.rated_by?(@sally).should be false }
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
				@post.rated?.should be false
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

		describe "#user_mark" do
			describe "should give mark" do
				specify { @post.user_mark(@bob).should eq 1}
			end
			describe "should give nil" do
				specify { @post.user_mark(@alice).should be_nil}
			end
			describe "should give marks" do
				specify { @post.user_mark([@bob, @alice]).should eq Hash[1,1] }
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
			before do
				@post.unrate @sally
			end

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
			@f_post = Post.where(:name => "Announcement").first
		end

		describe "#rated_by?" do
			describe "for Bob" do
				specify { @f_post.rated_by?(@bob).should be true }
			end

			describe "for Sally" do
				specify { @f_post.rated_by?(@sally).should be true }
			end

			describe "for Alice" do
				specify { @f_post.rated_by?(@alice).should be false}
			end
		end

		describe "#rates" do
			specify { @f_post.rates.should eql -2 }
		end

		describe "#rate_count" do
			specify { @f_post.rate_count.should eql 2 }
		end

		describe "#rating" do
			specify { @f_post.rating.should eq -1.0 }
		end

		describe "#previous_rating" do
			specify { @f_post.previous_rating.should eq 8.0 }
		end

		describe "#rating_delta" do
			specify { @post.rating_delta.should eq -9.0 }
		end

		describe "#unweighted_rating" do
			specify { @f_post.unweighted_rating.should eq -1.0 }
		end
	end

	describe "#rate_and_save" do
		before (:each) do
			@post.rate_and_save 8, @bob, 2
			@post.rate_and_save -10, @sally
			@f_post = Post.where(:name => "Announcement").first
		end

		describe "#rated?" do
			it "should be #rated? by Bob" do
				@f_post.rated_by?(@bob).should be true
			end

			it "should be #rated? by Sally" do
				@f_post.rated_by?(@sally).should be true
			end

			it "should be not #rated? by Alice" do
				@f_post.rated_by?(@alice).should be false
			end
		end

		it "should have #rates equal 6" do
			@f_post.rates.should eql 6
		end

		it "should have #rate_count equal 2" do
			@f_post.rate_count.should eql 2
		end

		it "should have #rate_weight equal 3" do
			@f_post.rate_weight.should eql 3
		end

		it "should have #rating equal 2.0" do
			@f_post.rating.should eq 2.0
		end

		it "should have #previous_rating equal 8.0" do
			@f_post.previous_rating.should eq 8.0
		end

		it "should have #rating_delta equal -6.0" do
			@f_post.rating_delta.should eq -6.0
		end

		it "should have #unweighted_rating equal -1.0" do
			@f_post.unweighted_rating.should eq -1.0
		end

		describe "#unrate_and_save" do
			before (:each) do
				@post.unrate_and_save @bob
				@f_post = Post.where(:name => "Announcement").first
			end

			describe "#rated?" do
				it "should be #rated? by Sally" do
					@f_post.rated_by?(@sally).should be true
				end

				it "should be not #rated? by Bob" do
					@f_post.rated_by?(@bob).should be false
				end

				it "should be #rated?" do
					@f_post.rated?.should be true
				end
			end

			it "should have #rates equal -10" do
				@f_post.rates.should eql -10
			end

			it "should have #rate_count equal 1" do
				@f_post.rate_count.should eql 1
			end

			it "should have #rate_weight equal 1" do
				@f_post.rate_weight.should eql 1
			end

			it "should have #rating equal -10.0" do
				@f_post.rating.should eq -10.0
			end

			it "should have #previous_rating equal 2.0" do
				@f_post.previous_rating.should eq 2.0
			end

			it "should have #rating_delta equal -12.0" do
				@f_post.rating_delta.should eq -12.0
			end

			it "should have #unweighted_rating equal -10.0" do
				@f_post.unweighted_rating.should eq -10.0
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

describe Comment do

	before(:each) do
		@bob = User.create :name => "Bob"
		@alice = User.create :name => "Alice"
		@sally = User.create :name => "Sally"
		@post = Post.create :name => "Announcement"
		@comment1 = @post.comments.create :content => 'Hello!'
		@comment2 = @post.comments.create :content => 'Goodbye!'
	end

	it "should have Mongoid::Rateable module" do
		#TODO: Refactor this
		@comment1.class.const_get("Mongoid").const_get("Rateable").should_not be nil
	end

	subject { @comment1 }
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
	it { should respond_to :user_mark }

	describe "#rating_marks" do
		it "should be proper Mongoid field" do
			@comment1.rating_marks.should be_an_instance_of Array
		end
	end

	context "when rated" do
		before (:each) do
			@comment1.rate 2, @bob
		end

		describe "#rate" do
			it "should track #rates properly" do
				@comment1.rate 3, @sally
				@comment1.rates.should eql 5
			end

			it "should track weighted #rates properly" do
				@comment1.rate 1, @alice, 4
				@comment1.rates.should eql 6
			end

			it "should limit #rates by user properly" do
				@comment1.rate 5, @bob
				@comment1.rates.should eql 5
			end

			context "when rate_value in rating range" do
				it { expect { @comment1.rate 1, @sally }.not_to raise_error }
			end

			context "when rate_value not in rating range" do
				it { expect { @comment1.rate 9, @sally }.to raise_error(ArgumentError) }
			end

			describe "when using negative values" do
				let(:num) { -rand(1..5) }

				it { expect { @comment1.rate num, @sally }.to change { @comment1.rates }.by(num) }
				it { expect { @comment1.rate -1, @sally, -num }.to change { @comment1.rates }.by(num) }
			end
		end

		describe "#rated?" do
			describe "for anyone" do
				specify { @comment1.rated?().should be true }
			end
			describe "for anyone" do
				specify { @comment2.rated?().should be false }
			end

			describe "for Bob" do
				specify { @comment1.rated_by?(@bob).should be true }
			end
			describe "for Bob" do
				specify { @comment2.rated_by?(@bob).should be false }
			end

			describe "when rated by someone else" do
				before do
					@comment1.rate 1, @alice
				end

				describe "for Alice" do
					specify { @comment1.rated_by?(@alice).should be true }
				end
			end

			describe "when not rated by someone else" do
				describe "for Sally" do
					specify { @comment1.rated_by?(@sally).should be false }
				end
			end
		end

		describe "#unrate" do
			before { @comment1.unrate @bob }

			it "should have null #rate_count" do
				@comment1.rate_count.should eql 0
			end

			it "should have null #rates" do
				@comment1.rates.should eql 0
			end

			it "should be unrated" do
				@comment1.rated?.should be false
			end
		end

		describe "#rate_count" do
			it "should know how many rates have been cast" do
				@comment1.rate 1, @sally
				@comment1.rate_count.should eql 2
			end
		end

		describe "#rating" do
			it "should calculate the average rate" do
				@comment1.rate 4, @sally
				@comment1.rating.should eq 3.0
			end

			it "should calculate the average rate if the result is zero" do
				@comment1.rate -2, @sally
				@comment1.rating.should eq 0.0
			end
		end

		describe "#previous_rating" do
			it "should store previous value of the average rate" do
				@comment1.rate 4, @sally
				@comment1.previous_rating.should eq 2.0
			end

			it "should store previous value of the average rate after two changes" do
				@comment1.rate -2, @sally
				@comment1.rate 4, @sally
				@comment1.previous_rating.should eq 0.0
			end
		end

		describe "#rating_delta" do
			it "should calculate delta of previous and new ratings" do
				@comment1.rate 4, @sally
				@comment1.rating_delta.should eq 1.0
			end

			it "should calculate delta of previous and new ratings" do
				@comment1.rate -1, @sally
				@comment1.rating_delta.should eq -1.5
			end
		end

		describe "#unweighted_rating" do
			it "should calculate the unweighted average rate" do
				@comment1.rate 4, @sally
				@comment1.unweighted_rating.should eq 3.0
			end

			it "should calculate the unweighted average rate if the result is zero" do
				@comment1.rate -2, @sally
				@comment1.unweighted_rating.should eq 0.0
			end
		end

		describe "#user_mark" do
			describe "should give mark" do
				specify { @comment1.user_mark(@bob).should eq 2}
			end
			describe "should give nil" do
				specify { @comment1.user_mark(@alice).should be_nil}
			end
		end
	end

	context "when not rated" do
		describe "#rates" do
			specify { @comment1.rates.should eql 0 }
		end

		describe "#rating" do
			specify { @comment1.rating.should be_nil }
		end

		describe "#previous_rating" do
			specify { @comment1.previous_rating.should be_nil }
		end

		describe "#rating_delta" do
			specify { @comment1.rating_delta.should eq 0.0 }
		end

		describe "#unweighted_rating" do
			specify { @comment1.unweighted_rating.should be_nil }
		end

		describe "#unrate" do
			before do
				@comment1.unrate @sally
			end

			it "should have null #rate_count" do
				@comment1.rate_count.should eql 0
			end

			it "should have null #rates" do
				@comment1 .rates.should eql 0
			end
		end
	end

	context "when saving the collection" do
		before (:each) do
			@comment1.rate 3, @bob
			@comment1.rate -2, @sally
			@comment1.save
			@f_post = Post.where(:name => "Announcement").first
			@f_comment = @f_post.comments.where(:content => "Hello!").first
		end

		describe "#rated_by?" do
			describe "for Bob" do
				specify { @f_comment.rated_by?(@bob).should be true }
			end

			describe "for Sally" do
				specify { @f_comment.rated_by?(@sally).should be true }
			end

			describe "for Alice" do
				specify { @f_comment.rated_by?(@alice).should be false}
			end
		end

		describe "#rates" do
			specify { @f_comment.rates.should eql 1 }
		end

		describe "#rate_count" do
			specify { @f_comment.rate_count.should eql 2 }
		end

		describe "#rating" do
			specify { @f_comment.rating.should eq 0.5 }
		end

		describe "#previous_rating" do
			specify { @f_comment.previous_rating.should eq 3.0 }
		end

		describe "#rating_delta" do
			specify { @f_comment.rating_delta.should eq -2.5 }
		end

		describe "#unweighted_rating" do
			specify { @f_comment.unweighted_rating.should eq 0.5 }
		end
	end

	describe "#rate_and_save" do
		before (:each) do
			@comment1.rate_and_save 4, @bob, 2
			@comment1.rate_and_save -2, @sally
			@f_post = Post.where(:name => "Announcement").first
			@f_comment = @f_post.comments.where(:content => "Hello!").first
		end

		describe "#rated?" do
			it "should be #rated? by Bob" do
				@f_comment.rated_by?(@bob).should be true
			end

			it "should be #rated? by Sally" do
				@f_comment.rated_by?(@sally).should be true
			end

			it "should be not #rated? by Alice" do
				@f_comment.rated_by?(@alice).should be false
			end
		end

		it "should have #rates equal 6" do
			@f_comment.rates.should eql 6
		end

		it "should have #rate_count equal 2" do
			@f_comment.rate_count.should eql 2
		end

		it "should have #rate_weight equal 3" do
			@f_comment.rate_weight.should eql 3
		end

		it "should have #rating equal 2.0" do
			@f_comment.rating.should eq 2.0
		end

		it "should have #previous_rating equal 4.0" do
			@f_comment.previous_rating.should eq 4.0
		end

		it "should have #rating_delta equal -2.0" do
			@f_comment.rating_delta.should eq -2.0
		end

		it "should have #unweighted_rating equal 1.0" do
			@f_comment.unweighted_rating.should eq 1.0
		end

		describe "#unrate_and_save" do
			before (:each) do
				@comment1.unrate_and_save @bob
			@f_post = Post.where(:name => "Announcement").first
			@f_comment = @f_post.comments.where(:content => "Hello!").first
			end

			describe "#rated?" do
				it "should be #rated? by Sally" do
					@f_comment.rated_by?(@sally).should be true
				end

				it "should be not #rated? by Bob" do
					@f_comment.rated_by?(@bob).should be false
				end

				it "should be #rated?" do
					@f_comment.rated?.should be true
				end
			end

			it "should have #rates equal -2" do
				@f_comment.rates.should eql -2
			end

			it "should have #rate_count equal 1" do
				@f_comment.rate_count.should eql 1
			end

			it "should have #rate_weight equal 1" do
				@f_comment.rate_weight.should eql 1
			end

			it "should have #rating equal -2.0" do
				@f_comment.rating.should eq -2.0
			end

			it "should have #previous_rating equal 2.0" do
				@f_comment.previous_rating.should eq 2.0
			end

			it "should have #rating_delta equal -4.0" do
				@f_comment.rating_delta.should eq -4.0
			end

			it "should have #unweighted_rating equal -2.0" do
				@f_comment.unweighted_rating.should eq -2.0
			end
		end
	end

	describe "#scopes" do
		before (:each) do
			@post1 = Post.create(:name => "Post 1")
			@c1 = @post1.comments.create(:content => 'c1')
			@c2 = @post1.comments.create(:content => 'c2')
			@c3 = @post1.comments.create(:content => 'c3')
			@c4 = @post1.comments.create(:content => 'c4')
			@c5 = @post1.comments.create(:content => 'c5')
			@c1.rate_and_save 5, @sally
			@c1.rate_and_save 3, @bob
			@c4.rate_and_save 1, @sally
		end

		describe "#unrated" do
			it "should return proper count of unrated comments" do
				@post1.comments.unrated.size.should eql 3
			end
		end

		describe "#rated" do
			it "should return proper count of rated comments" do
				@post1.comments.rated.size.should eql 2
			end
		end

		describe "#rated_by" do
			it "should return proper count of comments rated by Bob" do
				@post1.comments.rated_by(@bob).size.should eql 1
			end

			it "should return proper count of comments rated by Sally" do
				@post1.comments.rated_by(@sally).size.should eql 2
			end
		end

		describe "#with_rating" do
			before (:each) do
				@c1.rate_and_save 4, @alice
				@c2.rate_and_save 2, @alice
				@c3.rate_and_save 5, @alice
				@c4.rate_and_save 2, @alice
			end

			it "should return proper count of comments with rating 4..5" do
				@post1.comments.with_rating(4..5).size.should eql 2
			end

			it "should return proper count of comments with rating 0..2" do
				@post1.comments.with_rating(0..2).size.should eql 2
			end

			it "should return proper count of comments with rating 0..5" do
				@post1.comments.with_rating(0..5).size.should eql 4
			end
		end

		describe "#highest_rated" do
			it "should return proper count of comments" do
				#mongoid has problems with returning count of documents (https://github.com/mongoid/mongoid/issues/817)
				comments_count = 0
				@post1.comments.highest_rated(1).each {|x| comments_count+=1 }
				comments_count.should eql 1
			end

			it "should return proper count of comments" do
				#mongoid has problems with returning count of documents (https://github.com/mongoid/mongoid/issues/817)
				comments_count = 0
				@post1.comments.highest_rated(10).each {|x| comments_count+=1 }
				comments_count.should eql 5
			end

			#Don't work! (Mongoid can't sort embedded documents)
			# it "should return proper document" do
			# 	@post1.comments.highest_rated(1).first.content.should eql "c1"
			# end
		end
	end
end
