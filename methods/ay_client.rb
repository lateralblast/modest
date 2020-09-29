# Code for AutoYast clients

# List AutoYest clients

def list_ay_clients()
  service_type = "AutoYast"
  list_clients(options)
  return
end

# Configure AutoYast client

def configure_ay_client(options)
  configure_ks_client(options)
  return
end

# Unconfigure AutoYast client

def unconfigure_ay_client(options)
  unconfigure_ks_client(options)
  return
end
