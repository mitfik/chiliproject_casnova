# Patches Chiliproject's User dinamically. Disallows password change.

require 'principal'
module Casnova
  module UserPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable # Mark as unloadable so it is reloaded in development

        alias_method_chain :change_password_allowed?, :cas
      end
    end

    module InstanceMethods
      def change_password_allowed_with_cas?
        #Casnova.is_working? ? true : change_password_allowed_without_cas?
        true
      end
    end
  end
end

User.send(:include, Casnova::UserPatch)
