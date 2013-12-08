class Post
  include Mongoid::Document
  include Mongoid::Rateable
  include Mongoid::Attributes::Dynamic
  
  embeds_many :comments
end
