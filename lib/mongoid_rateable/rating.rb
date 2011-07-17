class RatingMark
	include Mongoid::Document
	embedded_in :rateable, :polymorphic => true
	field :mark, :type => Integer
	field :rater_class, :type => String
	field :rater_id, :type => BSON::ObjectId
end
