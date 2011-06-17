require "spec_helper"

describe Mongoid::Rateable do

  describe ".included" do

    it "adds fields to the rateable document" do
      fields = Post.fields
      fields['points'].should_not == nil
    end

    it "defines methods in rateable document" do
      @post = Post.new
      @post.respond_to?("rate").should == true
      @post.respond_to?("rated?").should == true
      @post.respond_to?("rate_count").should == true
    end

  end

  describe "rate" do

    before(:each) do
      @bob = User.create :name => "Bob"
      @alisa = User.create :name => "Alise"
      @sally = User.create :name => "Sally"
      @post = Post.create :name => "Announcement"
    end

    it "tracks rates" do
      @post.rate 1, @bob
      @post.rate 1, @sally
      @post.points.should == 2
    end

    it "limits rates by user" do
      @post.rate 1, @bob
      @post.rate 5, @bob
      @post.points.should == 5
    end

    it "works with both positive and negative rates" do
      @post.rate 5, @bob
      @post.rate -3, @sally
      @post.points.should == 2
    end

    it "should know if someone has rated" do
      @post.rate 5, @bob
      @post.rated?(@bob).should == true
      @post.rated?(@sally).should == false
    end

    it "should know how many rates have been cast" do
      @post.rate 5, @bob
      @post.rate -5, @sally
      @post.rate_count.should == 2
    end

    it "should calculate the average rate" do
      @post.rate 10, @bob
      @post.rate 5, @sally
      @post.rating.should == 7.5
    end

    it "should average if the result is zero" do
      @post.rate 1, @bob
      @post.rate -1, @sally
      @post.rating.should == 0
    end

    it "should not average if we have no rates" do
      @post.rating.nil?.should == true
    end

    it "should properly update the collection" do
      @post.rate 8, @bob
      @post.rate -10, @sally
      post = Post.where(:name => "Announcement").first
      post.points.should == -2
      post.rated?(@bob).should == true
      post.rated?(@sally).should == true
      post.rate_count.should == 2
      post.rating.should == -1
    end

  end

end

