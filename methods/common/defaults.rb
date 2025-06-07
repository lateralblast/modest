# frozen_string_literal: true

# Set OS defaults

def set_os_defaults(values, defaults)
  defaults['strict'] = false
  defaults['home'] = ENV['HOME']
  defaults['user'] = ENV['USER']
  defaults['host-os-uname']  = `uname`.chomp
  defaults['host-os-unamep'] = `uname -p`.chomp
  defaults['host-os-unamem'] = `uname -m`.chomp
  defaults['host-os-unamea'] = `uname -a`.chomp
  defaults['host-os-unamer'] = `uname -r`.chomp
  defaults['host-os-packages'] = []
  if defaults['host-os-uname'].to_s.match(/Darwin/)
    defaults['host-os-unamep'] = `uname -m`.chomp
    defaults['host-os-memory'] = `system_profiler SPHardwareDataType |grep Memory |awk '{print $2}'`.chomp
    defaults['host-os-cpu'] = `sysctl hw.ncpu |awk '{print $2}'`
    defaults['host-os-packages'] = `/usr/local/bin/brew list`.split(/\s+|\n/) if File.exist?('/usr/local/bin/brew')
  elsif defaults['host-os-uname'].to_s.match(/Linux/)
    if defaults['host-os-unamea'].to_s.match(/Ubuntu/)
      defaults['host-os-packages'] = `dpkg -l |awk '{print $2}'`.split(/\s+|\n/)
    elsif defaults['host-os-unamea'].to_s.match(/arch/)
      defaults['host-os-packages'] = `pacman -Q |awk '{print $1}'`.split(/\s+|\n/)
    end
    defaults['host-os-memory'] = `free -g |grep ^Mem |awk '{print $2}'`.chomp
    defaults['host-os-cpu']    = `cat /proc/cpuinfo |grep processor |wc -l`.chomp
  else
    defaults['host-os-memory'] = '1'
    defaults['host-os-cpu'] = '1'
  end
  if File.exist?('/proc/1/cgroup')
    output = `cat /proc/1/cgroup |grep docker`
    defaults['host-os'] = if output.match(/docker/)
                            'Docker'
                          else
                            defaults['host-os-unamea'].to_s
                          end
  else
    defaults['host-os'] = defaults['host-os-unamea'].to_s
  end
  if defaults['host-os-uname'].to_s.match(/SunOS|Darwin|NT/)
    if defaults['host-os-uname'].to_s.match(/SunOS/)
      defaults['host-os-revision'] = `cat /etc/release |grep Solaris |head -1`.chomp.gsub(/^\s+/, '') if File.exist?('/etc/release')
      if defaults['host-os-unamer'].to_s.match(/\./)
        defaults['host-os-version'] = defaults['host-os-unamer'].to_s.split(/\./)[1] if defaults['host-os-unamer'].to_s.match(/^5/)
        if defaults['host-os-version'].to_s.match(/^11/)
          os_version_string = `uname -v`.chomp
          defaults['host-os-update'] = os_version_string.split(/\./)[1] if os_version_string.match(/\./)
        end
      elsif defaults['host-os-revision'].to_s.match(/Oracle/)
        defaults['host-os-version'] = defaults['host-os-revision'].to_s.split(/\s+/)[3].split(/\./)[0]
        defaults['host-os-update'] = defaults['host-os-revision'].to_s.split(/\s+/)[3].split(/\./)[1]
      end
    else
      defaults['host-os-version'] = `sw_vers |grep ProductVersion |awk '{print $2}'`.chomp
    end
  end
  if defaults['host-os-unamer'].to_s.match(/\./)
    defaults['host-os-major'] = defaults['host-os-unamer'].to_s.split(/\./)[0]
    defaults['os-minor']      = defaults['host-os-unamer'].to_s.split(/\./)[1]
  else
    defaults['host-os-major'] = defaults['host-os-unamer']
    defaults['os-minor'] = '0'
  end
  [values, defaults]
end

# Set valid defaults

def set_valid_defaults(values, defaults)
  defaults['valid-acl']     = %w[private public-read public-read-write
                                 authenticated-read]
  defaults['valid-action']  = %w[add boot build connect check
                                 clone create delete deploy download
                                 export get halt info import list
                                 migrate shutdown start stop upload
                                 usage]
  defaults['valid-arch']    = %w[x86_64 i386 sparc arm64]
  defaults['valid-console'] = %w[text console x11 headless pty vnc]
  defaults['valid-format']  = %w[VMDK RAW VHD]
  defaults['valid-method']  = %w[ks xb vs ai js ps lxc mp
                                 ay ci image ldom cdom gdom]
  defaults['valid-mode']    = %w[client server osx]
  defaults['valid-os']      = %w[Solaris VMware-VMvisor CentOS
                                 OracleLinux SLES openSUSE NT
                                 Ubuntu Debian Fedora RHEL SL
                                 Purity Windows JeOS AMZNL]
  defaults['valid-output']  = %w[text html]
  defaults['valid-type']    = %w[iso flar ova snapshot service
                                 boot cdrom net disk client dvd
                                 server ansible vcsa packer docker
                                 amazon-ebs image ami instance bucket
                                 acl snapshot key sg dhcp keypair
                                 ssh stack object cf cloudformation
                                 public private securitygroup iprule
                                 pxe nic network]
  defaults['valid-target']  = %w[citrix vmware windows]
  [values, defaults]
end

# Set volume defaults

