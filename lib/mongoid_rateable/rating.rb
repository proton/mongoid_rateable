class Rating
	include Mongoid::Document
#	belongs_to :rater, polymorphic: true
	embedded_in :rateable, polymorphic: true
	field :mark, :type => Integer
end