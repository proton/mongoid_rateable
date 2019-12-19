# frozen_string_literal: true

module Mongoid
  module Rateable
    extend ActiveSupport::Concern

    module Ext
      extend ActiveSupport::Concern

      module ClassMethods
        def rateable(options = {})
          class_eval do
            send :include, Mongoid::Rateable
            rate_config options
          end
        end
      end
    end

    included do
      field :rates, type: Integer, default: 0
      field :rating, type: Float, default: nil
      field :rating_previous, type: Float, default: nil
      field :rating_delta, type: Float, default: 0.0
      field :weighted_rate_count, type: Integer, default: 0

      embeds_many :rating_marks, as: :rateable, cascade_callbacks: true

      index('rating_marks.rater_id' => 1, 'rating_marks.rater_class' => 1)

      scope :unrated,
            -> { where(:rating.exists => false) }
      scope :rated,
            -> { where(:rating.exists => true) }
      scope :rated_by,
            ->(rater) { where('rating_marks.rater_id' => rater.id, 'rating_marks.rater_class' => rater.class.to_s) }
      scope :with_rating,
            ->(range) { where(:rating.gte => range.begin, :rating.lte => range.end) }
      scope :highest_rated,
            ->(limit = 10) { order_by(%i[rating desc]).limit(limit) }
    end

    module ClassMethods
      def rater_classes
        @rater_classes ||= []
      end

      def valid_rater_class?(clazz)
        return true if !rater_classes || rater_classes.empty?

        rater_classes.include? clazz
      end

      def in_rating_range?(value)
        range = rating_range if respond_to?(:rating_range)
        range ? range.include?(value.to_i) : true
      end

      # macro to create dynamic :rating_range class method!
      # can now even take an Array and find the range of values!
      def set_rating_range(range = nil)
        raterange = case range
                    when Array
                      arr = range.sort
                      Range.new arr.first, arr.last
                    when Range
                      range
                    when nil
                      (1..5)
                    else
                      raise ArgumentError, "Must be a range, was: #{range}"
                    end

        (class << self; self; end).send(:define_method, :rating_range) do
          raterange
        end
      end

      def rateable_by(*clazzes)
        @rater_classes = []
        return if clazzes.compact.empty?

        clazzes.each do |clazz|
          unless clazz.respond_to?(:new)
            raise ArgumentError, "A rateable must be a class, was: #{clazz}"
          end

          @rater_classes << clazz
        end
      end

      def rate_config(options = {}, &block)
        set_rating_range options[:range]
        rateable_by options[:raters]
        default_rater options[:default_rater], &block
      end

      def default_rater(rater = nil, &block)
        case rater
        when Symbol, String
          define_method :default_rater do
            send(rater) # fx to use owner or user relation
          end
        when nil
          return unless block_given?

          define_method :default_rater do
            instance_eval(&block)
          end
        else
          raise ArgumentError, 'Must take symbol or block argument'
        end
      end
    end # class methods

    def rate(mark, rater = nil, weight = 1)
      if rater.is_a? Enumerable
        rater.each { |r| rate(mark, r, weight) }
        return
      end

      rater ||= default_rater

      validate_rater!(rater)
      validate_rating!(mark)
      unrate_without_rating_update!(rater)
      total_mark = mark.to_i * weight.to_i
      self.rates += total_mark
      rating_marks.new(rater_id: rater.id, mark: mark, rater_class: rater.class.to_s, weight: weight)
      self.weighted_rate_count += weight
      update_rating!
    end

    def fallback_rater
      unless respond_to?(:default_rater)
        raise ArgumentError, 'No rater argument and no default_rater specified'
      end

      default_rater
    end

    def unrate(rater)
      if rater.is_a? Enumerable
        rater.each { |r| unrate(mark, r, weight) }
        return
      end

      unrate_without_rating_update!(rater)
      update_rating!
    end

    def rate_and_save(mark, rater, weight = 1)
      if rater.is_a? Enumerable
        rater.each { |r| rate_and_save(mark, r, weight) }
        return
      end

      rate(mark, rater, weight)
      save
    end

    def unrate_and_save(rater)
      if rater.is_a? Enumerable
        rater.each { |r| unrate_and_save(mark, r, weight) }
        return
      end

      unrate(rater)
      save
    end

    def rated?
      rate_count.positive?
    end

    def rated_by?(rater)
      if rater.is_a? Enumerable
        rater.each { |r| rated_by(mark, r, weight) }
        return
      end

      rater_rating_marks(rater).count == 1
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
      return nil if rating_marks.empty?

      total_sum = rating_marks.map(&:mark).sum
      total_sum.to_f / rating_marks.size
    end

    def rate_count
      rating_marks.size
    end

    def rate_weight
      check_weighted_rate_count!
      read_attribute(:weighted_rate_count)
    end

    def user_mark(rater)
      r = rater_rating_marks(rater).first
      r.mark if r
    end

    def user_marks(raters)
      if raters.map(&:class).uniq.count > 1
        raise ArgumentError, 'Raters all must be of same class.'
      end

      r = rating_marks.in(rater_id: raters.map(&:id), rater_class: raters.first.class.to_s)
      return unless r

      r.each_with_object(Hash.new(0)) { |e, h| h[e.rater_id] = e.mark; }
    end

    protected

    def validate_rater!(rater)
      return if self.class.valid_rater_class?(rater.class)

      raise ArgumentError, "Not a valid rater: #{rater.class}, must be of one of #{self.class.rater_classes}"
    end

    def validate_rating!(value)
      return if self.class.in_rating_range?(value)

      raise ArgumentError, "Rating not in range #{self.class.rating_range}. Rating provided was #{value}."
    end

    def rater_rating_marks(rater)
      rating_marks
        .where(rater_id: rater.id, rater_class: rater.class.to_s)
    end

    def unrate_without_rating_update!(rater)
      rmark = rater_rating_marks(rater).first
      return unless rmark

      weight                   = (rmark.weight ||= 1)
      total_mark               = rmark.mark.to_i * weight.to_i
      self.rates               -= total_mark
      self.weighted_rate_count -= weight
      rmark.delete
    end

    def update_rating!
      check_weighted_rate_count!
      write_attribute(:rating_previous, rating)
      unless rating_marks.blank?
        rt = self.rates.to_f / self.weighted_rate_count.to_f
      end
      write_attribute(:rating, rt)
      update_delta!
    end

    def update_delta!
      delta = rating && previous_rating ? rating - previous_rating : 0.0
      write_attribute(:rating_delta, delta)
    end

    def check_weighted_rate_count!
      # migration from old version
      wrc = read_attribute(:weighted_rate_count).to_i
      return if rate_count.zero? && !wrc.zero?

      write_attribute(:weighted_rate_count, rating_marks.size)
    end
  end
end
