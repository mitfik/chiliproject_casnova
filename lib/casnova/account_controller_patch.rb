require 'dispatcher'
require 'net/http'
require 'rest_client'

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
        is_ajax = request.xhr? ? true : false
        if Casnova.is_working?
          if params[:ticket]
            redirect_back_or_default :controller => 'my', :action => 'page'
          else
            begin
              if request.post?
                # Check if user exist if yes if he has active account
                raise "User is Blocked" unless User.active.find_by_login(params[:username])
                #CASClient::Frameworks::Rails::Filter::redirect_to_cas_for_authentication(self)
                RestClient.post "#{Casnova::CONFIG['url']}/api/login", { :password => params[:password], :username => params[:username] }, :content_type => :json, :accept => :json do |response, request, result, &block|
                  case response.code
                    when 201
                      cas_params = JSON.parse(response)
                      cookies[:tgt] = cas_params["tgt"]
                      if is_ajax
                        replay = {}
                        replay[:tgt] = cas_params["tgt"]
                        render :json => replay
                      else
                        redirect_back_or_default :controller => 'my', :action => 'page'
                      end
                    when 401
                      flash.now[:error] = "Invalid credential or try another auth source"
                      render :login
                    else
                      flash.now[:error] = "Something went wrong"
                      render :login
                  end
                end
              end
            rescue Exception => e
              p "Error: Login faild: #{e}"
              login_without_cas
            end
          end
        else
          login_without_cas
        end
      end

      def logout_with_cas
        if Casnova.is_working?
          self.logged_user = nil
          RestClient.delete "#{Casnova::CONFIG['url']}/api/logout", :cookies => {:tgt => cookies['tgt']}, :content_type => :json do |response, request, result, &block|
            case response.code
              when 200
                cookies.delete 'tgt'
                logout_without_cas
              else
                flash.now[:error] = "Something went wrong"
                redirect_back_or_default :controller => 'my', :action => 'page'
            end
          end
        else
          logout_without_cas
        end
      end

      def register_with_cas
        set_language_if_valid params[:user][:language] rescue nil # Show the activation message in the user's language
        register_without_cas
        if Casnova.is_working? and !performed?
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
