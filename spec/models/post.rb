class Post
  include Mongoid::Document
  include Mongoid::Rateable
  include Mongoid::Attributes::Dynamic if Mongoid::VERSION>='4'
  
  embeds_many :comments
end
