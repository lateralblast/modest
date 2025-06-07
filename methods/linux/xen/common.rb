# frozen_string_literal: true

# XEN support code

# Check XEN is installed

def check_xen_is_installed(_values)
  nil
end

# List XEN VMs

def list_xen_vms(values)
  return unless values['host-os-uname'].to_s.match(/Linux/)

  nil
end
