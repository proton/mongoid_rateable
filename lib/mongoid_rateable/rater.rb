module Mongoid
	module Rater
		extend ActiveSupport::Concern

		included do
			has_many :rating_marks, as: :rater
		end

		module InstanceMethods
		end
	end
end