class User
  include Mongoid::Document
  include Mongoid::Rater

  field :name

end
