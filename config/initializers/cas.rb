# Load CAS authentication configuration

module CAS
  CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../cas.yml")[RAILS_ENV]
end

if CAS::CONFIG['enabled']
  # Basic CAS client configuration
  require 'casclient'
  require 'casclient/frameworks/rails/filter'

  CASClient::Frameworks::Rails::Filter.configure(
    :cas_base_url => CAS::CONFIG['url'],
    :enable_single_sign_out => true
  )
end
