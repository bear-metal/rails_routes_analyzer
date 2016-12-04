ENV['RAILS_ENV'] ||= 'test'

require 'rails'
require 'action_controller/railtie'

class Dummy < Rails::Application
  config.root = File.dirname(__FILE__)

  config.session_store :cookie_store, key: 'a'*40
  config.secret_token = 'b'*40

  config.logger = Logger.new(File.expand_path('../test.log', __FILE__))
  Rails.logger = config.logger
end

class ApplicationController < ActionController::Base
  def non_action
  end

  def second_non_action
  end

  class << self
    attr_accessor :broken_action_methods
    def action_methods
      if broken_action_methods
        super - %w[ non_action ]
      else
        super - %w[ non_action second_non_action ]
      end
    end
  end
end

class HomeController < ApplicationController
  def index
  end

  def show
  end
end

class FullItemsController < ApplicationController
  %w[ index show new edit create update destroy ].each do |action|
    define_method(action) { }
  end

  def custom
  end

  def custom_index
  end
end

class SubclassHomeController < HomeController
  def subclass_action
  end
end

class EmptyController < ApplicationController
end

module ModuleWithAction
  def module_provided_action
  end
end

class ControllerIncludingModule < ApplicationController
  include ModuleWithAction
end
