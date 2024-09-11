
# AutoYast server routines

# Configure AutoYast server

def configure_ay_server(values)
  if not values['search'].to_s.match(/[a-z]|[A-Z]|all/)
    if values['service'].to_s.match(/[a-z]/)
      if values['service'].downcase.match(/suse/)
        search_string = "SLE"
      end
    else
      search_string = "SLE"
    end
  end
  configure_linux_server(values, search_string)
  return
end

# List AutoYast services

def list_ay_services(values)
  values['method'] = "ay"
  dir_list = get_dir_item_list(values)
  message  = "AutoYast Services:"
  handle_output(values, message)
  dir_list.each do |service|
    handle_output(values, service)
  end
  handle_output(values, "")
  return
end

# Unconfigure AutoYast server

def unconfigure_ay_server(values)
  unconfigure_ks_repo(values)
end
