# frozen_string_literal: true

# Code for creating client VMs for testing (e.g. VirtualBox)

# Handle VM install status

def handle_vm_install_status(values)
  if values['status'].to_s.match(/no/)
    warning_message(values, "Virtualisation application does not exist for #{values['vm']}")
    quit(values)
  end
  nil
end

# AWS check

def check_aws_is_installed(values)
  check_if_aws_cli_is_installed(values)
  nil
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
  exists
end

# Delete VM network

def delete_vm_network(values)
  case values['vm']
  when /fusion/
    delete_fusion_vm_network(values)
  end
  nil
end

# Delete VM snapshot

def delete_vm_snapshot(values)
  case values['vm']
  when /fusion/
    delete_fusion_vm_snapshot(values)
  end
  nil
end

# Try to get client VM type

def get_client_vm_type(values)
  values['vm'] = ''
  values['valid-vm'].each do |test_vm|
    information_message(values, "Checking if '#{values['name']}' is a '#{test_vm}' VM")
    exists = eval "[check_#{test_vm}_is_installed(values)]"
    next unless exists.to_s.match(/yes/)

    exists = eval "[check_#{test_vm}_vm_exists(values)]"
    if exists.to_s.match(/yes/)
      values['vm'] = test_vm
      return values['vm']
    end
  end
  values['vm']
end

# Show VM config

def show_vm_config(values)
  case values['vm']
  when /fusion/
    show_fusion_vm_config(values)
  when /vbox/
    show_vbox_vm_config(values)
  end
  nil
end

# Get VM screen

def get_vm_screen(values)
  case values['vm']
  when /fusion/
    get_fusion_vm_screen(values)
  end
  nil
end

# Get VM network

def show_vm_network(values)
  case values['vm']
  when /fusion/
    show_fusion_vm_network(values)
  end
  nil
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
  nil
end

# VNC to VMware Fusion VM

