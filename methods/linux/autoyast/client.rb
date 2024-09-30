# Code for AutoYast clients

# List AutoYest clients

def list_ay_clients(values)
  service_type = "AutoYast"
  list_clients(values)
  return
end

# Configure AutoYast client

def configure_ay_client(values)
  configure_ks_client(values)
  return
end

# Unconfigure AutoYast client

def unconfigure_ay_client(values)
  unconfigure_ks_client(values)
  return
end
