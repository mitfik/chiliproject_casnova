require 'dispatcher'

# Patches Chiliproject's Setting dinamically. Disables self registration link.
module Casnova
  module SettingPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)

      base.class_eval do
        unloadable # Mark as unloadable so it is reloaded in development

        class << self
          alias_method_chain :self_registration?, :cas
        end
      end
    end

    module ClassMethods
      def self_registration_with_cas?
        CAS::CONFIG['enabled'] ? false : self_registration_without_cas?
      end
    end
  end
end

Dispatcher.to_prepare do
  require_dependency 'setting'
  Setting.send(:include, Casnova::SettingPatch)
end
