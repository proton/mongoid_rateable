module Mongoid
  module Rateable
    extend ActiveSupport::Concern

    module Ext
      extend ActiveSupport::Concern

      module ClassMethods
        def rateable options = {}
          class_eval do            
            self.send :include, Mongoid::Rateable
            self.rate_config options
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

      embeds_many :rating_marks, :as => :rateable, cascade_callbacks: true

      index({"rating_marks.rater_id" => 1, "rating_marks.rater_class" => 1})

      scope :unrated, ->{ where(:rating.exists => false) }
      scope :rated, ->{ where(:rating.exists => true) }
      scope :rated_by, ->(rater) { where("rating_marks.rater_id" => rater.id, "rating_marks.rater_class" => rater.class.to_s) }
      scope :with_rating, ->(range) { where(:rating.gte => range.begin, :rating.lte => range.end) }
      scope :highest_rated, ->(limit=10) { order_by([:rating, :desc]).limit(limit) }
    end

    module ClassMethods
      def rater_classes
        @rater_classes ||= []
      end

      def valid_rater_class? clazz
        return true if !rater_classes || rater_classes.empty?
        rater_classes.include? clazz
      end

      def in_rating_range?(value)
        range = rating_range if respond_to?(:rating_range)
        range ? range.include?(value.to_i) : true
      end      

      # macro to create dynamic :rating_range class method!
      # can now even take an Array and find the range of values!
      def set_rating_range range = nil
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

      def rateable_by *clazzes
        @rater_classes = []
        return if clazzes.compact.empty?
        clazzes.each do |clazz|
          raise ArgumentError, "A rateable must be a class, was: #{clazz}" unless clazz.respond_to?(:new)
          @rater_classes << clazz
        end
      end

      def rate_config options = {}, &block
        set_rating_range options[:range]
        rateable_by options[:raters]
        default_rater options[:default_rater], &block
      end

      def default_rater rater=nil, &block
        case rater
        when Symbol, String
          define_method :default_rater do
            self.send(rater) # fx to use owner or user relation
          end
        when nil
          return unless block_given?
          define_method :default_rater do
            self.instance_eval(&block)
          end
        else
          raise ArgumentError, "Must take symbol or block argument" 
        end
      end
    end # class methods

    def rate(mark, rater = nil, weight = 1)
      case rater
      when Array
        rater.each{|rater| rate(mark, rater, weight)}
      else 
        if !rater
          unless respond_to?(:default_rater)
            raise ArgumentError, "No rater argument and no default_rater specified"
          end
          rater = default_rater 
        end
        validate_rater!(rater)
        validate_rating!(mark)
        unrate_without_rating_update(rater)
        total_mark = mark.to_i*weight.to_i
        self.rates += total_mark
        self.rating_marks.new(:rater_id => rater.id, :mark => mark, :rater_class => rater.class.to_s, :weight => weight)
        self.weighted_rate_count += weight
        update_rating
      end
    end

    def unrate(rater)
      case rater
      when Array
        rater.each{|rater| unrate(mark, rater, weight)}
      else 
        unrate_without_rating_update(rater)
        update_rating
      end
    end

    def rate_and_save(mark, rater, weight = 1)
      case rater
      when Array
        rater.each{|rater| rate_and_save(mark, rater, weight)}
      else 
        rate(mark, rater, weight)
        save
      end
    end

    def unrate_and_save(rater)
      case rater
      when Array
        rater.each{|rater| unrate_and_save(mark, rater, weight)}
      else 
        unrate(rater)
        save
      end
    end

    def rated?
      rate_count != 0
    end

    def rated_by?(rater)
      case rater
      when Array
        rater.each{|rater| rated_by(mark, rater, weight)}
      else       
        self.rating_marks.where(:rater_id => rater.id, :rater_class => rater.class.to_s).count == 1
      end
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

    def user_mark(rater)
      r = self.rating_marks.where(:rater_id => rater.id, :rater_class => rater.class.to_s).first
      r ? r.mark : nil
    end

    protected

    def validate_rater!(rater)
      unless self.class.valid_rater_class?(rater.class)
        raise ArgumentError, "Not a valid rater: #{rater.class}, must be of one of #{self.class.rater_classes}"
      end
    end

    def validate_rating!(value)
      if !self.class.in_rating_range?(value)
        raise ArgumentError, "Rating not in range #{self.class.rating_range}. Rating provided was #{value}."
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
