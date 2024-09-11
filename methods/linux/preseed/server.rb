
# Preseed routines

# Configure Preseed server

def configure_ps_server(values)
  search_string = "ubuntu"
  configure_linux_server(values, search_string)
  return
end

# List Preseed services

def list_ps_services(values)
  values['method'] = "ps"
  dir_list = get_dir_item_list(values)
  message  = "Preseed Services:"
  handle_output(values, message)
  dir_list.each do |service|
    handle_output(values, service)
  end
  handle_output(values, "")
  return
end

# Unconfigure Preseed server

def unconfigure_ps_server(values)
  unconfigure_ks_repo(values['service'])
end
