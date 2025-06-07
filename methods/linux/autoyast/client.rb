# frozen_string_literal: true

# Code for AutoYast clients

# List AutoYest clients

def list_ay_clients(values)
  list_clients(values)
  nil
end

# Configure AutoYast client

def configure_ay_client(values)
  configure_ks_client(values)
  nil
end

# Unconfigure AutoYast client

def unconfigure_ay_client(values)
  unconfigure_ks_client(values)
  nil
end
