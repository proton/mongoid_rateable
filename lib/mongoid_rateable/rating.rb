class Rating < ActiveRecord::Base
#	belongs_to :rater, polymorphic: true
	embedded_in :rateable, polymorphic: true
	field :mark, :type => Integer
end