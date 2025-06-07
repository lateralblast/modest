# frozen_string_literal: true

# Solaris LDoms support code

def list_ldoms(values)
  case values['vm']
  when /ldom/
    list_all_ldoms(values)
  when /gdom/
    list_gdoms(values)
  when /cdom/
    list_cdoms(values)
  else
    list_all_ldoms(values)
  end
  nil
end

def list_all_ldoms(values)
  list_cdoms(values)
  list_gdoms(values)
  nil
end
