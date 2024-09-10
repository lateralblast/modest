# Common Windows (PE) related code

def list_pe_isos()
  options['os-type'] = "win"
  options['method']  = ""
  options['release'] = ""
  options['arch']    = ""
  options['file']    = ""
  list_isos(options)
  return
end