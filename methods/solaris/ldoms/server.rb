# frozen_string_literal: true

# Control Domain related code

# List CDom services

def list_cdom_services(values)
  if values['host-os-unamea'].match(/SunOS/)
    if values['host-os-unamer'].match(/10|11/)
      if values['host-os-unamea'].match(/sun4v/)
        ldom_type    = 'Control Domain'
        ldom_command = "ldm list |grep ^primary |awk '{print $1}'"
        list_doms(ldom_type, ldom_command)
      elsif values['verbose'] == true
        verbose_message(values, '')
        warning_message(values, 'This service is only available on the Sun4v platform')
        verbose_message(values, '')
      end
    elsif values['verbose'] == true
      verbose_message(values, '')
      warning_message(values, 'This service is only available on Solaris 10 or later')
      verbose_message(values, '')
    end
  elsif values['verbose'] == true
    verbose_message(values, '')
    warning_message(values, 'This service is only available on Solaris')
    verbose_message(values, '')
  end
  nil
end

def list_ldom_services(values)
  list_cdom_services(values)
  nil
end

def list_gdom_services(values)
  list_cdom_services(values)
  nil
end

# Check LDoms installed

def check_cdom_install(values)
  ldm_bin = '/usr/sbin/ldm'
  if !File.exist?(ldm_bin) && values['host-os-unamer'].match(/11/)
    message = "Information:\tInstalling LDoms software"
    command = 'pkg install ldomsmanager'
    execute_command(values, message, command)
  end
  smf_service = 'ldmd'
  enable_smf_service(values, smf_service)
  nil
end

# Check LDom VCC

def check_cdom_vcc(values)
  message = "Information:\tChecking LDom VCC"
  command = "ldm list-services |grep 'primary-vcc'"
  output  = execute_command(values, message, command)
  unless output.match(/vcc/)
    message = "Information:\tEnabling VCC"
    command = 'ldm add-vcc port-range=5000-5100 primary-vcc0 primary'
    execute_command(values, message, command)
  end
  nil
end

# Check LDom VDS

def check_cdom_vds(values)
  message = "Information:\tChecking LDom VDS"
  command = "ldm list-services |grep 'primary-vds'"
  output  = execute_command(values, message, command)
  unless output.match(/vds/)
    message = "Information:\tEnabling VDS"
    command = 'ldm add-vds primary-vds0 primary'
    execute_command(values, message, command)
  end
  nil
end

# Check LDom vSwitch

def check_cdom_vsw(values)
  message = "Information:\tChecking LDom vSwitch"
  command = "ldm list-services |grep 'primary-vsw'"
  output  = execute_command(values, message, command)
  unless output.match(/vsw/)
    message = "Information:\tEnabling vSwitch"
    command = 'ldm add-vsw net-dev=net0 primary-vsw0 primary'
    execute_command(values, message, command)
  end
  nil
end

# Check LDom config

def check_cdom_config(values)
  message = "Information:\tChecking LDom configuration"
  command = "ldm list-config |grep 'current'"
  output  = execute_command(values, message, command)
  if output.match(/factory-default/)
    config  = values['answers']['cdom_name'].value
    message = "Information:\tChecking LDom configuration #{config} does not exist"
    command = "ldm list-config |grep #{config}"
    output  = execute_command(values, message, command)
    if output.match(/#{config}/)
      warning_message(values, "LDom configuration #{config} already exists")
      quit(values)
    end
    if values['host-os-unamea'].match(/T5[0-9]|T3/)
      mau     = values['answers']['cdom_mau'].value
      message = "Information:\tAllocating #{mau}Crypto unit(s) to primary domain"
      command = "ldm set-mau #{mau} primary"
      execute_command(values, message, command)
    end
    vcpu    = values['answers']['cdom_vcpu'].value
    message = "Information:\tAllocating #{vcpu}vCPU unit(s) to primary domain"
    command = "ldm set-vcpu #{vcpu} primary"
    execute_command(values, message, command)
    message = "Information:\tStarting reconfiguration of primary domain"
    command = 'ldm start-reconf primary'
    execute_command(values, message, command)
    memory  = values['answers']['cdom_memory'].value
    message = "Information:\tAllocating #{memory}to primary domain"
    command = "ldm set-memory #{memory} primary"
    execute_command(values, message, command)
    message = "Information:\tSaving LDom configuration of primary domain as #{config}"
    command = "ldm add-config #{config}"
    execute_command(values, message, command)
    command = 'shutdown -y -g0 -i6'
    if values['yes'] == true
      message = "Warning:\tRebooting primary domain to enable settings"
      execute_command(values, message, command)
    else
      warning_message(values, 'Reboot required for settings to take effect')
      verbose_message(values, "Infromation:\tExecute #{command}")
      quit(values)
    end
  end
  nil
end

# Configure LDom vntsd

def check_cdom_vntsd(values)
  smf_service = 'vntsd'
  enable_smf_service(values, smf_service)
  nil
end

# Configure LDom Control (primary) domain

def configure_cdom(values)
  values['service'] = ''
  check_dhcpd_config(values)
  values = populate_cdom_questions(values)
  process_questions(values)
  check_cdom_install(values)
  check_cdom_vcc(values)
  check_cdom_vds(values)
  check_cdom_vsw(values)
  check_cdom_config(values)
  check_cdom_vntsd(values)
  nil
end

# Configure LDom Server (calls configure_cdom)

def configure_ldom_server(values)
  configure_cdom(values)
  nil
end

def configure_cdom_server(values)
  configure_cdom(values)
  nil
end

# Unconfigure LDom Server

def unconfigure_cdom(values)
  warning_message(values, 'Currently unconfiguring the Control Domain must be done manually')
  quit(values)
  nil
end

def unconfigure_ldom_server(values)
  unconfigure_cdom(values)
  nil
end

def unconfigure_gdom_server(values)
  unconfigure_cdom(values)
  nil
end

# List LDom ISOs

def list_ldom_isos(_values)
  nil
end

def list_cdom_isos(_values)
  nil
end

def list_gdom_isos(_values)
  nil
end
