# Common packer code

# Get packer version

def get_packer_version()
  packer_version = %x[#{values['packer']} --version].chomp
  return packer_version
end

# Check packer is installed

def check_packer_is_installed(values)
  if values['packer'] == values['empty']
    packer_bin = %x[which packer].chomp
  else
    packer_bin = values['packer'].to_s
  end
  packer_version = values['packerversion'].to_s
  if !packer_bin.match(/packer/) or !File.exist?(packer_bin)
    if values['host-os-uname'].to_s.match(/Darwin/)
      install_osx_package(values, "packer")
      packer_bin = %x[which packer].chomp
    else
      if values['host-os-unamem'].to_s.match(/64/)
        packer_bin = "packer_"+packer_version+"_"+values['host-os-uname'].downcase+"_amd64.zip"
        packer_url = "https://releases.hashicorp.com/packer/"+packer_version+"/"+packer_bin
      else
        packer_bin = "packer_"+packer_version+"_"+values['host-os-uname'].downcase+"_386.zip"
        packer_url = "https://releases.hashicorp.com/packer/"+$packer_version+"/"+packer_bin
      end
      tmp_file = "/tmp/"+packer_bin
      if not File.exist?(tmp_file)
        wget_file(values, packer_url, tmp_file)
      end
      if not File.directory?("/usr/local/bin") and not File.symlink?("/usr/local/bin")
        message = "Information:\tCreating /usr/local/bin"
        command = "mkdir /usr/local/bin"
        execute_command(values, message, command)
      end
      message = "Information:\tExtracting and installing Packer"
      command = "sudo sh -c 'cd /tmp ; unzip -o #{tmp_file} ; cp /tmp/packer /usr/local/bin ; chmod +x /usr/local/bin/packer'"
      execute_command(values, message, command)
    end
  end
  values['packer'] = packer_bin
  return values
end

# Import Packer VM

def import_packer_vm(values)
  case values['vm']
  when /fusion/
    import_packer_fusion_vm(values)
  when /vbox/
    import_packer_vbox_vm(values)
  when /kvm/
    import_packer_kvm_vm(values)
  end
  return
end
