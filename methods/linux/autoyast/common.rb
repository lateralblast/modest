# frozen_string_literal: true

# AutoYast common routines

# List available SLES ISOs

def list_ay_isos(values)
  values['method'] = 'ay'
  values['search'] = 'SLE|SuSE' unless values['search'].to_s.match(/[a-z]|[A-Z]|all/)
  list_linux_isos(values)
  nil
end