def vnc_to_vm(values)
  values['ip'] = single_install_ip(values)
  novnc_dir = values['novncdir']
  check_vnc_install(values)
  exists = check_vm_exists(values)
  if exists.match(/yes/) && File.directory?(values['novncdir'])
    values['ip'] = get_fusion_vm_ip(values) unless values['ip'].to_s.match(/[0-9]/)
    if values['ip'].to_s.match(/[0-9]/)
      temp_ip = values['ip'].split(/\./)[-1]
      local_vnc_port = if temp_ip.to_i < 100
                         "60#{temp_ip}"
                       else
                         "6#{temp_ip}"
                       end
      if values['vncport'] == values['empty']
        remote_vnc_port = get_fusion_vm_vmx_file_value(values['name'], 'remotedisplay.vnc.port') if values['vm'].to_s.match(/fusion/)
      else
        remote_vnc_port = values['vncport']
      end
      if remote_vnc_port.match(/[0-9]/)
        message = "Information:\tChecking noVNC is not already running"
        command = "ps -ef |grep noVNC |grep #{values['ip']} | grep -v grep"
        output  = execute_command(values, message, command)
        if !output.match(/noVNC/)
          message = "Information:\tStarting noVNC web proxy on port #{local_vnc_port} and redirecting to #{remote_vnc_port}"
          command = "cd '#{novnc_dir}' ; ./utils/launch.sh --listen #{local_vnc_port} --vnc #{values['ip']}:#{remote_vnc_port} &"
          execute_command(values, message, command)
          information_message(values, "NoVNC started on port #{local_vnc_port}")
        else
          information_message(values, 'noVNC already running')
        end
      else
        warning_message(values, "Unable to determine VNC port for #{values['vmapp']} VM #{values['name']}")
      end
    else
      warning_message(values, "Unable to determine IP for #{values['vmapp']} VM #{values['name']}")
    end
  end
  [values['ip'], local_vnc_port, remote_vnc_port]
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
  guest_os
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
    message = "Information:\tChecking #{vm_if_name} is configured"
    command = "ifconfig #{vm_if_name} |grep inet"
    output  = execute_command(values, message, command)
  end
  unless output.match(/#{values['hostonlyip']}/)
    message = "Information:\tConfiguring #{vm_if_name}"
    command = if values['host-os-uname'].to_s.match(/NT/)
                "netsh interface ip set address #{vm_if_name} static #{values['hostonlyip']} #{values['netmask']}"
              else
                "ifconfig #{vm_if_name} inet #{values['hostonlyip']} netmask #{values['netmask']} up"
              end
    execute_command(values, message, command)
  end
  values
end

# List VM snapshots

def list_vm_snapshots(values)
  values['vm'] = get_client_vm_type(values) if values['vm'] == values['empty']
  case values['vm']
  when /vbox/
    list_vbox_vm_snapshots(values)
  when /fusion/
    list_fusion_vm_snapshots(values)
  end
  nil
end

# List all VM snapshots

def list_all_vm_snaphsots(values)
  values['vm'] = get_client_vm_type(values) if values['vm'] == values['empty']
  case values['vm']
  when /vbox/
    list_all_vbox_vm_snapshots(values)
  when /fusion/
    list_all_fusion_vm_snapshots(values)
  end
  nil
end

# Delete VM snapshots

def delete_vm_snaphsot(values)
  values['vm'] = get_client_vm_type(values) if values['vm'] == values['empty']
  case values['vm']
  when /vbox/
    delete_vbox_vm_snapshot(values)
  when /fusion/
    delete_fusion_vm_snapshot(values)
  when /aws/
    delete_aws_vm_snapshot(values)
  end
  nil
end

# Control VM

def control_vm(values)
  values['vm'] = get_client_vm_type(values) if values['vm'] == values['empty']
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
  nil
end

# Boot VM

def boot_vm(values)
  values['vm'] = get_client_vm_type(values) if values['vm'] == values['empty']
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
  exists
end

# Stop VM

def stop_vm(values)
  halt_vm(values)
end

# Import VMDK

def import_vmdk(values)
  case values['vm']
  when /fusion/
    import_fusion_ova(values)
  end
  nil
end

# Add VM network

def add_vm_network(values)
  case values['vm']
  when /fusion/
    add_fusion_vm_network(values)
  end
  nil
end

# Halt VM

def halt_vm(values)
  values['vm'] = get_client_vm_type(values) if values['vm'] == values['empty']
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
  exists
end

# Configure VM

def configure_vm(values)
  values['vm'] = get_client_vm_type(values) if values['vm'] == values['empty']
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
  nil
end

# Delete VM

def unconfigure_vm(values)
  delete_vm(values)
  nil
end

def delete_vm(values)
  values['vm'] = get_client_vm_type(values) if values['vm'] == values['empty']
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
  nil
end

# Create VM

def create_vm(values)
  values['ip'] = single_install_ip(values)
  values['mac'] = check_fusion_vm_mac(values) if values['vm'].to_s.match(/fusion/) && values['mac'].to_s.match(/[0-9]/)
  if !values['method'].to_s.match(/[a-z]/) && !values['os-type'].to_s.match(/[a-z]/)
    warning_message(values, 'Install method or OS not specified')
    information_message(values, 'Setting OS to other')
    values['method'] = 'other'
  end
  if values['file'].to_s.match(/ova$/)
    configure_vm(values) if values['vm'].to_s.match(/vbox/)
    import_ova(values)
  else
    configure_vm(values)
  end
  nil
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
  nil
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
    verbose_message(values, "Warning:\tInvalid VM type")
    quit(values)
  end
  nil
end

# list VM

def list_vm(values)
  if !values['os-type'].to_s.match(/[a-z]/) && !values['method'].to_s.match(/[a-z]/)
    eval "[list_all_#{values['vm']}_vms(values)]"
  elsif values['method'].to_s.match(/[a-z]/)
    eval "[list_#{values['method']}_#{values['vm']}_vms(values)]"
  else
    %w[ks js ps ay ai].each do |method|
      eval "[list_#{method}_#{values['vm']}_vms(values)]"
    end
  end
  nil
end

# List VM snaphots

def list_vm_snapshots(values)
  if values['name'].to_s.match(/[a-z]/)
    eval "[list_#{values['vm']}_vm_snapshots(values)]"
  elsif !values['os-type'].to_s.match(/[a-z]/) && !values['method'].to_s.match(/[a-z]/)
    eval "[list_all_#{values['vm']}_vm_snapshots(values)]"
  end
  nil
end

# Catch all for listing VMs

def list_none_vms(_values)
  nil
end
