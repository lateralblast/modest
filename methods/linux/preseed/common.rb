# Common PS code

# List available Ubuntu ISOs

def list_ps_isos(values)
  if not values['search'].to_s.match(/[a-z]|[A-Z]|all/)
    values['search'] = "ubuntu|debian|purity"
  end
  list_linux_isos(values)
  return
end