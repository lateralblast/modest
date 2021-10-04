
# Common routines for server and client configuration

# Question/config structure

Vs = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

# List available ISOs

def list_vs_isos()
  if not options['search'].to_s.match(/[a-z]|[A-Z]|all/)
    options['search'] = "VMvisor"
  end
  list_linux_isos(options)
  return
end