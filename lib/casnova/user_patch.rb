require 'dispatcher'

# Patches Chiliproject's User dinamically. Disallows password change.
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
        CAS::CONFIG['enabled'] ? false : change_password_allowed_without_cas
      end
    end
  end
end

Dispatcher.to_prepare do
  require_dependency 'principal'
  require_dependency 'user'
  User.send(:include, Casnova::UserPatch)
end
