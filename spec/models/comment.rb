class Comment
  include Mongoid::Document

  rateable range: (-5..7)

  embedded_in :post

  field :content
end
