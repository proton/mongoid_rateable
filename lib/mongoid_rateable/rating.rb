class RatingMark
	include Mongoid::Document
	embedded_in :rateable, :polymorphic => true
	field :mark, :type => Integer
	field :rater_class, :type => String
end
