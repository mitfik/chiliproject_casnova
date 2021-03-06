# Load Casnova authentication configuration

module Casnova
  CONFIG = YAML.load_file("#{File.dirname(__FILE__)}/../casnova.yml")[RAILS_ENV]
  def Casnova.is_enabled?
    Casnova::CONFIG['enabled'] 
  end

  def Casnova.is_working?
    Casnova.is_enabled? && Casnova.is_alive?
  end

  def Casnova.is_alive?
    begin
      response = RestClient.get "#{Casnova::CONFIG['url']}/api/isalive", :accept => :json
      return response.code == 204 
    rescue => e
      puts "Error: CAS server: #{e}. Proceed without cas."
    end 
  end
end

if Casnova.is_enabled?
  CASClient::Frameworks::Rails::Filter.configure(
    :cas_base_url => Casnova::CONFIG['url'],
    :enable_single_sign_out => true
  )
end
