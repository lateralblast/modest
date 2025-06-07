# frozen_string_literal: true

# AutoYast server routines

# Configure AutoYast server

def configure_ay_server(values)
  unless values['search'].to_s.match(/[a-z]|[A-Z]|all/)
    if values['service'].to_s.match(/[a-z]/)
      search_string = 'SLE' if values['service'].downcase.match(/suse/)
    else
      search_string = 'SLE'
    end
  end
  configure_linux_server(values, search_string)
  nil
end

# List AutoYast services

def list_ay_services(values)
  values['method'] = 'ay'
  dir_list = get_dir_item_list(values)
  message  = 'AutoYast Services:'
  verbose_message(values, message)
  dir_list.each do |service|
    verbose_message(values, service)
  end
  verbose_message(values, '')
  nil
end

# Unconfigure AutoYast server

def unconfigure_ay_server(values)
  unconfigure_ks_repo(values)
end
