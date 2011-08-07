class Article
  include Mongoid::Document
  include Mongoid::Rateable

  RATING_RANGE = (1..5)

  field :name

end
