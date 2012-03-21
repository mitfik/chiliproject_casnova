require 'dispatcher'

# Patches Chiliproject's ApplicationController dinamically. Prepends a CAS gatewaying
# filter.
module Casnova
  module ApplicationControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable # Mark as unloadable so it is reloaded in development

        prepend_before_filter :cas_filter, :set_user_id
      end
    end

    module InstanceMethods
      def cas_filter
        if CAS::CONFIG['enabled'] and !['atom', 'xml', 'json'].include? request.format
          if params[:controller] != 'account'
            CASClient::Frameworks::Rails::GatewayFilter.filter(self)
          else
            CASClient::Frameworks::Rails::Filter.filter(self)
          end
        else
          true
        end
      end

      def set_user_id
        if CAS::CONFIG['enabled']
          user = User.find_by_login session[:cas_user]
          if user.nil? # New user
            @user = User.new(:language => Setting.default_language)
            @user.login = session[:cas_user]
            session[:auth_source_registration] = { :login => @user.login }
            render :template => 'account/register_with_cas'
          elsif session[:user_id] != user.id and !['atom', 'xml', 'json'].include? request.format

            session[:user_id] = user.id
            call_hook(:controller_account_success_authentication_after, { :user => user })
          end
        end
        true
      end
    end
  end
end

Dispatcher.to_prepare do
  require_dependency 'application_controller'
  ApplicationController.send(:include, Casnova::ApplicationControllerPatch)
end
