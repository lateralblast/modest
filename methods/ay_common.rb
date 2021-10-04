

# AutoYast common routines

# List available SLES ISOs

def list_ay_isos(options)
  options['method'] = "ay"
  if not options['search'].to_s.match(/[a-z]|[A-Z]|all/)
    options['search'] = "SLE|SuSE"
  end
  list_linux_isos(options)
  return
end
