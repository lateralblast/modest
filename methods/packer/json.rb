
# Packer JSON code

# Configure Packer JSON file

def create_packer_json(values)
  net_config        = ""
  nic_command1      = ""
  nic_command2      = ""
  nic_command3      = ""
  nic_config1       = ""
  nic_config2       = ""
  nic_config3       = ""
  communicator      = values['communicator'].to_s
  controller        = values['controller'].to_s
  hw_version        = values['hwversion'].to_s
  winrm_use_ssl     = values['winrmusessl'].to_s
  winrm_insecure    = values['winrminsecure'].to_s
  virtual_dev       = values['virtualdevice'].to_s
  ethernet_dev      = values['ethernetdevice'].to_s
  vnc_enabled       = values['enablevnc'].to_s
  vhv_enabled       = values['enablevhv'].to_s
  ethernet_enabled  = values['enableethernet'].to_s
  boot_wait         = values['bootwait'].to_s
  shutdown_timeout  = values['shutdowntimeout'].to_s
  ssh_port          = values['sshport'].to_s
  ssh_host          = values['ip'].to_s
  winrm_host        = values['ip'].to_s
  ssh_timeout       = values['sshtimeout'].to_s
  hwvirtex          = values['hwvirtex'].to_s
  vtxvpid           = values['vtxvpid'].to_s
  vtxux             = values['vtxux'].to_s
  rtcuseutc         = values['rtcuseutc'].to_s
  audio             = values['audio'].to_s
  mouse             = values['mouse'].to_s
  ssh_pty           = values['sshpty'].to_s
  winrm_port        = values['winrmport'].to_s
  disk_format       = values['format'].to_s
  accelerator       = values['accelerator'].to_s
  disk_interface    = values['diskinterface'].to_s
  net_device        = values['netdevice'].to_s
  guest_os_type     = values['guest'].to_s
  disk_size         = values['size'].to_s.gsub(/G/, "000")
  natpf_ssh_rule    = ""
  ssh_host_port_min = values['sshportmin'].to_s
  ssh_host_port_max = values['sshportmax'].to_s
  admin_home        = values['adminhome'].to_s
  admin_group       = values['admingroup'].to_s
  iso_url           = "file://"+values['file'].to_s
  packer_dir        = values['clientdir'].to_s+"/packer"
  image_dir         = values['clientdir'].to_s+"/images"
  http_dir          = packer_dir
  http_port_max     = values['httpportmax'].to_s
  http_port_min     = values['httpportmin'].to_s
  vm_name           = values['name'].to_s
  vm_type           = values['vmtype'].to_s
  memsize           = values['memory'].to_s
  numvcpus          = values['vcpus'].to_s
  mac_address       = values['mac'].to_s
  usb               = values['usb'].to_s
  ssh_port          = values['packersshport'].to_s
  usb_xhci_present  = values['usbxhci'].to_s
  disk_adapter_type = values['diskinterface'].to_s
  boot_command      = ""
  virtio_file       = values['virtiofile'].to_s
  if values['vm'].to_s.match(/kvm/)
    file_name = "/usr/share/ovmf/OVMF.fd"
    if File.exist?(file_name)
      bios_file = file_name
    end
    file_name = "/usr/share/edk2/x64/OVMF.fd"
    if File.exist?(file_name)
      bios_file = file_name
    end
  end
  if values['vm'].to_s.match(/fusion/)
    if hw_version.to_i >= 20
      disk_adapter_type = "nvme"
    end
  end
  if values['answers']['admin_password']
    install_password = values['answers']['admin_password'].value
  else
    install_password = values['answers']['root_password'].value
  end
  if values['vm'].to_s.match(/parallels/)
    case values['service'].to_s
    when /win/
      parallels_tools_flavor = "win"
    when /ubuntu|rhel|sles|rocky|alma/
      parallels_tools_flavor = "lin"
    when /mac|osx/
      parallels_tools_flavor = "mac"
    else
      parallels_tools_flavor = "other"
    end
  end
  if values['livecd'] == true
    http_dir = packer_dir+"/"+values['vm']+"/"+values['name']+"/subiquity/http"
  end
  if values['dhcp'] == true 
    if values['vm'].to_s.match(/fusion/)
      if values['service'].to_s.match(/vmware|vsphere|esx/)
        ethernet_type = "vpx"
      else
        ethernet_type = "generated"
      end
    else
      ethernet_type = "dhcp"
    end
  else
    ethernet_type = "static"
  end
  if Dir.exist?(image_dir)
    FileUtils.rm_rf(image_dir)
  end
  json_file = packer_dir+"/"+values['vm']+"/"+values['name']+"/"+values['name']+".json"
  check_dir_exists(values, values['clientdir'])
  if !values['service'].to_s.match(/purity/)
    headless_mode = values['answers']['headless_mode'].value
  end
  if values['method'].to_s.match(/vs/)
    admin_crypt = values['answers']['root_crypt'].value
  else
    if not values['service'].to_s.match(/win|sol_[9,10]/)
      admin_crypt = values['answers']['admin_crypt'].value
    end
  end
  if values['answers']['guest_additions_mode']
    guest_additions_mode = values['answers']['guest_additions_mode'].value
  else
    guest_additions_mode = values['vmtools']
  end
  if values['vmnetwork'].to_s.match(/hostonly/)
    if values['httpbindaddress'] != values['empty']
      if values['vn'].to_s.match(/fusion/)
        ks_ip = values['vmgateway']
      else
        ks_ip = values['httpbindaddress']
      end
    else
      if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 10 
        if values['vm'].to_s.match(/fusion/)
          ks_ip = values['vmgateway']
        else
          ks_ip = values['hostip']
        end
      else
        ks_ip = values['vmgateway']
      end
    end
    natpf_ssh_rule = "packerssh,tcp,"+values['ip']+","+ssh_port+","+values['ip']+",22"
  else
    if values['httpbindaddress'] != values['empty']
      ks_ip = values['httpbindaddress']
    else
      if values['vm'].to_s.match(/fusion/) and values['dhcp'] == true
        ks_ip = values['vmgateway']
      else
        ks_ip = values['hostip']
      end
    end
    natpf_ssh_rule = ""
  end
  if values['ip'].to_s.match(/[0-9]/)
    port_no = values['ip'].split(/\./)[-1]
    if port_no.to_i < 100
      port_no = "0"+port_no
    end
    vnc_port_min = "6"+port_no
    vnc_port_max = "6"+port_no
  else
    vnc_port_min = "5900"
    vnc_port_max = "5980"
  end
  case values['vm'].to_s
  when /vbox/
    output_format = "ova"
    if values['service'].to_s.match(/win/)
      ssh_host_port_min = "5985"
      ssh_host_port_max = "5985"
      winrm_port        = "5985"
    end
  when /fusion/
    hw_version = get_fusion_version(values)
  when /kvm|xen|qemu/
    vm_type = "qemu"
    disk_format = "qcow2"
    if values['vm'].to_s.match(/kvm/)
      accelerator = "kvm"
      if values['service'].to_s.match(/windows/)
        if File.exist?(virtio_file)
          disk_interface = "ide"
          net_device     = "e1000"
          ssh_port       = winrm_port
          ssh_host_port_min = winrm_port
          ssh_host_port_max = winrm_port
