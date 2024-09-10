# Common PS code

# List available Ubuntu ISOs

def list_ps_isos(options)
  if not options['search'].to_s.match(/[a-z]|[A-Z]|all/)
    options['search'] = "ubuntu|debian|purity"
  end
  list_linux_isos(options)
  return
end