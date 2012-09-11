module Mongoid
  module Rateable
    extend ActiveSupport::Concern

    included do
      field :rates, type: Integer, default: 0
      field :rating, type: Float, default: nil
      field :rating_previous, type: Float, default: nil
      field :rating_delta, type: Float, default: 0.0
      field :weighted_rate_count, type: Integer, default: 0

      embeds_many :rating_marks, :as => :rateable

      index({"rating_marks.rater_id" => 1, "rating_marks.rater_class" => 1})

      scope :unrated, where(:rating.exists => false)
      scope :rated, where(:rating.exists => true)
      scope :rated_by, ->(rater) { where("rating_marks.rater_id" => rater.id, "rating_marks.rater_class" => rater.class.to_s) }
      scope :with_rating, ->(range) { where(:rating.gte => range.begin, :rating.lte => range.end) }
      scope :highest_rated, ->(limit=10) { order_by([:rating, :desc]).limit(limit) }
    end

    def rate(mark, rater, weight = 1)
      validate_rating!(mark)
      unrate_without_rating_update(rater)
      total_mark = mark.to_i*weight.to_i
      self.rates += total_mark
      self.rating_marks.new(:rater_id => rater.id, :mark => mark, :rater_class => rater.class.to_s, :weight => weight)
      self.weighted_rate_count += weight
      update_rating
    end

    def unrate(rater)
      unrate_without_rating_update(rater)
      update_rating
    end

    def rate_and_save(mark, rater, weight = 1)
      rate(mark, rater, weight)
      save
    end

    def unrate_and_save(rater)
      unrate(rater)
      save
    end

    def rated?
      rate_count != 0
    end

    def rated_by?(rater)
      self.rating_marks.where(:rater_id => rater.id, :rater_class => rater.class.to_s).count == 1
    end

    def rating
      read_attribute(:rating)
    end

    def previous_rating
      read_attribute(:rating_previous)
    end

    def rating_delta
      read_attribute(:rating_delta)
    end

    def unweighted_rating
      return nil if self.rating_marks.empty?
      total_sum = self.rating_marks.map(&:mark).sum
      return total_sum.to_f/self.rating_marks.size
    end

    def rate_count
      self.rating_marks.size
    end

    def rate_weight
      check_weighted_rate_count
      read_attribute(:weighted_rate_count)
    end

    protected

    def validate_rating!(value)
      if (defined? self.class::RATING_RANGE) and (range = self.class::RATING_RANGE) and !range.include?(value.to_i)
        raise ArgumentError, "Rating not in range #{range}. Rating provided was #{value}."
      end
    end

    def unrate_without_rating_update(rater)
      rmark = self.rating_marks.where(:rater_id => rater.id, :rater_class => rater.class.to_s).first
      return unless rmark

      weight                   = (rmark.weight ||= 1)
      total_mark               = rmark.mark.to_i*weight.to_i
      self.rates               -= total_mark
      self.weighted_rate_count -= weight
      rmark.delete
    end

    def update_rating
      check_weighted_rate_count
      write_attribute(:rating_previous, self.rating)
      rt = (self.rates.to_f / self.weighted_rate_count.to_f) unless self.rating_marks.blank?
      write_attribute(:rating, rt)
      delta = (self.rating && self.previous_rating) ? rating-previous_rating : 0.0
      write_attribute(:rating_delta, delta)      
    end

    def check_weighted_rate_count
      #migration from old version
      wrc = read_attribute(:weighted_rate_count).to_i
      if (wrc==0 && rate_count!=0)
        write_attribute(:weighted_rate_count, self.rating_marks.size)
      end
    end
  end
end