#          disk_interface = "virtio-scsi"
#          net_device     = "virtio-net"
        else 
          disk_interface = "ide"
          net_device     = "e1000"
        end
      else
        disk_interface = "virtio"
        net_device     = "virtio-net"
        nic_device     = "virtio"
      end
      net_bridge = values['bridge'].to_s
    end
  end
  tools_upload_flavor = ""
  tools_upload_path   = ""
  if values['vmnetwork'].to_s.match(/hostonly/) and values['vm'].to_s.match(/vbox/)
    if_name  = get_bridged_vbox_nic(values)
    nic_name = check_vbox_hostonly_network(values)
    nic_command1 = "--nic1"
    nic_config1  = "hostonly"
    nic_command2 = "--nictype1"
    if values['service'].to_s.match(/vmware|esx|vsphere/)
      nic_config2  = "virtio"
    else
      nic_config2  = "82545EM"
    end
    nic_command3 = "--hostonlyadapter1"
    nic_config3  = "#{nic_name}"
    if values['httpbindaddress'] != values['empty']
      ks_ip = values['httpbindaddress']
    else
      ks_ip = values['vmgateway']
    end
  end
  if values['vmnetwork'].to_s.match(/bridged/) and values['vm'].to_s.match(/vbox/)
    nic_name = get_bridged_vbox_nic()
    nic_command1 = "--nic1"
    nic_config1  = "bridged"
    nic_command2 = "--nictype1"
    if values['service'].to_s.match(/vmware|esx|vsphere/)
      nic_config2 = "virtio"
    else
      nic_config2 = "82545EM"
    end
    nic_command3 = "--bridgeadapter1"
    nic_config3  = "#{nic_name}"
  end
  if values['service'].to_s.match(/[el,centos,rocky,alma]_8/)
    virtual_dev = "pvscsi"
  end
  if values['service'].to_s.match(/sol_10/)
    ssh_username   = values['adminuser']
    ssh_password   = values['adminpassword']
    admin_username = values['adminuser']
    admin_password = values['adminpassword']
  else
    if values['method'].to_s.match(/vs/)
      ssh_username = "root"
      ssh_password = values['answers']['root_password'].value
    else
      ssh_username   = values['answers']['admin_username'].value
      ssh_password   = values['answers']['admin_password'].value
      admin_username = values['answers']['admin_username'].value
      admin_password = values['answers']['admin_password'].value
    end
  end
  if not values['service'].to_s.match(/win|purity/)
    root_password = values['answers']['root_password'].value
  end
  shutdown_command = ""
  if not mac_address.to_s.match(/[0-9]/)
    mac_address = generate_mac_address(values['vm'])
  end
  if values['guest'].class == Array
    values['guest'] = values['guest'].join
  end
  if values['service'].to_s.match(/sol/)
    if values['copykeys'] == true && File.exist?(values['sshkeyfile'].to_s)
      ssh_key = %x[cat #{values['sshkeyfile'].to_s}].chomp
      ssh_dir = "/export/home/#{values['answers']['admin_username'].value}/.ssh"
      ssh_com = "<wait>mkdir -p #{ssh_dir}<enter>"+
                "<wait>chmod 700 #{ssh_dir}<enter>"+
                "<wait>echo '#{ssh_key}' > #{ssh_dir}/authorized_keys<enter>"+
                "<wait>chmod 600 #{ssh_dir}/authorized_keys<enter>"
    else
      ssh_com = ""
    end
  end
  values['size'] = values['size'].gsub(/G/, "000")
  case values['service'].to_s
  when /win/
    if values['vmtools'] == true
      if not values['label'].to_s.match(/2016|2019/)
        tools_upload_flavor = "windows"
        tools_upload_path   = "C:\\Windows\\Temp\\windows.iso"
      end
    end
    shutdown_command = "shutdown /s /t 1 /c \"Packer Shutdown\" /f /d p:4:1"
    unattended_xml   = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/Autounattend.xml"
    post_install_psh = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/post_install.ps1"
    if values['label'].to_s.match(/20[0,1][0-8]/)
      if values['vm'].to_s.match(/fusion/)
        values['guest'] = "windows8srv-64"
        virtual_dev = "lsisas1068"
        hw_version  = "12"
      end
      if memsize.to_i < 2000
        memsize = "2048"
      end
    else
      if values['vm'].to_s.match(/fusion/)
        if values['label'].to_s.match(/20[1,2][0-9]/)
          values['guest'] = "windows9srv-64"
          virtual_dev = "lsisas1068"
        else
          values['guest'] = "windows7srv-64"
        end
      end
    end
  when /sol_11_[2-3]/
    if values['host-os-cpu'].to_i > 6 and values['host-os-memory'].to_i > 16
      wait_time1 = "<wait120>"
      wait_time2 = "<wait90>"
    else
      wait_time1 = "<wait160>"
      wait_time2 = "<wait120>"
    end
    if memsize.to_i < 2048
      memsize = "2048"
    end
    ssh_port            = "22"
    ssh_host_port_max   = "22"
    ssh_host_port_min   = "22"
    #tools_upload_flavor = "solaris"
    #tools_upload_path   = "/export/home/"+values['answers']['admin_username'].value
    tools_upload_flavor = ""
    tools_upload_path   = ""
    boot_command = wait_time1+
                   "<wait>27<enter><wait>"+
                   "<wait>3<enter><wait>"+
                   wait_time2+
                   "<wait>1<enter><wait10><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><bs><bs><bs><bs><bs><bs><bs>"+values['name']+"<wait>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><tab><f2><wait>"+
                   values['ip']+"<wait><tab><wait><tab>"+
                   values['vmgateway']+"<wait><f2><wait>"+
                   "<wait><f2><wait>"+
                   values['nameserver']+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   values['answers']['root_password'].value+"<wait><tab><wait>"+
                   values['answers']['root_password'].value+"<wait><tab><wait>"+
                   values['answers']['admin_username'].value+"<wait><tab><wait>"+
                   values['answers']['admin_username'].value+"<wait><tab><wait>"+
                   values['answers']['admin_password'].value+"<wait><tab><wait>"+
                   values['answers']['admin_password'].value+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   wait_time1+
                   wait_time1+
                   wait_time1+
                   "<wait><f8><wait10><wait10>"+
                   "<enter><wait10>"+
                   wait_time1+
                   "<enter><wait10>"+
                   values['answers']['admin_username'].value+"<enter><wait>"+
                   values['answers']['admin_password'].value+"<enter><wait>"+
                   ssh_com+
                   "echo '"+values['answers']['admin_password'].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+values['answers']['admin_username'].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail-client\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "sudo sh -c \"echo 'LookupClientHostnames no' >> /etc/ssh/sshd_config\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_11_4/
    if values['host-os-cpu'].to_i > 6 and values['host-os-memory'].to_i > 16
      wait_time1 = "<wait130>"
      wait_time2 = "<wait100>"
    else
      wait_time1 = "<wait160>"
      wait_time2 = "<wait120>"
    end
    if memsize.to_i < 2048
      memsize = "2048"
    end
    ssh_port            = "22"
    ssh_host_port_max   = "22"
    ssh_host_port_min   = "22"
    #tools_upload_flavor = "solaris"
    #tools_upload_path   = "/export/home/"+values['answers']['admin_username'].value
    tools_upload_flavor = ""
    tools_upload_path   = ""
    boot_command = "<wait180>"+
                   "<wait>27<enter><wait>"+
                   "<wait>3<enter><wait>"+
                   wait_time1+
                   "<wait>1<enter><wait10><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><bs><bs><bs><bs><bs><bs><bs>"+values['name']+"<wait>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><tab><f2><wait>"+
                   values['ip']+"<wait><tab><wait><tab>"+
                   "<wait><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+values['vmgateway']+"<wait><f2><wait>"+
                   "<wait><f2><wait>"+
                   values['nameserver']+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   values['answers']['root_password'].value+"<wait><tab><wait>"+
                   values['answers']['root_password'].value+"<wait><tab><wait>"+
                   values['answers']['admin_username'].value+"<wait><tab><wait>"+
                   values['answers']['admin_username'].value+"<wait><tab><wait>"+
                   values['answers']['admin_password'].value+"<wait><tab><wait>"+
                   values['answers']['admin_password'].value+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   wait_time1+
                   wait_time1+
                   wait_time1+
                   "<wait><f8><wait10><wait10>"+
                   "<enter><wait10>"+
                   wait_time1+
                   values['answers']['admin_username'].value+"<enter><wait>"+
                   values['answers']['admin_password'].value+"<enter><wait>"+
                   ssh_com+
                   "echo '"+values['answers']['admin_password'].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+values['answers']['admin_username'].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm stop sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm stop asr-notify\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_11_[0,1]/
    if values['host-os-cpu'].to_i > 6 and values['host-os-memory'].to_i > 16
      wait_time1 = "<wait120>"
      wait_time2 = "<wait90>"
    else
      wait_time1 = "<wait160>"
      wait_time2 = "<wait120>"
    end
    ssh_port            = "22"
    ssh_host_port_max   = "22"
    ssh_host_port_min   = "22"
    #tools_upload_flavor = "solaris"
    #tools_upload_path   = "/export/home/"+values['answers']['admin_username'].value
    tools_upload_flavor = ""
    tools_upload_path   = ""
    boot_command = wait2+
                   "27<enter><wait>"+
                   "3<enter><wait>"+
                   wait2+
                   "1<enter><wait10><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<bs><bs><bs><bs><bs><bs><bs>"+values['name']+"<wait>"+
                   "<tab><tab><f2><wait10>"+
                   values['ip']+"<wait><tab><wait><tab>"+
                   values['vmgateway']+"<wait><f2><wait>"+
                   "<f2><wait>"+
                   values['nameserver']+"<wait><f2><wait>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   values['answers']['root_password'].value+"<wait><tab><wait>"+
                   values['answers']['root_password'].value+"<wait><tab><wait>"+
                   values['answers']['admin_username'].value+"<wait><tab><wait>"+
                   values['answers']['admin_username'].value+"<wait><tab><wait>"+
                   values['answers']['admin_password'].value+"<wait><tab><wait>"+
                   values['answers']['admin_password'].value+"<wait><f2><wait>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   wait1+
                   wait1+
                   "<wait10><wait10><wait10><wait10>"+
                   "<f8><wait10><wait10>"+
                   "<enter><wait10>"+
                   wait1+
                   values['answers']['admin_username'].value+"<enter><wait>"+
                   values['answers']['admin_password'].value+"<enter><wait>"+
                   ssh_com+
                   "echo '"+values['answers']['admin_password'].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+values['answers']['admin_username'].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_10/
#    tools_upload_flavor = "solaris"
#    tools_upload_path   = "/export/home/"+values['answers']['admin_username'].value
    sysidcfg = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/sysidcfg"
    rules    = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/rules"
    rules_ok = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/rules.ok"
    profile  = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/profile"
    finish   = values['clientdir']+"/packer/"+values['vm']+"/"+values['name']+"/finish"
    boot_command = "e<wait>"+
                   "e<wait>"+
                   "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><wait>"+
                   "- nowin install -B install_media=cdrom<enter><wait>"+
                   "b<wait>"
    shutdown_command = "echo '/usr/sbin/poweroff' > shutdown.sh; pfexec bash -l shutdown.sh"
    shutdown_timeout = "20m"
  when /sles/
    ssh_port           = "22"
    ssh_host_port_max  = "22"
    ssh_host_port_min  = "22"
    install_domain     = values['domainname']
    ks_file            = values['vm']+"/"+values['name']+"/"+values['name']+".xml"
    ks_url             = "http://#{ks_ip}:#{values['httpport']}/"+ks_file
    install_nic        = values['answers']['nic'].value
    values['netmask'] = values['answers']['netmask'].value
    values['vmgateway']  = values['answers']['gateway'].value
    values['nameserver'] = values['answers']['nameserver'].value
    net_config            = install_nic+"="+values['ip']+"/24,"+values['vmgateway']+","+values['nameserver']+","+install_domain
    if values['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        boot_command = "<esc><enter><wait> linux<wait>"+
                       " netdevice="+values['answers']['nic'].value+
                       " ifcfg=\"{{ user `net_config`}}\""+
                       " autoyast="+ ks_url+
                       " lang="+values['language']+
                       " insecure=1 install=cd:/ textmode=1"+
                       "<enter><wait>"
      else
        boot_command = "<esc><enter><wait> linux text install=cd:/ textmode=1 insecure=1"+
                       " netdevice="+install_nic+
                       " netsetup=dhcp"+
                       " autoyast="+ ks_url+
                       " lang="+values['language']+
                       " insecure=1 install=cd:/ textmode=1"+
                       "<enter><wait>"
      end
    else
      ks_file      = values['vm']+"/"+values['name']+"/"+values['name']+".xml"
      ks_url       = "http://#{ks_ip}:#{values['httpport']}/"+ks_file
      boot_command = "<esc><enter><wait> linux text install=cd:/ textmode=1 insecure=1"+
                     " netdevice="+values['answers']['nic'].value+
                     " autoyast="+ ks_url+
                     " language="+values['language']+
                     " netsetup=-dhcp,+hostip,+netmask,+gateway,+nameserver1,+domain"+
                     " hostip="+values['ip']+"/24"+
                     " netmask="+values['netmask']+
                     " gateway="+values['vmgateway']+
                     " nameserver="+values['nameserver']+
                     " domain="+install_domain+
                     "<enter><wait>"
    end
  when /purity/
    install_netmask    = values['answers']['netmask'].value
    install_vmgateway  = values['answers']['gateway'].value
    install_nameserver = values['answers']['nameserver'].value
    install_broadcast  = values['answers']['broadcast'].value
    install_timezone   = values['answers']['timezone'].value
    install_netaddr    = values['answers']['network_address'].value
    install_nic        = values['answers']['nic'].value
    if install_nic.match(/^ct/)
      purity_nic  = values['answers']['nic'].value
      install_nic = values['answers']['nic'].value.split(".")[0]
    else
      purity_nic  = "ct0."+install_nic
    end
    if values['host-os-cpu'].to_i > 6 and values['host-os-memory'].to_i > 16
      wait_time1 = "<wait360>"
      wait_time2 = "<wait210>"
    else
      wait_time1 = "<wait500>"
      wait_time2 = "<wait210>"
    end
    install_domain    = values['domainname']
    ssh_host_port_min = ssh_port
    ssh_host_port_max = ssh_port
    net_config        = "/etc/network/interfaces"
    script_url        = "http://"+values['vmgateway']+":8888/"+values['vm']+"/"+values['name']+"/setup.sh"
    script_file       = packer_dir+"/"+values['vm']+"/"+values['name']+"/setup.sh"
    if !File.exist?(values['setup'])
      verbose_output(values, "Warning:\tSetup script '#{values['setup']}' not found")
      quit(values)
    else
      message = "Information:\tCopying '#{values['setup']}' to '#{script_file}'"
      command = "cp '#{values['setup']}' '#{script_file}'"
      execute_command(values, message, command)
      user = %x[cat '#{script_file}' |grep Username |awk '{print $3}'].chomp
      pass = %x[cat '#{script_file}' |grep Password |awk '{print $3}'].chomp
    end
    other_ips = ""
    other_net = ""
    if values['ip'].to_s.match(/,/)
      values['ip'] = values['ip'].split(/,/)[0]
    end
    if values['answers']['eth1_ip']
      if values['answers']['eth1_ip'].value.match(/[0-9]/)
        values['ip'] = values['answers']['eth1_ip'].value
        c_service = values['answers']['eth1_service'].value
        interface = "ct0.eth1"
        ethernet  = "eth1"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+values['ip']+" --netmask "+install_netmask+" --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{values['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{install_vmgateway}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{install_netmask}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    if values['answers']['eth2_ip']
      if values['answers']['eth2_ip'].value.match(/[0-9]/)
        values['ip'] = values['answers']['eth2_ip'].value
        c_service = values['answers']['eth2_service'].value
        interface = "ct0.eth2"
        ethernet  = "eth2"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+values['ip']+" --netmask 255.255.255.0 --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{values['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{values['vmgateway']}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{values['netmask']}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    if values['answers']['eth3_ip']
      if values['answers']['eth3_ip'].value.match(/[0-9]/)
        values['ip'] = values['answers']['eth3_ip'].value
        c_service = values['answers']['eth3_service'].value
        interface = "ct0.eth3"
        ethernet  = "eth3"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+values['ip']+" --netmask 255.255.255.0 --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{values['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{values['vmgateway']}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{values['netmask']}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    if values['answers']['eth4_ip']
      if values['answers']['eth4_ip'].value.match(/[0-9]/)
        values['ip'] = values['answers']['eth4_ip'].value
        c_service = values['answers']['eth4_service'].value
        interface = "ct0.eth4"
        ethernet  = "eth4"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+values['ip']+" --netmask 255.255.255.0 --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{values['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{values['vmgateway']}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{values['netmask']}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    if values['answers']['eth5_ip']
      if values['answers']['eth5_ip'].value.match(/[0-9]/)
        values['ip'] = values['answers']['eth5_ip'].value
        c_service = values['answers']['eth5_service'].value
        interface = "ct0.eth5"
        ethernet  = "eth5"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+values['ip']+" --netmask 255.255.255.0 --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{values['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{values['vmgateway']}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{values['netmask']}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    boot_command = wait_time1+user+"<enter><wait><enter>"+pass+"<enter>"+
                   "<wait2>ifconfig eth0 inet "+values['ip']+" up<enter>"+
                   "<wait3>wget -O /root/setup.sh "+script_url+"<enter>"+
                   "<wait3>chmod +x /root/setup.sh ; cd /root ; ./setup.sh<enter>"+wait_time2+"<enter><enter>"+
                   "<wait9>purenetwork setattr "+purity_nic+" --address "+values['ip']+" --gateway "+values['vmgateway']+" --netmask "+values['netmask']+"<enter>"+
                   "<wait9>purenetwork enable "+purity_nic+"<enter>"+
                   "<wait9>puredns setattr --nameservers "+values['nameserver']+"<enter>"+
                   "<wait9>puredns setattr --domain "+install_domain+"<enter><wait3>purearray rename "+values['name']+"<enter>"+
                   other_ips+
                   "<wait9>chmod 4755 /bin/su ; usermod --expiredate 1 pureeng<enter>"+ 
                   "<wait3>groupadd "+ssh_username+" ; groupadd "+admin_group+"<enter>"+
                   "<wait3>echo '"+ssh_username+" ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/"+ssh_username+"<enter>"+
                   "<wait3>useradd -p '"+admin_crypt+"' -g "+ssh_username+" -G "+admin_group+" -d "+admin_home+" -s /bin/bash -m "+ssh_username+"<enter>"+
                   "<wait3>echo 'UseDNS No' >> /etc/ssh/sshd_config<enter>"+
                   "<wait3>echo 'Port #{ssh_port}' >> /etc/ssh/sshd_config ; service ssh restart<enter>"+
                   "<wait3>echo '# The primary network interface' >> #{net_config}<enter>"+
                   "<wait3>echo 'auto #{install_nic}' >> #{net_config}<enter>"+
                   "<wait3>echo 'iface #{install_nic} inet static' >> #{net_config}<enter>"+
                   "<wait3>echo 'address #{values['ip']}' >> #{net_config}<enter>"+
                   "<wait3>echo 'gateway #{values['vmgateway']}' >> #{net_config}<enter>"+
                   "<wait3>echo 'netmask #{values['netmask']}' >> #{net_config}<enter>"+
                   "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
                   "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"+
                   other_net+
                   "<wait3>echo '#{values['timezone']}' > /etc/timezone<enter>"+
                   "<wait3>service firewall stop<enter>"
  when /debian|ubuntu/
    tools_upload_flavor = ""
    tools_upload_path   = ""
    if values['httpbindaddress'] != values['empty']
      ks_ip = values['httpbindaddress']
    else
      if !values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 10 
        if values['vmnetwork'].to_s.match(/nat/)
          if values['dhcp'] == true
            ks_ip = values['hostonlyip'].to_s
          else
            ks_ip = values['hostip'].to_s
          end
        else
          ks_ip = values['hostonlyip'].to_s
        end
      else
        if values['host-os-uname'].to_s.match(/Darwin/) && values['host-os-version'].to_i > 10 
          if values['vmnetwork'].to_s.match(/hostonly/)
            ks_ip = values['vmgateway'].to_s
          else
            ks_ip = values['hostip'].to_s
          end
        else
          ks_ip = values['hostip'].to_s
        end
      end
    end
    ks_file = values['vm']+"/"+values['name']+"/"+values['name']+".cfg"
    if values['livecd'] == true 
      boot_wait    = "3s"
      if values['release'].to_i >= 20
#        boot_header = "<wait>e<wait><down><wait><down><wait><down><wait><leftCtrlOn>e<leftCtrlOff>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs>linux /casper/vmlinuz --- "
        if not values['service'].to_s.match(/22_04_3/)
          boot_header = "<wait>e<wait><down><wait><down><wait><down><wait><leftCtrlOn>e<leftCtrlOff>"+
                        "<bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                        "--- "
        else
          boot_header = "<wait>e<wait><down><wait><down><wait><down><wait><leftCtrlOn>e<leftCtrlOff> "
        end
        boot_footer = "<wait><f10><wait><enter>"
#        boot_footer  = ""
      else
        boot_header  = "<enter><enter><f6><esc><wait><bs><bs><bs><bs>"
        boot_footer  = ""
      end
      if values['biosdevnames'] == true
        boot_header = boot_header+"net.ifnames=0 biosdevname=0 "
      end
      if values['release'].to_i >= 20
        boot_command = boot_header+
                      "autoinstall ds='nocloud-net;s=http://"+ks_ip+":#{values['httpport']}/' "+
                      boot_footer
      else
        boot_command = boot_header+
                      "--- autoinstall ds=nocloud-net;seedfrom=http://"+ks_ip+":#{values['httpport']}/"+
                       "<enter><wait>"+
                       boot_footer
      end
    else
      if values['vm'].to_s.match(/parallels/)
        boot_header = "<wait>e<wait><down><wait><down><wait><down><wait><leftCtrlOn>e<leftCtrlOff>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs>"
        boot_footer = "<wait><f10><wait>"
      else
        boot_header = "<enter><wait5><f6><esc><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><wait>"
        boot_footer = "<wait><enter><wait>"
      end
      if values['biosdevnames'] == true
        kernel_string = "net.ifnames=0 biosdevname=0 "
      else
        kernel_string = ""
      end
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        ks_url = "http://#{ks_ip}:#{values['httpport']}/"+ks_file
        boot_command = boot_header+
                       "<wait>/install/vmlinuz<wait> debian-installer/language="+values['answers']['language'].value+
                       " debian-installer/country="+values['answers']['country'].value+
                       " keyboard-configuration/layoutcode="+values['answers']['layout'].value+
                       " <wait>interface="+values['answers']['nic'].value+
                       " netcfg/disable_autoconfig="+values['answers']['disable_autoconfig'].value+
                       " netcfg/disable_dhcp="+values['answers']['disable_dhcp'].value+
                       " hostname="+values['name']+
                       " <wait>netcfg/get_ipaddress="+values['ip']+
                       " netcfg/get_netmask="+values['answers']['netmask'].value+
                       " netcfg/get_gateway="+values['answers']['gateway'].value+
                       " netcfg/get_nameservers="+values['answers']['nameserver'].value+
                       " netcfg/get_domain="+values['answers']['domain'].value+
                       " <wait>preseed/url="+ks_url+
                       " initrd=/install/initrd.gz "+kernel_string+"-- "+
                       boot_footer
      else
        ks_url = "http://#{ks_ip}:#{values['httpport']}/"+ks_file
        boot_command = boot_header+
                       "/install/vmlinuz<wait>"+
                       " auto-install/enable=true"+
                       " debconf/priority=critical"+
                       " <wait>preseed/url="+ks_url+
                       " initrd=/install/initrd.gz "+kernel_string+"-- "+
                       boot_footer
      end
    end
    shutdown_command = "echo 'shutdown -P now' > /tmp/shutdown.sh ; echo '#{install_password}'|sudo -S sh '/tmp/shutdown.sh'"
  when /vsphere|esx|vmware/
    boot_wait = "2s"
    if values['vm'].to_s.match(/fusion/)
      virtual_dev = "pvscsi"
    end
    hwvirtex = "on"
    ks_file  = values['vm']+"/"+values['name']+"/"+values['name']+".cfg"
    ks_url   = "http://#{ks_ip}:#{values['httpport']}/"+ks_file
    if values['vm'].to_s.match(/fusion/)
      boot_command = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=vmnic0 netdevice=vmnic0 ip="+values['ip']+" netmask="+values['netmask']+" gateway="+values['vmgateway']+"<wait><enter><wait>"
    else
      if values['vm'].to_s.match(/kvm/)
        net_device     = "e1000e"
        disk_interface = "ide"
        boot_command   = "<enter><wait><leftShiftOn>O<leftShiftOff><wait> netdevice=vmnic0 ip="+values['ip']+" netmask="+values['netmask']+" gateway="+values['vmgateway']+" ks="+ks_url+"<wait><enter><wait>"
      else
        boot_command = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=vmnic0 netdevice=vmnic0 ip="+values['ip']+" netmask="+values['netmask']+" gateway="+values['vmgateway']+"<wait><enter><wait>"
      end
    end
    ssh_username      = "root"
#    shutdown_command  = "poweroff; while true; do sleep 10; done;"
    ssh_host_port_min = "22"
    ssh_host_port_max = "22"
#    communicator      = "ssh"
  when /fedora|[el,centos,rocky,alma]_[8,9]/
    tools_upload_flavor = ""
    tools_upload_path   = ""
    ks_file      = values['vm']+"/"+values['name']+"/"+values['name']+".cfg"
    ks_url       = "http://#{ks_ip}:#{values['httpport']}/"+ks_file
    if values['biosdevnames'] == true
      kernel_string = "net.ifnames=0 biosdevname=0 "
    else
      kernel_string = ""
    end
    if values['vmnetwork'].to_s.match(/hostonly|bridged/)
      boot_command = "<tab><wait><bs><bs><bs><bs><bs><bs>=0 "+kernel_string+"inst.text inst.method=cdrom inst.repo=cdrom:/dev/sr0 inst.ks="+ks_url+" ip="+values['ip']+"::"+values['vmgateway']+":"+values['netmask']+":"+values['name']+":eth0:off<enter><wait>"
    else
      boot_command = "<tab><wait><bs><bs><bs><bs><bs><bs>=0 "+kernel_string+"inst.text inst.method=cdrom inst.repo=cdrom:/dev/sr0 inst.ks="+ks_url+" ip=dhcp<enter><wait>"
    end
    shutdown_command = "sudo /usr/sbin/shutdown -P now"
#  when /rhel_7/
#    ks_file       = values['vm']+"/"+values['name']+"/"+values['name']+".cfg"
#    ks_url        = "http://#{ks_ip}:#{values['httpport']}/"+ks_file
#    boot_command  = "<esc><wait> linux text install ks="+ks_url+" ksdevice=eno16777736 "+"ip="+values['ip']+" netmask="+values['netmask']+" gateway="+values['vmgateway']+"<enter><wait>"
  else
    if values['biosdevnames'] == true
      kernel_string = "net.ifnames=0 biosdevname=0 "
    else
      kernel_string = ""
    end
    ks_file = values['vm']+"/"+values['name']+"/"+values['name']+".cfg"
    ks_url  = "http://#{ks_ip}:#{values['httpport']}/"+ks_file
    if values['vmnetwork'].to_s.match(/hostonly|bridged/)
      boot_command  = "<esc><wait> linux "+kernel_string+"text install ks="+ks_url+" ip="+values['ip']+" netmask="+values['netmask']+" gateway="+values['vmgateway']+"<enter><wait>"
    else
      boot_command  = "<esc><wait> linux "+kernel_string+"text install ks="+ks_url+"<enter><wait>"
    end
    if values['guest'].class == Array
      values['guest'] = values['guest'].join
    end
    #shutdown_command = "echo '#{values['answers']['admin_password'].value}' |sudo -S /sbin/halt -h -p"
    shutdown_command = "sudo /usr/sbin/shutdown -P now"
  end
  controller = controller.gsub(/sas/, "scsi")
  case values['vm']
  when /vbox|virtualbox/
    vm_type = "virtualbox-iso"
    mac_address = mac_address.gsub(/:/, "")
  when /fusion|vmware/
    vm_type = "vmware-iso"
  when /parallels/
    vm_type = "parallels-iso"
  end
  if values['checksum'] == true
    md5_file = values['file']+".md5"
    if File.exist?(md5_file)
      install_md5 = File.readlines(md5_file)[0]
    else
      install_md5 = %x[md5 "#{values['file']}" |awk '{print $4}'].chomp
    end
    install_checksum      = install_md5
    install_checksum_type = "md5"
  else
    install_checksum      = ""
    install_checksum_type = "none"
  end
  if install_checksum_type == "none"
    install_checksum = "none"
  else
    install_checksum = install_checksum_type+":"+install_checksum
  end
  if values['vm'].to_s.match(/kvm/)
    if values['console'].to_s.match(/text/)
      headless_mode = "true"
    end
  end
  bridge_nic = get_vm_if_name(values)
  if values['service'].to_s.match(/windows/) and values['vm'].to_s.match(/vbox/) and values['vmnetwork'].to_s.match(/hostonly|bridged/)
    verbose_output(values, "Warning:\tPacker with Windows and VirtualBox only works on a NAT network (Packer issue)")
    verbose_output(values, "Information:\tUse the --network=nat option")
    quit(values)
  end
  if !values['guest'] || values['guest'] = values['empty']
    if values['vm'].to_s.match(/vbox/)
     values['guest'] = get_vbox_guest_os(values)
    end
    if values['vm'].to_s.match(/fusion/)
     values['guest'] = get_fusion_guest_os(values)
    end
  end
  case values['service']
  when /vmware|vsphere|esxi/
    case values['vm']
    when /vbox/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :guest_additions_mode => guest_additions_mode,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_host             => ssh_host,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :ssh_pty              => ssh_pty,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :format               => output_format,
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", memsize ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", numvcpus ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", mac_address ],
            ]
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :guest_additions_mode => guest_additions_mode,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :hard_drive_interface => controller,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_port             => ssh_port,
            :ssh_timeout          => ssh_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", memsize ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", numvcpus ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", mac_address ],
            ]
          ]
        }
      end
    when /fusion/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_host             => ssh_host,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :http_bind_address    => ks_ip,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :usb                  => usb,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"usb_xhci.present"                 => usb_xhci_present,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => memsize,
              :numvcpus                           => numvcpus,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => values['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :usb                  => usb,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"usb_xhci.present"                 => usb_xhci_present,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => memsize,
              :numvcpus                           => numvcpus,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => values['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    when /qemu|kvm|xen/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        if values['headless'] == true || values['console'].to_s.match(/text/)
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :communicator         => communicator,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_host             => ssh_host,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :http_bind_address    => ks_ip,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize ],
                [ "-smp", "cpus="+numvcpus ]
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
#              :communicator         => communicator,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_host             => ssh_host,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize ],
                [ "-smp", "cpus="+numvcpus ]
              ]
            ]
          }
        end
      else
        if values['headless'] == true
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize+"M" ],
                [ "-smp", "cpus="+numvcpus ]
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_max,
              :http_port_max        => http_port_min,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize+"M" ],
                [ "-smp", "cpus="+numvcpus ]
              ]
            ]
          }
        end
      end
    end
  when /purity/
    case values['vm']
    when /vbox/
      json_data = {
        :variables => {
          :hostname => values['name'],
          :net_config => net_config
        },
        :builders => [
          :name                 => vm_name,
          :vm_name              => vm_name,
          :guest_additions_mode => guest_additions_mode,
          :type                 => vm_type,
          :headless             => headless_mode,
          :guest_os_type        => guest_os_type,
          :output_directory     => image_dir,
          :disk_size            => disk_size,
          :iso_url              => iso_url,
          :ssh_host             => ssh_host,
          :ssh_port             => ssh_port,
          :ssh_username         => ssh_username,
          :ssh_password         => ssh_password,
          :ssh_timeout          => ssh_timeout,
          :shutdown_command     => shutdown_command,
          :shutdown_timeout     => shutdown_timeout,
          :ssh_pty              => ssh_pty,
          :iso_checksum         => install_checksum,
          :http_directory       => http_dir,
          :http_port_min        => http_port_min,
          :http_port_max        => http_port_max,
          :boot_wait            => boot_wait,
          :boot_command         => boot_command,
          :tools_upload_flavor  => tools_upload_flavor,
          :tools_upload_path    => tools_upload_path,
          :vboxmanage => [
            [ "modifyvm", "{{.Name}}", "--memory", memsize ],
            [ "modifyvm", "{{.Name}}", "--audio", audio ],
            [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
            [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
            [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
            [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
            [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
            [ "modifyvm", "{{.Name}}", "--cpus", numvcpus ],
            [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
            [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
            [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
            [ "modifyvm", "{{.Name}}", "--macaddress1", mac_address ],
          ]
        ]
      }
    when /fusion/
      json_data = {
        :variables => {
          :hostname => values['name'],
          :net_config => net_config
        },
        :builders => [
          :name                 => vm_name,
          :vm_name              => vm_name,
          :type                 => vm_type,
          :headless             => headless_mode,
          :guest_os_type        => guest_os_type,
          :output_directory     => image_dir,
          :disk_size            => disk_size,
          :iso_url              => iso_url,
          :ssh_host             => ssh_host,
          :ssh_port             => ssh_port,
          :ssh_username         => ssh_username,
          :ssh_password         => ssh_password,
          :ssh_timeout          => ssh_timeout,
          :shutdown_timeout     => shutdown_timeout,
          :shutdown_command     => shutdown_command,
          :ssh_pty              => ssh_pty,
          :iso_checksum         => install_checksum,
          :http_directory       => http_dir,
          :http_port_min        => http_port_min,
          :http_port_max        => http_port_max,
          :boot_wait            => boot_wait,
          :boot_command         => boot_command,
          :usb                  => usb,
          :tools_upload_flavor  => tools_upload_flavor,
          :tools_upload_path    => tools_upload_path,
          :vmx_data => {
            :"virtualHW.version"                => hw_version,
            :"usb_xhci.present"                 => usb_xhci_present,
            :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
            :memsize                            => memsize,
            :numvcpus                           => numvcpus,
            :"vhv.enable"                       => vhv_enabled,
            :"ethernet0.present"                => ethernet_enabled,
            :"ethernet0.connectionType"         => values['vmnetwork'],
            :"ethernet0.virtualDev"             => ethernet_dev,
            :"ethernet0.addressType"            => ethernet_type,
            :"ethernet0.address"                => generate_mac_address(values['vm']),
            :"ethernet1.present"                => ethernet_enabled,
            :"ethernet1.connectionType"         => values['vmnetwork'],
            :"ethernet1.virtualDev"             => ethernet_dev,
            :"ethernet1.addressType"            => ethernet_type,
            :"ethernet1.address"                => generate_mac_address(values['vm']),
            :"ethernet2.present"                => ethernet_enabled,
            :"ethernet2.connectionType"         => values['vmnetwork'],
            :"ethernet2.virtualDev"             => ethernet_dev,
            :"ethernet2.addressType"            => ethernet_type,
            :"ethernet2.address"                => generate_mac_address(values['vm']),
            :"ethernet3.present"                => ethernet_enabled,
            :"ethernet3.connectionType"         => values['vmnetwork'],
            :"ethernet3.virtualDev"             => ethernet_dev,
            :"ethernet3.addressType"            => ethernet_type,
            :"ethernet3.address"                => generate_mac_address(values['vm']),
            :"ethernet4.present"                => ethernet_enabled,
            :"ethernet4.connectionType"         => values['vmnetwork'],
            :"ethernet4.virtualDev"             => ethernet_dev,
            :"ethernet4.addressType"            => ethernet_type,
            :"ethernet4.address"                => generate_mac_address(values['vm']),
            :"ethernet5.present"                => ethernet_enabled,
            :"ethernet5.connectionType"         => values['vmnetwork'],
            :"ethernet5.virtualDev"             => ethernet_dev,
            :"ethernet5.addressType"            => ethernet_type,
            :"ethernet5.address"                => generate_mac_address(values['vm']),
            :"scsi0.virtualDev"                 => virtual_dev
          }
        ]
      }
    end
  when /sol_10/
    case values['vm']
    when /vbox/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :guest_additions_mode => guest_additions_mode,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_host             => ssh_host,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :http_bind_address    => ks_ip,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :format               => output_format,
            :floppy_files         => [
              sysidcfg,
              rules,
              rules_ok,
              profile,
              finish
            ],
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", memsize ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", numvcpus ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", mac_address ],
            ]
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :guest_additions_mode => guest_additions_mode,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :hard_drive_interface => controller,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_host             => ssh_host,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_pty              => ssh_pty,
            :ssh_timeout          => ssh_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :floppy_files         => [
              sysidcfg,
              rules,
              rules_ok,
              profile,
              finish
            ],
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", memsize ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", numvcpus ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", mac_address ],
            ]
          ]
        }
      end
    when /kvm|qemu|xen/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        if values['headless'] == true || values['console'].to_s.match(/text/)
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_host             => ssh_host,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :http_bind_address    => ks_ip,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize ],
                [ "-smp", "cpus="+numvcpus ]
              ],
              :floppy_files         => [
                sysidcfg,
                rules,
                rules_ok,
                profile,
                finish
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_host             => ssh_host,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :http_bind_address    => ks_ip,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize ],
                [ "-smp", "cpus="+numvcpus ]
              ],
              :floppy_files         => [
                sysidcfg,
                rules,
                rules_ok,
                profile,
                finish
              ]
            ]
          }
        end
      else
        if values['headless'] == true
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize+"M" ],
                [ "-smp", "cpus="+numvcpus ]
              ],
              :floppy_files         => [
                sysidcfg,
                rules,
                rules_ok,
                profile,
                finish
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize+"M" ],
                [ "-smp", "cpus="+numvcpus ]
              ],
              :floppy_files         => [
                sysidcfg,
                rules,
                rules_ok,
                profile,
                finish
              ]
            ]
          }
        end
      end
    when /fusion/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :http_bind_address    => ks_ip,
            :usb                  => usb,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :floppy_files         => [
              sysidcfg,
              rules,
              rules_ok,
              profile,
              finish
            ],
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"usb_xhci.present"                 => usb_xhci_present,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => memsize,
              :numvcpus                           => numvcpus,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => values['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :usb                  => usb,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :floppy_files         => [
              sysidcfg,
              rules,
              rules_ok,
              profile,
              finish
            ],
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"usb_xhci.present"                 => usb_xhci_present,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => memsize,
              :numvcpus                           => numvcpus,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => values['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    end
  when /win/
    case values['vm']
    when /vbox/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :type                 => vm_type,
            :guest_additions_mode => guest_additions_mode,
            :headless             => headless_mode,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :iso_checksum         => install_checksum,
            :guest_os_type        => guest_os_type,
            :communicator         => communicator,
            :ssh_host_port_min    => ssh_host_port_min,
            :ssh_host_port_max    => ssh_host_port_max,
            :winrm_port           => winrm_port,
            :winrm_host           => winrm_host,
            :winrm_username       => ssh_username,
            :winrm_password       => ssh_password,
            :winrm_timeout        => ssh_timeout,
            :winrm_use_ssl        => winrm_use_ssl,
            :winrm_insecure       => winrm_insecure,
            :boot_wait            => boot_wait,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :format               => output_format,
            :floppy_files         => [
              unattended_xml,
              post_install_psh
            ],
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", memsize ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", numvcpus ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", mac_address ],
            ]
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :guest_additions_mode => guest_additions_mode,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :iso_checksum         => install_checksum,
              :guest_os_type        => guest_os_type,
              :communicator         => communicator,
              :winrm_username       => ssh_username,
              :winrm_password       => ssh_password,
              :winrm_timeout        => ssh_timeout,
              :boot_wait            => boot_wait,
              :shutdown_timeout     => shutdown_timeout,
              :shutdown_command     => shutdown_command,
              :format               => output_format,
              :floppy_files         => [
                unattended_xml,
                post_install_psh
            ],
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", memsize ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", numvcpus ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", mac_address ],
              [ "modifyvm", "{{.Name}}", "--natpf1", "guestwinrm,tcp,,5985,,5985" ]
            ]
          ]
        }
      end
    when /fusion/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :communicator         => communicator,
            :winrm_host           => winrm_host,
            :winrm_username       => ssh_username,
            :winrm_password       => ssh_password,
            :winrm_timeout        => ssh_timeout,
            :winrm_use_ssl        => winrm_use_ssl,
            :winrm_insecure       => winrm_insecure,
            :winrm_port           => winrm_port,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :http_bind_address    => ks_ip,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :usb                  => usb,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :floppy_files         => [
              unattended_xml,
              post_install_psh
            ],
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"usb_xhci.present"                 => usb_xhci_present,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :"RemoteDisplay.vnc.port"           => vnc_port_min,
              :memsize                            => memsize,
              :numvcpus                           => numvcpus,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => values['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :communicator         => communicator,
            :winrm_username       => ssh_username,
            :winrm_password       => ssh_password,
            :winrm_timeout        => ssh_timeout,
            :winrm_use_ssl        => winrm_use_ssl,
            :winrm_insecure       => winrm_insecure,
            :winrm_port           => winrm_port,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :usb                  => usb,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :floppy_files         => [
              unattended_xml,
              post_install_psh
            ],
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"usb_xhci.present"                 => usb_xhci_present,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :"RemoteDisplay.vnc.port"           => vnc_port_min,
              :memsize                            => memsize,
              :numvcpus                           => numvcpus,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => values['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    when /qemu|kvm|xen/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        if values['headless'] == true || values['console'].to_s.match(/text/)
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :communicator         => communicator,
              :iso_url              => iso_url,
              :winrm_port           => winrm_port,
              :winrm_host           => winrm_host,
              :winrm_username       => ssh_username,
              :winrm_password       => ssh_password,
              :winrm_timeout        => ssh_timeout,
              :winrm_use_ssl        => winrm_use_ssl,
              :winrm_insecure       => winrm_insecure,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :http_bind_address    => ks_ip,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize ],
                [ "-smp", "cpus="+numvcpus ]
              ],
              :floppy_files         => [
                unattended_xml,
                post_install_psh
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :communicator         => communicator,
              :iso_url              => iso_url,
              :winrm_port           => winrm_port,
              :winrm_host           => winrm_host,
              :winrm_username       => ssh_username,
              :winrm_password       => ssh_password,
              :winrm_timeout        => ssh_timeout,
              :winrm_use_ssl        => winrm_use_ssl,
              :winrm_insecure       => winrm_insecure,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :http_bind_address    => ks_ip,
              :boot_wait            => boot_wait,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-serial",  "stdio" ],
                [ "-cpu",     "host" ],
                [ "-m",       memsize ],
                [ "-smp",     "cpus="+numvcpus ]
              ],
              :floppy_files         => [
                unattended_xml,
                post_install_psh
              ]
            ]
          }
        end
      else
        if values['headless'] == true
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :communicator         => communicator,
              :iso_url              => iso_url,
              :winrm_port           => winrm_port,
              :winrm_username       => ssh_username,
              :winrm_password       => ssh_password,
              :winrm_timeout        => ssh_timeout,
              :winrm_use_ssl        => winrm_use_ssl,
              :winrm_insecure       => winrm_insecure,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize+"M" ],
                [ "-smp", "cpus="+numvcpus ]
              ],
              :floppy_files         => [
                unattended_xml,
                post_install_psh
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :communicator         => communicator,
              :iso_url              => iso_url,
              :winrm_port           => winrm_port,
              :winrm_username       => ssh_username,
              :winrm_password       => ssh_password,
              :winrm_timeout        => ssh_timeout,
              :winrm_use_ssl        => winrm_use_ssl,
              :winrm_insecure       => winrm_insecure,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize+"M" ],
                [ "-smp", "cpus="+numvcpus ]
              ],
              :floppy_files         => [
                unattended_xml,
                post_install_psh
              ]
            ]
          }
        end
      end
    end
  else
    case values['vm']
    when /vbox/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :guest_additions_mode => guest_additions_mode,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_host             => ssh_host,
            :ssh_port             => ssh_port,
            :ssh_host_port_min    => ssh_host_port_min,
            :ssh_host_port_max    => ssh_host_port_max,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :ssh_pty              => ssh_pty,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :http_bind_address    => ks_ip,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :format               => output_format,
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", memsize ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", numvcpus ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", mac_address ],
            ]
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :guest_additions_mode => guest_additions_mode,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :hard_drive_interface => controller,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :iso_url              => iso_url,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", memsize ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", numvcpus ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", mac_address ],
            ]
          ]
        }
      end
    when /fusion/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :disk_adapter_type    => disk_adapter_type,
            :iso_url              => iso_url,
            :ssh_host             => ssh_host,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :http_bind_address    => ks_ip,
            :boot_wait            => boot_wait,
            :usb                  => usb,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"usb_xhci.present"                 => usb_xhci_present,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => memsize,
              :numvcpus                           => numvcpus,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => values['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address
            }
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => values['name'],
            :net_config => net_config
          },
          :builders => [
            :name                 => vm_name,
            :vm_name              => vm_name,
            :type                 => vm_type,
            :headless             => headless_mode,
            :guest_os_type        => guest_os_type,
            :output_directory     => image_dir,
            :disk_size            => disk_size,
            :disk_adapter_type    => disk_adapter_type,
            :iso_url              => iso_url,
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => http_port_min,
            :http_port_max        => http_port_max,
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :usb                  => usb,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"usb_xhci.present"                 => usb_xhci_present,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => memsize,
              :numvcpus                           => numvcpus,
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => values['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.GeneratedAddress"       => mac_address
            }
          ]
        }
      end
    when /parallels/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        if values['headless'] == true
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                   => vm_name,
              :vm_name                => vm_name,
              :type                   => vm_type,
              :output_directory       => image_dir,
              :disk_size              => disk_size,
              :memory                 => memsize, 
              :cpus                   => numvcpus, 
              :iso_url                => iso_url,
              :ssh_host               => ssh_host,
              :ssh_port               => ssh_port,
              :ssh_username           => ssh_username,
              :ssh_password           => ssh_password,
              :ssh_timeout            => ssh_timeout,
              :shutdown_command       => shutdown_command,
              :shutdown_timeout       => shutdown_timeout,
              :ssh_pty                => ssh_pty,
              :iso_checksum           => install_checksum,
              :http_directory         => http_dir,
              :http_port_min          => http_port_min,
              :http_port_max          => http_port_max,
              :http_bind_address      => ks_ip,
              :boot_wait              => boot_wait,
              :boot_command           => boot_command,
              :parallels_tools_flavor => parallels_tools_flavor,
              "prlctl": [
                ["set", "{{.Name}}", "--3d-accelerate", "off"],
                ["set", "{{.Name}}", "--adaptive-hypervisor", "on"]
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                   => vm_name,
              :vm_name                => vm_name,
              :type                   => vm_type,
              :output_directory       => image_dir,
              :disk_size              => disk_size,
              :memory                 => memsize, 
              :cpus                   => numvcpus, 
              :iso_url                => iso_url,
              :ssh_host               => ssh_host,
              :ssh_port               => ssh_port,
              :ssh_username           => ssh_username,
              :ssh_password           => ssh_password,
              :ssh_timeout            => ssh_timeout,
              :shutdown_command       => shutdown_command,
              :shutdown_timeout       => shutdown_timeout,
              :ssh_pty                => ssh_pty,
              :iso_checksum           => install_checksum,
              :http_directory         => http_dir,
              :http_port_min          => http_port_min,
              :http_port_max          => http_port_max,
              :boot_wait              => boot_wait,
              :boot_command           => boot_command,
              :parallels_tools_flavor => parallels_tools_flavor,
              "prlctl": [
                ["set", "{{.Name}}", "--3d-accelerate", "off"],
                ["set", "{{.Name}}", "--adaptive-hypervisor", "on"]
              ]
            ]
          }
        end
      end
    when /qemu|kvm|xen/
      if values['vmnetwork'].to_s.match(/hostonly|bridged/)
        if values['headless'] == true || values['console'].to_s.match(/text/)
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_host             => ssh_host,
              :ssh_port             => ssh_port,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :http_bind_address    => ks_ip,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize ],
                [ "-smp", "cpus="+numvcpus ]
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_host             => ssh_host,
              :ssh_port             => ssh_port,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :http_bind_address    => ks_ip,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize ],
                [ "-smp", "cpus="+numvcpus ]
              ]
            ]
          }
        end
      else
        if values['headless'] == true
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize+"M" ],
                [ "-smp", "cpus="+numvcpus ]
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => values['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => vm_name,
              :vm_name              => vm_name,
              :type                 => vm_type,
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => disk_size,
              :iso_url              => iso_url,
              :ssh_port             => ssh_port,
              :ssh_host_port_min    => ssh_host_port_min,
              :ssh_host_port_max    => ssh_host_port_max,
              :ssh_username         => ssh_username,
              :ssh_password         => ssh_password,
              :ssh_timeout          => ssh_timeout,
              :shutdown_command     => shutdown_command,
              :shutdown_timeout     => shutdown_timeout,
              :ssh_pty              => ssh_pty,
              :iso_checksum         => install_checksum,
              :http_directory       => http_dir,
              :http_port_min        => http_port_min,
              :http_port_max        => http_port_max,
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => disk_format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-cpu", "host" ],
                [ "-m", memsize+"M" ],
                [ "-smp", "cpus="+numvcpus ]
              ]
            ]
          }
        end
      end
    end
  end
  json_output = JSON.pretty_generate(json_data)
  json_dir = File.dirname(json_file)
  if not Dir.exist?(json_dir)
    FileUtils.mkdir_p(json_dir)
  end
  delete_file(values,json_file)
  File.write(json_file,json_output)
  print_contents_of_file(values,"",json_file)
  return values
