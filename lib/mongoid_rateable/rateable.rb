module Mongoid
	module Rateable
		extend ActiveSupport::Concern

		included do
			field :rates, :type => Integer, :default => 0
			field :rating, :type => Float, :default => nil
			field :rate_count, :type => Integer, :default => 0

			embeds_many :rating_marks, :as => :rateable

			index(
				[
					["rating_marks.rater_id"],
					["rating_marks.rater_class"]
				],
				unique: true
			)
		end

		module InstanceMethods

			def rate(mark, rater)
				unrate_without_rating_update(rater)
				self.rates += mark.to_i
				self.rating_marks.new(:rater_id => rater.id, :mark => mark, :rater_class => rater.class.to_s)
				update_rating
			end

			def unrate(rater)
				unrate_without_rating_update(rater)
				update_rating
			end

			def rate_and_save(mark, rater)
				rate(mark, rater)
				save
			end

			def unrate_and_save(rater)
				unrate(rater)
				save
			end

			def rated?(rater = nil)
				if rater
					self.rating_marks.where(:rater_id => rater.id, :rater_class => rater.class.to_s).count == 1
				else
					rate_count!=0
				end
			end

			def rating
				read_attribute(:rating) || calculate_and_store_rating
			end

			def rate_count
				rating_marks.size
			end

			private

			def unrate_without_rating_update(rater)
				rmark = self.rating_marks.where(:rater_id => rater.id, :rater_class => rater.class.to_s).first
				if rmark
					self.rates -= rmark.mark.to_i
					rmark.delete
				end
			end

			def update_rating
 				rt = (self.rates.to_f / self.rating_marks.size) unless self.rating_marks.blank?
 				write_attribute(:rating, rt)
			end

			def calculate_and_store_rating
				puts "Deprecated"
				update_rating
				read_attribute(:rating)
			end

		end
	end
end
