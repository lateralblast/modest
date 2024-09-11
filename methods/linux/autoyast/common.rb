

# AutoYast common routines

# List available SLES ISOs

def list_ay_isos(values)
  values['method'] = "ay"
  if not values['search'].to_s.match(/[a-z]|[A-Z]|all/)
    values['search'] = "SLE|SuSE"
  end
  list_linux_isos(values)
  return
end
