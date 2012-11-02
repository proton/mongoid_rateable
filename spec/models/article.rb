class Article
  include Mongoid::Document
  include Mongoid::Rateable

  set_rating_range (1..5)

  field :name

end
