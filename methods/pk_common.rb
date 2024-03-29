# Common packer code

# Get packer version

def get_packer_version()
  packer_version = %x[#{options['packer']} --version].chomp
  return packer_version
end

# Check packer is installed

def check_packer_is_installed(options)
  if options['packer'] == options['empty']
    packer_bin = %x[which packer].chomp
  else
    packer_bin = options['packer'].to_s
  end
  packer_version = options['packerversion'].to_s
  if !packer_bin.match(/packer/) or !File.exist?(packer_bin)
    if options['host-os-uname'].to_s.match(/Darwin/)
      install_osx_package(options, "packer")
      packer_bin = %x[which packer].chomp
    else
      if options['host-os-unamem'].to_s.match(/64/)
        packer_bin = "packer_"+packer_version+"_"+options['host-os-uname'].downcase+"_amd64.zip"
        packer_url = "https://releases.hashicorp.com/packer/"+packer_version+"/"+packer_bin
      else
        packer_bin = "packer_"+packer_version+"_"+options['host-os-uname'].downcase+"_386.zip"
        packer_url = "https://releases.hashicorp.com/packer/"+$packer_version+"/"+packer_bin
      end
      tmp_file = "/tmp/"+packer_bin
      if not File.exist?(tmp_file)
        wget_file(options, packer_url, tmp_file)
      end
      if not File.directory?("/usr/local/bin") and not File.symlink?("/usr/local/bin")
        message = "Information:\tCreating /usr/local/bin"
        command = "mkdir /usr/local/bin"
        execute_command(options, message, command)
      end
      message = "Information:\tExtracting and installing Packer"
      command = "sudo sh -c 'cd /tmp ; unzip -o #{tmp_file} ; cp /tmp/packer /usr/local/bin ; chmod +x /usr/local/bin/packer'"
      execute_command(options, message, command)
    end
  end
  options['packer'] = packer_bin
  return options
end

# Import Packer VM

def import_packer_vm(options)
  case options['vm']
  when /fusion/
    import_packer_fusion_vm(options)
  when /vbox/
    import_packer_vbox_vm(options)
  when /kvm/
    import_packer_kvm_vm(options)
  end
  return
end
