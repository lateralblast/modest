
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
  message = "AutoYast Services:"
  command = "ls #{options['baserepodir']}/ |grep 'sles'"
  output  = execute_command(options,message,command)
  handle_output(options,message)
  handle_output(options,output)
  return
end

# Unconfigure AutoYast server

def unconfigure_ay_server(options)
  unconfigure_ks_repo(options)
end
