require 'net/http'
require 'rest_client'

# Patches chiliproject AccountController dinamically. Manages login and logout
# through CAS.
module Casnova
  module AccountControllerPatch
    def self.included(base) # :nodoc:

      base.class_eval do
        unloadable # Mark as unloadable so it is reloaded in development

        include InstanceMethods

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
                RestClient.post "#{Casnova::CONFIG['url']}/api/login", { :password => params[:password], :username => params[:username] }, :content_type => :json, :accept => :json do |response, request, result, &block|
                  case response.code
                    when 201
                      # Check if user exist in chiliproject 
                      user = User.find_by_login(params[:username])
                      session[:cas_user] = user.id
                      cas_params = JSON.parse(response)
                      cookies[:tgt] = {:value => cas_params["tgt"], :domain => Casnova::CONFIG['domain']}
                      unless user
                        user = User.new
                        user.login = params[:username]
                        user.language = Setting.default_language
                        if user.save
                          user.reload
                          logger.info("User '#{user.login}' created from cas")
                        end
                        if is_ajax
                          replay = {:message => "You must register first Your account"}
                          render :json => replay
                        else
                          register_with_cas
                        end
                      else
                        if is_ajax
                          replay = {}
                          replay[:tgt] = cas_params["tgt"]
                          render :json => replay
                        else
                          redirect_back_or_default :controller => 'my', :action => 'page'
                        end
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
              #login_without_cas
            end
          end
        else
          login_without_cas
        end
      end

      def logout_with_cas
        if Casnova.is_working?
          self.logged_user = nil
          # TODO do it in background and move to  rubyrest-client
          RestClient.delete "#{Casnova::CONFIG['url']}/api/logout", :cookies => {:tgt => cookies['tgt'] || ""}, :content_type => :json do |response, request, result, &block|
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

AccountController.send(:include, Casnova::AccountControllerPatch)
