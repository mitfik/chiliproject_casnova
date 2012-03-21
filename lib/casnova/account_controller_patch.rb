require 'dispatcher'

# Patches chiliproject AccountController dinamically. Manages login and logout
# through CAS.
module Casnova
  module AccountControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable # Mark as unloadable so it is reloaded in development

        alias_method_chain :login, :cas
        alias_method_chain :logout, :cas
        alias_method_chain :register, :cas
      end
    end

    module InstanceMethods
      def login_with_cas
        if CAS::CONFIG['enabled']
          if params[:ticket]
            redirect_back_or_default :controller => 'my', :action => 'page'
          else
            CASClient::Frameworks::Rails::Filter::redirect_to_cas_for_authentication(self)
          end
        else
          login_without_cas
        end
      end

      def logout_with_cas
        if CAS::CONFIG['enabled']
          self.logged_user = nil
          CASClient::Frameworks::Rails::Filter::logout(self, home_url)
        else
          logout_without_cas
        end
      end

      def register_with_cas
        set_language_if_valid params[:user][:language] rescue nil # Show the activation message in the user's language
        register_without_cas
        if CAS::CONFIG['enabled'] and !performed?
          render :template => 'account/register_with_cas'
        end
      end
    end
  end
end

Dispatcher.to_prepare do
  require_dependency 'account_controller'
  AccountController.send(:include, Casnova::AccountControllerPatch)
end
