# frozen_string_literal: true

# Common routines for server and client configuration

# List available ISOs

def list_vs_isos(values)
  values['search'] = 'VMvisor' unless values['search'].to_s.match(/[a-z]|[A-Z]|all/)
  list_linux_isos(values)
  nil
end