end

# Create Packer JSON file for AWS

def create_packer_aws_json(values)
  values['service'] = values['answers']['type'].value
  values['access']  = values['answers']['access_key'].value
  values['secret']  = values['answers']['secret_key'].value
  values['ami']     = values['answers']['source_ami'].value
  values['region']  = values['answers']['region'].value
  values['size']    = values['answers']['instance_type'].value
  values['keyfile'] = File.basename(values['answers']['keyfile'].value,".pem")+".key.pub"
  values['name']    = values['answers']['ami_name'].value
  values['adminuser'] = values['answers']['ssh_username'].value
  values['clientdir'] = packer_dir+"/aws/"+values['name']
  tmp_keyfile    = "/tmp/"+values['keyfile']
  user_data_file = values['answers']['user_data_file'].value
  packer_dir     = values['clientdir']+"/packer"
  json_file      = values['clientdir']+"/"+values['name']+".json"
  check_dir_exists(values,values['clientdir'])
  json_data = {
    :builders => [
      {
        :name             => "aws",
        :type             => values['service'],
        :access_key       => values['access'],
        :secret_key       => values['secret'],
        :source_ami       => values['ami'],
        :region           => values['region'],
        :instance_type    => values['size'],
        :ssh_username     => values['adminuser'],
        :ami_name         => values['name'],
        :user_data_file   => user_data_file
      }
    ],
    :provisioners => [
      {
        :type             => "file",
        :source           => values['keyfile'],
        :destination      => tmp_keyfile
      },
      {
        :type             => "shell",
        :execute_command  => "{{ .Vars }} sudo -E -S sh '{{ .Path }}'",
        :scripts          => [
          "scripts/vagrant.sh"
        ]
      }
    ],
    :"post-processors"    => [
      {
        :output           => "builds/packer_{{.BuildName}}_{{.Provider}}.box",
        :type             => "vagrant"
      }
    ]
  }
  json_output = JSON.pretty_generate(json_data)
  delete_file(json_file)
  File.write(json_file, json_output)
  set_file_perms(json_file, "600")
  print_contents_of_file(values, "", json_file)
  return values
end
