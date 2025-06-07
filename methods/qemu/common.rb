# frozen_string_literal: true

# QEMU support code

# Check QEMU VM exists

def check_qemu_vm_exists(values)
  message   = "Information:\tChecking VM #{values['name']} exists"
  command   = 'virsh list --all'
  host_list = execute_command(values, message, command)
  if !host_list.match(/#{values['name']}/)
    information_message(values, "KVM VM #{values['name']} does not exist")
    exists = false
  else
    exists = true
  end
  exists
end

# Get QEMY guest OS

def get_qemu_guest_os(values)
  if values['method'].to_s.match(/win/)
    'windows'
  else
    'linux'
  end
end

# Check KVM VM exists

def check_kvm_vm_exists(values)
  check_qemu_vm_exists(values)
end

# Check KVM VM exists

def check_xen_vm_exists(values)
  check_qemu_vm_exists(values)
end

# Get KVM guest OS

def get_kvm_guest_os(values)
  get_qemu_guest_os(values)
end

# Get XEN guest OS

def get_xen_guest_os(_values)
  nil
end

# Check QEMU is installed

def check_qemu_is_installed(_values)
  nil
end

# List QEMU VMs

def list_qemu_vms(_values)
  nil
end
