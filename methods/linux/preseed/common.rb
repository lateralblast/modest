# frozen_string_literal: true

# Common PS code

# List available Ubuntu ISOs

def list_ps_isos(values)
  values['search'] = 'ubuntu|debian|purity' unless values['search'].to_s.match(/[a-z]|[A-Z]|all/)
  list_linux_isos(values)
  nil
end
