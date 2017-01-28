require 'mongoid_rateable/rateable'
require 'mongoid_rateable/rating'

Mongoid::Document.send :include, Mongoid::Rateable::Ext



