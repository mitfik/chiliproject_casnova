# Run initializers
# Needs to be atop requires because some of them need to be run after initialization
Dir["#{File.dirname(__FILE__)}/config/initializers/**/*.rb"].sort.each do |initializer|
  require initializer
end

require 'redmine'
require 'dispatcher'
Dispatcher.to_prepare do
 # require_dependency 'application_controller'
 # require_dependency 'account_controller'
 # require_dependency 'principal'
 # require_dependency 'user'
  require_dependency 'casnova/account_controller_patch'
  require_dependency 'casnova/application_controller_patch'
  require_dependency 'casnova/user_patch'
end

Redmine::Plugin.register :chiliproject_casnova do
  name 'Chiliproject Casnova plugin'
  author 'Robert Mitwicki'
  description 'Chiliproject plugin for CAS authentication'
  version '0.0.1'
  url 'https://github.com/mitfik/chiliproject_casnova'
  author_url 'https://github.com/mitfik/'
end
