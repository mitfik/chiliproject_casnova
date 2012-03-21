# Run initializers
# Needs to be atop requires because some of them need to be run after initialization
Dir["#{File.dirname(__FILE__)}/config/initializers/**/*.rb"].sort.each do |initializer|
  require initializer
end

require 'redmine'
require 'casnova/account_controller_patch'
require 'casnova/application_controller_patch'
require 'casnova/setting_patch'
require 'casnova/user_patch'

Redmine::Plugin.register :chiliproject_casnova do
  name 'Chiliproject Casnova plugin'
  author 'Robert Mitwicki'
  description 'Chiliproject plugin for CAS authentication'
  version '0.0.1'
  url 'https://github.com/mitfik/chiliproject_casnova'
  author_url 'https://github.com/mitfik/'
end