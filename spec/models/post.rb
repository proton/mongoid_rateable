class Post
  include Mongoid::Document
  include Mongoid::Rateable
  
  embeds_many :comments
end
