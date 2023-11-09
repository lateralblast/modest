
# Packer JSON code

# Configure Packer JSON file

def create_packer_json(options)
  net_config        = ""
  nic_command1      = ""
  nic_command2      = ""
  nic_command3      = ""
  nic_config1       = ""
  nic_config2       = ""
  nic_config3       = ""
  communicator      = options['communicator'].to_s
  controller        = options['controller'].to_s
  hw_version        = options['hwversion'].to_s
  winrm_use_ssl     = options['winrmusessl'].to_s
  winrm_insecure    = options['winrminsecure'].to_s
  virtual_dev       = options['virtualdevice'].to_s
  ethernet_dev      = options['ethernetdevice'].to_s
  vnc_enabled       = options['enablevnc'].to_s
  vhv_enabled       = options['enablevhv'].to_s
  ethernet_enabled  = options['enableethernet'].to_s
  boot_wait         = options['bootwait'].to_s
  shutdown_timeout  = options['shutdowntimeout'].to_s
  ssh_port          = options['sshport'].to_s
  ssh_host          = options['ip'].to_s
  winrm_host        = options['ip'].to_s
  ssh_timeout       = options['sshtimeout'].to_s
  hwvirtex          = options['hwvirtex'].to_s
  vtxvpid           = options['vtxvpid'].to_s
  vtxux             = options['vtxux'].to_s
  rtcuseutc         = options['rtcuseutc'].to_s
  audio             = options['audio'].to_s
  mouse             = options['mouse'].to_s
  ssh_pty           = options['sshpty'].to_s
  winrm_port        = options['winrmport'].to_s
  disk_format       = options['format'].to_s
  accelerator       = options['accelerator'].to_s
  disk_interface    = options['diskinterface'].to_s
  net_device        = options['netdevice'].to_s
  guest_os_type     = options['guest'].to_s
  disk_size         = options['size'].to_s.gsub(/G/, "000")
  natpf_ssh_rule    = ""
  ssh_host_port_min = options['sshportmin'].to_s
  ssh_host_port_max = options['sshportmax'].to_s
  admin_home        = options['adminhome'].to_s
  admin_group       = options['admingroup'].to_s
  iso_url           = "file://"+options['file'].to_s
  packer_dir        = options['clientdir'].to_s+"/packer"
  image_dir         = options['clientdir'].to_s+"/images"
  http_dir          = packer_dir
  http_port_max     = options['httpportmax'].to_s
  http_port_min     = options['httpportmin'].to_s
  vm_name           = options['name'].to_s
  vm_type           = options['vmtype'].to_s
  memsize           = options['memory'].to_s
  numvcpus          = options['vcpus'].to_s
  mac_address       = options['mac'].to_s
  usb               = options['usb'].to_s
  usb_xhci_present   = options['usbxhci'].to_s
  disk_adapter_type = options['diskinterface'].to_s
  if options['vm'].to_s.match(/fusion/)
    if hw_version.to_i >= 20
      disk_adapter_type = "nvme"
    end
  end
  if options['q_struct']['admin_password']
    install_password  = options['q_struct']['admin_password'].value
  else
    install_password  = options['q_struct']['root_password'].value
  end
  if options['vm'].to_s.match(/parallels/)
    case options['service'].to_s
    when /win/
      parallels_tools_flavor = "win"
    when /ubuntu|rhel|sles/
      parallels_tools_flavor = "lin"
    when /mac|osx/
      parallels_tools_flavor = "mac"
    else
      parallels_tools_flavor = "other"
    end
  end
  if options['livecd'] == true
    http_dir = packer_dir+"/"+options['vm']+"/"+options['name']+"/subiquity/http"
  end
  if options['dhcp'] == true 
    if options['vm'].to_s.match(/fusion/)
      if options['service'].to_s.match(/vmware|vsphere|esx/)
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
  json_file = packer_dir+"/"+options['vm']+"/"+options['name']+"/"+options['name']+".json"
  check_dir_exists(options, options['clientdir'])
  if !options['service'].to_s.match(/purity/)
    headless_mode = options['q_struct']['headless_mode'].value
  end
  if options['method'].to_s.match(/vs/)
    admin_crypt = options['q_struct']['root_crypt'].value
  else
    if not options['service'].to_s.match(/win|sol_[9,10]/)
      admin_crypt = options['q_struct']['admin_crypt'].value
    end
  end
  if options['q_struct']['guest_additions_mode']
    guest_additions_mode = options['q_struct']['guest_additions_mode'].value
  else
    guest_additions_mode = options['vmtools']
  end
  if options['vmnetwork'].to_s.match(/hostonly/)
    if options['httpbindaddress'] != options['empty']
      if options['vn'].to_s.match(/fusion/)
        ks_ip = options['vmgateway']
      else
        ks_ip = options['httpbindaddress']
      end
    else
      if options['host-os-name'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10 
        if options['vm'].to_s.match(/fusion/)
          ks_ip = options['vmgateway']
        else
          ks_ip = options['hostip']
        end
      else
        ks_ip = options['vmgateway']
      end
    end
    natpf_ssh_rule = "packerssh,tcp,"+options['ip']+",2222,"+options['ip']+",22"
  else
    if options['httpbindaddress'] != options['empty']
      ks_ip = options['httpbindaddress']
    else
      if options['vm'].to_s.match(/fusion/) and options['dhcp'] == true
        ks_ip = options['vmgateway']
      else
        ks_ip = options['hostip']
      end
    end
    natpf_ssh_rule = ""
  end
  if options['ip'].to_s.match(/[0-9]/)
    port_no = options['ip'].split(/\./)[-1]
    if port_no.to_i < 100
      port_no = "0"+port_no
    end
    vnc_port_min = "6"+port_no
    vnc_port_max = "6"+port_no
  else
    vnc_port_min = "5900"
    vnc_port_max = "5980"
  end
  case options['vm'].to_s
  when /vbox/
    output_format = "ova"
    if options['service'].to_s.match(/win/)
      ssh_host_port_min = "5985"
      ssh_host_port_max = "5985"
      winrm_port        = "5985"
    end
  when /fusion/
    hw_version = get_fusion_version(options)
  when /kvm|xen|qemu/
    vm_type = "qemu"
    disk_format = "qcow2"
    if options['vm'].to_s.match(/kvm/)
      accelerator    = "kvm"
      disk_interface = "virtio"
      net_device     = "virtio-net"
      nic_device     = "virtio"
      net_bridge     = options['bridge'].to_s
    end
  end
  tools_upload_flavor = ""
  tools_upload_path   = ""
  if options['vmnetwork'].to_s.match(/hostonly/) and options['vm'].to_s.match(/vbox/)
    if_name  = get_bridged_vbox_nic(options)
    nic_name = check_vbox_hostonly_network(options)
    nic_command1 = "--nic1"
    nic_config1  = "hostonly"
    nic_command2 = "--nictype1"
    if options['service'].to_s.match(/vmware|esx|vsphere/)
      nic_config2  = "virtio"
    else
      nic_config2  = "82545EM"
    end
    nic_command3 = "--hostonlyadapter1"
    nic_config3  = "#{nic_name}"
    if options['httpbindaddress'] != options['empty']
      ks_ip = options['httpbindaddress']
    else
      ks_ip = options['vmgateway']
    end
  end
  if options['vmnetwork'].to_s.match(/bridged/) and options['vm'].to_s.match(/vbox/)
    nic_name = get_bridged_vbox_nic()
    nic_command1 = "--nic1"
    nic_config1  = "bridged"
    nic_command2 = "--nictype1"
    if options['service'].to_s.match(/vmware|esx|vsphere/)
      nic_config2 = "virtio"
    else
      nic_config2 = "82545EM"
    end
    nic_command3 = "--bridgeadapter1"
    nic_config3  = "#{nic_name}"
  end
  if options['service'].to_s.match(/el_8|centos_8/)
    virtual_dev = "pvscsi"
  end
  if options['service'].to_s.match(/sol_10/)
    ssh_username   = options['adminuser']
    ssh_password   = options['adminpassword']
    admin_username = options['adminuser']
    admin_password = options['adminpassword']
  else
    if options['method'].to_s.match(/vs/)
      ssh_username = "root"
      ssh_password = options['q_struct']['root_password'].value
    else
      ssh_username   = options['q_struct']['admin_username'].value
      ssh_password   = options['q_struct']['admin_password'].value
      admin_username = options['q_struct']['admin_username'].value
      admin_password = options['q_struct']['admin_password'].value
    end
  end
  if not options['service'].to_s.match(/win|purity/)
    root_password = options['q_struct']['root_password'].value
  end
  shutdown_command = ""
  if not mac_address.to_s.match(/[0-9]/)
    mac_address = generate_mac_address(options['vm'])
  end
  if options['guest'].class == Array
    options['guest'] = options['guest'].join
  end
  if options['service'].to_s.match(/sol/)
    if options['copykeys'] == true && File.exist?(options['sshkeyfile'].to_s)
      ssh_key = %x[cat #{options['sshkeyfile'].to_s}].chomp
      ssh_dir = "/export/home/#{options['q_struct']['admin_username'].value}/.ssh"
      ssh_com = "<wait>mkdir -p #{ssh_dir}<enter>"+
                "<wait>chmod 700 #{ssh_dir}<enter>"+
                "<wait>echo '#{ssh_key}' > #{ssh_dir}/authorized_keys<enter>"+
                "<wait>chmod 600 #{ssh_dir}/authorized_keys<enter>"
    else
      ssh_com = ""
    end
  end
  options['size'] = options['size'].gsub(/G/, "000")
  case options['service'].to_s
  when /win/
    if options['vmtools'] == true
      if not options['label'].to_s.match(/2016|2019/)
        tools_upload_flavor = "windows"
        tools_upload_path   = "C:\\Windows\\Temp\\windows.iso"
      end
    end
    shutdown_command = "shutdown /s /t 1 /c \"Packer Shutdown\" /f /d p:4:1"
    unattended_xml   = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/Autounattend.xml"
    post_install_psh = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/post_install.ps1"
    if options['label'].to_s.match(/20[0,1][0-8]/)
      if options['vm'].to_s.match(/fusion/)
        options['guest'] = "windows8srv-64"
        virtual_dev = "lsisas1068"
        hw_version  = "12"
      end
      if memsize.to_i < 2000
        memsize = "2048"
      end
    else
      if options['vm'].to_s.match(/fusion/)
        if options['label'].to_s.match(/20[1,2][0-9]/)
          options['guest'] = "windows9srv-64"
          virtual_dev = "lsisas1068"
        else
          options['guest'] = "windows7srv-64"
        end
      end
    end
  when /sol_11_[2-3]/
    if options['host-os-cpu'].to_i > 6 and options['host-os-memory'].to_i > 16
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
    #tools_upload_path   = "/export/home/"+options['q_struct']['admin_username'].value
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
                   "<wait><wait><bs><bs><bs><bs><bs><bs><bs>"+options['name']+"<wait>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><tab><f2><wait>"+
                   options['ip']+"<wait><tab><wait><tab>"+
                   options['vmgateway']+"<wait><f2><wait>"+
                   "<wait><f2><wait>"+
                   options['nameserver']+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   options['q_struct']['root_password'].value+"<wait><tab><wait>"+
                   options['q_struct']['root_password'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_username'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_username'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_password'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_password'].value+"<wait><f2><wait>"+
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
                   options['q_struct']['admin_username'].value+"<enter><wait>"+
                   options['q_struct']['admin_password'].value+"<enter><wait>"+
                   ssh_com+
                   "echo '"+options['q_struct']['admin_password'].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+options['q_struct']['admin_username'].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail-client\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "sudo sh -c \"echo 'LookupClientHostnames no' >> /etc/ssh/sshd_config\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_11_4/
    if options['host-os-cpu'].to_i > 6 and options['host-os-memory'].to_i > 16
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
    #tools_upload_path   = "/export/home/"+options['q_struct']['admin_username'].value
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
                   "<wait><wait><bs><bs><bs><bs><bs><bs><bs>"+options['name']+"<wait>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><f2><wait10>"+
                   "<wait><wait><tab><f2><wait>"+
                   options['ip']+"<wait><tab><wait><tab>"+
                   "<wait><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+options['vmgateway']+"<wait><f2><wait>"+
                   "<wait><f2><wait>"+
                   options['nameserver']+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   options['q_struct']['root_password'].value+"<wait><tab><wait>"+
                   options['q_struct']['root_password'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_username'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_username'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_password'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_password'].value+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   wait_time1+
                   wait_time1+
                   wait_time1+
                   "<wait><f8><wait10><wait10>"+
                   "<enter><wait10>"+
                   wait_time1+
                   options['q_struct']['admin_username'].value+"<enter><wait>"+
                   options['q_struct']['admin_password'].value+"<enter><wait>"+
                   ssh_com+
                   "echo '"+options['q_struct']['admin_password'].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+options['q_struct']['admin_username'].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm stop sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm stop asr-notify\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_11_[0,1]/
    if options['host-os-cpu'].to_i > 6 and options['host-os-memory'].to_i > 16
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
    #tools_upload_path   = "/export/home/"+options['q_struct']['admin_username'].value
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
                   "<bs><bs><bs><bs><bs><bs><bs>"+options['name']+"<wait>"+
                   "<tab><tab><f2><wait10>"+
                   options['ip']+"<wait><tab><wait><tab>"+
                   options['vmgateway']+"<wait><f2><wait>"+
                   "<f2><wait>"+
                   options['nameserver']+"<wait><f2><wait>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   options['q_struct']['root_password'].value+"<wait><tab><wait>"+
                   options['q_struct']['root_password'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_username'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_username'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_password'].value+"<wait><tab><wait>"+
                   options['q_struct']['admin_password'].value+"<wait><f2><wait>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   wait1+
                   wait1+
                   "<wait10><wait10><wait10><wait10>"+
                   "<f8><wait10><wait10>"+
                   "<enter><wait10>"+
                   wait1+
                   options['q_struct']['admin_username'].value+"<enter><wait>"+
                   options['q_struct']['admin_password'].value+"<enter><wait>"+
                   ssh_com+
                   "echo '"+options['q_struct']['admin_password'].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+options['q_struct']['admin_username'].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_10/
#    tools_upload_flavor = "solaris"
#    tools_upload_path   = "/export/home/"+options['q_struct']['admin_username'].value
    shutdown_command    = "echo '/usr/sbin/poweroff' > shutdown.sh; pfexec bash -l shutdown.sh"
    shutdown_timeout    = "20m"
    sysidcfg    = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/sysidcfg"
    rules       = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/rules"
    rules_ok    = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/rules.ok"
    profile     = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/profile"
    finish      = options['clientdir']+"/packer/"+options['vm']+"/"+options['name']+"/finish"
    boot_command = "e<wait>"+
                   "e<wait>"+
                   "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><wait>"+
                   "- nowin install -B install_media=cdrom<enter><wait>"+
                   "b<wait>"
  when /sles/
    ssh_port              = "22"
    ssh_host_port_max     = "22"
    ssh_host_port_min     = "22"
    ks_file               = options['vm']+"/"+options['name']+"/"+options['name']+".xml"
    ks_url                = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
    install_nic           = options['q_struct']['nic'].value
    options['netmask']    = options['q_struct']['netmask'].value
    options['vmgateway']  = options['q_struct']['gateway'].value
    options['nameserver'] = options['q_struct']['nameserver'].value
    install_domain        = options['domainname']
    net_config            = install_nic+"="+options['ip']+"/24,"+options['vmgateway']+","+options['nameserver']+","+install_domain
    if options['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        boot_command = "<esc><enter><wait> linux<wait>"+
                       " netdevice="+options['q_struct']['nic'].value+
                       " ifcfg=\"{{ user `net_config`}}\""+
                       " autoyast="+ ks_url+
                       " lang="+options['language']+
                       " insecure=1 install=cd:/ textmode=1"+
                       "<enter><wait>"
      else
        boot_command = "<esc><enter><wait> linux text install=cd:/ textmode=1 insecure=1"+
                       " netdevice="+install_nic+
                       " netsetup=dhcp"+
                       " autoyast="+ ks_url+
                       " lang="+options['language']+
                       " insecure=1 install=cd:/ textmode=1"+
                       "<enter><wait>"
      end
    else
      ks_file      = options['vm']+"/"+options['name']+"/"+options['name']+".xml"
      ks_url       = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
      boot_command = "<esc><enter><wait> linux text install=cd:/ textmode=1 insecure=1"+
                     " netdevice="+options['q_struct']['nic'].value+
                     " autoyast="+ ks_url+
                     " language="+options['language']+
                     " netsetup=-dhcp,+hostip,+netmask,+gateway,+nameserver1,+domain"+
                     " hostip="+options['ip']+"/24"+
                     " netmask="+options['netmask']+
                     " gateway="+options['vmgateway']+
                     " nameserver="+options['nameserver']+
                     " domain="+install_domain+
                     "<enter><wait>"
    end
  when /purity/
    install_netmask    = options['q_struct']['netmask'].value
    install_vmgateway  = options['q_struct']['gateway'].value
    install_nameserver = options['q_struct']['nameserver'].value
    install_broadcast  = options['q_struct']['broadcast'].value
    install_timezone   = options['q_struct']['timezone'].value
    install_netaddr    = options['q_struct']['network_address'].value
    install_nic        = options['q_struct']['nic'].value
    if install_nic.match(/^ct/)
      purity_nic  = options['q_struct']['nic'].value
      install_nic = options['q_struct']['nic'].value.split(".")[0]
    else
      purity_nic  = "ct0."+install_nic
    end
    if options['host-os-cpu'].to_i > 6 and options['host-os-memory'].to_i > 16
      wait_time1 = "<wait360>"
      wait_time2 = "<wait210>"
    else
      wait_time1 = "<wait500>"
      wait_time2 = "<wait210>"
    end
    install_domain    = options['domainname']
    ssh_host_port_min = "2222"
    ssh_host_port_max = "2222"
    net_config        = "/etc/network/interfaces"
    script_url        = "http://"+options['vmgateway']+":8888/"+options['vm']+"/"+options['name']+"/setup.sh"
    script_file       = packer_dir+"/"+options['vm']+"/"+options['name']+"/setup.sh"
    if !File.exist?(options['setup'])
      handle_output(options, "Warning:\tSetup script '#{options['setup']}' not found")
      quit(options)
    else
      message = "Information:\tCopying '#{options['setup']}' to '#{script_file}'"
      command = "cp '#{options['setup']}' '#{script_file}'"
      execute_command(options, message, command)
      user = %x[cat '#{script_file}' |grep Username |awk '{print $3}'].chomp
      pass = %x[cat '#{script_file}' |grep Password |awk '{print $3}'].chomp
    end
    other_ips = ""
    other_net = ""
    if options['ip'].to_s.match(/,/)
      options['ip'] = options['ip'].split(/,/)[0]
    end
    if options['q_struct']['eth1_ip']
      if options['q_struct']['eth1_ip'].value.match(/[0-9]/)
        options['ip'] = options['q_struct']['eth1_ip'].value
        c_service = options['q_struct']['eth1_service'].value
        interface = "ct0.eth1"
        ethernet  = "eth1"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+options['ip']+" --netmask "+install_netmask+" --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{options['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{install_vmgateway}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{install_netmask}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    if options['q_struct']['eth2_ip']
      if options['q_struct']['eth2_ip'].value.match(/[0-9]/)
        options['ip'] = options['q_struct']['eth2_ip'].value
        c_service = options['q_struct']['eth2_service'].value
        interface = "ct0.eth2"
        ethernet  = "eth2"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+options['ip']+" --netmask 255.255.255.0 --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{options['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{options['vmgateway']}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{options['netmask']}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    if options['q_struct']['eth3_ip']
      if options['q_struct']['eth3_ip'].value.match(/[0-9]/)
        options['ip'] = options['q_struct']['eth3_ip'].value
        c_service = options['q_struct']['eth3_service'].value
        interface = "ct0.eth3"
        ethernet  = "eth3"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+options['ip']+" --netmask 255.255.255.0 --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{options['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{options['vmgateway']}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{options['netmask']}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    if options['q_struct']['eth4_ip']
      if options['q_struct']['eth4_ip'].value.match(/[0-9]/)
        options['ip'] = options['q_struct']['eth4_ip'].value
        c_service = options['q_struct']['eth4_service'].value
        interface = "ct0.eth4"
        ethernet  = "eth4"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+options['ip']+" --netmask 255.255.255.0 --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{options['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{options['vmgateway']}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{options['netmask']}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    if options['q_struct']['eth5_ip']
      if options['q_struct']['eth5_ip'].value.match(/[0-9]/)
        options['ip'] = options['q_struct']['eth5_ip'].value
        c_service = options['q_struct']['eth5_service'].value
        interface = "ct0.eth5"
        ethernet  = "eth5"
        other_ips = other_ips+"<wait3>purenetwork setattr "+interface+" --address "+options['ip']+" --netmask 255.255.255.0 --service "+c_service+"<enter>"+
        "<wait3>purenetwork enable "+interface+"<enter>"
        other_net = other_net+"<wait3>echo 'auto #{ethernet}' >> #{net_config}<enter>"+
        "<wait3>echo 'iface #{ethernet} inet static' >> #{net_config}<enter>"+
        "<wait3>echo 'address #{options['ip']}' >> #{net_config}<enter>"+
        "<wait3>echo 'gateway #{options['vmgateway']}' >> #{net_config}<enter>"+
        "<wait3>echo 'netmask #{options['netmask']}' >> #{net_config}<enter>"+
        "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
        "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"
      end
    end
    boot_command = wait_time1+user+"<enter><wait><enter>"+pass+"<enter>"+
                   "<wait2>ifconfig eth0 inet "+options['ip']+" up<enter>"+
                   "<wait3>wget -O /root/setup.sh "+script_url+"<enter>"+
                   "<wait3>chmod +x /root/setup.sh ; cd /root ; ./setup.sh<enter>"+wait_time2+"<enter><enter>"+
                   "<wait9>purenetwork setattr "+purity_nic+" --address "+options['ip']+" --gateway "+options['vmgateway']+" --netmask "+options['netmask']+"<enter>"+
                   "<wait9>purenetwork enable "+purity_nic+"<enter>"+
                   "<wait9>puredns setattr --nameservers "+options['nameserver']+"<enter>"+
                   "<wait9>puredns setattr --domain "+install_domain+"<enter><wait3>purearray rename "+options['name']+"<enter>"+
                   other_ips+
                   "<wait9>chmod 4755 /bin/su ; usermod --expiredate 1 pureeng<enter>"+ 
                   "<wait3>groupadd "+ssh_username+" ; groupadd "+admin_group+"<enter>"+
                   "<wait3>echo '"+ssh_username+" ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/"+ssh_username+"<enter>"+
                   "<wait3>useradd -p '"+admin_crypt+"' -g "+ssh_username+" -G "+admin_group+" -d "+admin_home+" -s /bin/bash -m "+ssh_username+"<enter>"+
                   "<wait3>echo 'UseDNS No' >> /etc/ssh/sshd_config<enter>"+
                   "<wait3>echo 'Port 2222' >> /etc/ssh/sshd_config ; service ssh restart<enter>"+
                   "<wait3>echo '# The primary network interface' >> #{net_config}<enter>"+
                   "<wait3>echo 'auto #{install_nic}' >> #{net_config}<enter>"+
                   "<wait3>echo 'iface #{install_nic} inet static' >> #{net_config}<enter>"+
                   "<wait3>echo 'address #{options['ip']}' >> #{net_config}<enter>"+
                   "<wait3>echo 'gateway #{options['vmgateway']}' >> #{net_config}<enter>"+
                   "<wait3>echo 'netmask #{options['netmask']}' >> #{net_config}<enter>"+
                   "<wait3>echo 'network #{install_netaddr}' >> #{net_config}<enter>"+
                   "<wait3>echo 'broadcast #{install_broadcast}' >> #{net_config}<enter>"+
                   other_net+
                   "<wait3>echo '#{options['timezone']}' > /etc/timezone<enter>"+
                   "<wait3>service firewall stop<enter>"
  when /debian|ubuntu/
    tools_upload_flavor = ""
    tools_upload_path   = ""
    if options['httpbindaddress'] != options['empty']
      ks_ip = options['httpbindaddress']
    else
      if !options['host-os-name'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10 
        if options['vmnetwork'].to_s.match(/nat/)
          if options['dhcp'] == true
            ks_ip = options['hostonlyip'].to_s
          else
            ks_ip = options['hostip'].to_s
          end
        else
          ks_ip = options['hostonlyip'].to_s
        end
      else
        if options['host-os-name'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10 
          if options['vmnetwork'].to_s.match(/hostonly/)
            ks_ip = options['vmgateway'].to_s
          else
            ks_ip = options['hostip'].to_s
          end
        else
          ks_ip = options['hostip'].to_s
        end
      end
    end
    ks_file = options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
    if options['livecd'] == true 
      boot_wait    = "3s"
      if options['release'].to_i >= 20
#        boot_header = "<wait>e<wait><down><wait><down><wait><down><wait><leftCtrlOn>e<leftCtrlOff>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
#                      "<bs><bs><bs><bs><bs>linux /casper/vmlinuz --- "
        boot_header = "<wait>e<wait><down><wait><down><wait><down><wait><leftCtrlOn>e<leftCtrlOff>"+
                      "<bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                      "--- "
        boot_footer = "<wait><f10><wait><enter>"
#        boot_footer  = ""
      else
        boot_header  = "<enter><enter><f6><esc><wait><bs><bs><bs><bs>"
        boot_footer  = ""
      end
      if options['biosdevnames'] == true
        boot_header = boot_header+"net.ifnames=0 biosdevname=0 "
      end
      if options['release'].to_i >= 20
        boot_command = boot_header+
                      "autoinstall ds='nocloud-net;s=http://"+ks_ip+":#{options['httpport']}/' "+
                      boot_footer
      else
        boot_command = boot_header+
                      "--- autoinstall ds=nocloud-net;seedfrom=http://"+ks_ip+":#{options['httpport']}/"+
                       "<enter><wait>"+
                       boot_footer
      end
    else
      if options['vm'].to_s.match(/parallels/)
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
      if options['biosdevnames'] == true
        kernel_string = "net.ifnames=0 biosdevname=0 "
      else
        kernel_string = ""
      end
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        ks_url = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
        boot_command = boot_header+
                       "<wait>/install/vmlinuz<wait> debian-installer/language="+options['q_struct']['language'].value+
                       " debian-installer/country="+options['q_struct']['country'].value+
                       " keyboard-configuration/layoutcode="+options['q_struct']['layout'].value+
                       " <wait>interface="+options['q_struct']['nic'].value+
                       " netcfg/disable_autoconfig="+options['q_struct']['disable_autoconfig'].value+
                       " netcfg/disable_dhcp="+options['q_struct']['disable_dhcp'].value+
                       " hostname="+options['name']+
                       " <wait>netcfg/get_ipaddress="+options['ip']+
                       " netcfg/get_netmask="+options['q_struct']['netmask'].value+
                       " netcfg/get_gateway="+options['q_struct']['gateway'].value+
                       " netcfg/get_nameservers="+options['q_struct']['nameserver'].value+
                       " netcfg/get_domain="+options['q_struct']['domain'].value+
                       " <wait>preseed/url="+ks_url+
                       " initrd=/install/initrd.gz "+kernel_string+"-- "+
                       boot_footer
      else
        ks_url = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
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
    if options['vm'].to_s.match(/fusion/)
      virtual_dev = "pvscsi"
    end
    hwvirtex = "on"
    ks_file  = options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
    ks_url   = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
    if options['vm'].to_s.match(/fusion/)
      boot_command = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=vmnic0 netdevice=vmnic0 ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<wait><enter><wait>"
    else
      if options['vm'].to_s.match(/kvm/)
        net_device     = "vmxnet3"
        disk_interface = "ide"
        boot_command   = "<enter><wait>O<wait> ks="+ks_url+" ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<wait><enter><wait>"
      else
        boot_command = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=vmnic0 netdevice=vmnic0 ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<wait><enter><wait>"
      end
    end
    ssh_username      = "root"
    shutdown_command  = ""
    ssh_host_port_min = "22"
    ssh_host_port_max = "22"
  when /fedora|el_8|centos_8/
    tools_upload_flavor = ""
    tools_upload_path   = ""
    ks_file      = options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
    ks_url       = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
    if options['biosdevnames'] == true
      kernel_string = "net.ifnames=0 biosdevname=0 "
    else
      kernel_string = ""
    end
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      boot_command = "<tab><wait><bs><bs><bs><bs><bs><bs>=0 "+kernel_string+"inst.text inst.method=cdrom inst.repo=cdrom:/dev/sr0 inst.ks="+ks_url+" ip="+options['ip']+"::"+options['vmgateway']+":"+options['netmask']+":"+options['name']+":eth0:off<enter><wait>"
    else
      boot_command = "<tab><wait><bs><bs><bs><bs><bs><bs>=0 "+kernel_string+"inst.text inst.method=cdrom inst.repo=cdrom:/dev/sr0 inst.ks="+ks_url+" ip=dhcp<enter><wait>"
    end
#  when /rhel_7/
#    ks_file       = options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
#    ks_url        = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
#    boot_command  = "<esc><wait> linux text install ks="+ks_url+" ksdevice=eno16777736 "+"ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<enter><wait>"
  else
    if options['biosdevnames'] == true
      kernel_string = "net.ifnames=0 biosdevname=0 "
    else
      kernel_string = ""
    end
    ks_file = options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
    ks_url  = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      boot_command  = "<esc><wait> linux "+kernel_string+"text install ks="+ks_url+" ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<enter><wait>"
    else
      boot_command  = "<esc><wait> linux "+kernel_string+"text install ks="+ks_url+"<enter><wait>"
    end
    if options['guest'].class == Array
  	  options['guest'] = options['guest'].join
    end
    #shutdown_command = "echo '#{options['q_struct']['admin_password'].value}' |sudo -S /sbin/halt -h -p"
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      shutdown_command = "sudo /usr/sbin/shutdown -P now"
    end
  end
	controller = controller.gsub(/sas/, "scsi")
	case options['vm']
	when /vbox|virtualbox/
		vm_type = "virtualbox-iso"
    mac_address = mac_address.gsub(/:/, "")
	when /fusion|vmware/
		vm_type = "vmware-iso"
  when /parallels/
    vm_type = "parallels-iso"
	end
	if options['checksum'] == true
		md5_file = options['file']+".md5"
		if File.exist?(md5_file)
			install_md5 = File.readlines(md5_file)[0]
		else
			install_md5 = %x[md5 "#{options['file']}" |awk '{print $4}'].chomp
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
  if options['vm'].to_s.match(/kvm/)
    if options['console'].to_s.match(/text/)
      headless_mode = "true"
    end
  end
  bridge_nic = get_vm_if_name(options)
  if options['service'].to_s.match(/windows/) and options['vm'].to_s.match(/vbox/) and options['vmnetwork'].to_s.match(/hostonly|bridged/)
    handle_output(options, "Warning:\tPacker with Windows and VirtualBox only works on a NAT network (Packer issue)")
    handle_output(options, "Information:\tUse the --network=nat option")
    quit(options)
  end
  if !options['guest'] || options['guest'] = options['empty']
    if options['vm'].to_s.match(/vbox/)
     options['guest'] = get_vbox_guest_os(options)
    end
    if options['vm'].to_s.match(/fusion/)
     options['guest'] = get_fusion_guest_os(options)
    end
  end
  case options['service']
  when /vmware|vsphere|esxi/
    case options['vm']
    when /vbox/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
        	:variables => {
        		:hostname => options['name'],
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
            :hostname => options['name'],
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
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => options['name'],
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
              :"ethernet0.connectionType"         => options['vmnetwork'],
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
            :hostname => options['name'],
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
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    when /qemu|kvm|xen/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        if options['headless'] == true || options['console'].to_s.match(/text/)
          json_data = {
            :variables => {
              :hostname => options['name'],
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
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => options['name'],
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
        if options['headless'] == true
          json_data = {
            :variables => {
              :hostname => options['name'],
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
              :hostname => options['name'],
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
    case options['vm']
    when /vbox/
      json_data = {
        :variables => {
          :hostname => options['name'],
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
          :hostname => options['name'],
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
            :"ethernet0.connectionType"         => options['vmnetwork'],
            :"ethernet0.virtualDev"             => ethernet_dev,
            :"ethernet0.addressType"            => ethernet_type,
            :"ethernet0.address"                => generate_mac_address(options['vm']),
            :"ethernet1.present"                => ethernet_enabled,
            :"ethernet1.connectionType"         => options['vmnetwork'],
            :"ethernet1.virtualDev"             => ethernet_dev,
            :"ethernet1.addressType"            => ethernet_type,
            :"ethernet1.address"                => generate_mac_address(options['vm']),
            :"ethernet2.present"                => ethernet_enabled,
            :"ethernet2.connectionType"         => options['vmnetwork'],
            :"ethernet2.virtualDev"             => ethernet_dev,
            :"ethernet2.addressType"            => ethernet_type,
            :"ethernet2.address"                => generate_mac_address(options['vm']),
            :"ethernet3.present"                => ethernet_enabled,
            :"ethernet3.connectionType"         => options['vmnetwork'],
            :"ethernet3.virtualDev"             => ethernet_dev,
            :"ethernet3.addressType"            => ethernet_type,
            :"ethernet3.address"                => generate_mac_address(options['vm']),
            :"ethernet4.present"                => ethernet_enabled,
            :"ethernet4.connectionType"         => options['vmnetwork'],
            :"ethernet4.virtualDev"             => ethernet_dev,
            :"ethernet4.addressType"            => ethernet_type,
            :"ethernet4.address"                => generate_mac_address(options['vm']),
            :"ethernet5.present"                => ethernet_enabled,
            :"ethernet5.connectionType"         => options['vmnetwork'],
            :"ethernet5.virtualDev"             => ethernet_dev,
            :"ethernet5.addressType"            => ethernet_type,
            :"ethernet5.address"                => generate_mac_address(options['vm']),
            :"scsi0.virtualDev"                 => virtual_dev
          }
        ]
      }
    end
  when /sol_10/
    case options['vm']
    when /vbox/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => options['name'],
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
            :hostname => options['name'],
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
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        if options['headless'] == true || options['console'].to_s.match(/text/)
          json_data = {
            :variables => {
              :hostname => options['name'],
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
              :hostname => options['name'],
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
        if options['headless'] == true
          json_data = {
            :variables => {
              :hostname => options['name'],
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
              :hostname => options['name'],
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
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => options['name'],
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
              :"ethernet0.connectionType"         => options['vmnetwork'],
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
            :hostname => options['name'],
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
              :"ethernet0.connectionType"         => options['vmnetwork'],
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
    case options['vm']
    when /vbox/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => options['name'],
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
            :hostname => options['name'],
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
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => options['name'],
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
              :"ethernet0.connectionType"         => options['vmnetwork'],
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
            :hostname => options['name'],
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
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address,
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    when /qemu|kvm|xen/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        if options['headless'] == true || options['console'].to_s.match(/text/)
          json_data = {
            :variables => {
              :hostname => options['name'],
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
                unattended_xml,
                post_install_psh
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => options['name'],
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
                unattended_xml,
                post_install_psh
              ]
            ]
          }
        end
      else
        if options['headless'] == true
          json_data = {
            :variables => {
              :hostname => options['name'],
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
                unattended_xml,
                post_install_psh
              ]
            ]
          }
        else
          json_data = {
            :variables => {
              :hostname => options['name'],
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
                unattended_xml,
                post_install_psh
              ]
            ]
          }
        end
      end
    end
  else
    case options['vm']
    when /vbox/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
        	:variables => {
        		:hostname => options['name'],
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
            :hostname => options['name'],
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
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        json_data = {
          :variables => {
            :hostname => options['name'],
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
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => mac_address
            }
          ]
        }
      else
        json_data = {
          :variables => {
            :hostname => options['name'],
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
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.GeneratedAddress"       => mac_address
            }
          ]
        }
      end
    when /parallels/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        if options['headless'] == true
          json_data = {
            :variables => {
              :hostname => options['name'],
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
              :hostname => options['name'],
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
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        if options['headless'] == true || options['console'].to_s.match(/text/)
          json_data = {
            :variables => {
              :hostname => options['name'],
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
              :hostname => options['name'],
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
        if options['headless'] == true
          json_data = {
            :variables => {
              :hostname => options['name'],
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
              :hostname => options['name'],
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
  delete_file(options,json_file)
  File.write(json_file,json_output)
  print_contents_of_file(options,"",json_file)
  return communicator
end

# Create Packer JSON file for AWS

def create_packer_aws_json(options)
  options['service'] = options['q_struct']['type'].value
  options['access']  = options['q_struct']['access_key'].value
  options['secret']  = options['q_struct']['secret_key'].value
  options['ami']     = options['q_struct']['source_ami'].value
  options['region']  = options['q_struct']['region'].value
  options['size']    = options['q_struct']['instance_type'].value
  options['keyfile'] = File.basename(options['q_struct']['keyfile'].value,".pem")+".key.pub"
  options['name']    = options['q_struct']['ami_name'].value
  options['adminuser'] = options['q_struct']['ssh_username'].value
  options['clientdir'] = packer_dir+"/aws/"+options['name']
  tmp_keyfile    = "/tmp/"+options['keyfile']
  user_data_file = options['q_struct']['user_data_file'].value
  packer_dir     = options['clientdir']+"/packer"
  json_file      = options['clientdir']+"/"+options['name']+".json"
  check_dir_exists(options,options['clientdir'])
  json_data = {
    :builders => [
      {
        :name             => "aws",
        :type             => options['service'],
        :access_key       => options['access'],
        :secret_key       => options['secret'],
        :source_ami       => options['ami'],
        :region           => options['region'],
        :instance_type    => options['size'],
        :ssh_username     => options['adminuser'],
        :ami_name         => options['name'],
        :user_data_file   => user_data_file
      }
    ],
    :provisioners => [
      {
        :type             => "file",
        :source           => options['keyfile'],
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
  print_contents_of_file(options, "", json_file)
  return options
end
