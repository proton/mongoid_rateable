# frozen_string_literal: true

require 'mongoid_rateable/rateable'
require 'mongoid_rateable/rating'

Mongoid::Document.include Mongoid::Rateable::Ext
