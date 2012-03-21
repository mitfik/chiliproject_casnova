# Load Casnova authentication configuration

module Casnova
  CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../casnova.yml")[RAILS_ENV]
  def Casnova.is_enabled?
    Casnova::CONFIG['enabled']
  end
end

if Casnova.is_enabled?

  CASClient::Frameworks::Rails::Filter.configure(
    :cas_base_url => Casnova::CONFIG['url'],
    :enable_single_sign_out => true
  )
end
