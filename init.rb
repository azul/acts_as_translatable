require 'acts_as_translatable'
ActiveRecord::Base.send(:include, ActiveRecord::Acts::Translatable)
require File.dirname(__FILE__) + '/lib/acts_as_translatable'
require File.dirname(__FILE__) + '/lib/translation_model'

