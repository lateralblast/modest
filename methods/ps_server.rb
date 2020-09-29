
# AutoYast routines

# Configure Preseed server

def configure_ps_server(options)
  search_string = "ubuntu"
  configure_linux_server(options,search_string)
  return
end

# List Preseed services

def list_ps_services(options)
  message = "Preseed Services:"
  command = "ls #{options['baserepodir']}/ |grep ubuntu"
  output  = execute_command(options,message,command)
  handle_output(options,message)
  handle_output(options,output)
  command = "ls #{options['baserepodir']}/ |grep debian"
  output  = execute_command(options,message,command)
  handle_output(options,output)
  return
end

# Unconfigure Preseed server

def unconfigure_ps_server(options)
  unconfigure_ks_repo(options['service'])
end