def set_volume_defaults(values, defaults)
  defaults['accelerator']     = 'kvm'
  defaults['audio']           = 'none'
  defaults['auditfs']         = 'ext4'
  defaults['auditsize']       = '8192'
  defaults['unattendedfile']  = ''
  defaults['autoyastfile']    = ''
  defaults['bootfs']          = 'ext4'
  defaults['bootsize']        = '512'
  defaults['bridge']          = 'virbr0'
  defaults['netbridge']       = defaults['bridge']
  defaults['communicator']    = 'winrm'
  defaults['homefs']          = 'ext4'
  defaults['homesize']        = '8192'
  defaults['localsize']       = '8192'
  defaults['localfs']         = 'ext4'
  defaults['localsize']       = '8192'
  defaults['logfs']           = 'ext4'
  defaults['logsize']         = '8192'
  defaults['rootfs']          = 'ext4'
  defaults['rootsize']        = '8192'
  defaults['scratchfs']       = 'ext4'
  defaults['scratchsize']     = '8192'
  defaults['swapfs']          = 'linux-swap'
  defaults['swapsize']        = '8192'
  defaults['tmpfs']           = 'ext4'
  defaults['tmpsize']         = '8192'
  defaults['usrfs']           = 'ext4'
  defaults['usrsize']         = '8192'
  defaults['varfs']           = 'ext4'
  defaults['varsize']         = '8192'
  [values, defaults]
end

# Set VM defaults

