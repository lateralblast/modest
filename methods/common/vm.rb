# Code for creating client VMs for testing (e.g. VirtualBox)

# Handle VM install status

def handle_vm_install_status(values)
  if values['status'].to_s.match(/no/)
    handle_output(values, "Warning:\tVirtualisation application does not exist for #{values['vm']}")
    quit(values)
  end
  return
end

# AWS check

def check_aws_is_installed(values)
  check_if_aws_cli_is_installed()
  return
end

# Check a vm exists

def check_vm_exists(values)
  case values['vm']
  when /docker/
    exists = check_docker_vm_exists(values)
  when /aws/
    exists = check_aws_vm_exists(values)
  when /parallels/
    exists = check_parallels_vm_exists(values)
  when /qemu/
    exists = check_qemu_vm_exists(values)
  when /kvm/
    exists = check_kvm_vm_exists(values)
  when /vbox/
    exists = check_vbox_vm_exists(values)
  when /fusion/
    exists = check_fusion_vm_exists(values)
  when /mp|multipass/
    exists = check_multipass_vm_exists(values)
  end
  return exists
end

# Delete VM network

def delete_vm_network(values)
  case values['vm']
  when /fusion/
    exists = delete_fusion_vm_network(values)
  end
  return
end

# Delete VM snapshot

def delete_vm_snapshot(values)
  case values['vm']
  when /fusion/
    exists = delete_fusion_vm_snapshot(values)
  end
  return
end

# Try to get client VM type

def get_client_vm_type(values)
  values['vm'] = ""
  values['valid-vm'].each do |test_vm|
    if values['verbose'] == true
      handle_output(values, "Information:\tChecking if '#{values['name']}' is a '#{test_vm}' VM")
    end
    exists = eval"[check_#{test_vm}_is_installed(values)]"
    if exists.to_s.match(/yes/)
      exists = eval"[check_#{test_vm}_vm_exists(values)]"
      if exists.to_s.match(/yes/)
        values['vm'] = test_vm
        return values['vm']
      end
    end
  end
  return values['vm']
end

# Show VM config

def show_vm_config(values)
  case values['vm']
  when /fusion/
    show_fusion_vm_config(values)
  when /vbox/
    show_vbox_vm_config(values)
  end
  return
end

# Get VM screen

def get_vm_screen(values)
  case values['vm']
  when /fusion/
    get_fusion_vm_screen(values)
  end
  return
end

# Get VM network

def show_vm_network(values)
  case values['vm']
  when /fusion/
    show_fusion_vm_network(values)
  end
  return
end

# Get VM status

def get_vm_status(values)
  case values['vm']
  when /fusion/
    get_fusion_vm_status(values)
  when /vbox/
    get_vboc_vm_status(values)
  when /parallels/
    get_parallels_vm_status(values)
  end
  return
end

# VNC to VMware Fusion VM

def vnc_to_vm(values)
  values['ip'] = single_install_ip(values)
  novnc_dir = values['novncdir']
  check_vnc_install(values)
  exists = check_vm_exists(values)
  if exists.match(/yes/)
    if File.directory?(values['novncdir'])
      if not values['ip'].to_s.match(/[0-9]/)
        values['ip'] = get_fusion_vm_ip(values)
      end
      if values['ip'].to_s.match(/[0-9]/)
        temp_ip = values['ip'].split(/\./)[-1]
        if temp_ip.to_i < 100
          local_vnc_port = "60"+temp_ip
        else
          local_vnc_port = "6"+temp_ip
        end
        if values['vncport'] == values['empty']
          if values['vm'].to_s.match(/fusion/)
            remote_vnc_port = get_fusion_vm_vmx_file_value(values['name'], "remotedisplay.vnc.port")
          end
        else
          remote_vnc_port = values['vncport']
        end
        if remote_vnc_port.match(/[0-9]/)
          message = "Information:\tChecking noVNC isn't already running"
          command = "ps -ef |grep noVNC |grep #{values['ip']} | grep -v grep"
          output  = execute_command(values, message, command)
          if not output.match(/noVNC/)
            message = "Information:\tStarting noVNC web proxy on port "+local_vnc_port+" and redirecting to "+remote_vnc_port
            command = "cd '#{novnc_dir}' ; ./utils/launch.sh --listen #{local_vnc_port} --vnc #{values['ip']}:#{remote_vnc_port} &"
            execute_command(values, message, command)
            handle_output(values, "Information:\tNoVNC started on port #{local_vnc_port}")
          else
            handle_output(values, "Information:\tnoVNC already running")
          end
        else
          handle_output(values, "Warning:\tUnable to determine VNC port for #{values['vmapp']} VM #{values['name']}")
        end
      else
        handle_output(values, "Warning:\tUnable to determine IP for #{values['vmapp']} VM #{values['name']}")
      end
    end
  end
  return values['ip'], local_vnc_port, remote_vnc_port
