require 'rails/railtie'

module RailsRoutesAnalyzer

  class Railtie < ::Rails::Railtie
    rake_tasks do
      load File.join(File.dirname(__FILE__), '../tasks/rails-routes-analyzer.rake')
    end
  end

  MULTI_METHODS = %w[resource resources].freeze
  SINGLE_METHODS = %w[match get head post patch put delete options root].freeze
  ROUTE_METHODS = (MULTI_METHODS + SINGLE_METHODS).freeze

  def self.get_full_filename(filename)
    return filename.to_s if filename.to_s.starts_with?('/')
    Rails.root.join(filename).to_s
  end

  RESOURCE_ACTIONS = [:index, :create, :new, :show, :update, :destroy, :edit]

  def self.identify_route_issues
    RouteAnalysis.new
  end

  def self.get_all_defined_routes
    identify_route_issues[:implemented_routes]
  end

  def self.get_all_action_methods(ignore_parent_provided: true)
    [].tap do |result|
      ApplicationController.descendants.each do |controller_class|
        action_methods = controller_class.action_methods

        if ignore_parent_provided && (super_class_actions = controller_class.superclass.try(:action_methods)).present?
          action_methods -= super_class_actions
        end

        action_methods.each do |action_method|
          result << [controller_class.name, action_method.to_sym]
        end
      end
    end
  end

end
