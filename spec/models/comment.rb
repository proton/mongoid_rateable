class Comment
  include Mongoid::Document
  include Mongoid::Rateable

  set_rating_range (-5..7)

  embedded_in :post

  field :content
end
