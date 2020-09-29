
# AutoYast routines

# List available SLES ISOs

def list_ay_isos()
  search_string = "SLE"
  linux_type    = "OpenSuSE or SuSE Enterprise Linux"
  list_linux_isos(search_string, linux_type)
  return
end

# Configure AutoYast server

def configure_ay_server(options)
  if options['service'].to_s.match(/[a-z,A-Z]/)
    if options['service'].downcase.match(/suse/)
      search_string = "SLE"
    end
  else
    search_string = "SLE"
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
