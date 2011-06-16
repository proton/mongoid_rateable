module Mongoid
	module Rateable
		extend ActiveSupport::Concern

		included do
			field :points, :type => Integer, :default => 0
			embeds_many :rating_marks, as: :rateable
		end

		module InstanceMethods

			def rate(mark, rater)
				unrate(rater)
				self.points += mark.to_i
				self.rating_marks.new(:rater_id => rater.id, :mark => mark)
			end

			def unrate(rater)
				mark = self.rating_marks.where(:rater_id => rater.id).first
				if mark
					self.points -= mark.mark.to_i
					mark.delete
				end
			end

			def rated?(rater)
				self.rating_marks.where(:rater_id => rater.id).count == 1
			end

			def rating
				if self.rating_marks.blank?
					nil
				else
					self.points.to_f / self.rating_marks.count
				end
			end

			def rate_count
				self.rating_marks.count
			end

		end
	end
end
