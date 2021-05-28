
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
  communicator      = "winrm"
  hw_version        = "12"
  winrm_use_ssl     = "false"
  winrm_insecure    = "true"
  virtual_dev       = "lsilogic"
  ethernet_dev      = "e1000e"
  vnc_enabled       = "true"
  vhv_enabled       = "TRUE"
  ethernet_enabled  = "TRUE"
  boot_wait         = "8s"
  shutdown_timeout  = "1h"
  ssh_port          = options['sshport']
  ssh_timeout       = options['sshtimeout']
  hwvirtex          = "on"
  vtxvpid           = "on"
  vtxux             = "on"
  rtcuseutc         = "on"
  audio             = "none"
  mouse             = "ps2"
  ssh_pty           = "true"
  winrm_port        = "5985"
  format            = ""
  accelerator       = ""
  disk_interface    = ""
  net_device        = ""
  natpf_ssh_rule    = ""
  ssh_host_port_min = "2222"
  ssh_host_port_max = "2222"
  admin_home        = options['adminhome']
  admin_group       = options['admingroup']
  iso_url           = "file://"+options['file']
	packer_dir        = options['clientdir']+"/packer"
  image_dir         = options['clientdir']+"/images"
  install_password  = $q_struct['admin_password'].value
  http_dir          = packer_dir
  if options['livecd'] == true
    http_dir = packer_dir+"/"+options['vm']+"/"+options['name']+"/subiquity/http"
  end
  if options['dhcp'] == true 
    if options['vm'].to_s.match(/fusion/)
      ethernet_type = "vpx"
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
  check_dir_exists(options,options['clientdir'])
  if !options['service'].to_s.match(/purity/)
    headless_mode = $q_struct['headless_mode'].value
  end
  if options['method'].to_s.match(/vs/)
    admin_crypt = $q_struct['root_crypt'].value
  else
    if not options['service'].to_s.match(/win|sol_[9,10]/)
      admin_crypt = $q_struct['admin_crypt'].value
    end
  end
  if $q_struct['guest_additions_mode']
    guest_additions_mode = $q_struct['guest_additions_mode'].value
  else
    guest_additions_mode = options['vmtools']
  end
  if options['vmnetwork'].to_s.match(/hostonly/)
    ks_ip = options['vmgateway']
    natpf_ssh_rule = "packerssh,tcp,"+options['ip']+",2222,"+options['ip']+",22"
  else
    if options['vm'].to_s.match(/fusion/) and options['dhcp'] == true
      ks_ip = options['vmgateway']
    else
      ks_ip = options['hostip']
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
  case options['vm']
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
    options['type'] = "qemu"
    format = "qcow2"
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
    ks_ip        = options['vmgateway']
  end
  if options['vmnetwork'].to_s.match(/bridged/) and options['vm'].to_s.match(/vbox/)
    nic_name = get_bridged_vbox_nic()
    nic_command1 = "--nic1"
    nic_config1  = "bridged"
    nic_command2 = "--nictype1"
    if options['service'].to_s.match(/vmware|esx|vsphere/)
      nic_config2  = "virtio"
    else
      nic_config2  = "82545EM"
    end
    nic_command3 = "--bridgeadapter1"
    nic_config3  = "#{nic_name}"
  end
  options['size']     = options['size'].gsub(/G/,"000")
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
      ssh_username   = "root"
      ssh_password   = $q_struct['root_password'].value
    else
      ssh_username   = $q_struct['admin_username'].value
      ssh_password   = $q_struct['admin_password'].value
      admin_username = $q_struct['admin_username'].value
      admin_password = $q_struct['admin_password'].value
    end
  end
  if not options['service'].to_s.match(/win|purity/)
    root_password = $q_struct['root_password'].value
  end
  shutdown_command = ""
  if not options['mac'].to_s.match(/[0-9]/)
    options['mac'] = generate_mac_address(options['vm'])
  end
  if options['guest'].class == Array
    options['guest'] = options['guest'].join
  end
  if options['service'].to_s.match(/sol/)
    if options['copykeys'] == true && File.exist?(options['sshkeyfile'].to_s)
      ssh_key = %x[cat #{options['sshkeyfile'].to_s}].chomp
      ssh_dir = "/export/home/#{$q_struct['admin_username'].value}/.ssh"
      ssh_com = "<wait>mkdir -p #{ssh_dir}<enter>"+
                "<wait>chmod 700 #{ssh_dir}<enter>"+
                "<wait>echo '#{ssh_key}' > #{ssh_dir}/authorized_keys<enter>"+
                "<wait>chmod 600 #{ssh_dir}/authorized_keys<enter>"
    else
      ssh_com = ""
    end
  end
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
    if options['label'].to_s.match(/20[0-2][0-9]/)
      if options['vm'].to_s.match(/fusion/)
        virtual_dev   = "lsisas1068"
        options['guest'] = "windows8srv-64"
        hw_version    = "12"
      end
      if options['memory'].to_i < 2000
        options['memory'] = "2048"
      end
    else
      if options['vm'].to_s.match(/fusion/)
        options['guest'] = "windows7srv-64"
      end
    end
  when /sol_11_[2-3]/
    if options['oscpu'].to_i > 6 and options['osmem'].to_i > 16
      wait_time1 = "<wait120>"
      wait_time2 = "<wait90>"
    else
      wait_time1 = "<wait160>"
      wait_time2 = "<wait120>"
    end
    if options['memory'].to_i < 2048
      options['memory'] = "2048"
    end
    ssh_port            = "22"
    ssh_host_port_max   = "22"
    ssh_host_port_min   = "22"
    #tools_upload_flavor = "solaris"
    #tools_upload_path   = "/export/home/"+$q_struct['admin_username'].value
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
                   $q_struct['root_password'].value+"<wait><tab><wait>"+
                   $q_struct['root_password'].value+"<wait><tab><wait>"+
                   $q_struct['admin_username'].value+"<wait><tab><wait>"+
                   $q_struct['admin_username'].value+"<wait><tab><wait>"+
                   $q_struct['admin_password'].value+"<wait><tab><wait>"+
                   $q_struct['admin_password'].value+"<wait><f2><wait>"+
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
                   $q_struct['admin_username'].value+"<enter><wait>"+
                   $q_struct['admin_password'].value+"<enter><wait>"+
                   ssh_com+
                   "echo '"+$q_struct['admin_password'].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+$q_struct['admin_username'].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail-client\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "sudo sh -c \"echo 'LookupClientHostnames no' >> /etc/ssh/sshd_config\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_11_4/
    if options['oscpu'].to_i > 6 and options['osmem'].to_i > 16
      wait_time1 = "<wait130>"
      wait_time2 = "<wait100>"
    else
      wait_time1 = "<wait160>"
      wait_time2 = "<wait120>"
    end
    if options['memory'].to_i < 2048
      options['memory'] = "2048"
    end
    ssh_port            = "22"
    ssh_host_port_max   = "22"
    ssh_host_port_min   = "22"
    #tools_upload_flavor = "solaris"
    #tools_upload_path   = "/export/home/"+$q_struct['admin_username'].value
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
                   $q_struct['root_password'].value+"<wait><tab><wait>"+
                   $q_struct['root_password'].value+"<wait><tab><wait>"+
                   $q_struct['admin_username'].value+"<wait><tab><wait>"+
                   $q_struct['admin_username'].value+"<wait><tab><wait>"+
                   $q_struct['admin_password'].value+"<wait><tab><wait>"+
                   $q_struct['admin_password'].value+"<wait><f2><wait>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   "<wait><f2><wait10>"+
                   wait_time1+
                   wait_time1+
                   wait_time1+
                   "<wait><f8><wait10><wait10>"+
                   "<enter><wait10>"+
                   wait_time1+
                   $q_struct['admin_username'].value+"<enter><wait>"+
                   $q_struct['admin_password'].value+"<enter><wait>"+
                   ssh_com+
                   "echo '"+$q_struct['admin_password'].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+$q_struct['admin_username'].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm stop sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm stop asr-notify\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_11_[0,1]/
    if options['oscpu'].to_i > 6 and options['osmem'].to_i > 16
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
    #tools_upload_path   = "/export/home/"+$q_struct['admin_username'].value
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
                   $q_struct['root_password'].value+"<wait><tab><wait>"+
                   $q_struct['root_password'].value+"<wait><tab><wait>"+
                   $q_struct['admin_username'].value+"<wait><tab><wait>"+
                   $q_struct['admin_username'].value+"<wait><tab><wait>"+
                   $q_struct['admin_password'].value+"<wait><tab><wait>"+
                   $q_struct['admin_password'].value+"<wait><f2><wait>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   "<f2><wait10>"+
                   wait1+
                   wait1+
                   "<wait10><wait10><wait10><wait10>"+
                   "<f8><wait10><wait10>"+
                   "<enter><wait10>"+
                   wait1+
                   $q_struct['admin_username'].value+"<enter><wait>"+
                   $q_struct['admin_password'].value+"<enter><wait>"+
                   ssh_com+
                   "echo '"+$q_struct['admin_password'].value+"' |sudo -Sv<enter><wait>"+
                   "sudo sh -c \"echo '"+$q_struct['admin_username'].value+" ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/gnu/bin/sed -i 's/^.*requiretty/#Defaults requiretty/' /etc/sudoers\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable sendmail\"<enter><wait>"+
                   "sudo sh -c \"/usr/sbin/svcadm disable asr-notify\"<enter><wait>"+
                   "exit<enter><wait>"
  when /sol_10/
#    tools_upload_flavor = "solaris"
#    tools_upload_path   = "/export/home/"+$q_struct['admin_username'].value
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
    ssh_port            = "22"
    ssh_host_port_max   = "22"
    ssh_host_port_min   = "22"
    ks_file             = options['vm']+"/"+options['name']+"/"+options['name']+".xml"
    ks_url              = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
    install_nic         = $q_struct['nic'].value
    options['netmask']     = $q_struct['netmask'].value
    options['vmgateway']     = $q_struct['gateway'].value
    options['nameserver']  = $q_struct['nameserver'].value
    install_domain      = options['domainname']
    net_config          = install_nic+"="+options['ip']+"/24,"+options['vmgateway']+","+options['nameserver']+","+install_domain
    if options['service'].to_s.match(/sles_12_[1-9]|sles_15/)
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        boot_command = "<esc><enter><wait> linux<wait>"+
                       " netdevice="+$q_struct['nic'].value+
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
                     " netdevice="+$q_struct['nic'].value+
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
    install_netmask    = $q_struct['netmask'].value
    install_vmgateway  = $q_struct['gateway'].value
    install_nameserver = $q_struct['nameserver'].value
    install_broadcast  = $q_struct['broadcast'].value
    install_timezone   = $q_struct['timezone'].value
    install_netaddr    = $q_struct['network_address'].value
    install_nic        = $q_struct['nic'].value
    if install_nic.match(/^ct/)
      purity_nic  = $q_struct['nic'].value
      install_nic = $q_struct['nic'].value.split(".")[0]
    else
      purity_nic  = "ct0."+install_nic
    end
    if options['oscpu'].to_i > 6 and options['osmem'].to_i > 16
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
      handle_output(options,"Warning:\tSetup script '#{options['setup']}' not found")
      quit(options)
    else
      message = "Information:\tCopying '#{options['setup']}' to '#{script_file}'"
      command = "cp '#{options['setup']}' '#{script_file}'"
      execute_command(options,message,command)
      user = %x[cat '#{script_file}' |grep Username |awk '{print $3}'].chomp
      pass = %x[cat '#{script_file}' |grep Password |awk '{print $3}'].chomp
    end
    other_ips = ""
    other_net = ""
    if options['ip'].to_s.match(/,/)
      options['ip'] = options['ip'].split(/,/)[0]
    end
    if $q_struct['eth1_ip']
      if $q_struct['eth1_ip'].value.match(/[0-9]/)
        options['ip'] = $q_struct['eth1_ip'].value
        c_service = $q_struct['eth1_service'].value
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
    if $q_struct['eth2_ip']
      if $q_struct['eth2_ip'].value.match(/[0-9]/)
        options['ip'] = $q_struct['eth2_ip'].value
        c_service = $q_struct['eth2_service'].value
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
    if $q_struct['eth3_ip']
      if $q_struct['eth3_ip'].value.match(/[0-9]/)
        options['ip'] = $q_struct['eth3_ip'].value
        c_service = $q_struct['eth3_service'].value
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
    if $q_struct['eth4_ip']
      if $q_struct['eth4_ip'].value.match(/[0-9]/)
        options['ip'] = $q_struct['eth4_ip'].value
        c_service = $q_struct['eth4_service'].value
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
    if $q_struct['eth5_ip']
      if $q_struct['eth5_ip'].value.match(/[0-9]/)
        options['ip'] = $q_struct['eth5_ip'].value
        c_service = $q_struct['eth5_service'].value
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
    if options['vmnetwork'].to_s.match(/nat/)
      if options['dhcp'] == true
        ks_ip = options['hostonlyip'].to_s
      else
        ks_ip = options['hostip'].to_s
      end
    else
      ks_ip = options['hostonlyip'].to_s
    end
    ks_file = options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
    if options['livecd'] == true
      boot_wait    = "3s"
      boot_header  = "<enter><enter><f6><esc><wait><bs><bs><bs><bs>net.ifnames=0 biosdevname=0 "
      boot_command = boot_header+
                     "autoinstall ds=nocloud-net;seedfrom=http://"+ks_ip+":#{options['httpport']}/ --- "+
                     "<enter><wait>"
    else
      boot_header = "<enter><wait5><f6><esc><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>"+
                    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><bs><wait>"
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        ks_url = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
        boot_command = boot_header+
                       "<wait>/install/vmlinuz<wait> debian-installer/language="+$q_struct['language'].value+
                       " debian-installer/country="+$q_struct['country'].value+
                       " keyboard-configuration/layoutcode="+$q_struct['layout'].value+
                       " <wait>interface="+$q_struct['nic'].value+
                       " netcfg/disable_autoconfig="+$q_struct['disable_autoconfig'].value+
                       " netcfg/disable_dhcp="+$q_struct['disable_dhcp'].value+
                       " hostname="+options['name']+
                       " <wait>netcfg/get_ipaddress="+options['ip']+
                       " netcfg/get_netmask="+$q_struct['netmask'].value+
                       " netcfg/get_gateway="+$q_struct['gateway'].value+
                       " netcfg/get_nameservers="+$q_struct['nameserver'].value+
                       " netcfg/get_domain="+$q_struct['domain'].value+
                       " <wait>preseed/url="+ks_url+
                       " initrd=/install/initrd.gz net.ifnames=0 biosdevname=0 -- <wait><enter><wait>"
      else
        ks_url = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
        boot_command = boot_header+
                       "/install/vmlinuz<wait>"+
                       " auto-install/enable=true"+
                       " debconf/priority=critical"+
                       " <wait>preseed/url="+ks_url+
                       " initrd=/install/initrd.gz net.ifnames=0 biosdevname=0 -- <wait><enter><wait>"
      end
    end
    shutdown_command = "echo 'shutdown -P now' > /tmp/shutdown.sh ; echo '#{install_password}'|sudo -S sh '/tmp/shutdown.sh'"
  when /vsphere|esx|vmware/
    if options['vm'].to_s.match(/fusion/)
      virtual_dev       = "pvscsi"
    end
    hwvirtex          = "on"
    ks_file           = options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
    ks_url            = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
    if options['vm'].to_s.match(/fusion/)
      boot_command      = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=vmnic0 netdevice=vmnic0 ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<wait><enter><wait>"
    else
      boot_command      = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=vmnic0 netdevice=vmnic0 ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<wait><enter><wait>"
#      boot_command      = "<enter><wait>O<wait> ks="+ks_url+" ksdevice=eth0 netdevice=eth0 ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<wait><enter><wait>"
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
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      boot_command = "<tab><wait><bs><bs><bs><bs><bs><bs>=0 net.ifnames=0 biosdevname=0 inst.text inst.method=cdrom inst.repo=cdrom:/dev/sr0 inst.ks="+ks_url+" ip="+options['ip']+"::"+options['vmgateway']+":"+options['netmask']+":"+options['name']+":eth0:off<enter><wait>"
    else
      boot_command = "<tab><wait><bs><bs><bs><bs><bs><bs>=0 net.ifnames=0 biosdevname=0 inst.text inst.method=cdrom inst.repo=cdrom:/dev/sr0 inst.ks="+ks_url+" ip=dhcp<enter><wait>"
    end
#  when /rhel_7/
#    ks_file       = options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
#    ks_url        = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
#    boot_command  = "<esc><wait> linux text install ks="+ks_url+" ksdevice=eno16777736 "+"ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<enter><wait>"
  else
    ks_file       = options['vm']+"/"+options['name']+"/"+options['name']+".cfg"
    ks_url        = "http://#{ks_ip}:#{options['httpport']}/"+ks_file
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      boot_command  = "<esc><wait> linux net.ifnames=0 biosdevname=0 text install ks="+ks_url+" ip="+options['ip']+" netmask="+options['netmask']+" gateway="+options['vmgateway']+"<enter><wait>"
    else
      boot_command  = "<esc><wait> linux net.ifnames=0 biosdevname=0 text install ks="+ks_url+"<enter><wait>"
    end
    if options['guest'].class == Array
  	  options['guest'] = options['guest'].join
    end
    #shutdown_command = "echo '#{$q_struct['admin_password'].value}' |sudo -S /sbin/halt -h -p"
    if options['vmnetwork'].to_s.match(/hostonly|bridged/)
      shutdown_command = "sudo /usr/sbin/shutdown -P now"
    end
  end
	options['controller'] = options['controller'].gsub(/sas/,"scsi")
	case options['vm']
	when /vbox|virtualbox/
		options['type'] = "virtualbox-iso"
    options['mac']  = options['mac'].gsub(/:/,"")
	when /fusion|vmware/
		options['type'] = "vmware-iso"
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
  bridge_nic = get_vm_if_name(options)
  if options['service'].to_s.match(/windows/) and options['vm'].to_s.match(/vbox/) and options['vmnetwork'].to_s.match(/hostonly|bridged/)
    handle_output(options,"Warning:\tPacker with Windows and VirtualBox only works on a NAT network (Packer issue)")
    handle_output(options,"Information:\tUse the --network=nat option")
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
            :name                 => options['name'],
            :guest_additions_mode => guest_additions_mode,
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :ssh_host             => options['ip'],
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :ssh_pty              => ssh_pty,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :format               => output_format,
      			:vboxmanage => [
      				[ "modifyvm", "{{.Name}}", "--memory", options['memory'] ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
      				[ "modifyvm", "{{.Name}}", "--cpus", options['vcpus'] ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", options['mac'] ],
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
            :name                 => options['name'],
            :guest_additions_mode => guest_additions_mode,
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :hard_drive_interface => options['controller'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :ssh_port             => ssh_port,
            :ssh_timeout          => ssh_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", options['memory'] ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", options['vcpus'] ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", options['mac'] ],
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
            :name                 => options['name'],
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :ssh_host             => options['ip'],
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => options['memory'],
              :numvcpus                           => options['vcpus'],
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => options['mac'],
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
            :name                 => options['name'],
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
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
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => options['memory'],
              :numvcpus                           => options['vcpus'],
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => options['mac'],
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    when /qemu|kvm|xen/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        if options['headless'] == true
          json_data = {
            :variables => {
              :hostname => options['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
              :iso_url              => iso_url,
              :ssh_host             => options['ip'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-m", options['memory'] ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
              :iso_url              => iso_url,
              :ssh_host             => options['ip'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-m", options['memory'] ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-m", options['memory']+"M" ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-m", options['memory']+"M" ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
          :name                 => options['name'],
          :guest_additions_mode => guest_additions_mode,
          :vm_name              => options['name'],
          :type                 => options['type'],
          :headless             => headless_mode,
          :guest_os_type        => options['guest'],
          :output_directory     => image_dir,
          :disk_size            => options['size'],
          :iso_url              => iso_url,
          :ssh_host             => options['ip'],
          :ssh_port             => ssh_port,
          :ssh_username         => ssh_username,
          :ssh_password         => ssh_password,
          :ssh_timeout          => ssh_timeout,
          :shutdown_command     => shutdown_command,
          :shutdown_timeout     => shutdown_timeout,
          :ssh_pty              => ssh_pty,
          :iso_checksum         => install_checksum,
          :http_directory       => http_dir,
          :http_port_min        => options['httpport'],
          :http_port_max        => options['httpport'],
          :boot_wait            => boot_wait,
          :boot_command         => boot_command,
          :tools_upload_flavor  => tools_upload_flavor,
          :tools_upload_path    => tools_upload_path,
          :vboxmanage => [
            [ "modifyvm", "{{.Name}}", "--memory", options['memory'] ],
            [ "modifyvm", "{{.Name}}", "--audio", audio ],
            [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
            [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
            [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
            [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
            [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
            [ "modifyvm", "{{.Name}}", "--cpus", options['vcpus'] ],
            [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
            [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
            [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
            [ "modifyvm", "{{.Name}}", "--macaddress1", options['mac'] ],
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
          :name                 => options['name'],
          :vm_name              => options['name'],
          :type                 => options['type'],
          :headless             => headless_mode,
          :guest_os_type        => options['guest'],
          :output_directory     => image_dir,
          :disk_size            => options['size'],
          :iso_url              => iso_url,
          :ssh_host             => options['ip'],
          :ssh_port             => ssh_port,
          :ssh_username         => ssh_username,
          :ssh_password         => ssh_password,
          :ssh_timeout          => ssh_timeout,
          :shutdown_timeout     => shutdown_timeout,
          :shutdown_command     => shutdown_command,
          :ssh_pty              => ssh_pty,
          :iso_checksum         => install_checksum,
          :http_directory       => http_dir,
          :http_port_min        => options['httpport'],
          :http_port_max        => options['httpport'],
          :boot_wait            => boot_wait,
          :boot_command         => boot_command,
          :tools_upload_flavor  => tools_upload_flavor,
          :tools_upload_path    => tools_upload_path,
          :vmx_data => {
            :"virtualHW.version"                => hw_version,
            :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
            :memsize                            => options['memory'],
            :numvcpus                           => options['vcpus'],
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
            :name                 => options['name'],
            :guest_additions_mode => guest_additions_mode,
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :ssh_host             => options['ip'],
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
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
              [ "modifyvm", "{{.Name}}", "--memory", options['memory'] ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", options['vcpus'] ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", options['mac'] ],
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
            :name                 => options['name'],
            :guest_additions_mode => guest_additions_mode,
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :hard_drive_interface => options['controller'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :ssh_host             => options['ip'],
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_pty              => ssh_pty,
            :ssh_timeout          => ssh_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
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
              [ "modifyvm", "{{.Name}}", "--memory", options['memory'] ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", options['vcpus'] ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", options['mac'] ],
            ]
          ]
        }
      end
    when /kvm|qemu|xen/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        if options['headless'] == true
          json_data = {
            :variables => {
              :hostname => options['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
              :iso_url              => iso_url,
              :ssh_host             => options['ip'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-m", options['memory'] ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
              :iso_url              => iso_url,
              :ssh_host             => options['ip'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-m", options['memory'] ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-m", options['memory']+"M" ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-m", options['memory']+"M" ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
            :name                 => options['name'],
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
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
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
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
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => options['memory'],
              :numvcpus                           => options['vcpus'],
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => options['mac'],
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
            :name                 => options['name'],
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_command     => shutdown_command,
            :shutdown_timeout     => shutdown_timeout,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
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
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => options['memory'],
              :numvcpus                           => options['vcpus'],
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => options['mac'],
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
            :type                 => options['type'],
            :guest_additions_mode => guest_additions_mode,
            :headless             => headless_mode,
            :vm_name              => options['name'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :iso_checksum         => install_checksum,
            :guest_os_type        => options['guest'],
            :communicator         => communicator,
            :ssh_host_port_min    => ssh_host_port_min,
            :ssh_host_port_max    => ssh_host_port_max,
            :winrm_port           => winrm_port,
            :winrm_host           => options['ip'],
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
              [ "modifyvm", "{{.Name}}", "--memory", options['memory'] ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", options['vcpus'] ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", options['mac'] ],
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
              :type                 => options['type'],
              :guest_additions_mode => guest_additions_mode,
              :headless             => headless_mode,
              :vm_name              => options['name'],
              :output_directory     => image_dir,
              :disk_size            => options['size'],
              :iso_url              => iso_url,
              :iso_checksum         => install_checksum,
              :guest_os_type        => options['guest'],
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
              [ "modifyvm", "{{.Name}}", "--memory", options['memory'] ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", options['vcpus'] ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", options['mac'] ],
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
            :name                 => options['name'],
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :communicator         => communicator,
            :winrm_host           => options['ip'],
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
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
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
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :"RemoteDisplay.vnc.port"           => vnc_port_min,
              :memsize                            => options['memory'],
              :numvcpus                           => options['vcpus'],
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => options['mac'],
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
            :name                 => options['name'],
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
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
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
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
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :"RemoteDisplay.vnc.port"           => vnc_port_min,
              :memsize                            => options['memory'],
              :numvcpus                           => options['vcpus'],
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => options['mac'],
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    when /qemu|kvm|xen/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        if options['headless'] == true
          json_data = {
            :variables => {
              :hostname => options['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
              :iso_url              => iso_url,
              :ssh_host             => options['ip'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-m", options['memory'] ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
              :iso_url              => iso_url,
              :ssh_host             => options['ip'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-m", options['memory'] ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-m", options['memory']+"M" ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-m", options['memory']+"M" ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
            :name                 => options['name'],
            :guest_additions_mode => guest_additions_mode,
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :ssh_host             => options['ip'],
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
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :format               => output_format,
      			:vboxmanage => [
      				[ "modifyvm", "{{.Name}}", "--memory", options['memory'] ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
      				[ "modifyvm", "{{.Name}}", "--cpus", options['vcpus'] ],
              [ "modifyvm", "{{.Name}}", nic_command1, nic_config1 ],
              [ "modifyvm", "{{.Name}}", nic_command2, nic_config2 ],
              [ "modifyvm", "{{.Name}}", nic_command3, nic_config3 ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", options['mac'] ],
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
            :name                 => options['name'],
            :guest_additions_mode => guest_additions_mode,
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :hard_drive_interface => options['controller'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
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
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :vboxmanage => [
              [ "modifyvm", "{{.Name}}", "--memory", options['memory'] ],
              [ "modifyvm", "{{.Name}}", "--audio", audio ],
              [ "modifyvm", "{{.Name}}", "--mouse", mouse ],
              [ "modifyvm", "{{.Name}}", "--hwvirtex", hwvirtex ],
              [ "modifyvm", "{{.Name}}", "--rtcuseutc", rtcuseutc ],
              [ "modifyvm", "{{.Name}}", "--vtxvpid", vtxvpid ],
              [ "modifyvm", "{{.Name}}", "--vtxux", vtxux ],
              [ "modifyvm", "{{.Name}}", "--cpus", options['vcpus'] ],
              [ "modifyvm", "{{.Name}}", "--macaddress1", options['mac'] ],
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
            :name                 => options['name'],
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
            :iso_url              => iso_url,
            :ssh_host             => options['ip'],
            :ssh_port             => ssh_port,
            :ssh_username         => ssh_username,
            :ssh_password         => ssh_password,
            :ssh_timeout          => ssh_timeout,
            :shutdown_timeout     => shutdown_timeout,
            :shutdown_command     => shutdown_command,
            :ssh_pty              => ssh_pty,
            :iso_checksum         => install_checksum,
            :http_directory       => http_dir,
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => options['memory'],
              :numvcpus                           => options['vcpus'],
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.address"                => options['mac'],
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
            :name                 => options['name'],
            :vm_name              => options['name'],
            :type                 => options['type'],
            :headless             => headless_mode,
            :guest_os_type        => options['guest'],
            :output_directory     => image_dir,
            :disk_size            => options['size'],
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
            :http_port_min        => options['httpport'],
            :http_port_max        => options['httpport'],
            :boot_wait            => boot_wait,
            :boot_command         => boot_command,
            :tools_upload_flavor  => tools_upload_flavor,
            :tools_upload_path    => tools_upload_path,
            :vmx_data => {
              :"virtualHW.version"                => hw_version,
              :"RemoteDisplay.vnc.enabled"        => vnc_enabled,
              :memsize                            => options['memory'],
              :numvcpus                           => options['vcpus'],
              :"vhv.enable"                       => vhv_enabled,
              :"ethernet0.present"                => ethernet_enabled,
              :"ethernet0.connectionType"         => options['vmnetwork'],
              :"ethernet0.virtualDev"             => ethernet_dev,
              :"ethernet0.addressType"            => ethernet_type,
              :"ethernet0.GeneratedAddress"       => options['mac'],
              :"scsi0.virtualDev"                 => virtual_dev
            }
          ]
        }
      end
    when /qemu|kvm|xen/
      if options['vmnetwork'].to_s.match(/hostonly|bridged/)
        if options['headless'] == true
          json_data = {
            :variables => {
              :hostname => options['name'],
              :net_config => net_config
            },
            :builders => [
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
              :iso_url              => iso_url,
              :ssh_host             => options['ip'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-m", options['memory'] ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
              :iso_url              => iso_url,
              :ssh_host             => options['ip'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :net_bridge           => net_bridge,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-m", options['memory'] ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-nographic" ],
                [ "-serial", "stdio" ],
                [ "-m", options['memory']+"M" ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
              :name                 => options['name'],
              :vm_name              => options['name'],
              :type                 => options['type'],
              :headless             => headless_mode,
              :output_directory     => image_dir,
              :disk_size            => options['size'],
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
              :http_port_min        => options['httpport'],
              :http_port_max        => options['httpport'],
              :boot_wait            => boot_wait,
              :boot_command         => boot_command,
              :format               => format,
              :accelerator          => accelerator,
              :disk_interface       => disk_interface,
              :net_device           => net_device,
              :qemuargs             => [
                [ "-serial", "stdio" ],
                [ "-m", options['memory']+"M" ],
                [ "-smp", "cpus="+options['vcpus'] ]
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
  options['service'] = $q_struct['type'].value
  options['access']  = $q_struct['access_key'].value
  options['secret']  = $q_struct['secret_key'].value
  options['ami']     = $q_struct['source_ami'].value
  options['region']  = $q_struct['region'].value
  options['size']    = $q_struct['instance_type'].value
  options['adminuser']   = $q_struct['ssh_username'].value
  options['keyfile'] = File.basename($q_struct['keyfile'].value,".pem")+".key.pub"
  options['name']  = $q_struct['ami_name'].value
  tmp_keyfile     = "/tmp/"+options['keyfile']
  user_data_file  = $q_struct['user_data_file'].value
  packer_dir      = options['clientdir']+"/packer"
  options['clientdir']      = packer_dir+"/aws/"+options['name']
  json_file       = options['clientdir']+"/"+options['name']+".json"
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
  File.write(json_file,json_output)
  set_file_perms(json_file,"600")
  print_contents_of_file(options,"",json_file)
  return options
end
