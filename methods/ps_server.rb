
# Preseed routines

# Configure Preseed server

def configure_ps_server(options)
  search_string = "ubuntu"
  configure_linux_server(options,search_string)
  return
end

# List Preseed services

def list_ps_services(options)
  options['method'] = "ps"
  dir_list = get_dir_item_list(options)
  message  = "Preseed Services:"
  handle_output(options,message)
  dir_list.each do |service|
    handle_output(options,service)
  end
  handle_output(options,"")
  return
end

# Unconfigure Preseed server

def unconfigure_ps_server(options)
  unconfigure_ks_repo(options['service'])
end
