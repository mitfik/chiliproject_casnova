# Patches Chiliproject's ApplicationController dinamically. Prepends a CAS gatewaying
# filter.
module Casnova
  module ApplicationControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable # Mark as unloadable so it is reloaded in development

        prepend_before_filter :set_user_id
        prepend_before_filter :cas_filter
      end
    end

    module InstanceMethods
      def cas_filter
        begin
          if !['atom', 'xml'].include? request.format 
            if params[:controller] != 'account'
              # TODO gateway allow display page even if authorization fail, so above if statemant is incorect because we do not check that here.
              CASClient::Frameworks::Rails::GatewayFilter.filter(self)
            else
              # TODO implement APIFilter ? to make sure that none of actions will redirect anywhere.
              CASClient::Frameworks::Rails::Filter.filter(self)
            end
          end
        rescue => exception
          logger.error "CASClient error: #{exception.message}" if logger
        end
        true
      end

      def set_user_id
      #  if Casnova.is_working?
      # TODO make sure that above if statement make sense because we do not need to check each time /is_alive only in place where is necessary (because it will be called each request
        #  # find_by_login return always anonymouse if it gets nil TODO
          user = User.find_by_login session[:cas_user]
          if user.nil? # New user TODO this never be true look above
            @user = User.new(:language => Setting.default_language)
            @user.login = session[:cas_user]
            session[:auth_source_registration] = { :login => @user.login }
            render :template => 'account/register_with_cas'
          elsif session[:user_id] != user.id and !['atom', 'xml', 'json'].include? request.format
            session[:user_id] = user.id
            call_hook(:controller_account_success_authentication_after, { :user => user })
          end
        #end
      end
    end
  end
end

ApplicationController.send(:include, Casnova::ApplicationControllerPatch)
