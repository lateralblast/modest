# frozen_string_literal: true

# Common Windows (PE) related code

def list_pe_isos(values)
  values['os-type'] = 'win'
  values['method']  = ''
  values['release'] = ''
  values['arch']    = ''
  values['file']    = ''
  list_isos(values)
  nil
end
