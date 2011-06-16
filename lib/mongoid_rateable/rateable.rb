module Mongoid
	module Rateable
		extend ActiveSupport::Concern

		included do
			field :points, :type => Integer, :default => 0
			embeds_many :marks, as: :rateable
		end

		module InstanceMethods

			def rate(mark, rater)
				unless rated? rater
					self.points += num.to_i
					self.marks << Mark.new(:rater_id => rater.id, :mark => mark)
				end
			end

			def rated?(rater)
				marks.where(:rater_id => rater.id).count == 1
			end

			def rating
				if marks.blank?
					nil
				else
					points.to_f / marks.count
				end
			end

		end
	end
end