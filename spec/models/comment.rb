class Comment
  include Mongoid::Document
  include Mongoid::Rateable

  RATING_RANGE = (-5..7)

  embedded_in :post

  field :content
end
