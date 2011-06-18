require "spec_helper"

RSpec::Matchers.define :have_module do |expected|
  match do |actual|
    actual == expected
  end
  
  diffable
end


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
  it { should respond_to :rated? }
  it { should respond_to :unrate }
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
  
  describe "when rated" do
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
      describe "for Bob" do 
        specify { @post.rated?(@bob).should be_true }
      end
      
      describe "when rated by someone else" do
        before { @post.rate 1, @alice }
        
        describe "for Alice" do
          specify { @post.rated?(@alice).should be_true }
        end
      end
      
      describe "when not rated by someone else" do
        describe "for Sally" do
          specify { @post.rated?(@sally).should be_false }
        end
      end
    end
    
    describe "#unrate" do
      before { @post.unrate @bob } 
      
      # TODO: Write some non-cryptic messages
      describe "#rate_count" do
        specify { @post.rate_count.should eql 0 } 
      end
      
      describe "#rates" do
        specify { @post.rates.should eql 0 }
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

      it "should average if the result is zero" do
        @post.rate -1, @sally
        @post.rating.should eql 0.0
      end
    end
  end
  
  describe "when not rated" do
    describe "#rates" do
      specify { @post.rates.should eql 0 }
    end
    
    describe "#rating" do
      specify { @post.rating.should be_nil }
    end
  end
 
  describe "when saving the collection" do
    before (:each) do
      @post.rate 8, @bob
      @post.rate -10, @sally
      @post.save
      @finded_post = Post.where(:name => "Announcement").first
    end
    
    describe "#rated?" do
      describe "for Bob" do
        specify { @finded_post.rated?(@bob).should be_true }
      end
      
      describe "for Sally" do
        specify { @finded_post.rated?(@sally).should be_true }
      end
      
      describe "for Alice" do
        specify { @finded_post.rated?(@alice).should be_false}
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
  
end