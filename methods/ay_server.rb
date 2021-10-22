
# AutoYast server routines

# Configure AutoYast server

def configure_ay_server(options)
  if not options['search'].to_s.match(/[a-z]|[A-Z]|all/)
    if options['service'].to_s.match(/[a-z]/)
      if options['service'].downcase.match(/suse/)
        search_string = "SLE"
      end
    else
      search_string = "SLE"
    end
  end
  configure_linux_server(options,search_string)
  return
end

# List AutoYast services

def list_ay_services(options)
  options['method'] = "ay"
  dir_list = get_dir_item_list(options)
  message  = "AutoYast Services:"
  handle_output(options,message)
  dir_list.each do |service|
    handle_output(options,service)
  end
  handle_output(options,"")
  return
end

# Unconfigure AutoYast server

def unconfigure_ay_server(options)
  unconfigure_ks_repo(options)
end
