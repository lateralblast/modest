
# Common routines for server and client configuration

# List available ISOs

def list_vs_isos()
  if not values['search'].to_s.match(/[a-z]|[A-Z]|all/)
    values['search'] = "VMvisor"
  end
  list_linux_isos(values)
  return
end