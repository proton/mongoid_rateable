module Mongoid
	module Rateable
		extend ActiveSupport::Concern

		included do
			field :rates, :type => Integer, :default => 0
			field :rating, :type => Float, :default => nil

			embeds_many :rating_marks, :as => :rateable

			index(
				[
					["rating_marks.rater_id", Mongo::ASCENDING],
					["rating_marks.rater_class", Mongo::ASCENDING]
				]
			)

			scope :unrated, where(:rating.exists => false)
			scope :rated, where(:rating.exists => true)
			scope :rated_by, ->(rater) { where("rating_marks.rater_id" => rater.id, "rating_marks.rater_class" => rater.class.to_s) }
			scope :with_rating, ->(range) { where(:rating.gte => range.begin, :rating.lte => range.end) }
 			scope :highest_rated, ->(limit=10) { order_by([:rating, :desc]).limit(limit) }
		end

		module InstanceMethods

			def rate(mark, rater)
				validate_rating!(mark)
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
					puts "Deprecated method, please use rated_by?"
					rated_by?(rater)
				else
					rate_count!=0
				end
			end

			def rated_by?(rater)
				self.rating_marks.where(:rater_id => rater.id, :rater_class => rater.class.to_s).count == 1
			end

			def rating
				read_attribute(:rating)
			end

			def rate_count
				rating_marks.size
			end

			protected

			def validate_rating!(value)
				if (defined? self.class::RATING_RANGE) and (range = self.class::RATING_RANGE) and !range.include?(value.to_i)
					raise ArgumentError, "Rating not in range #{range}. Rating provided was #{value}."
 				end
			end

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

		end
	end
end
