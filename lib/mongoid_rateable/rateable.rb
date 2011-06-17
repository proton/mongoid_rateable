module Mongoid
	module Rateable
		extend ActiveSupport::Concern

		included do
			field :rates, :type => Integer, :default => 0
			embeds_many :rating_marks, as: :rateable
		end

		module InstanceMethods

			def rate(mark, rater)
				unrate(rater)
				self.rates += mark.to_i
				self.rating_marks.new(:rater_id => rater.id, :mark => mark, :rater_class => rater.class.to_s)
			end

			def unrate(rater)
				mark = self.rating_marks.where(:rater_id => rater.id).first
				if mark
					self.rates -= mark.mark.to_i
					mark.delete
				end
			end

			def rated?(rater)
				self.rating_marks.where(:rater_id => rater.id, :rater_class => rater.class.to_s).count == 1
			end

			def rating
				if self.rating_marks.blank?
					nil
				else
					self.rates.to_f / self.rating_marks.size
				end
			end

			def rate_count
				self.rating_marks.size
			end

		end
	end
end
