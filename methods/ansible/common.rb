# frozen_string_literal: true

# Common Ansible code

# Get ansible version

def get_ansible_version(_values)
  `ansible --version |head -1 |awk '{print $1'}`.chomp
end

# Check Ansible is installed

def check_ansible_is_installed(_values)
  check_python_module_is_installed('boto')
  ansible_bin = `which ansible`.chomp
  install_package('ansible') if !ansible_bin.match(/ansible/) || ansible_bin.match(/no /)
  nil
end