end

# Get Guest OS type

def get_vm_guest_os(values)
  case values['vm']
  when /qemu/
    guest_os = get_qemu_guest_os(values)
  when /kvm/
    guest_os = get_kvm_guest_os(values)
  when /xen/
    guest_os = get_xen_guest_os(values)
  when /vbox/
    guest_os = get_vbox_guest_os(values)
  when /fusion/
    guest_os = get_fusion_guest_os(values)
  end
  return guest_os
end

# Check VM network

def check_vm_network(values)
  check_local_config(values)
  get_default_host(values)
  vm_if_name = get_vm_if_name(values)
  if values['vmnetwork'].to_s.match(/nat/)
    gw_if_name = get_gw_if_name(values)
    gw_if_ip   = get_gw_if_ip(values, gw_if_name)
    values['vmgateway'] = gw_if_ip
  end
  case values['vm']
  when /vbox/
    values = check_vbox_natd(values, vm_if_name)
  when /fusion/
    values = check_fusion_natd(values, vm_if_name)
  when /mp|multipass/
    values = check_multipass_natd(values, vm_if_name)
  end
  if values['host-os-uname'].to_s.match(/NT/)
    output = get_win_ip_from_if_name(vm_if_name)
  else
    message = "Information:\tChecking "+vm_if_name+" is configured"
    command = "ifconfig #{vm_if_name} |grep inet"
    output  = execute_command(values, message, command)
  end
  if not output.match(/#{values['hostonlyip']}/)
    message = "Information:\tConfiguring "+vm_if_name
    if values['host-os-uname'].to_s.match(/NT/)
      command = "netsh interface ip set address #{vm_if_name} static #{values['hostonlyip']} #{values['netmask']}"
    else
      command = "ifconfig #{vm_if_name} inet #{values['hostonlyip']} netmask #{values['netmask']} up"
    end
    execute_command(values, message, command)
  end
  return values
end

# List VM snapshots

def list_vm_snapshots(values)
  if values['vm'] == values['empty']
    values['vm'] = get_client_vm_type(values)
  end
  case values['vm']
  when /vbox/
    list_vbox_vm_snapshots(values)
  when /fusion/
    list_fusion_vm_snapshots(values)
  end
  return
end

# List all VM snapshots

def list_all_vm_snaphsots(values)
  if values['vm'] == values['empty']
    values['vm'] = get_client_vm_type(values)
  end
  case values['vm']
  when /vbox/
    list_all_vbox_vm_snapshots(values)
  when /fusion/
    list_all_fusion_vm_snapshots(values)
  end
  return
end

# Delete VM snapshots

def delete_vm_snaphsot(values)
  if values['vm'] == values['empty']
    values['vm'] = get_client_vm_type(values)
  end
  case values['vm']
  when /vbox/
    delete_vbox_vm_snapshot(values)
  when /fusion/
    delete_fusion_vm_snapshot(values)
  when /aws/
    delete_aws_vm_snapshot(values)
  end
  return
end

# Control VM

def control_vm(values)
  if values['vm'] == values['empty']
    values['vm'] = get_client_vm_type(values)
  end
  case values['action']
  when /delete|unconfigure/
    unconfigure_vm(values)
  when /create|configure/
    configure_vm(values)
  when /boot|start/
    boot_vm(values)
  when /halt|stop/
    halt_vm(values)
  end
  return
end

# Boot VM

def boot_vm(values)
  if values['vm'] == values['empty']
    values['vm'] = get_client_vm_type(values)
  end
  case values['vm']
  when /docker/
    exists = boot_docker_vm(values)
  when /aws/
    exists = boot_aws_vm(values)
  when /parallels/
    exists = boot_parallels_vm(values)
  when /qemu/
    exists = boot_qemu_vm(values)
  when /kvm/
    exists = boot_kvm_vm(values)
  when /vbox/
    exists = boot_vbox_vm(values)
  when /fusion/
    exists = boot_fusion_vm(values)
  when /cdom/
    exists = boot_cdom_vm(values)
  when /gdom/
    exists = boot_cdom_vm(values)
  end
  return exists
end

# Stop VM

def stop_vm(values)
  exists = halt_vm(values)
  return exists
end

# Import VMDK

def import_vmdk(values)
  case values['vm']
  when /fusion/
    import_fusion_ova(values)
  end
  return
end

# Add VM network

def add_vm_network(values)
  case values['vm']
  when /fusion/
    add_fusion_vm_network(values)
  end
  return
end

# Halt VM

def halt_vm(values)
  if values['vm'] == values['empty']
    values['vm'] = get_client_vm_type(values)
  end
  case values['vm']
  when /docker/
    exists = halt_docker_vm(values)
  when /aws/
    exists = halt_aws_vm(values)
  when /parallels/
    exists = halt_parallels_vm(values)
  when /qemu/
    exists = halt_qemu_vm(values)
  when /kvm/
    exists = halt_kvm_vm(values)
  when /vbox/
    exists = halt_vbox_vm(values)
  when /fusion/
    exists = halt_fusion_vm(values)
  when /cdom/
    exists = halt_cdom_vm(values)
  when /gdom/
    exists = halt_cdom_vm(values)
  end
  return exists
end

# Configure VM

def configure_vm(values)
  if values['vm'] == values['empty']
    values['vm'] = get_client_vm_type(values)
  end
  case values['vm']
  when /docker/
    configure_docker_vm(values)
  when /aws/
    configure_aws_vm(values)
  when /parallels/
   configure_parallels_vm(values)
  when /qemu/
   configure_qemu_vm(values)
  when /kvm/
    configure_kvm_vm(values)
  when /vbox/
    configure_vbox_vm(values)
  when /fusion/
    configure_fusion_vm(values)
  when /cdom/
    configure_cdom_vm(values)
  when /gdom/
    configure_cdom_vm(values)
  when /multipass|mp/
    configure_multipass_vm(values)
  end
  return
end

# Delete VM

def unconfigure_vm(values)
  delete_vm(values)
  return
end

def delete_vm(values)
  if values['vm'] == values['empty']
    values['vm'] = get_client_vm_type(values)
  end
  case values['vm']
  when /docker/
    unconfigure_docker_vm(values)
  when /aws/
    unconfigure_aws_vm(values)
  when /parallels/
    unconfigure_parallels_vm(values)
  when /qemu/
    unconfigure_qemu_vm(values)
  when /kvm/
    unconfigure_kvm_vm(values)
  when /vbox/
    unconfigure_vbox_vm(values)
  when /fusion/
    unconfigure_fusion_vm(values)
  when /cdom/
    unconfigure_cdom_vm(values)
  when /gdom/
    unconfigure_cdom_vm(values)
  when /multipass|mp/
    unconfigure_multipass_vm(values)
  end
  remove_hosts_entry(values)
  return
end

# Create VM

def create_vm(values)
  values['ip'] = single_install_ip(values)
  if values['vm'].to_s.match(/fusion/) and values['mac'].to_s.match(/[0-9]/)
    values['mac'] = check_fusion_vm_mac(values)
  end
  if not values['method'].to_s.match(/[a-z]/) and not values['os-type'].to_s.match(/[a-z]/)
    if values['verbose'] == true
      handle_output(values, "Warning:\tInstall method or OS not specified")
      handle_output(values, "Information:\tSetting OS to other")
    end
    values['method'] = "other"
  end
  if values['file'].to_s.match(/ova$/)
    if values['vm'].to_s.match(/vbox/)
      configure_vm(values)
    end
    import_ova(values)
  else
    configure_vm(values)
  end
  return
end

# Import OVA

def import_ova(values)
  case values['vm']
  when /kmv/
    import_kvm_ova(values)
  when /vbox/
    import_vbox_ova(values)
  when /fusion/
    import_fusion_ova(values)
  end
  return
end

# list VMs

def list_vms(values)
  case values['vm']
  when /vbox/
    list_vbox_vms(values)
  when /fusion/
    list_fusion_vms(values)
  when /parallels/
    list_parallels_vms(values)
  when /kvm/
    list_kvm_vms(values)
  when /docker/
    list_docker_vms(values)
  when /multipass|mp/
    list_multipass_vms(values)
  when /libvirt|qemu/
    list_kvm_vms(values)
  else
    handle_output(values,"Warning:\tInvalid VM type")
    exit
  end
  return
end

# list VM

def list_vm(values)
  if not values['os-type'].to_s.match(/[a-z]/) and not values['method'].to_s.match(/[a-z]/)
    eval"[list_all_#{values['vm']}_vms()]"
  else
    if values['method'].to_s.match(/[a-z]/)
      eval"[list_#{values['method']}_#{values['vm']}_vms()]"
    else
      [ "ks", "js", "ps", "ay", "ai" ].each do |method|
        eval"[list_#{method}_#{values['vm']}_vms()]"
      end
    end
  end
  return
end

# List VM snaphots

def list_vm_snapshots(values)
  if values['name'].to_s.match(/[a-z]/)
    eval"[list_#{values['vm']}_vm_snapshots(values)]"
  else
    if not values['os-type'].to_s.match(/[a-z]/) and not values['method'].to_s.match(/[a-z]/)
      eval"[list_all_#{values['vm']}_vm_snapshots()]"
    end
  end
  return
end

# Catch all for listing VMs

def list_none_vms(values)
  return
end
