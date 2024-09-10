# Solaris LDoms support code

def list_ldoms(options)
  case options['vm']
  when /ldom/
    list_all_ldoms(options)
  when /gdom/
    list_gdoms(options)
  when /cdom/
    list_cdoms(options)
  else
    list_all_ldoms(options)
  end
  return
end

def list_all_ldoms(options)
  list_cdoms(options)
  list_gdoms(options)
  return
end


  