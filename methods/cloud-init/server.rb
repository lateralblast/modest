# frozen_string_literal: true

# Code for Cloud Config server config
# E.g. installations via Ubuntu live CD

# Configure Preseed server

def configure_cc_server(values)
  search_string = 'live'
  configure_linux_server(values, search_string)
  nil
end

# List Ubuntu Subiquity / Cloud Config services

def list_cc_services(values)
  values['method'] = 'ci'
  dir_list = get_dir_item_list(values)
  message  = 'Ubuntu Subiquity or Cloud Config/Init Services:'
  verbose_message(values, message)
  dir_list.each do |service|
    verbose_message(values, service)
  end
  verbose_message(values, '')
  nil
end

# Unconfigure Cloud Config server

def unconfigure_cc_server(values)
  unconfigure_ks_repo(values['service'])
end