def set_vm_defaults(values, defaults)
  if defaults['host-os-unamep'].to_s.match(/sparc/)
    defaults['valid-vm'] = %w[zone cdom gdom aws] if (defaults['host-os-major'] = `uname -r`.split(/\./)[1].to_i > 9)
  else
    case defaults['host-os-uname']
    when /not recognised/
      verbose_message(values, "Information:\tAt the moment Cygwin is required to run on Windows")
    when /NT/
      defaults['valid-vm'] = %w[vbox aws vmware fusion multipass]
    when /SunOS/
      defaults['valid-vm'] = %w[vbox zone aws]
      defaults['nic']      = `dladm show-link |grep phys |grep up |awk '{print $1}'`.chomp
      defaults['host-os-platform'] = `prtdiag |grep 'System Configuration'`.chomp
    when /Linux/
      defaults['valid-vm'] = %w[vbox lxc docker aws qemu kvm xen fusion vmware multipass]
      defaults['dmidecode'] = if File.exist?('/sbin/dmidecode')
                                '/sbin/dmidecode'
                              else
                                '/usr/sbin/dmidecode'
                              end
      hv_check = `cat /proc/cpuinfo |grep -i hypervisor`.downcase
      defaults['host-os-platform'] = if hv_check.match(/hyper/)
                                       `sudo #{defaults['dmidecode']} |grep 'Product Name'`.chomp
                                     else
                                       `cat /proc/cpuinfo |grep -i "model name" |head -1`.chomp
                                     end
      defaults['lsb'] = if File.exist?('/bin/lsb_release')
                          '/bin/lsb_release'
                        else
                          '/usr/bin/lsb_release'
                        end
      defaults['host-lsb-all']         = `#{defaults['lsb']} -a`.chomp
      defaults['host-lsb-id']          = `#{defaults['lsb']} -i -s`.chomp
      defaults['host-lsb-release']     = `#{defaults['lsb']} -r -s`.chomp
      defaults['host-lsb-version']     = `#{defaults['lsb']} -v -s`.chomp
      defaults['host-lsb-codename']    = `#{defaults['lsb']} -c -s`.chomp
      defaults['host-lsb-distributor'] = `#{defaults['lsb']} -i -s`.chomp
      defaults['host-lsb-description'] = `#{defaults['lsb']} -d -s`.chomp.gsub(/"/, '')
    when /Darwin/
      defaults['nic']      = 'en0'
      defaults['ovfbin']   = '/Applications/VMware OVF Tool/ovftool'
      defaults['valid-vm'] = %w[vbox vmware fusion parallels aws docker qemu multipass kvm]
    end
  end
  defaults['vmntools']        = false
  defaults['vmnetwork']       = 'hostonly'
  defaults['vncpassword']     = 'P455w0rd'
  #  defaults['vncport']         = "5961"
  defaults['vncport']         = '5900'
  defaults['vlanid']          = '0'
  #  defaults['vm']              = "vbox"
  defaults['vmnet']           = 'vboxnet0'
  defaults['vmnetdhcp']       = false
  defaults['vmnetwork']       = 'hostonly'
  defaults['vmtools']         = 'disable'
  defaults['vmtype']          = ''
  defaults['vswitch']         = 'vSwitch0'
  defaults['vtxvpid']         = 'on'
  defaults['vtxux']           = 'on'
  [values, defaults]
end

# Set VM defaults

def set_vmnic_defaults(values, defaults)
  defaults['vmnic'] = if values['clientnic'].to_s.match(/[0-9]/)
                        values['clientnic'].to_s
                      elsif values['vm'].to_s.match(/kvm|mp|multipass/)
                        if values['biosdevnames'] == false
                          'enp1s0'
                        else
                          'eth0'
                        end
                      elsif values['vm'].to_s.match(/fusion/) && defaults['host-os-unamep'].to_s.match(/arm/)
                        if values['biosdevnames'] == false
                          'ens160'
                        else
                          'eth0'
                        end
                      else
                        'eth0'
                      end
  [values, defaults]
end

# Set gateway defaults

def set_gateway_defaults(values, defaults)
  defaults['gateway']     = ''
  defaults['gatewaynode'] = '1'
  case defaults['host-os-platform']
  when /VMware/
    if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      if values['vmnetwork'].to_s.match(/nat/)
        defaults['vmgateway']  = '192.168.158.1'
        defaults['hostonlyip'] = '192.168.158.1'
      elsif defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 11
        defaults['vmgateway']  = '192.168.2.1'
        defaults['hostonlyip'] = '192.168.2.1'
      else
        defaults['vmgateway']  = '192.168.104.1'
        defaults['hostonlyip'] = '192.168.104.1'
      end
    else
      defaults['vmgateway']  = '192.168.52.1'
      defaults['hostonlyip'] = '192.168.52.1'
    end
    defaults['nic'] = `netstat -rn |grep UG |head -1`.chomp.split[-1] if defaults['host-os-uname'].to_s.match(/Linux/)
  when /VirtualBox/
    defaults['vmgateway']  = '192.168.56.1'
    defaults['hostonlyip'] = '192.168.56.1'
    defaults['nic']        = 'eth0'
  when /Parallels/
    if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      defaults['vmgateway']  = '10.211.55.1'
      defaults['hostonlyip'] = '10.211.55.1'
    else
      defaults['vmgateway']  = '192.168.54.1'
      defaults['hostonlyip'] = '192.168.54.1'
    end
  else
    defaults['vmgateway']  = '192.168.55.1'
    defaults['hostonlyip'] = '192.168.55.1'
    if defaults['host-os-uname'].to_s.match(/Linux/)
      defaults['nic'] = 'eth0'
      network_test = `ifconfig -a |grep eth0`.chomp
      defaults['nic'] = `ip r |grep default |awk '{print $5}'` unless network_test.match(/eth0/)
    end
  end
  if values['vm'].to_s.match(/kvm/)
    defaults['vmgateway']  = '192.168.122.1'
    defaults['hostonlyip'] = '192.168.122.1'
  end
  [values, defaults]
end

# Set directory defaults

def set_dir_defaults(values, defaults)
  defaults['virtdir'] = ''
  defaults['basedir'] = ''
  defaults['zonedir'] = '/zones'
  if defaults['host-os-uname'].match(/Darwin/) && defaults['host-os-major'].to_i > 18
    # defaults['basedir']  = "/System/Volumes/Data"
    # defaults['mountdir'] = '/System/Volumes/Data/cdrom'
    defaults['basedir']  = "#{defaults['home']}/Documents/modest"
    defaults['mountdir'] = "#{defaults['home']}/Documents/modest/cdrom"
    if values['vm'].to_s.match(/kvm/) && defaults['host-os-uname'].to_s.match(/Darwin/)
      defaults['virtdir'] = if Dir.exist?('/opt/homebrew/Cellar')
                              '/opt/homebrew/Cellar/libvirt/images'
                            else
                              '/usr/local/Cellar/libvirt/images'
                            end
    end
  else
    if values['vm'].to_s.match(/kvm/)
      defaults['virtdir'] = if defaults['host-os-uname'].to_s.match(/Darwin/)
                              if Dir.exist?('/opt/homebrew/Cellar')
                                '/opt/homebrew/Cellar/libvirt/images'
                              else
                                '/usr/local/Cellar/libvirt/images'
                              end
                            else
                              '/var/lib/libvirt/images'
                            end
    end
    defaults['mountdir'] = '/cdrom'
  end
  defaults['aibasedir']     = '/export/auto_install'
  defaults['novncdir']      = '/usr/local/novnc'
  defaults['clientrootdir'] = "#{defaults['basedir']}/export/clients"
  defaults['clientdir']     = "#{defaults['basedir']}/export/clients"
  defaults['aidir']         = "#{defaults['basedir']}/export/auto_install"
  defaults['isodir']        = "#{defaults['basedir']}/export/isos"
  defaults['pkgdir']        = "#{defaults['basedir']}/export/pkgs"
  defaults['baserepodir']   = "#{defaults['basedir']}/export/repo"
  defaults['repodir']       = "#{defaults['basedir']}/export/repo"
  defaults['exportdir']     = "#{defaults['basedir']}/export/#{defaults['scriptname']}"
  defaults['imagedir']      = "#{defaults['basedir']}/export/images"
  defaults['apachedir']     = '/etc/apache2'
  defaults['wikidir']       = "#{defaults['scriptdir']}/#{File.basename(defaults['script'], '.rb')}.wiki"
  defaults['wikiurl']       = 'https://github.com/lateralblast/mode.wiki.git'
  defaults['tmpdir']        = '/tmp'
  defaults['tftpdir']       = '/etc/netboot'
  defaults['fusiondir']     = "#{defaults['home']}/Virtual Machines"
  defaults['sharedfolder']  = "#{defaults['home']}/Documents"
  defaults['sharedmount']   = if values['host-os-uname'].to_s.match(/Darwin/)
                               "#{defaults['home']}/Documents/modest/mnt"
                              else
                                '/mnt'
                              end
  [values, defaults]
end

# Set port defaults

def set_port_defaults(values, defaults)
  defaults['aiport']      = '10081'
  defaults['sshport']     = '22'
  defaults['httpport']    = '8888'
  defaults['httpportmax'] = defaults['httpport']
  defaults['httpportmin'] = defaults['httpport']
  [values, defaults]
end

# Set install defaults

def set_install_defaults(values, defaults)
  defaults['installdrivers']  = false
  defaults['installupdates']  = false
  defaults['installupgrades'] = false
  defaults['installsecurity'] = false
  defaults['preservesources'] = false
  [values, defaults]
end

# Set admin defaults

def set_admin_defaults(values, defaults)
  defaults['admingid']        = '200'
  defaults['adminuser']       = 'modest'
  defaults['admingroup']      = 'wheel'
  defaults['adminhome']       = "/home/#{defaults['adminuser']}"
  defaults['adminname']       = 'modest'
  defaults['adminpassword']   = 'P455w0rd'
  defaults['adminuid']        = '200'
  defaults['adminshell']      = '/bin/bash'
  defaults['adminsudo']       = 'ALL=(ALL) NOPASSWD:ALL'
  defaults['severadmin']      = 'root'
  defaults['servernetwork']   = 'vmnetwork1'
  defaults['serverpassword']  = 'P455w0rd'
  defaults['sshpassword']     = defaults['serverpassword']
  defaults['rootpassword']    = 'P455w0rd'
  [values, defaults]
end

# Set admin defaults

def set_host_os_defaults(values, defaults)
  values['host-os-uname']  = defaults['host-os-uname']
  values['host-os-unamep'] = defaults['host-os-unamep']
  values['host-os-unamem'] = defaults['host-os-unamem']
  values['host-os-unamea'] = defaults['host-os-unamea']
  values['host-os-unamer'] = defaults['host-os-unamer']
  if values['host-os-uname'].to_s.match(/Linux/)
    values['host-lsb-id']  = defaults['host-lsb-id']
    values['host-lsb-all'] = defaults['host-lsb-all']
    values['host-lsb-release']  = defaults['host-lsb-release']
    values['host-lsb-version']  = defaults['host-lsb-version']
    values['host-lsb-codename'] = defaults['host-lsb-codename']
    values['host-lsb-distributor'] = defaults['host-lsb-distributor']
    values['host-lsb-description'] = defaults['host-lsb-description']
  end
  [values, defaults]
end

# Set admin defaults

def set_kvm_defaults(values, defaults)
  defaults['graphics'] = 'none'
  defaults['kvmgroup'] = 'kvm'
  defaults['kvmgid']   = get_group_gid(values, defaults['kvmgroup'].to_s)
  if values['vm'].to_s.match(/kvm/)
    defaults['cdrom']           = 'none'
    defaults['install']         = 'none'
    defaults['controller']      = 'none'
    defaults['container']       = false
    defaults['destroy-on-exit'] = false
    defaults['check']           = false
  end
  defaults['cloudinitfile'] = ''
  [values, defaults]
end

# Set admin defaults

def set_ssh_defaults(values, defaults)
  defaults['packersshport'] = '2222'
  if values['vm']
    defaults['keydir'] = if values['vm'].to_s.match(/aws/)
                           "#{ENV['HOME']}/.ssh/aws"
                         else
                           "#{ENV['HOME']}/.ssh"
                         end
  end
  defaults['sshconfig']  = "#{defaults['home']}/.ssh/config"
  defaults['sshenadble'] = 'true'
  defaults['sshkeydir']  = "#{defaults['home']}/.ssh"
  defaults['usesshkey']  = true
  %w[dsa rsa ed25519].each do |ssh_key_type|
    ssh_key_file = "#{defaults['sshkeydir']}/id_#{ssh_key_type}.pub"
    next unless File.exist?(ssh_key_file)
    defaults['sshkeyfile'] = ssh_key_file
    defaults['sshkeytype'] = ssh_key_type
    defaults['sshkey']     = File.read(ssh_key_file).chomp
  end
  defaults['sshkeybits']    = '2048'
  defaults['sshpty']        = true
  defaults['sshtimeout']    = '1h'
  defaults['opensshwinurl'] = 'http://www.mls-software.com/files/setupssh-7.2p2-1-v1.exe'
  [values, defaults]
end

# Set script defaults

def set_script_defaults(values, defaults)
  defaults['manifest']      = 'modest'
  defaults['scriptname']    = 'modest'
  defaults['organisation']  = 'Multi OS Deployment Server'
  defaults['script']        = $PROGRAM_NAME
  defaults['scriptfile']    = Pathname.new(defaults['script'].to_s).realpath
  defaults['scriptdir']     = File.dirname(defaults['scriptfile'].to_s)
  defaults['workdir']       = "#{defaults['home']}/.modest"
  defaults['backupdir']     = "#{defaults['workdir']}/backup"
  defaults['bindir']        = "#{defaults['workdir']}/bin"
  defaults['rpmdir']        = "#{defaults['workdir']}/rpms"
  defaults['ubuntudir']     = '/ubuntu'
  defaults['suffix']        = defaults['scriptname'].to_s
  defaults['backupsuffix']  = '.pre-modest'
  defaults['mode']          = 'client'
  defaults['install']       = 'initial_install'
  defaults['rpm2cpiobin']   = ''
  defaults['executehost']   = 'localhost'
  defaults['net']           = 'net0'
  defaults['console']       = ''
  defaults['postscript']    = ''
  [values, defaults]
end

# Set other defaults

def set_other_defaults(values, defaults)
  defaults['biosdevnames']    = true
  defaults['checksum']        = false
  defaults['checknat']        = false
  defaults['copykeys']        = true
  defaults['defaults']        = false
  defaults['dhcp']            = false
  defaults['dnsmasq']         = false
  defaults['download']        = false
  defaults['dryrun']          = false
  defaults['enableethernet']  = true
  defaults['enablevnc']       = false
  defaults['enablevhv']       = true
  defaults['force']           = false
  defaults['headless']        = false
  defaults['help']            = false
  defaults['nokeys']          = false
  defaults['nomirror']        = true
  defaults['nosuffix']        = false
  defaults['notice']          = false
  defaults['noreboot']        = false
  defaults['build']           = false
  defaults['noboot']          = false
  defaults['reboot']          = true
  defaults['techpreview']     = false
  defaults['text']            = false
  defaults['unmasked']        = false
  defaults['usemirror']       = false
  defaults['usb']             = true
  defaults['usbxhci']         = true
  defaults['yes']             = false
  defaults['verbose']         = false
  defaults['version']         = false
  defaults['splitvols']       = false
  defaults['livecd']          = false
  defaults['lockpassword']    = false
  defaults['mirrordisk']      = false
  defaults['masked']          = false
  [values, defaults]
end

# Set win defaults

def set_win_defaults(values, defaults)
  defaults['winrmport']     = '5985'
  defaults['winshell']      = 'winrm'
  defaults['winrmusessl']   = false
  defaults['winrminsecure'] = true
  [values, defaults]
end

# Set user defaults

def set_user_defaults(values, defaults)
  defaults['uid']  = `/usr/bin/id -u`.chomp
  defaults['uid']  = Integer(defaults['uid'])
  defaults['uuid'] = ''
  defaults['user'] = `whoami`.chomp
  [values, defaults]
end

# Set sun defaults

def set_sun_defaults(values, defaults)
  defaults['bename']        = 'solaris'
  defaults['cluster']       = 'SUNWCprog'
  defaults['ldomdir']       = '/ldoms'
  defaults['publisherhost'] = defaults['hostip'].to_s
  defaults['publisherport'] = '10081'
  defaults['dpool']         = 'dpool'
  defaults['rpoolname']     = 'rpool'
  defaults['zpoolname']     = 'rpool'
  defaults['security']      = 'none'
  defaults['nfs4domain']    = 'dynamic'
  defaults['opencsw']       = 'http://mirror.opencsw.org/opencsw/'
  defaults['terminal']      = 'sun'
  defaults['autoreg']       = 'disable'
  [values, defaults]
end

# Set sudo defaults

def set_sudo_defaults(values, defaults)
  defaults['sudo']      = true
  defaults['sudogroup'] = if defaults['host-lsb-description'].to_s.match(/Endeavour|Arch/)
                            'wheel'
                          else
                            'sudo'
                          end
  defaults['sudoers']   = 'ALL=(ALL) NOPASSWD:ALL'
  [values, defaults]
end

# Set disk defaults

def set_disk_defaults(values, defaults)
  defaults['diskmode']        = 'thin'
  defaults['diskformat']      = 'qcow2'
  defaults['diskinterface']   = 'ide'
  defaults['containertype']   = 'ova'
  defaults['controller']      = 'sas'
  defaults['size']            = '100G'
  defaults['slice']           = '8192'
  defaults['files']           = 'files'
  defaults['format']          = 'VMDK'
  defaults['virtiofile']      = ''
  defaults['virtualdevice']   = 'lsilogic'
  defaults['boot']            = 'disk'
  defaults['bootsize']        = '512'
  defaults['bootwait']        = '5s'
  defaults['growpart']        = true
  defaults['growpartdevice']  = '/'
  defaults['growpartmode']    = 'auto'
  defaults['rootdisk']        = '/dev/sda'
  defaults['thindiskmode']    = 'true'
  defaults['vgname']          = 'vg01'
  [values, defaults]
end

# Set aws defaults

def set_aws_defaults(values, defaults)
  defaults['creds']  = "#{defaults['home']}/.aws/credentials"
  defaults['bucket'] = "#{defaults['scriptname']}.bucket"
  defaults['region'] = 'ap-southeast-2'
  defaults['grant']  = 'CanonicalUser'
  [values, defaults]
end

# Set locale defaults

def set_locale_defaults(values, defaults)
  defaults['systemlocale']  = 'C'
  defaults['time']          = 'Eastern Standard Time'
  defaults['timezone']      = 'Australia/Victoria'
  defaults['keyboard']      = 'US'
  defaults['keymap']        = 'US-English'
  defaults['language']      = 'en_US'
  defaults['local']         = 'local'
  defaults['locale']        = 'en_US'
  defaults['country']       = 'AU'
  [values, defaults]
end

# Set IP defaults

def set_ip_defaults(values, defaults)
  defaults['proto']       = 'tcp'
  defaults['ipfamily']    = 'ipv4'
  defaults['netmask']     = '255.255.255.0'
  defaults['domainname']  = 'lab.net'
  defaults['environment'] = 'en_US.UTF-8'
  defaults['hostname']    = `'hostname'`.chomp
  defaults['hostnet']     = '192.168.1.0'
  defaults['hosts']       = 'files dns'
  defaults['nameserver']  = '8.8.8.8'
  defaults['hostip']      = get_my_ip(defaults)
  defaults['timeserver']  = "0.#{defaults['country'].to_s.downcase}.pool.ntp.org"
  defaults['nameservice'] = 'none'
  defaults['server']      = defaults['hostip'].to_s
  defaults['sitename']    = defaults['domainname'].to_s.split('.')[0]
  defaults['apacheallow'] = ''
  [values, defaults]
end

# Set Ubuntu defaults

def set_ubuntu_defaults(values, defaults)
  defaults['mirror']        = "#{defaults['country'].to_s.downcase}.archive.ubuntu.com"
  defaults['mirrordir']     = '/ubuntu'
  defaults['mirrorurl']     = defaults['mirror'].to_s + defaults['mirrordir'].to_s
  defaults['trunk']         = 'stable'
  defaults['ubuntumirror']  = 'mirror.aarnet.edu.au'
  defaults['preseedfile']   = ''
  defaults['kernel']        = 'linux-generic'
  defaults['disableautoconf'] = 'true'
  [values, defaults]
end

# Set MAAS defaults

def set_maas_defaults(values, defaults)
  defaults['maasadmin']     = 'root'
  defaults['maasemail']     = "#{defaults['maasadmin']}@#{defaults['hostip']}"
  defaults['maaspassword']  = defaults['adminpassword'].to_s
  [values, defaults]
end

# Set vmware defaults

def set_vmware_defaults(values, defaults)
  defaults['memory']    = '2048'
  defaults['vcpus']     = '2'
  defaults['vcpu']      = '1'
  defaults['instances'] = '1,1'
  defaults['mouse']     = 'ps2'
  defaults['number']    = '1,1'
  defaults['utc']       = 'off'
  defaults['target']    = 'vmware'
  defaults['datastore'] = 'datastore1'
  defaults['hwvirtex']  = 'on'
  defaults['rtcuseutc'] = 'on'
  defaults['ovftarurl'] = 'https://github.com/richardatlateralblast/ottar/blob/master/vmware-ovftools.tar.gz?raw=true'
  defaults['ovfdmgurl'] = 'https://github.com/richardatlateralblast/ottar/blob/master/VMware-ovftool-4.1.0-2459827-mac.x64.dmg?raw=true'
  defaults['biostype']    = 'bios'
  defaults['serversize']  = 'small'
  defaults['hardwareversion'] = '8'
  defaults['ethernetdevice']  = 'e1000e'
  [values, defaults]
end

# Set lxc defaults

def set_lxc_defaults(values, defaults)
  defaults['lxcdir']      = '/export/clients/lxc'
  defaults['lxcimagedir'] = '/export/clients/lxc/images'
  [values, defaults]
end

# Set packer defaults

def set_packer_defaults(values, defaults)
  defaults['shutdowntimeout'] = '1h'
  defaults['packerversion']   = '1.9.4'
  defaults['keyfile']         = 'none'
  [values, defaults]
end

# Set virtualbox defaults

def set_vbox_defaults(values, defaults)
  defaults['vboxadditions'] = '/Applications/VirtualBox.app//Contents/MacOS/VBoxGuestAdditions.iso'
  defaults['vboxmanage']    = '/usr/local/bin/VBoxManage'
  [values, defaults]
end

# Set defaults

def set_defaults(values, defaults)
  defaults['empty']  = 'none'
  defaults['action'] = 'help'
  defaults['search'] = ''
  defaults['object'] = 'uploads'
  defaults['cidr']   = '24'
  defaults['acl']    = 'private'
  defaults['arch']   = 'x86_64'
  defaults['check']  = 'perms'
  defaults['mac']    = ''
  defaults['output'] = 'text'
  (values, defaults) = set_os_defaults(values, defaults)
  (values, defaults) = set_aws_defaults(values, defaults)
  (values, defaults) = set_script_defaults(values, defaults)
  (values, defaults) = set_valid_defaults(values, defaults)
  (values, defaults) = set_volume_defaults(values, defaults)
  (values, defaults) = set_vm_defaults(values, defaults)
  (values, defaults) = set_vmnic_defaults(values, defaults)
  (values, defaults) = set_gateway_defaults(values, defaults)
  (values, defaults) = set_dir_defaults(values, defaults)
  (values, defaults) = set_sun_defaults(values, defaults)
  (values, defaults) = set_port_defaults(values, defaults)
  (values, defaults) = set_ip_defaults(values, defaults)
  (values, defaults) = set_admin_defaults(values, defaults)
  (values, defaults) = set_install_defaults(values, defaults)
  (values, defaults) = set_ssh_defaults(values, defaults)
  (values, defaults) = set_kvm_defaults(values, defaults)
  (values, defaults) = set_host_os_defaults(values, defaults)
  (values, defaults) = set_win_defaults(values, defaults)
  (values, defaults) = set_user_defaults(values, defaults)
  (values, defaults) = set_other_defaults(values, defaults)
  (values, defaults) = set_ubuntu_defaults(values, defaults)
  (values, defaults) = set_disk_defaults(values, defaults)
  (values, defaults) = set_sudo_defaults(values, defaults)
  (values, defaults) = set_locale_defaults(values, defaults)
  (values, defaults) = set_maas_defaults(values, defaults)
  (values, defaults) = set_vmware_defaults(values, defaults)
  (values, defaults) = set_lxc_defaults(values, defaults)
  (values, defaults) = set_vbox_defaults(values, defaults)
  (values, defaults) = set_packer_defaults(values, defaults)
  [values, defaults]
end

# Reset VM defaults

def reset_machine_defaults(values, defaults)
  defaults['bridge'] = 'br0' if values['vm'].to_s.match(/kvm/) && values['vmnetwork'].to_s.match(/bridged/)
  defaults['cputype'] = if values['arch'].to_s.match(/arm|aarch/)
                          'cortex-a57'
                        else
                          'host'
                        end
  defaults['hostname'] = values['name'] if values['name'].to_s.match(/[a-z]/) && !values['hostname']
  defaults['vmnic'] = 'enp1s0' if values['vm'].to_s.match(/kvm/) && values['method'].to_s.match(/ci/) || values['file'].to_s.match(/cloudimg/)
  if values['file'].to_s.match(/[a-z]/)
    defaults['arch'] = get_install_arch_from_file(values)
    defaults['service'] = get_install_service_from_file(values) unless values['service'].to_s.match(/[a-z]/)
    defaults['method'] = 'ci' if values['file'].to_s.match(/cloudimg/)
  end
  if values['file'].to_s.match(/VMware-VMvisor-Installer/)
    defaults['vcpus']  = '4'
    defaults['memory'] = '4096'
  end
  if defaults['host-os-unamep'].to_s.match(/^arm/)
    defaults['machine']  = 'arm64'
    defaults['arch']     = 'arm64'
    defaults['biostype'] = 'efi'
  end
  [values, defaults]
end

# Reset KVM defaults

def reset_kvm_defaults(values, defaults)
  if values['vm'].to_s.match(/kvm/)
    defaults['imagedir'] = if values['host-os-uname'].to_s.match(/Darwin/)
                             if Dir.exist?('/opt/homebrew/Cellar')
                               '/opt/homebrew/Cellar/libvirt/images'
                             else
                               '/usr/local/Cellar/libvirt/images'
                             end
                           else
                             '/var/lib/libvirt/images'
                           end
    defaults['console']  = 'pty,target_type=virtio'
    defaults['mac']      = generate_mac_address(values)
    defaults['network'] = if !values['bridge'].to_s.match(/br[0-9]/)
                            "bridge=#{defaults['bridge']}"
                          else
                            "bridge=#{values['bridge']}"
                          end
    defaults['features']  = 'kvm_hidden=on'
    defaults['vmnetwork'] = 'hostonly'
    if defaults['host-os-unamep'].to_s.match(/^x/)
      defaults['machine'] = 'q35'
      defaults['arch']    = 'x86_64'
    end
    unless values['disk']
      host_name = if values['name'].to_s.match(/,/)
                    values['name'].to_s.split(/,/)[0]
                  else
                    values['name'].to_s
                  end
      defaults['disk'] =
        "path=#{defaults['imagedir']}/#{host_name}-seed.qcow2 path=#{defaults['imagedir']}/#{host_name}.qcow2,device=disk"
    end
    defaults['cpu']  = 'host-passthrough'
    defaults['boot'] = 'hd,menu=on'
    defaults['import'] = true if !values['type'].to_s.match(/packer/) && values['action'].to_s.match(/create/)
    defaults['rootdisk'] = '/dev/vda'
  end
  [values, defaults]
end

# Reset method defaults

def reset_method_defaults(values, defaults)
  defaults['method'] = 'ci' if values['vm'].to_s.match(/kvm/)
  case values['method']
  when /ai/
    defaults['size'] = if values['type'].to_s.match(/packer/)
                         '20G'
                       else
                         'large'
                       end
  when /pe/
    defaults['size'] = if values['type'].to_s.match(/packer/)
                         '20G'
                       else
                         '500'
                       end
  when /ps/
    defaults['software'] = 'openssh-server'
    defaults['language'] = 'en'
  end
  case values['service']
  when /win/
    defaults['size'] = '500'
  when /ubuntu/
    defaults['mirror']    = "#{defaults['country'].to_s.downcase}.archive.ubuntu.com"
    defaults['mirrordir'] = '/ubuntu'
    defaults['mirrorurl'] = defaults['mirror'].to_s + defaults['mirrordir'].to_s
    defaults['adminuid']  = '1000'
    defaults['admingid']  = '1000'
    defaults['languge']   = 'en'
    defaults['locale']    = 'en_US.UTF-8'
  when /centos/
    defaults['mirror'] = 'mirror.centos.org'
  when /sl_/
    defaults['mirror'] = 'ftp.scientificlinux.org/linux'
    defaults['epel']   = 'download.fedoraproject.org'
  when /el_/
    defaults['epel']   = 'download.fedoraproject.org'
  end
  case values['vm']
  when /aws/
    defaults['cidr'] = '0.0.0.0/0'
  end
  [values, defaults]
end

# Reset OS defaults

def reset_os_defaults(values, defaults)
  defaults['method'] = 'ci' if values['vm'].to_s.match(/kvm/) && values['file'].to_s.match(/cloudimg/)
  defaults['livecd'] = true if values['service'].to_s.match(/live/) || values['file'].to_s.match(/live/)
  defaults['dhcp'] = if values['ip'].to_s.match(/[0-9]/)
                       false
                     else
                       true
                     end
  defaults['dhcp'] = true if values['vmnetwork'].to_s.match(/nat/) && (values['ip'] == values['empty'])
  defaults['reboot'] = false if values['noreboot'] == true
  values['vm'] = 'aws' if values['type'].to_s.match(/bucket|ami|instance|object|snapshot|stack|cf|cloud|image|key|securitygroup|id|iprule/) && values['dir'] == values['empty'] && values['vm'] == values['empty']
  defaults['timeserver'] = "0.#{defaults['country'].to_s.downcase}.pool.ntp.org"
  [values, defaults]
end

# Reset admin defaults

def reset_admin_defaults(values, defaults)
  if values['os-type'].to_s.match(/win/)
    defaults['adminuser'] = 'Administrator'
    defaults['adminname'] = 'Administrator'
  end
  [values, defaults]
end

# Reset VM defaults

def reset_vm_defaults(values, defaults)
  vm_type = if values['vm'] != values['empty']
              values['vm'].to_s
            else
              defaults['vm'].to_s
            end
  case vm_type
  when /mp|multipass/
    values['vmnic'] = 'eth0' if values['biosdevnames'] == true
    defaults['size']  = '20G'
    defaults['dhcp']  = true
    if defaults['host-os-uname'].to_s.match(/Darwin/)
      defaults['vmnet'] = 'bridge100'
    else
      defaults['vmnet'] = 'mpqemubr0'
      defaults['vmgateway']  = '10.251.24.1'
      defaults['hostonlyip'] = '10.251.24.1'
    end
    defaults['memory']  = '1G'
    defaults['release'] = '20.04'
    defaults['vmnetwork'] = 'hostonly'
    if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 11
      defaults['vmgateway']  = '192.168.64.1'
      defaults['hostonlyip'] = '192.168.64.1'
    else
      defaults['vmgateway']  = '172.16.10.1'
      defaults['hostonlyip'] = '172.16.10.1'
    end
  when /parallels/
    if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      defaults['vmgateway']  = '10.211.55.1'
      defaults['hostonlyip'] = '10.211.55.1'
    else
      defaults['vmgateway']  = '192.168.54.1'
      defaults['hostonlyip'] = '192.168.54.1'
    end
  when /fusion/
    defaults['hwversion'] = get_fusion_version(values)
    if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      if values['vmnetwork'].to_s.match(/nat/)
        defaults['vmgateway']  = '192.168.158.1'
        defaults['hostonlyip'] = '192.168.158.1'
      elsif defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 11
        defaults['vmgateway']  = '192.168.2.1'
        defaults['hostonlyip'] = '192.168.2.1'
      elsif values['vmnetwork'].to_s.match(/bridged/)
        defaults['vmgateway']  = get_ipv4_default_route(values)
        defaults['hostonlyip'] = defaults['hostip']
      else
        defaults['vmgateway']  = '192.168.104.1'
        defaults['hostonlyip'] = '192.168.104.1'
      end
      defaults['vmnet'] = if File.exist?('/usr/local/bin/multipass')
                            'bridge101'
                          else
                            'bridge100'
                          end
    else
      defaults['vmnet'] = 'vmnet1'
    end
  when /kvm/
    defaults['vmnet'] = 'virbr0'
  when /vbox/
    defaults['vmnet'] = 'vboxnet0'
  when /dom/
    defaults['vmnet']  = 'net0'
    defaults['mau']    = '1'
    defaults['memory'] = '1'
    defaults['vmnic']  = 'vnet0'
    defaults['vcpu']   = '8'
    defaults['size']   = '20G'
  when /aws/
    defaults['type'] = 'instance'
    if values['action'].to_s.match(/list/)
      defaults['group']    = 'all'
      defaults['secgroup'] = 'all'
      defaults['key']      = 'all'
      defaults['keypair']  = 'all'
      defaults['stack']    = 'all'
      defaults['awsuser']  = 'ec2-user'
    else
      values['group']      = 'default'
      values['secgroup']   = 'default'
      values['service']    = 'amazon-ebs'
      values['size']       = 't2.micro'
      defaults['importid'] = 'c4d8eabf8db69dbe46bfe0e517100c554f01200b104d59cd408e777ba442a322'
    end
    case values['os-type']
    when /centos/
      defaults['adminuser'] = 'centos'
      defaults['ami']       = "ami-fedafc9d'"
    else
      defaults['adminuser'] = 'ec2-user'
      defaults['ami']       = 'ami-28cff44b'
    end
  else
    defaults['vmnet'] = 'eth0'
  end
  [values, defaults]
end

# Reset type defaults

def reset_type_defaults(values, defaults)
  case values['type']
  when /vcsa/
    defaults['size'] = 'tiny'
  when /packer/
    defaults['sshport'] = if values['vmnetwork'].to_s.match(/hostonly/)
                            '22'
                          elsif values['method'].to_s.match(/vs/)
                            '22'
                          else
                            '2222'
                          end
    defaults['sshportmax'] = defaults['sshport']
    defaults['sshportmin'] = defaults['sshport']
  end
  defaults['size'] = '40G' if values['os-type'].to_s.match(/vmware/)
  values['packersshport'] = '22' if values['vmnetwork'].to_s.match(/hostonly/)
  [values, defaults]
end

# Reset keyname defaults

def reset_keyname_defaults(values, defaults)
  if values['keyname'] == values['empty']
    defaults['keyname'] = if values['name'] != values['empty']
                            if values['region'] != values['empty']
                              "#{values['name']}-#{values['region']}"
                            else
                              "#{values['name']}-#{defaults['region']}"
                            end
                          elsif values['region'] != values['empty']
                            values['region'].to_s
                          else
                            defaults['region'].to_s
                          end
  end
  [values, defaults]
end

# Set some parameter once we have more details

def reset_defaults(values, defaults)
  (values, defaults) = reset_machine_defaults(values, defaults)
  (values, defaults) = reset_os_defaults(values, defaults)
  (values, defaults) = reset_vm_defaults(values, defaults)
  (values, defaults) = reset_type_defaults(values, defaults)
  (values, defaults) = reset_admin_defaults(values, defaults)
  (values, defaults) = reset_kvm_defaults(values, defaults)
  (values, defaults) = reset_method_defaults(values, defaults)
  (values, defaults) = reset_keyname_defaults(values, defaults)
  if values['dryrun'] == true
    defaults['test']     = true
    defaults['download'] = false
  else
    defaults['download'] = true
    defaults['test']     = false
  end
  defaults
end
