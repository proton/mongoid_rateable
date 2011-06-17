class Post
  include Mongoid::Document
  include Mongoid::Rateable

  field :name

end
