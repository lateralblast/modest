# Common Ansible code

# Get ansible version

def get_ansible_version(values)
	version = %x[ansible --version |head -1 |awk '{print $1'}].chomp
  return version
end

# Check Ansible is installed

def check_ansible_is_installed(values)
  check_python_module_is_installed("boto")
  ansible_bin = %x[which ansible].chomp
  if not ansible_bin.match(/ansible/) or ansible_bin.match(/no /)
    values = install_package("ansible")
  end
  return
end
