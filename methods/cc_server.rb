# Code for Cloud Config server config
# E.g. installations via Ubuntu live CD

# Configure Preseed server

def configure_cc_server(options)
  search_string = "live"
  configure_linux_server(options, search_string)
  return
end

# List Ubuntu Subiquity / Cloud Config services

def list_cc_services(options)
  options['method'] = "ci"
  dir_list = get_dir_item_list(options)
  message  = "Ubuntu Subiquity or Cloud Config/Init Services:"
  handle_output(options, message)
  dir_list.each do |service|
    handle_output(options, service)
  end
  handle_output(options, "")
  return
end

# Unconfigure Cloud Config server

def unconfigure_cc_server(options)
  unconfigure_ks_repo(options['service'])
end
