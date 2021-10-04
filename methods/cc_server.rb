# Code for Cloud Config server config
# E.g. installations via Ubuntu live CD

# Configure Preseed server

def configure_cc_server(options)
  search_string = "live"
  configure_linux_server(options,search_string)
  return
end

# List Cloud Config services

def list_cc_services(options)
  message = "Cloud Config/Init Services:"
  command = "ls #{options['baserepodir']}/ |grep ubuntu |grep live"
  output  = execute_command(options,message,command)
  handle_output(options,message)
  handle_output(options,output)
  handle_output(options,"")
  return
end

# Unconfigure Cloud Config server

def unconfigure_cc_server(options)
  unconfigure_ks_repo(options['service'])
end
