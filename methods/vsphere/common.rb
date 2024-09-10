
# Common routines for server and client configuration

# List available ISOs

def list_vs_isos()
  if not options['search'].to_s.match(/[a-z]|[A-Z]|all/)
    options['search'] = "VMvisor"
  end
  list_linux_isos(options)
  return
end