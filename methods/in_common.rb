
# Code common to all services

# Set defaults

def set_defaults(options,defaults)
  # Declare OS defaults
  defaults['home'] = ENV['HOME']
  defaults['host-os-name']     = %x[uname].chomp
  defaults['host-os-arch']     = %x[uname -p].chomp
  defaults['host-os-machine']  = %x[uname -m].chomp
  defaults['host-os-uname']    = %x[uname -a].chomp
  defaults['host-os-release']  = %x[uname -r].chomp
  defaults['host-os-packages'] = []
  if defaults['host-os-name'].to_s.match(/Darwin/)
    defaults['host-os-memory'] = %x[system_profiler SPHardwareDataType |grep Memory |awk '{print $2}'].chomp
    defaults['host-os-cpu'] = %x[sysctl hw.ncpu |awk '{print $2}']
    if File.exist?("/usr/local/bin/brew")
      defaults['host-os-packages'] = %x[/usr/local/bin/brew list].split(/\s+|\n/)
    end
  else
    if defaults['host-os-name'].to_s.match(/Linux/)
      if defaults['host-os-uname'].to_s.match(/Ubuntu/)
        defaults['host-os-packages'] = %x[dpkg -l |awk '{print $2}'].split(/\s+|\n/)
      end
      defaults['host-os-memory'] = %x[free -g |grep ^Mem |awk '{print $2}'].chomp
      defaults['host-os-cpu']    = %x[cat /proc/cpuinfo |grep processor |wc -l].chomp
    else
      defaults['host-os-memory'] = "1"
      defaults['host-os-cpu']    = "1"
    end
  end
  if File.exist?("/proc/1/cgroup")
    output = %x[cat /proc/1/cgroup |grep docker]
    if output.match(/docker/)
      defaults['host-os'] = "Docker"
    else
      defaults['host-os'] = defaults['host-os-uname'].to_s
    end
  else
    defaults['host-os'] = defaults['host-os-uname'].to_s
  end
  if defaults['host-os-name'].to_s.match(/SunOS|Darwin|NT/)
    if defaults['host-os-name'].to_s.match(/SunOS/)
      if File.exist?("/etc/release")
        defaults['host-os-revision'] = %x[cat /etc/release |grep Solaris |head -1].chomp.gsub(/^\s+/,"")
      end
      if defaults['host-os-release'].to_s.match(/\./)
        if defaults['host-os-release'].to_s.match(/^5/)
          defaults['host-os-version'] = defaults['host-os-release'].to_s.split(/\./)[1]
        end
        if defaults['host-os-version'].to_s.match(/^11/)
          os_version_string = %x[uname -v].chomp
          if os_version_string.match(/\./)
            defaults['host-os-update'] = os_version_string.split(/\./)[1]
          end
        end
      else
        if defaults['host-os-revision'].to_s.match(/Oracle/)
          defaults['host-os-version'] = defaults['host-os-revision'].to_s.split(/\s+/)[3].split(/\./)[0]
          defaults['host-os-update']  = defaults['host-os-revision'].to_s.split(/\s+/)[3].split(/\./)[1]
        end
      end
    else
      defaults['host-os-version'] = %x[sw_vers |grep ProductVersion |awk '{print $2}'].chomp
    end
  end  
  if defaults['host-os-release'].to_s.match(/\./)
    defaults['host-os-major'] = defaults['host-os-release'].to_s.split(/\./)[0]
    defaults['os-minor']      = defaults['host-os-release'].to_s.split(/\./)[1]
  else
    defaults['host-os-major'] = defaults['host-os-release']
    defaults['os-minor'] = "0"
  end
  # Declare valid defaults
  defaults['valid-acl']     = [ 'private', 'public-read', 'public-read-write',
                                'authenticated-read' ]
  defaults['valid-action']  = [ 'add', 'boot', 'build', 'connect', 'check',
                                'clone', 'create', 'delete', 'deploy', 'download',
                                'export', 'get', 'halt', 'info', 'import', 'list',
                                'migrate', 'shutdown', 'start', 'stop', 'upload',
                                'usage' ]
  defaults['valid-arch']    = [ 'x86_64', 'i386', 'sparc' ]
  defaults['valid-console'] = [ 'text', 'console', 'x11', 'headless', "pty", "vnc" ]
  defaults['valid-format']  = [ 'VMDK', 'RAW', 'VHD' ]
  defaults['valid-method']  = [ 'ks', 'xb', 'vs', 'ai', 'js', 'ps', 'lxc', 'mp',
                                'ay', "ci", 'image', 'ldom', 'cdom', 'gdom' ]
  defaults['valid-mode']    = [ 'client', 'server', 'osx' ]
  defaults['valid-os']      = [ 'Solaris', 'VMware-VMvisor', 'CentOS',
                                'OracleLinux', 'SLES', 'openSUSE', 'NT',
                                'Ubuntu', 'Debian', 'Fedora', 'RHEL', 'SL',
                                'Purity', 'Windows', 'JeOS', 'AMZNL' ]
  defaults['valid-output']  = [ 'text', 'html' ]
  defaults['valid-type']    = [ 'iso', 'flar', 'ova', 'snapshot', 'service',
                                'boot', 'cdrom', 'net', 'disk', 'client', 'dvd',
                                'server', 'ansible', 'vcsa', 'packer', 'docker',
                                'amazon-ebs', 'image', 'ami', 'instance', 'bucket',
                                'acl', 'snapshot', 'key', 'sg', 'dhcp', 'keypair',
                                'ssh', 'stack', 'object', 'cf', 'cloudformation',
                                'public', 'private', 'securitygroup', 'iprule',
                                'pxe', 'nic', 'network' ]
  defaults['valid-target']  = [ 'citrix', 'vmware', 'windows' ]
  # VM related defaults
  if defaults['host-os-arch'].to_s.match(/sparc/)
    if defaults['host-os-major'] = %x[uname -r].split(/\./)[1].to_i > 9
      defaults['valid-vm']       = [ 'zone', 'cdom', 'gdom', 'aws' ]
    end
  else
    case defaults['host-os-name']
    when /not recognised/
      handle_output(options,"Information:\tAt the moment Cygwin is required to run on Windows")
    when /NT/
      defaults['valid-vm'] = [ 'vbox', 'aws', 'vmware', 'fusion', 'multipass' ]
    when /SunOS/
      defaults['valid-vm'] = [ 'vbox', 'zone', 'aws' ]
      defaults['nic']      = %x[dladm show-link |grep phys |grep up |awk '{print $1}'].chomp
      defaults['host-os-platform'] = %x[prtdiag |grep 'System Configuration'].chomp
    when /Linux/
      defaults['valid-vm'] = [ 'vbox', 'lxc', 'docker', 'aws', 'qemu', 'kvm', 'xen', 'fusion', 'vmware', 'multipass' ]
      if File.exist?("/sbin/dmidecode")
        defaults['dmidecode'] = "/sbin/dmidecode"
      else
        defaults['dmidecode'] = "/usr/sbin/dmidecode"
      end
      hv_check = %x[cat /proc/cpuinfo |grep -i hypervisor].downcase
      if hv_check.match(/hyper/)
        defaults['host-os-platform'] = %x[sudo #{defaults['dmidecode']} |grep 'Product Name'].chomp
      else
        defaults['host-os-platform'] = %x[cat /proc/cpuinfo |grep -i "model name" |head -1].chomp
      end
      if File.exist?("/bin/lsb_release")
        defaults['lsb'] = "/bin/lsb_release"
      else
        defaults['lsb'] = "/usr/bin/lsb_release"
      end
      defaults['host-os-uname']   = %x[#{defaults['lsb']} -i -s].chomp
      defaults['host-os-release'] = %x[#{defaults['lsb']} -r -s].chomp
      defaults['host-os-version'] = %x[#{defaults['lsb']} -r -s].chomp.split(".")[0]
    when /Darwin/
      defaults['nic']    = "en0"
      defaults['ovfbin'] = "/Applications/VMware OVF Tool/ovftool"
      defaults['valid-vm'] = [ 'vbox', 'vmware', 'fusion', 'parallels', 'aws', 'docker', 'qemu', 'multipass'  ]
    end
    case defaults['host-os-platform']
    when /VMware/
      if defaults['host-os-name'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
        if options['vmnetwork'].to_s.match(/nat/)
          defaults['vmgateway']  = "192.168.158.1"
          defaults['hostonlyip'] = "192.168.158.1"
        else
          if defaults['host-os-name'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 11
            defaults['vmgateway']  = "192.168.2.1"
            defaults['hostonlyip'] = "192.168.2.1"
          else
            defaults['vmgateway']  = "192.168.104.1"
            defaults['hostonlyip'] = "192.168.104.1"
          end
        end
      else
        defaults['vmgateway']  = "192.168.52.1"
        defaults['hostonlyip'] = "192.168.52.1"
      end
      if defaults['host-os-name'].to_s.match(/Linux/)
        defaults['nic'] = %x[netstat -rn |grep UG].chomp.split()[-1]
      end
    when /VirtualBox/
      defaults['vmgateway']  = "192.168.56.1"
      defaults['hostonlyip'] = "192.168.56.1"
      defaults['nic']        = "eth0"
    when /Parallels/
      if defaults['host-os-name'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
        defaults['vmgateway']  = "10.211.55.1"
        defaults['hostonlyip'] = "10.211.55.1"
      else
        defaults['vmgateway']  = "192.168.54.1"
        defaults['hostonlyip'] = "192.168.54.1"
      end
    else
      defaults['vmgateway']  = "192.168.55.1"
      defaults['hostonlyip'] = "192.168.55.1"
      if defaults['host-os-name'].to_s.match(/Linux/)
        defaults['nic'] = "eth0"
        network_test = %x[ifconfig -a |grep eth0].chomp
        if !network_test.match(/eth0/)
          output = %x[route |grep default]
          defaults['nic'] = output.split(/\s+/)[-1].chomp
        end
      end
    end
    if options['vm'].to_s.match(/kvm/)
      defaults['vmgateway']  = "192.168.122.1"
      defaults['hostonlyip'] = "192.168.122.1"
    end
  end
  # Declare other defaults
  defaults['virtdir'] = ""
  defaults['basedir'] = ""
  if defaults['host-os-name'].match(/Darwin/) && defaults['host-os-major'].to_i > 18
    #defaults['basedir']  = "/System/Volumes/Data"
    #defaults['mountdir'] = '/System/Volumes/Data/cdrom'
    defaults['basedir']  = defaults['home'].to_s+"/Documents/modest"
    defaults['mountdir'] = defaults['home'].to_s+"/Documents/modest/cdrom"
  else
    if options['vm'].to_s.match(/kvm/)
      defaults['virtdir'] = "/var/lib/libvirt/images"
    end
    defaults['mountdir'] = '/cdrom'
  end
  # Set up some volume information
  defaults['auditfs']         = "ext4"
  defaults['auditsize']       = "8192"
  defaults['bootfs']          = "ext4"
  defaults['bootsize']        = "512"
  defaults['bridge']          = "virbr0"
  defaults['homefs']          = "ext4"
  defaults['homesize']        = "8192"
  defaults['localsize']       = "8192"
  defaults['localfs']         = "ext4"
  defaults['localsize']       = "8192"
  defaults['logfs']           = "ext4"
  defaults['logsize']         = "8192"
  defaults['rootfs']          = "ext4"
  defaults['rootsize']        = "8192"
  defaults['scratchfs']       = "ext4"
  defaults['scratchsize']     = "8192"
  defaults['swapfs']          = "linux-swap"
  defaults['swapsize']        = "8192"
  defaults['tmpfs']           = "ext4"
  defaults['tmpsize']         = "8192"
  defaults['usrfs']           = "ext4"
  defaults['usrsize']         = "8192"
  defaults['varfs']           = "ext4"
  defaults['varsize']         = "8192"
  # General defaults
  defaults['acl']             = "private"
  defaults['action']          = "help"
  defaults['aibasedir']       = "/export/auto_install"
  defaults['apacheallow']     = ""
  defaults['arch']            = "x86_64"
  defaults['autoreg']         = "disable"
  defaults['scriptname']      = 'modest'
  defaults['script']          = $0
  defaults['scriptfile']      = Pathname.new(defaults['script'].to_s).realpath
  defaults['scriptdir']       = File.dirname(defaults['scriptfile'].to_s)
  defaults['admingid']        = "200"
  defaults['adminuser']       = "administrator"
  defaults['admingroup']      = "wheel"
  defaults['adminhome']       = "/home/"+defaults['adminuser'].to_s
  defaults['adminname']       = "Sys Admin"
  defaults['adminpassword']   = "P455w0rd"
  defaults['adminuid']        = "200"
  defaults['adminshell']      = "/bin/bash"
  defaults['apachedir']       = '/etc/apache2'
  defaults['aidir']           = defaults['basedir'].to_s+'/export/auto_install'
  defaults['aiport']          = '10081'
  defaults['bename']          = "solaris"
  defaults['backupsuffix']    = ".pre-modest"
  defaults['baserepodir']     = defaults['basedir'].to_s+"/export/repo"
  defaults['biosdevnames']    = true
  defaults['boot']            = "disk"
  defaults['bootsize']        = "512"
  defaults['bucket']          = defaults['scriptname'].to_s+".bucket"
  defaults['check']           = "perms"
  defaults['checksum']        = false
  defaults['cidr']            = "24"
  defaults['clientrootdir']   = defaults['basedir'].to_s+'/export/clients'
  defaults['clientdir']       = defaults['basedir'].to_s+'/export/clients'
  defaults['cluster']         = "SUNWCprog"
  defaults['containertype']   = "ova"
  defaults['controller']      = "sas"
  defaults['console']         = ""
  defaults['copykeys']        = true
  defaults['country']         = 'AU'
  defaults['creds']           = defaults['home'].to_s+"/.aws/credentials"
  defaults['datastore']       = "datastore1"
  defaults['defaults']        = false
  defaults['dhcp']            = false
  defaults['disableautoconf'] = "true"
  defaults['diskmode']        = "thin"
  defaults['domainname']      = "lab.net"
  defaults['download']        = false
  defaults['dpool']           = "dpool"
  defaults['dryrun']          = false
  defaults['empty']           = 'none'
  defaults['environment']     = "en_US.UTF-8"
  defaults['exportdir']       = defaults['basedir'].to_s+"/export/"+defaults['scriptname'].to_s
  defaults['executehost']     = "localhost"
  defaults['files']           = "files"
  defaults['force']           = false
  defaults['format']          = 'VMDK'
  defaults['fusiondir']       = defaults['home'].to_s+"/Virtual Machines"
  defaults['gatewaynode']     = "1"
  defaults['gateway']         = ""
  defaults['graphics']        = "none"
  defaults['grant']           = "CanonicalUser"
  defaults['hardwareversion'] = "8"
  defaults['headless']        = false
  defaults['hostname']        = %x['hostname'].chomp
  defaults['hostnet']         = "192.168.1.0"
  defaults['hosts']           = "files dns"
  defaults['hostip']          = get_my_ip(defaults)
  defaults['httpport']        = "8888"
  defaults['imagedir']        = defaults['basedir'].to_s+'/export/images'
  defaults['install']         = "initial_install"
  defaults['instances']       = "1,1"
  defaults['ipfamily']        = "ipv4"
  defaults['isodir']          = defaults['basedir'].to_s+'/export/isos'
  defaults['region']          = "ap-southeast-2"
  if options['vm']
    if options['vm'].to_s.match(/aws/)
      defaults['keydir'] = ENV['HOME'].to_s+"/.ssh/aws"
    else
      defaults['keydir'] = ENV['HOME'].to_s+"/.ssh"
    end
    if options['vm'].to_s.match(/kvm/)
      defaults['method'] = "ci"
    end
  end
  if options['clientnic'].to_s.match(/[0-9]/)
    defaults['vmnic'] = options['clientnic'].to_s
  else
    if options['vm'] == "kvm"
      defaults['vmnic'] = "enp1s0"
    else
      defaults['vmnic'] = "eth0"
    end
  end
  defaults['keyboard']       = "US"
  defaults['keyfile']        = "none"
  defaults['keymap']         = "US-English"
  defaults['kvmgroup']       = "kvm"
  defaults['kvmgid']         = get_group_gid(options,defaults['kvmgroup'].to_s)
  defaults['language']       = "en_US"
  defaults['livecd']         = false
  defaults['ldomdir']        = '/ldoms'
  defaults['local']          = "local"
  defaults['locale']         = "en_US"
  defaults['lxcdir']         = "/export/clients/lxc"
  defaults['lxcimagedir']    = "/export/clients/lxc/images"
  defaults['mac']            = ""
  defaults['maasadmin']      = "root"
  defaults['maasemail']      = defaults['maasadmin'].to_s+"@"+defaults['hostip'].to_s
  defaults['maaspassword']   = defaults['adminpassword'].to_s
  defaults['manifest']       = "modest"
  defaults['masked']         = false
  defaults['memory']         = "2048"
  defaults['vcpus']          = "1"
  defaults['mirror']         = defaults['country'].to_s.downcase+'.archive.ubuntu.com'
  defaults['mirrordir']      = "/ubuntu"
  defaults['mirrorurl']      = defaults['mirror'].to_s+defaults['mirrordir'].to_s
  defaults['mirrordisk']     = false   
  defaults['mode']           = 'client'
  defaults['nameserver']     = "8.8.8.8"
  defaults['nameservice']    = "none"
  defaults['net']            = "net0"
  defaults['netmask']        = "255.255.255.0"
  defaults['nfs4domain']     = "dynamic"
  defaults['nokeys']         = false
  defaults['nomirror']       = true
  defaults['nosuffix']       = false
  defaults['noreboot']       = false
  defaults['reboot']         = true
  defaults['novncdir']       = "/usr/local/novnc"
  defaults['number']         = "1,1"
  defaults['object']         = "uploads"
  defaults['opencsw']        = 'http://mirror.opencsw.org/opencsw/'
  defaults['organisation']   = "Multi OS Deployment Server"
  defaults['output']         = 'text'
  defaults['ovftarurl']      = "https://github.com/richardatlateralblast/ottar/blob/master/vmware-ovftools.tar.gz?raw=true"
  defaults['ovfdmgurl']      = "https://github.com/richardatlateralblast/ottar/blob/master/VMware-ovftool-4.1.0-2459827-mac.x64.dmg?raw=true"
  defaults['packerversion']  = "1.7.2"
  defaults['pkgdir']         = defaults['basedir'].to_s+'/export/pkgs'
  defaults['proto']          = "tcp"
  defaults['publisherhost']  = defaults['hostip'].to_s
  defaults['publisherport']  = "10081"
  defaults['biostype']       = "bios"
  defaults['repodir']        = defaults['basedir'].to_s+'/export/repo'
  defaults['rpoolname']      = 'rpool'
  defaults['rootdisk']       = "/dev/sda"
  defaults['rootpassword']   = "P455w0rd"
  defaults['rpm2cpiobin']    = ""
  defaults['search']         = ""
  defaults['security']       = "none"
  defaults['server']         = defaults['hostip'].to_s
  defaults['severadmin']     = "root"
  defaults['servernetwork']  = "vmnetwork1"
  defaults['serverpassword'] = "P455w0rd"
  defaults['serversize']     = "small"
  defaults['serial']         = false
  defaults['sitename']       = defaults['domainname'].to_s.split(".")[0]
  defaults['size']           = "100G"
  defaults['slice']          = "8192"
  defaults['sharedfolder']   = defaults['home'].to_s+"/Documents"
  defaults['sharedmount']    = "/mnt"
  defaults['splitvols']      = false
  defaults['sshconfig']      = defaults['home'].to_s+"/.ssh/config"
  defaults['sshenadble']     = "true"
  defaults['sshkeydir']      = defaults['home'].to_s+"/.ssh"
  defaults['sshkeyfile']     = defaults['home'].to_s+"/.ssh/id_rsa.pub"
  defaults['sshport']        = "22"
  defaults['sshtimeout']     = "20m"
  defaults['sudo']           = true
  defaults['sudogroup']      = "sudo"
  defaults['suffix']         = defaults['scriptname'].to_s
  defaults['systemlocale']   = "C"
  defaults['target']         = "vmware"
  defaults['terminal']       = "sun"
  defaults['techpreview']    = false
  defaults['text']           = false
  defaults['timeserver']     = "0."+defaults['country'].to_s.downcase+".pool.ntp.org"
  defaults['tmpdir']         = "/tmp"
  defaults['tftpdir']        = "/etc/netboot"
  defaults['thindiskmode']   = "true"
  defaults['time']           = "Eastern Standard Time"
  defaults['timezone']       = "Australia/Victoria"
  defaults['trunk']          = 'stable'
  defaults['ubuntumirror']   = "mirror.aarnet.edu.au"
  defaults['ubuntudir']      = "/ubuntu"
  defaults['uid']            = %x[/usr/bin/id -u].chomp
  defaults['uid']            = Integer(defaults['uid'])
  defaults['uuid']           = ""
  defaults['unmasked']       = false
  defaults['usemirror']      = false
  defaults['user']           = %x[whoami].chomp
  defaults['utc']            = "off"
  defaults['vboxadditions']  = "/Applications/VirtualBox.app//Contents/MacOS/VBoxGuestAdditions.iso"
  defaults['vboxmanage']     = "/usr/local/bin/VBoxManage"
  defaults['vcpu']           = "1"
  defaults['vgname']         = "vg01"
  defaults['vnc']            = true
  defaults['verbose']        = "false"
  defaults['vmntools']       = false
  defaults['vmnetwork']      = "hostonly"
  defaults['vncpassword']    = "P455w0rd"
#  defaults['vncport']        = "5961"
  defaults['vncport']        = "5900"
  defaults['vlanid']         = "0"
#  defaults['vm']              = "vbox"
  defaults['vmnet']          = "vboxnet0"
  defaults['vmnetdhcp']      = false
  defaults['vmnetwork']      = "hostonly"
  defaults['vmtools']        = "disable"
  defaults['vswitch']        = "vSwitch0"
  defaults['wikidir']        = defaults['scriptdir'].to_s+"/"+File.basename(defaults['script'],".rb")+".wiki"
  defaults['wikiurl']        = "https://github.com/lateralblast/mode.wiki.git"
  defaults['workdir']        = defaults['home'].to_s+"/.modest"
  defaults['backupdir']      = defaults['workdir'].to_s+"/backup"
  defaults['bindir']         = defaults['workdir'].to_s+"/bin"
  defaults['rpmdir']         = defaults['workdir'].to_s+"/rpms"
  defaults['zonedir']        = '/zones'
  defaults['yes']            = false
  defaults['zpoolname']      = 'rpool'
  if options['vm'].to_s.match(/kvm/)
    defaults['cdrom']           = "none"
    defaults['install']         = "none"
    defaults['controller']      = "none"
    defaults['container']       = false
    defaults['destroy-on-exit'] = false
    defaults['check']           = false
  end
  return defaults
end

# Set some parameter once we have more details

def reset_defaults(options,defaults)
  if options['ip'].to_s.match(/[0-9]/)
    defaults['dhcp'] = false
  else
    defaults['dhcp'] = true
  end
  if options['os-type'].to_s.match(/win/)
    defaults['adminuser'] = "Administrator"
    defaults['adminname'] = "Administrator"
  end
  if options['vm'].to_s.match(/kvm/)
    defaults['imagedir']  = "/var/lib/libvirt/images"
    defaults['console']   = "pty,target_type=virtio"
    defaults['mac']       = generate_mac_address(options)
    defaults['network']   = "bridge=virbr0"
    defaults['features']  = "kvm_hidden=on"
    defaults['vmnetwork'] = "hostonly"
    if defaults['host-os-arch'].to_s.match(/^x/) 
      defaults['machine'] = "q35"
      defaults['arch']    = "x86_64"
    end
    if not options['disk']
      defaults['disk'] = "path="+defaults['imagedir'].to_s+"/"+options['name'].to_s+"-seed.qcow2 path="+defaults['imagedir'].to_s+".qcow2,device=disk"
    end
    defaults['cpu']  = "host-passthrough"
    defaults['boot'] = "hd,menu=on"
    if !options['type'].to_s.match(/packer/) && options['action'].to_s.match(/create/)
      defaults['import'] = true
    end
    defaults['rootdisk'] = "/dev/vda"
  end
  if options['vmnetwork'].to_s.match(/nat/)
    if options['ip'] == options['empty']
      defaults['dhcp'] = true
    end
  end
  if options['noreboot'] == true
    defaults['reboot'] = false
  end
  if options['type'].to_s.match(/bucket|ami|instance|object|snapshot|stack|cf|cloud|image|key|securitygroup|id|iprule/) && options['dir'] == options['empty'] && options['vm'] == options['empty']
    options['vm'] = "aws"
  end
  defaults['timeserver'] = "0."+defaults['country'].to_s.downcase+".pool.ntp.org"
  if options['vm']
    vm_type = options['vm']
  else
    vm_type = defaults['vm']
  end
  case vm_type
  when /mp|multipass/
    defaults['dhcp'] = true
    defaults['vmgateway']  = "192.168.64.1"
    defaults['hostonlyip'] = "192.168.64.1"
  when /parallels/
    if defaults['host-os-name'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      defaults['vmgateway']  = "10.211.55.1"
      defaults['hostonlyip'] = "10.211.55.1"
    else
      defaults['vmgateway']  = "192.168.54.1"
      defaults['hostonlyip'] = "192.168.54.1"
    end
  when /fusion/
    if defaults['host-os-name'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      if options['vmnetwork'].to_s.match(/nat/)
        defaults['vmgateway']  = "192.168.158.1"
        defaults['hostonlyip'] = "192.168.158.1"
      else
        if defaults['host-os-name'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 11
          defaults['vmgateway']  = "192.168.2.1"
          defaults['hostonlyip'] = "192.168.2.1"
        else
          defaults['vmgateway']  = "192.168.104.1"
          defaults['hostonlyip'] = "192.168.104.1"
        end
      end
      defaults['vmnet'] = "bridge100"
    else
      defaults['vmnet'] = "vmnet1"
    end
  when /kvm/
    defaults['vmnet'] = "virbr0"
  when /vbox/
    defaults['vmnet'] = "vboxnet0"
  when /mp|multipass/
    defaults['size']   = "20G"
    defaults['memory'] = "1G"
  when /dom/
    defaults['vmnet']  = "net0"
    defaults['mau']    = "1"
    defaults['memory'] = "1"
    defaults['vmnic']  = "vnet0"
    defaults['vcpu']   = "8"
    defaults['size']   = "20G"
  when /aws/
    defaults['type'] = "instance"
    if options['action'].to_s.match(/list/)
      defaults['group']    = "all"
      defaults['secgroup'] = "all"
      defaults['key']      = "all"
      defaults['keypair']  = "all"
      defaults['stack']    = "all"
      defaults['awsuser']  = "ec2-user"
    else
      options['group']     = "default"
      options['secgroup']  = "default"
      options['service']   = "amazon-ebs"
      options['size']      = "t2.micro"
      defaults['importid'] = "c4d8eabf8db69dbe46bfe0e517100c554f01200b104d59cd408e777ba442a322"
    end
    case options['os-type']
    when /centos/
      defaults['adminuser'] = "centos"
      defaults['ami']       = "ami-fedafc9d'"
    else
      defaults['adminuser'] = "ec2-user"
      defaults['ami']       = "ami-28cff44b"
    end
  else
    defaults['vmnet'] = "eth0"
  end
  case options['type']
  when /vcsa/
    defaults['size'] = "tiny"
  when /packer/
    if options['method'].to_s.match(/vs/)
      defaults['sshport'] = "22"
    else
      defaults['sshport'] = "2222"
    end
  end
  case options['method']
  when /ai/
    if options['type'].to_s.match(/packer/)
      defaults['size'] = "20G"
    else
      defaults['size'] = "large"
    end
  when /pe/
    if options['type'].to_s.match(/packer/)
      defaults['size'] = "20G"
    else
      defaults['size'] = "500"
    end
  when /ps/
    defaults['software'] = "openssh-server"
    defaults['language'] = "en"
  end
  case options['service']
  when /win/
    defaults['size'] = "500"
  when /ubuntu/
    defaults['mirror']    = defaults['country'].to_s.downcase+".archive.ubuntu.com"
    defaults['mirrordir'] = "/ubuntu"
    defaults['mirrorurl'] = defaults['mirror'].to_s+defaults['mirrordir'].to_s
    defaults['adminuid']  = "1000"
    defaults['admingid']  = "1000"
    defaults['languge']   = "en"
    defaults['locale']    = "en_US.UTF-8"
  when /centos/
    defaults['mirror'] = "mirror.centos.org"
  when /sl_/
    defaults['mirror'] = "ftp.scientificlinux.org/linux"
    defaults['epel']   = "download.fedoraproject.org"
  when /el_/
    defaults['epel']   = "download.fedoraproject.org"
  end
  case options['vm']
  when /aws/
    defaults['cidr'] = "0.0.0.0/0"
  end
  if options['os-type'].to_s.match(/vmware/)
    defaults['size'] = "40G"
  end
  if options['test'] == true
    defaults['test']     = true
    defaults['download'] = false
  else
    defaults['download'] = true
    defaults['test']     = false
  end
  if options['keyname'] == options['empty']
    if options['name'] != options['empty']
      if options['region'] != options['empty']
        defaults['keyname'] = options['name'].to_s+"-"+options['region'].to_s
      else
        defaults['keyname'] = options['name'].to_s+"-"+defaults['region'].to_s
      end
    else
      if options['region'] != options['empty']
        defaults['keyname'] = options['region'].to_s
      else
        defaults['keyname'] = defaults['region'].to_s
      end
    end
  end
  return defaults
end

# Clean up options

def cleanup_options(options,defaults)
  options['host-os-packages'] = defaults['host-os-packages']
  if options['vm'].to_s.match(/parallels/)
    options['vmapp'] = "Parallels Desktop"
  end
  if options['noreboot'] == true
    options['reboot'] = false
  end
  # Backward compatibility for old --client switch
  if options['client'] && options['client'] != options['empty']
    options['name'] = options['client'].to_s
  end
  # Handle OS option
  if options['os-type'] != options['empty']
    options['os-type'] = options['os-type'].to_s.downcase
    options['os-type'] = options['os-type'].gsub(/^win$/,"windows")
    options['os-type'] = options['os-type'].gsub(/^sol$/,"solaris")
  end
  # Some clean up of parameters
  if options['method'] != options['empty']
    options['method'] = options['method'].to_s.downcase
    options['method'] = options['method'].to_s.gsub(/kickstart/,"js")
    options['method'] = options['method'].to_s.gsub(/preseed/,"ps")
    options['method'] = options['method'].to_s.gsub(/jumpstart/,"js")
    options['method'] = options['method'].to_s.gsub(/autoyast/,"ay")
    options['method'] = options['method'].to_s.gsub(/vsphere|esx/,"vs")
  end
  # Handle OS switch
  if options['os-type'] != options['empty']
    options['os-type'] = options['os-type'].to_s.downcase
    options['os-type'] = options['os-type'].to_s.gsub(/windows/,"win")
    options['os-type'] = options['os-type'].to_s.gsub(/scientificlinux|scientific/,"sl")
    options['os-type'] = options['os-type'].to_s.gsub(/oel/,"oraclelinux")
    options['os-type'] = options['os-type'].to_s.gsub(/esx|esxi|vsphere/,"vmware")
    options['os-type'] = options['os-type'].to_s.gsub(/^suse$/,"opensuse")
    options['os-type'] = options['os-type'].to_s.gsub(/solaris/,"sol")
    options['os-type'] = options['os-type'].to_s.gsub(/redhat/,"rhel")
  end
  # Handle VMware Workstation
  if options['vm'].to_s.match(/vmware|workstation/)
    options['vm'] = "fusion"
  end
  # Handle keys
  if options['nokeys'] == true
    options['copykeys'] = false
  else
    options['copykeys'] = true
  end
  # Handle port switch
  if options['ports'] != options['empty']
    options['from'] = options['ports'].to_s
    options['to']   = options['ports'].to_s
  end
  return options
end

# Set SSH port

def set_ssh_port(options)
  case options['type']
  when /packer/
    if options['method'].to_s.match(/vs/)
      options['sshport'] = "22"
    else
      options['sshport'] = "2222"
    end
  end
  return options
end

# Set up some global variables/defaults

def set_global_vars(options)
  $q_struct                  = {}
  $q_order                   = []
  options['backupdir']       = ""
  $openssh_win_url           = "http://www.mls-software.com/files/setupssh-7.2p2-1-v1.exe"
  $openbsd_base_url          = "http://ftp.openbsd.org/pub/OpenBSD"
  $centos_rpm_base_url       = "http://"+$local_centos_mirror+"/centos"
  $default_options           = ""
  options['size']            = "500"
  options['stdout']          = []
  $default_aws_centos_ami    = "ami-fedafc9d"

  # Some general defaults

  # New defaults (cleaning up after commandline handling cleanup)

  $default_aws_admin      = "ec2-user"


  # Docker server defaulta

  $docker_host_base_dir   = options['exportdir']+"/docker"
  $docker_host_file_dir   = $docker_host_base_dir+"/"+options['scriptname']
  $docker_host_tftp_dir   = options['exportdir']+"/tftpboot"

  # OS specific defaults

  options['nic'] = "net0"

  # VMware Fusion Global variables

  options['vmrun'] = ""
  options['vmapp'] = ""

  # Declare some package versions

  $vagrant_version = "1.8.1"

  # Set some global OS types

  if options['verbose'] == true
    handle_output(options,"Information:\tFound OS #{options['host-os-name']}")
    handle_output(options,"Information:\tFound Architecture #{options['host-os-arch']}")
    handle_output(options,"Information:\tFound Machine #{options['host-os-machine']}")
  end
  if options['host-os-name'].to_s.match(/SunOS|Darwin|NT/)
    options['host-os-uname'] = %x[uname -a].chomp
    options['host-os-release']  = %x[uname -r].chomp
    if options['host-os-name'].to_s.match(/SunOS/)
      options['host-os-version'] = options['host-os-release'].to_s.split(/\./)[1]
      $os_rev = options['host-os-release'].split(/\./)[1]
    else
      options['host-os-version'] = options['host-os-release'].to_s.split(/\./)[0]
      if File.exist?("/et/release")
        $os_rev = %x[cat /etc/release |grep Solaris |head -1].chomp
        if $os_rev.match(/Oracle/)
          options['host-os-version'] = $os_rev.split(/\s+/)[3].split(/\./)[1]
        end
      end
    end
    if options['host-os-release'].match(/5\.11/) && options['host-os-name'].to_s.match(/SunOS/)
      options['update'] = %x[uname -v].chomp
      options['nic']    = "net0"
    end
    return options
  end
end

# Get architecture from model

def get_arch_from_model(options)
  if options['model'].to_s.to_lower.match(/^t/)
    options['arch'] = "sun4v"
  else
    options['arch'] = "sun4u"
  end
  return options
end

# Set hostonly information

def set_hostonly_info(options)
  host_ip        = get_my_ip(options)
  host_subnet    = host_ip.split(".")[2] 
  install_subnet = options['ip'].split(".")[2] 
  hostonly_base  = "192.168"
  case options['vm']
  when /vmware|vmx|fusion/
    if options['host-os-name'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10
      if options['vmnetwork'].to_s.match(/nat/)
        hostonly_subnet = "158"
      else
        if options['host-os-name'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 11
          hostonly_subnet = "2"
        else
          hostonly_subnet = "104"
        end
      end
    else
      hostonly_subnet = "52"
    end
  when /parallels/
    hostonly_base  = "10.211"
    if options['host-os-name'].to_s.match(/Darwin/) && options['host-os-version'].to_i > 10
      hostonly_subnet      = "55"
    else
      hostonly_subnet      = "54"
    end
  when /vbox|virtualbox/
    hostonly_subnet      = "56"
  when /kvm/
    hostonly_subnet      = "122"
  else
    if not options['vm'] == options['empty']
      hostonly_subnet      = "58"
    end
  end
  if hostonly_subnet == host_subnet
    output = "Warning:\tHost and Hostonly network are the same"
    handle_output(options,output)
    hostonly_subnet = host_subnet.to_i+10
    hostonly_subnet = hostonly_subnet.to_s
    output = "Information:\tChanging hostonly network to "+hostonly_base+"."+hostonly_subnet+".0"
    handle_output(options,output)
    options['force'] = true
  end
  if install_subnet == host_subnet
    if options['dhcp'] == false
      output = "Warning:\tHost and client network are the same"
      handle_output(options,output)
      install_subnet = host_subnet.to_i+10
      install_subnet = install_subnet.to_s
      options['ip'] = options['ip'].split(".")[0]+"."+options['ip'].split(".")[1]+"."+install_subnet+"."+options['ip'].split(".")[3]
      output = "Information:\tChanging Client IP to "+hostonly_base+"."+hostonly_subnet+".0"
      handle_output(options,output)
      options['force'] = true
    end
  end
  options['vmgateway']  = hostonly_base+"."+hostonly_subnet+".1"
  options['hostonlyip'] = hostonly_base+"."+hostonly_subnet+".1"
  options['hostonlyip'] = hostonly_base+"."+hostonly_subnet+".1"
  options['ip']         = hostonly_base+"."+hostonly_subnet+".101"
  options = check_vm_network(options)
  return options
end

# Get my IP - Useful when running in server mode

def get_my_ip(options)
  message = "Information:\tDetermining IP of local machine"
  if !options['host-os-name'].to_s.match(/[a-z]/)
   options['host-os-name'] = %x[uname]
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    command = "ipconfig getifaddr en0"
  else
    if options['host-os-name'].to_s.match(/SunOS/)
      command = "/usr/sbin/ifconfig -a | awk \"BEGIN { count=0; } { if ( \\\$1 ~ /inet/ ) { count++; if( count==2 ) { print \\\$2; } } }\""
    else
      if options['vm'].to_s == "kvm"
        command = "hostname -I |awk \"{print \\\$2}\""
      else
        command = "hostname -I |awk \"{print \\\$1}\""
      end
    end
  end
  output = execute_command(options,message,command)
  output = output.chomp
  output = output.strip
  output = output.gsub(/\s+|\n/,"")
  output = output.strip
  return output
end

# Get the NIC name from the service name - Now trying to use biosdevname=0 everywhere

def get_nic_name_from_install_service(options)
  nic_name = "eth0"
#  case options['service']
#  when /ubuntu_18/
#    if options['vm'].to_s.match(/vbox/)
#      nic_name = "enp0s3"
#    else
#      if options['vm'].to_s.match(/kvm/)
#        nic_name = "ens3"
#      else
#        nic_name = "eth0"
#      end
#    end
#  when /rhel_7|centos_7|ubuntu/
#    nic_name = "enp0s3"
#  end
  return nic_name
end

# Calculate CIDR

def netmask_to_cidr(netmask)
  cidr = Integer(32-Math.log2((IPAddr.new(netmask,Socket::AF_INET).to_i^0xffffffff)+1))
  return cidr
end

# options['cidr'] = netmask_to_cidr(options['netmask'])

# Code to run on quiting

def quit(options)
  if options['output'].to_s.match(/html/)
    options['stdout'].push("</body>")
    options['stdout'].push("</html>")
    puts options['stdout'].join("\n")
  end
  exit
end

# Get valid switches and put in an array

def get_valid_options()
  file_array  = IO.readlines $0
  option_list = file_array.grep(/\['--/)
  return option_list
end

# Handle IP

def single_install_ip(options)
  if options['ip'].to_s.match(/\,/)
    install_ip = options['ip'].to_s.split(/\,/)[0]
  else
    install_ip = options['ip'].to_s
  end
  return install_ip
end

# Print script usage information

def print_help(options)
  switches     = []
  long_switch  = ""
  short_switch = ""
  help_info    = ""
  handle_output(options,"")
  handle_output(options,"Usage: #{options['script']}")
  handle_output(options,"")
  option_list = get_valid_options()
  option_list.each do |line|
    if not line.match(/file_array/)
      help_info    = line.split(/# /)[1]
      switches     = line.split(/,/)
      long_switch  = switches[0].gsub(/\[/,"").gsub(/\s+/,"")
      short_switch = switches[1].gsub(/\s+/,"")
      if short_switch.match(/REQ|BOOL/)
        short_switch = ""
      end
      if long_switch.gsub(/\s+/,"").length < 7
        handle_output(options,"#{long_switch},\t\t\t#{short_switch}\t#{help_info}")
      else
        if long_switch.gsub(/\s+/,"").length < 15
          handle_output(options,"#{long_switch},\t\t#{short_switch}\t#{help_info}")
        else
          handle_output(options,"#{long_switch},\t#{short_switch}\t#{help_info}")
        end
      end
    end
  end
  handle_output(options,"")
  return
end

# Output if verbose flag set

def verbose_output(options,text)
  if options['verbose'] == true
    options = handle_output(options,text)
  end
  return options
end

# Handle output

def handle_output(options,text)
  if options['output'].to_s.match(/html/)
    if text == ""
      text = "<br>"
    end
  end
  if options['output'].to_s.match(/text/)
    puts text
  end
  #options['stdout'].push(text)
  return options
end

# HTML header

def html_header(pipe,title)
  pipe.push("<html>")
  pipe.push("<header>")
  pipe.push("<title>")
  pipe.push(title)
  pipe.push("</title>")
  pipe.push("</header>")
  pipe.push("<body>")
  return pipe
end

# HTML footer

def html_footer(pipe)
  pipe.push("</body>")
  pipe.push("</html>")
  return pipe
end

# Get version

def get_version()
  file_array = IO.readlines $0
  version    = file_array.grep(/^# Version/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  packager   = file_array.grep(/^# Packager/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  name       = file_array.grep(/^# Name/)[0].split(":")[1].gsub(/^\s+/,'').chomp
  return version,packager,name
end

# Print script version information

def print_version(options)
  (version,packager,name) = get_version()
  handle_output(options,"#{name} v. #{version} #{packager}")
  return
end

# Set file perms

def set_file_perms(file_name,file_perms)
  message = "Information:\tSetting permissions on file '#{file_name}' to '#{file_perms}'"
  command = "chmod #{file_perms} \"#{file_name}\""
  execute_command(options,message,command)
  return
end

# Write array to file

def write_array_to_file(options,file_array,file_name,file_mode)
  dir_name = Pathname.new(file_name).dirname
  if !Dir.exist?(dir_name)
    FileUtils.mkpath(dir_name)
  end
  if file_mode.match(/a/)
    file_mode = "a"
  else
    file_mode = "w"
  end
  file = File.open(file_name,file_mode)
  file_array.each do |line|
    if not line.match(/\n/)
      line = line+"\n"
    end
    file.write(line)
  end
  file.close
  print_contents_of_file(options,"",file_name)
  return
end

# Get SSH config

def get_user_ssh_config(options)
  user_ssh_config = ConfigFile.new
  if options['ip'].to_s.match(/[0-9]/)
    host_list = user_ssh_config.search(/#{options['id']}/)
  end
  if options['id'].to_s.match(/[0-9]/)
    host_list = user_ssh_config.search(/#{options['ip']}/)
  end
  if options['name'].to_s.match(/[0-9]|[a-z]/)
    host_list = user_ssh_config.search(/#{options['name']}/)
  end
  if not host_list
    host_list = "none"
  else
    if not host_list.match(/[A-Z]|[a-z]|[0-9]/)
      host_list = "none"
    end
  end
  return host_list
end


# List hosts in SSH config

def list_user_ssh_config(options)
  host_list = get_user_ssh_config(options)
  if not host_list == options['empty']
    handle_output(host_list)
  end
  return
end

# Update SSH config

def update_user_ssh_config(options)
  host_list   = get_user_ssh_config(options)
  if host_list == options['empty']
    host_string = "Host "
    ssh_config  = options['sshconfig']
    if options['name'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      host_string = host_string+" "+options['name']
    end
    if options['id'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      host_string = host_string+" "+options['id']
    end
    if not File.exist?(ssh_config)
      file = File.open(ssh_config,"w")
    else
      file = File.open(ssh_config,"a")
    end
    file.write(host_string+"\n")
    if options['sshkeyfile'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      file.write("    IdentityFile "+options['sshkeyfile']+"\n")
    end
    if options['adminuser'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      file.write("    User "+options['adminuser']+"\n")
    end
    if options['ip'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      file.write("    HostName "+options['ip']+"\n")
    end
    file.close
  end
  return
end

# Remove SSH config

def delete_user_ssh_config(options)
  host_list   = get_user_ssh_config(options)
  if not host_list == options['empty']
    host_info  = host_list.split(/\n/)[0].chomp
    handle_output(options,"Warning:\tRemoving entries for '#{host_info}'")
    ssh_config = options['sshconfig']
    ssh_data   = File.readlines(ssh_config)
    new_data   = []
    found_host = 0
    ssh_data.each do |line|
      if line.match(/^Host/)
        if line.match(/#{options['name']}|#{options['id']}|#{options['ip']}/)
          found_host = true
        else
          found_host = 0
        end
      end
      if found_host == false
        new_data.push(line)
      end
    end
    file = File.open(ssh_config,"w")
    new_data.each do |line|
      file.write(line)
    end
    file.close
  end
  return
end

# Check VNC is installed

def check_vnc_install()
  if not File.directory?(options['novncdir'])
    message = "Information:\tCloning noVNC from "+$novnc_url
    command = "git clone #{$novnc_url}"
    execute_command(options,message,command)
  end
end

# Get Windows default interface name

def get_win_default_if_name()
  message = "Information:\tDeterming default interface name"
  command = "wmic nic where NetConnectionStatus=2 get NetConnectionID |grep -v NetConnectionID |head -1"
  default = execute_command(options,message,command)
  default = default.strip_control_and_extended_characters
  default = default.gsub(/^\s+|\s+$/,"")
  return(default)
end

# Get Windows interface MAC address

def get_win_if_mac(if_name)
  if options['host-os-name'].to_s.match(/NT/) and if_name.match(/\s+/)
    if_name = if_name.split(/\s+/)[0]
    if_name = if_name.gsub(/"/,"")
    if_name = "%"+if_name+"%"
  end
  message = "Information:\tDeterming MAC address for '#{if_name}'"
  command = "wmic nic where \"netconnectionid like '#{if_name}'\" get macaddress"
  nic_mac = execute_command(options,message,command)
  nic_mac = nic_mac.strip_control_and_extended_characters
  nic_mac = nic_mac.split(/\s+/)[1]
  nic_mac = nic_mac.gsub(/^\s+|\s+$/,"")
  return(nic_mac)
end

# Get Windows IP from MAC

def get_win_ip_form_mac(nic_mac)
  message = "Information:\tDeterming IP address from MAC address '#{nic_mac}'"
  command = "wmic nicconfig get macaddress,ipaddress |grep \"#{nic_mac}\""
  host_ip = execute_command(options,message,command)
  host_ip = host_ip.strip_control_and_extended_characters
  host_ip = host_ip.split(/\s+/)[0]
  host_ip = host_ip.split(/"/)[1]
  return host_ip
end

# Get Windows default host IP

def get_win_default_host()
  if_name = get_win_default_if_name
  nic_mac = get_win_if_mac(if_name)
  host_ip = get_win_ip_form_mac(nic_mac)
  return host_ip
end

# Get Windows IP from interface name

def get_win_ip_from_if_name(if_name)
  nic_mac = get_win_if_mac(if_name)
  host_ip = get_win_ip_form_mac(nic_mac)
  return host_ip
end

# Get default host

def get_default_host(options)
  if options['hostip'] == nil
    options['hostip'] = ""
  end
  if !options['hostip'].to_s.match(/[0-9]/)
    if options['host-os-name'].to_s.match(/NT/)
      host_ip = get_win_default_host
    else
      message = "Information:\tDetermining Default host IP"
      case options['host-os-name']
      when /SunOS/
        command = "/usr/sbin/ifconfig -a | awk \"BEGIN { count=0; } { if ( \\\$1 ~ /inet/ ) { count++; if( count==2 ) { print \\\$2; } } }\""
      when /Darwin/
        command = "ifconfig #{options['nic']} |grep inet |grep -v inet6"
      when /Linux/
        command = "ifconfig #{options['nic']} |grep inet |grep -v inet6"
      end
      host_ip = execute_command(options,message,command)
      if host_ip.match(/inet/)
        host_ip = host_ip.gsub(/^\s+/,"").split(/\s+/)[1]
      end
      if host_ip.match(/addr:/)
        host_ip = host_ip.split(/:/)[1].split(/ /)[0]
      end
    end
  else
    host_ip = options['hostip']
  end
  if host_ip
    host_ip = host_ip.strip
  end
  return host_ip
end

# Get default route IP

def get_gw_if_ip(options,gw_if_name)
  if options['host-os-name'].to_s.match(/NT/)
    gw_if_ip = get_win_default_host
  else
    message = "Information:\tGetting IP of default router"
    if options['host-os-name'].to_s.match(/Linux/)
      command = "sudo sh -c \"netstat -rn |grep UG |awk '{print \\\$2}'\""
    else
      command = "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$2}'\""
    end
    gw_if_ip = execute_command(options,message,command)
    gw_if_ip = gw_if_ip.chomp
  end
  return gw_if_ip
end

# Get default route interface

def get_gw_if_name(options)
  if options['host-os-name'].to_s.match(/NT/)
    gw_if_ip = get_win_default_if_name
  else
    message = "Information:\tGetting interface name of default router"
    if options['host-os-name'].to_s.match(/Linux/)
      command = "sudo sh -c \"netstat -rn |grep UG |awk '{print \\\$8}'\""
    else
      if options['host-os-release'].to_s.match(/^19/)
        command = "sudo sh -c \"netstat -rn |grep ^default |grep UGS |tail -1 |awk '{print \\\$4}'\""
      else
        if options['host-os-version'].to_i > 10
          command = "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$4}'\""
        else
          command = "sudo sh -c \"netstat -rn |grep ^default |head -1 |awk '{print \\\$6}'\""
        end
      end
    end
    gw_if_name = execute_command(options,message,command)
    gw_if_name = gw_if_name.chomp
  end
  return gw_if_name
end

# Get interface name for VM networks

def get_vm_if_name(options)
  case options['vm']
  when /parallels/
    if_name = "prlsnet0"
  when /virtualbox|vbox/
    if options['host-os-name'].to_s.match(/NT/)
      if_name = "\"VirtualBox Host-Only Ethernet Adapter\""
    else
      if_name = options['vmnet'].to_s
    end
  when /vmware|fusion/
    if options['host-os-name'].to_s.match(/NT/)
      if_name = "\"VMware Network Adapter VMnet1\""
    else
      if_name = options['vmnet'].to_s
    end
  when /kvm/
    if_name = options['vmnet'].to_s
  end
  return if_name
end

# Set config file locations

def set_local_config(options)
  if options['host-os-name'].to_s.match(/Linux/)
#    options['tftpdir']   = "/var/lib/tftpboot"
    options['tftpdir']   = "/srv/tftp"
    options['dhcpdfile'] = "/etc/dhcp/dhcpd.conf"
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    options['tftpdir']   = "/private/tftpboot"
    options['dhcpdfile'] = "/usr/local/etc/dhcpd.conf"
  end
  if options['host-os'].to_s.match(/Docker/)
    options['tftpdir']   = "/export/tftpboot"
    options['dhcpdfile'] = "/export/etc/dhcpd.conf"
  end
  if options['host-os'].to_s.match(/SunOS/)
    options['tftpdir']   = "/etc/netboot"
    options['dhcpdfile'] = "/etc/inet/dhcpd4.conf"
  end
  return options
end

# Check local configuration
# Create work directory if it doesn't exist
# If not running on Solaris, run in test mode
# Useful for generating client config files

def check_local_config(options)
  # Check packer is installed
  if options['type'].to_s.match(/packer/)
    check_packer_is_installed(options)
  end
  # Check Docker is installed
  if options['type'].to_s.match(/docker/)
    check_docker_is_installed
  end
  if options['host-os'].to_s.downcase.match(/docker/)
    options['type'] = "docker"
    options['mode'] = "server"
  end
  # Set VMware Fusion/Workstation VMs
  if options['vm'].to_s.match(/fusion/)
    options = check_fusion_is_installed(options)
    options = set_vmrun_bin(options)
    options = set_fusion_dir(options)
  end
  # Check base dirs exist
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking base repository directory")
  end
  check_dir_exists(options,options['baserepodir'])
  check_dir_owner(options,options['baserepodir'],options['uid'])
  if options['vm'].to_s.match(/vbox/)
    options = set_vbox_bin(options)
  end
  if options['copykeys'] == true
    check_ssh_keys(options)
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tHome directory #{options['home']}")
  end
  if not options['workdir'].to_s.match(/[a-z,A-Z,0-9]/)
    dir_name = File.basename(options['script'],".*")
    if options['uid'] == false
      options['workdir'] = "/opt/"+dir_name
    else
      options['workdir'] = options['home']+"/."+dir_name
    end
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tSetting work directory to #{options['workdir']}")
  end
  if not options['tmpdir'].match(/[a-z,A-Z,0-9]/)
    options['tmpdir'] = options['workdir']+"/tmp"
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tSetting temporary directory to #{options['workdir']}")
  end
  # Get OS name and set system settings appropriately
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking work directory")
  end
  check_dir_exists(options,options['workdir'])
  check_dir_owner(options,options['workdir'],options['uid'])
  check_dir_exists(options,options['tmpdir'])
  if options['host-os-name'].to_s.match(/Linux/)
    options['host-os-release'] = %x[lsb_release -r |awk '{print $2}'].chomp
  end
  if options['host-os-uname'].match(/Ubuntu/)
    options['lxcdir'] = "/var/lib/lxc"
  end
  options['hostip'] = get_default_host(options)
  if not options['apacheallow'].to_s.match(/[0-9]/)
    if options['hostnet'].to_s.match(/[0-9]/)
      options['apacheallow'] = options['hostip'].to_s.split(/\./)[0..2].join(".")+" "+options['hostnet']
    else
      options['apacheallow'] = options['hostip'].to_s.split(/\./)[0..2].join(".")
    end
  end
  if options['mode'].to_s.match(/server/)
    if options['host-os-name'].to_s.match(/Darwin/)
      options['tftpdir']   = "/private/tftpboot"
      options['dhcpdfile'] = "/usr/local/etc/dhcpd.conf"
    end
    if options['host-os'].match(/Docker/)
      options['tftpdir']   = "/export/tftpboot"
      options['dhcpdfile'] = "/export/etc/dhcpd.conf"
    end
    if options['host-os-name'].to_s.match(/SunOS/) and options['host-os-release'].match(/11/)
      check_dpool(options)
      check_tftpd(options)
      check_local_publisher(options)
      install_sol11_pkg(options,"pkg:/system/boot/network")
      install_sol11_pkg(options,"installadm")
      install_sol11_pkg(options,"lftp")
      check_dir_exists(options,"/etc/netboot")
    end
    if options['host-os-name'].to_s.match(/SunOS/) and not options['host-os-release'].match(/11/)
      check_dir_exists(options,"/tftpboot")
    end
    if options['verbose'] == true
      handle_output(options,"Information:\tSetting apache allow range to #{options['apacheallow']}")
    end
    if options['host-os-name'].to_s.match(/SunOS/)
      if options['host-os-name'].to_s.match(/SunOS/) and options['host-os-release'].match(/11/)
        check_dpool(options)
      end
      check_sol_bind(options)
    end
    if options['host-os-name'].to_s.match(/Linux/)
      install_package(options,"apache2")
      install_package(options,"rpm2cpio")
      install_package(options,"shim")
      install_package(options,"shim-signed")
      options['apachedir'] = "/etc/httpd"
      if options['host-os-uname'].match(/RedHat|CentOS/)
        check_yum_xinetd(options)
        check_yum_tftpd(options)
        check_yum_dhcpd(options)
        check_yum_httpd(options)
        options['tftpdir']   = "/var/lib/tftpboot"
        options['dhcpdfile'] = "/etc/dhcp/dhcpd.conf"
      else
        check_apt_tftpd(options)
        check_apt_dhcpd(options)
        if options['host-os-uname'].to_s.match(/Ubuntu/)
          options['tftpdir']   = "/srv/tftp"
        else
          options['tftpdir']   = "/var/lib/tftpboot"
        end
        options['dhcpdfile'] = "/etc/dhcp/dhcpd.conf"
      end
      check_dhcpd_config(options)
      check_tftpd_config(options)
    end
  else
    if options['host-os-name'].to_s.match(/Linux/)
      options['tftpdir']   = "/var/lib/tftpboot"
      options['dhcpdfile'] = "/etc/dhcp/dhcpd.conf"
    end
    if options['host-os-name'].to_s.match(/Darwin/)
      options['tftpdir']   = "/private/tftpboot"
      options['dhcpdfile'] = "/usr/local/etc/dhcpd.conf"
    end
    if options['host-os'].to_s.match(/Docker/)
      options['tftpdir']   = "/export/tftpboot"
      options['dhcpdfile'] = "/export/etc/dhcpd.conf"
    end
    if options['host-os-name'].to_s.match(/SunOS/) and options['host-os-version'].to_s.match(/11/)
      check_dhcpd_config(options)
      check_tftpd_config(options)
    end
  end
  # If runnning on OS X check we have brew installed
  if options['host-os-name'].to_s.match(/Darwin/)
    if not File.exist?("/usr/local/bin/brew")
      message = "Installing:\tBrew for OS X"
      command = "ruby -e \"$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)\""
      execute_command(options,message,command)
    end
  end
  check_dir_exists(options,options['backupdir'])
  options = install_package(options,"rpm")
  options = install_package(options,"rpm2cpio")
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking work bin directory")
  end
  if File.exist?("/bin/rpm2cpio")
    options['rpm2cpiobin'] = "/bin/rpm2cpio"
  else
    if File.exist?("/usr/bin/rpm2cpio")
      options['rpm2cpiobin'] = "/usr/bin/rpm2cpio"
    else
      if File.exist?("/usr/local/bin/rpm2cpio")
        options['rpm2cpiobin'] = "/usr/local/bin/rpm2cpio"
      else
        if options['host-os-name'].to_s.match(/Darwin/)
          install_brew_pkg(options,"rpm2cpio")
          options['rpm2cpiobin'] = "/usr/local/bin/rpm2cpio"
        else
          bin_dir = options['workdir']+"/bin"
          check_dir_exists(options,bin_dir)
          check_dir_owner(options,bin_dir,options['uid'])
          options['rpm2cpiobin'] = bin_dir+"/rpm2cpio"
        end
      end
    end
  end
  if not File.exist?(options['rpm2cpiobin'])
    if options['download'] == true
      install_package(options,"rpm2cpio")
#      wget_file(options,options['rpm2cpiourl'],options['rpm2cpiobin'])
      if File.exist?(options['rpm2cpiobin'] )
        check_file_owner(options,options['rpm2cpiobin'],options['uid'])
        check_file_executable(options,options['rpm2cpiobin'])
      end
    end
  end
  # Check directory ownerships
  [ options['workdir'], options['bindir'], options['rpmdir'], options['backupdir'] ].each do |test_dir|
    if options['verbose'] == true
      handle_output(options,"Information:\tChecking #{test_dir} directory")
    end
    check_dir_exists(options,test_dir)
    check_dir_owner(options,test_dir,options['uid'])
  end
  check_file_executable(options,options['rpm2cpiobin'])
  return options
end

# Check script is executable

def check_file_executable(options,file_name)
  if File.exist?(file_name)
    if not File.executable?(file_name)
      message = "Information:\tMaking '#{file_name}' executable"
      command = "chmod +x '#{file_name}'"
      execute_command(options,message,command)
    end
  end
  return
end

# Print valid list

def print_valid_list(options,message,valid_list)
  handle_output(options,"")
  handle_output(options,message)
  handle_output(options,"")
  handle_output(options,"Available options:")
  handle_output(options,"")
  valid_list.each do |item|
    handle_output(options,item)
  end
  handle_output(options,"")
  return
end

# Print change log

def print_changelog()
  if File.exist?("changelog")
    changelog = File.readlines("changelog")
    changelog = changelog.reverse
    changelog.each_with_index do |line, index|
      line = line.gsub(/^# /,"")
      if line.match(/^[0-9]/)
        handle_output(line)
        text = changelog[index-1].gsub(/^# /,"")
        handle_output(options,text)
        handle_output(options,"")
      end
    end
  end
  return
end

# Check default dpool

def check_dpool(options)
  message = "Information:\tChecking for alternate pool for LDoms"
  command = "zfs list |grep \"^#{options['dpool']}\""
  output  = execute_command(options,message,command)
  if not output.match(/dpool/)
    options['dpool'] = "rpool"
  end
  return
end

# Copy packages to local packages directory

def download_pkg(remote_file)
  local_file = File.basename(remote_file)
  if not File.exist?(local_file)
    message = "Information:\tFetching "+remote_file+" to "+local_file
    command = "wget #{remote_file} -O #{local_file}"
    execute_command(options,message,command)
  end
  return
end

# Get install type from file

def get_install_type_from_file(options)
  case options['file'].downcase
  when /vcsa/
    options['type'] = "vcsa"
  else
    options['type'] = File.extname(options['file']).downcase.split(/\./)[1]
  end
  return options['type']
end

# Check password

def check_password(install_password)
  if not install_password.match(/[A-Z]/)
    handle_output(options,"Warning:\tPassword does not contain and upper case character")
    quit(options)
  end
  if not install_password.match(/[0-9]/)
    handle_output(options,"Warning:\tPassword does not contain a number")
    quit(options)
  end
  return
end

# Check ovftool is installed

def check_ovftool_exists()
  if options['host-os-name'].to_s.match(/Darwin/)
    check_osx_ovftool()
  end
  return
end

# Detach DMG

def detach_dmg(tmp_dir)
  %x[sudo hdiutil detach "#{tmp_dir}']
  return
end

# Attach DMG

def attach_dmg(pkg_file,app_name)
  tmp_dir = %x[sudo sh -c 'echo Y | hdiutil attach "#{pkg_file}" |tail -1 |cut -f3-'].chomp
  if not tmp_dir.match(/[a-z,A-Z]/)
    tmp_dir = %x[ls -rt /Volumes |grep "#{app_name}" |tail -1].chomp
    tmp_dir = "/Volumes/"+tmp_dir
  end
  if $werbose_mode == true
    handle_output(options,"Information:\tDMG mounted on #{tmp_dir}")
  end
  return tmp_dir
end

# Check OSX ovftool

def check_osx_ovftool()
  options['ovfbin'] = "/Applications/VMware OVF Tool/ovftool"
  if not File.exist?(options['ovfbin'])
    handle_output(options,"Warning:\tOVF Tool not installed")
    ovftool_dmg = options['ovfdmgurl'].split(/\?/)[0]
    ovftool_dmg = File.basename(ovftool_dmg)
    wget_file(options,options['ovfdmgurl'],ovftool_dmg)
    handle_output(options,"Information:\tInstalling OVF Tool")
    app_name = "VMware OVF Tool"
    tmp_dir  = attach_dmg(ovftool_dmg,app_name)
    pkg_file = tmp_dir+"/VMware OVF Tool.pkg"
    message = "Information:\tInstalling package "+pkg_file
    command = "/usr/sbin/installer -pkg #{pkg_bin} -target /"
    execute_command(options,message,command)
    detach_dmg(tmp_dir)
  end
  return
end

# SCP file to remote host

def scp_file(options,local_file,remote_file)
  if options['verbose'] == true
    handle_output(options,"Information:\tCopying file \""+local_file+"\" to \""+options['server']+":"+remote_file+"\"")
  end
  Net::SCP.start(options['server'],options['serveradmin'], :password => options['serverpassword'], :paranoid => false) do |scp|
    scp.upload! local_file, remote_file
  end
  return
end

# Execute SSH command

def execute_ssh_command(options,command)
  if options['verbose'] == true
    handle_output(options,"Information:\tExecuting command \""+command+"\" on server "+options['server'])
  end
  Net::SSH.start(options['server'],options['serveradmin'], :password => options['serverpassword'], :paranoid => false) do |ssh|
    ssh.exec!(command)
  end
  return
end

# Get client config

def get_client_config(options)
  config_files  = []
  options['clientdir']    = ""
  config_prefix = ""
  if options['vm'].to_s.match(/[a-z]/)
    show_vm_config(options)
  else
    options['clientdir'] = get_client_dir(options)
    if options['type'].to_s.match(/packer/) or options['clientdir'].to_s.match(/packer/)
      options['method'] = "packer"
      options['clientdir']     = get_packer_client_dir(options)
    else
      if not options['service'].to_s.match(/[a-z]/)
        options['service'] = get_install_service_from_client_name(options)
      end
      if not options['method'].to_s.match(/[a-z]/)
        options['method']  = get_install_method(options)
      end
    end
    config_prefix = options['clientdir']+"/"+options['name']
    case options['method']
    when /packer/
      config_files[0] = config_prefix+".json"
      config_files[1] = config_prefix+".cfg"
      config_files[2] = config_prefix+"_first_boot.sh"
      config_files[3] = config_prefix+"_post.sh"
      config_files[4] = options['clientdir']+"/Autounattend.xml"
      config_files[5] = options['clientdir']+"/post_install.ps1"
    when /config|cfg|ks|Kickstart/
      config_files[0] = config_prefix+".cfg"
    when /post/
      case method
      when /ps/
        config_files[0] = config_prefix+"_post.sh"
      end
    when /first/
      case method
      when /ps/
        config_files[0] = config_prefix+"_first_boot.sh"
      end
    end
    config_files.each do |config_file|
      if File.exist?(config_file)
        print_contents_of_file(options,"",config_file)
      end
    end
  end
  return
end

# Get client install service for a client

def get_install_service(options)
  options['clientdir'] = get_client_dir(options)
  options['service']   = options['clientdir'].split(/\//)[-2]
  return options['service']
end

# Get install method from service

def get_install_method(options)
  if options['vm'].to_s.match(/mp|multipass/)
    if options['method'] == options['empty']
      options['method'] = "mp"
      return options['method']
    end
  end
  if not options['service'].to_s.match(/[a-z]/)
    options['service'] = get_install_service(options)
  end
  service_dir = options['baserepodir']+"/"+options['service']
  if File.directory?(service_dir) or File.symlink?(service_dir)
    if options['verbose'] == true
      handle_output(options,"Information:\tFound directory #{service_dir}")
      handle_output(options,"Information:\tDetermining service type")
    end
  else
    handle_output(options,"Warning:\tService #{options['service']} does not exist")
  end
  options['method'] = ""
  test_file = service_dir+"/vmware-esx-base-osl.txt"
  if File.exist?(test_file)
    options['method'] = "vs"
  else
    test_file = service_dir+"/repodata"
    if File.exist?(test_file)
      options['method'] = "ks"
    else
      test_dir = service_dir+"/preseed"
      if File.directory?(test_dir)
        options['method'] = "ps"
      end
    end
  end
  return options['method']
end

# Unconfigure a server

def unconfigure_server(options)
  if options['method'] == options['empty']
    options['method'] = get_install_method(options)
  end
  if options['method'].to_s.match(/[a-z]/)
    case options['method']
    when /ai/
      unconfigure_ai_server(options)
    when /ay/
      unconfigure_ay_server(options)
    when /js/
      unconfigure_js_server(options)
    when /ks/
      unconfigure_ks_server(options)
    when /ldom/
      unconfigure_ldom_server(options)
    when /gdom/
      unconfigure_gdom_server(options)
    when /ps/
      unconfigure_ps_server(options)
    when /vs/
      unconfigure_vs_server(options)
    when /xb/
      unconfigure_xb_server(options) 
    end
  else
    handle_output(options,"Warning:\tCould not determine service type for #{options['service']}")
  end
  return
end

# list OS install ISOs

def list_os_isos(options)
  case options['os-type'].to_s
  when /linux/
    if not options['search'].to_s.match(/[a-z]/)
      options['search'] = "CentOS|OracleLinux|SUSE|SLES|SL|Fedora|ubuntu|debian|purity"
    end
  when /sol/
    search_string = "sol"
  when /esx|vmware|vsphere/
    search_string = "VMvisor"
  else
    list_all_isos(options)
    return
  end
  if options['os-type'].to_s.match(/linux/)
    list_linux_isos(options)
  end
  return
end

# List all isos

def list_all_isos(options)
  list_isos(options)
  return
end

# Get install method from service name

def get_install_method_from_service(options)
  case options['service']
  when /vmware/
    options['method'] = "vs"
  when /centos|oel|rhel|fedora|sl/
    options['method'] = "ks"
  when /ubuntu|debian/
    options['method'] = "ps"
  when /suse|sles/
    options['method'] = "ay"
  when /sol_6|sol_7|sol_8|sol_9|sol_10/
    options['method'] = "js"
  when /sol_11/
    options['method'] = "ai"
  end
  return options['method']
end

# Describe file

def describe_file(options)
  options = get_install_service_from_file(options)
  handle_output(options,"")
  handle_output(options,"Install File:\t\t#{options['file']}")
  handle_output(options,"Install Service:\t#{options['service']}")
  handle_output(options,"Install OS:\t\t#{options['os-type']}")
  handle_output(options,"Install Method:\t\t#{options['method']}")
  handle_output(options,"Install Release:\t#{options['release']}")
  handle_output(options,"Install Architecture:\t#{options['arch']}")
  handle_output(options,"Install Label:\t#{options['label']}")
  return
end

# Get install service from ISO file name

def get_install_service_from_file(options)
  service_version    = ""
  options['service'] = ""
  options['service'] = ""
  options['arch']    = ""
  options['release'] = ""
  options['method']  = ""
  options['label']   = ""
  if options['file'].to_s.match(/amd64|x86_64/) || options['vm'].to_s.match(/kvm/)
    options['arch'] = "x86_64"
  else
    options['arch'] = "i386"
  end
  case options['file']
  when /purity/
    options['service'] = "purity"
    options['release'] = options['file'].split(/_/)[1]
    options['arch']    = "x86_64"
    service_version = options['release']+"_"+options['arch']
    options['method']  = "ps"
  when /ubuntu/
    options['service'] = "ubuntu"
    if options['vm'].to_s.match(/kvm/)
      options['os-type'] = "linux"
    else
      options['os-type'] = "ubuntu"
    end
    if options['file'].to_s.match(/cloudimg/)
      options['method']  = "ci"
      options['release'] = options['file'].to_s.split(/-/)[1].split(/\./)[0..1].join(".")
      options['arch']    = options['file'].to_s.split(/-/)[4].split(/\./)[0].gsub(/amd64/,"x86_64")
      service_version    = options['service'].to_s.+"_"+options['release'].to_s.gsub(/\./,"_")+options['arch']+to_s
      options['os-type'] = "linux"
    else
      service_version = options['file'].to_s.split(/-/)[1].gsub(/\./,"_").gsub(/_iso/,"")
      if options['file'].to_s.match(/live/)
        options['method'] = "ci"
        service_version   = service_version+"_live_"+options['arch']
      else
        options['method'] = "ps"
        service_version   = service_version+"_"+options['arch']
      end
      options['release'] = options['file'].to_s.split(/-/)[1].split(/\./)[0..1].join(".")
    end
    if options['release'].to_s.split(".")[0].to_i > 20
      options['release'] = "20.04"
    end
    options['os-variant'] = "ubuntu"+options['release'].to_s
    if options['file'].to_s.match(/live/)
      options['livecd'] = true
    end
  when /purity/
    options['service'] = "purity"
    service_version = options['file'].to_s.split(/_/)[1]
    options['method']  = "ps"
    options['arch']    = "x86_64"
  when /vCenter-Server-Appliance|VCSA/
    options['service'] = "vcsa"
    service_version = options['file'].to_s.split(/-/)[3..4].join(".").gsub(/\./,"_").gsub(/_iso/,"")
    options['method']  = "image"
    options['release'] = options['file'].to_s.split(/-/)[3..4].join(".").gsub(/\.iso/,"")
    options['arch']    = "x86_64"
  when /VMvisor-Installer/
    options['service'] = "vmware"
    options['arch']    = "x86_64"
    service_version = options['file'].to_s.split(/-/)[3].gsub(/\./,"_")+"_"+options['arch']
    options['method']  = "vs"
    options['release'] = options['file'].to_s.split(/-/)[3].gsub(/update/,"")
  when /CentOS/
    options['service'] = "centos"
    service_version = options['file'].to_s.split(/-/)[1..2].join(".").gsub(/\./,"_").gsub(/_iso/,"")
    options['os-type'] = options['service']
    options['method']  = "ks"
    options['release'] = options['file'].to_s.split(/-/)[1]
    if options['release'].to_s.match(/^7/)
      case options['file']
      when /1406/
        options['release'] = "7.0"
      when /1503/
        options['release'] = "7.1"
      when /1511/
        options['release'] = "7.2"
      when /1611/
        options['release'] = "7.3"
      when /1708/
        options['release'] = "7.4"
      when /1804/
        options['release'] = "7.5"
      when /1810/
        options['release'] = "7.6"
      end
      service_version = options['release'].gsub(/\./,"_")+"_"+options['arch']
    end
  when /Fedora-Server/
    options['service'] = "fedora"
    if options['file'].to_s.match(/DVD/)
      service_version = options['file'].split(/-/)[-1].gsub(/\./,"_").gsub(/_iso/,"_")
      service_arch    = options['file'].split(/-/)[-2].gsub(/\./,"_").gsub(/_iso/,"_")
      options['release'] = options['file'].split(/-/)[-1].gsub(/\.iso/,"")
    else
      service_version = options['file'].split(/-/)[-2].gsub(/\./,"_").gsub(/_iso/,"_")
      service_arch    = options['file'].split(/-/)[-3].gsub(/\./,"_").gsub(/_iso/,"_")
      options['release'] = options['file'].split(/-/)[-2].gsub(/\.iso/,"")
    end
    service_version = service_version+"_"+service_arch
    options['method']  = "ks"
  when /OracleLinux/
    options['service'] = "oel"
    service_version = options['file'].split(/-/)[1..2].join(".").gsub(/\./,"_").gsub(/R|U/,"")
    service_arch    = options['file'].split(/-/)[-2]
    service_version = service_version+"_"+service_arch
    options['release'] = options['file'].split(/-/)[1..2].join(".").gsub(/[a-z,A-Z]/,"")
    options['method']  = "ks"
  when /openSUSE/
    options['service'] = "opensuse"
    service_version = options['file'].split(/-/)[1].gsub(/\./,"_").gsub(/_iso/,"")
    service_arch    = options['file'].split(/-/)[-1].gsub(/\./,"_").gsub(/_iso/,"")
    service_version = service_version+"_"+service_arch
    options['method']  = "ay"
    options['release'] = options['file'].split(/-/)[1]
  when /rhel/
    options['service'] = "rhel"
    options['method']  = "ks"
    if options['file'].to_s.match(/beta|8\.[0-9]/)
      service_version = options['file'].split(/-/)[1..2].join(".").gsub(/\./,"_").gsub(/_iso/,"")
      options['release'] = options['file'].split(/-/)[1]
    else
      service_version = options['file'].split(/-/)[2..3].join(".").gsub(/\./,"_").gsub(/_iso/,"")
      options['release'] = options['file'].split(/-/)[2]
    end 
  when /SLE/
    options['service'] = "sles"
    service_version = options['file'].split(/-/)[1..2].join("_").gsub(/[A-Z]/,"")
    service_arch    = options['file'].split(/-/)[4]
    if service_arch.match(/DVD/)
      service_arch    = options['file'].split(/-/)[5]
    end
    service_version = service_version+"_"+service_arch
    options['method']  = "ay"
    options['release'] = options['file'].split(/-/)[1]
  when /sol/
    options['service'] = "sol"
    options['release'] = options['file'].split(/-/)[1].gsub(/_/,".")
    if options['release'].to_i > 10
      if options['file'].to_s.match(/1111/)
        options['release'] = "11.0"
      end
      options['method']  = "ai"
      options['arch']    = "x86_64"
    else
      options['release'] = options['file'].split(/-/)[1..2].join(".").gsub(/u/,"")
      options['method']  = "js"
      options['arch']    = "i386"
    end
    service_version = options['release']+"_"+options['arch']
    service_version = service_version.gsub(/\./,"_")
  when /V[0-9][0-9][0-9][0-9][0-9]/
    isofile_bin = %[which isofile].chomp
    if isofile_bin.match(/not found/)
      options = install_package("cdrtools")
      isofile_bin = %x[which isofile].chomp
      if isofile_bin.match(/not found/)
        handle_output(options,"Warning:\tUtility isofile not found")
        quit(options)
      end
    end
    options['service'] = "oel"
    options['method']  = "ks"
    volume_id_info  = %x[isoinfo -d -i "#{options['file']}" |grep "^Volume id" |awk '{print $3}'].chomp
    service_arch    = volume_id_info.split(/-/)[-1]
    service_version = volume_id_info.split(/-/)[1..2].join("_")
    service_version = service_version+"-"+service_arch
    options['release'] = volume_id_info.split(/-/)[1]
  when /[0-9][0-9][0-9][0-9]|Win|Srv/
    options['service'] = "windows"
    mount_iso(options)
    wim_file = options['mountdir']+"/sources/install.wim"
    if File.exist?(wim_file)
      wiminfo_bin = %x[which wiminfo]
      if not wiminfo_bin.match(/wiminfo/)
        message = "Information:\tInstall wiminfo (wimlib)"
        command = "brew install wimlib"
        execute_command(options,message,command)
        wiminfo_bin = %x[which wiminfo]
        if not wiminfo_bin.match(/wiminfo/)
          handle_output(options,"Warning:\tCannnot find wiminfo (required to determine version of windows from ISO)")
          quit(options)
        end
      end
      message = "Information:\tDeterming version of Windows from: "+wim_file
      command = "wiminfo \"#{wim_file}\" 1| grep ^Description"
      output  = execute_command(options,message,command)
      options['label']   = output.chomp.split(/\:/)[1].gsub(/^\s+/,"").gsub(/CORE/,"")
      service_version = output.split(/Description:/)[1].gsub(/^\s+|SERVER|Server/,"").downcase.gsub(/\s+/,"_").split(/_/)[1..-1].join("_")
      message = "Information:\tDeterming architecture of Windows from: "+wim_file
      command = "wiminfo \"#{wim_file}\" 1| grep ^Architecture"
      output  = execute_command(options,message,command)
      options['arch'] = output.chomp.split(/\:/)[1].gsub(/^\s+/,"")
      umount_iso(options)
    end
    service_version = service_version+"_"+options['release']+"_"+options['arch']
    service_version = service_version.gsub(/__/,"_")
    options['method'] = "pe"
  end
  if !options['vm'].to_s.match(/kvm/)
    options['service'] = options['service']+"_"+service_version.gsub(/__/,"_")
  else
    if options['file'].to_s.match(/cloudimg/) && options['file'].to_s.match(/ubuntu/)
      options['os-type'] = "linux"
    else
      if options['vm'].to_s.match(/kvm/)
        options['os-type'] = "linux"
      else
        options['os-type'] = options['service']
      end
    end
    options['service'] = options['service']+"_"+service_version.gsub(/__/,"_")
  end
  if options['verbose'] == true
    handle_output(options,"Information:\tSetting service name to #{options['service']}")
    handle_output(options,"Information:\tSetting OS name to #{options['os-type']}")
  end
  return(options)
end

# Get Install method from ISO file name

def get_install_method_from_iso(options)
  if options['file'].to_s.match(/\//)
    iso_file = File.basename(options['file'])
  end
  case iso_file
  when /VMware-VMvisor/
    options['method'] = "vs"
  when /CentOS|OracleLinux|^SL|Fedora|rhel|V[0-9][0-9][0-9][0-9]/
    options['method'] = "ks"
  when /ubuntu|debian|purity/
    options['method'] = "ps"
  when /SUSE|SLE/
    options['method'] = "ay"
  when /sol-6|sol-7|sol-8|sol-9|sol-10/
    options['method'] = "js"
  when /sol-11/
    options['method'] = "ai"
  when /Win|WIN|srv|EVAL|eval|win/
    options['method'] = "pe"
  end
  return options['method']
end

# Configure a service

def configure_server(options)
  if options['host-os-name'].to_s.match(/Darwin/)
    check_osx_dhcpd_installed()
    create_osx_dhcpd_plist()
  end
  if not options['method'].to_s.match(/[a-z,A-Z]/)
    if not options['file'].to_s.match(/[a-z,A-Z]/)
      handle_output(options,"Warning:\tCould not determine service name")
      quit(options)
    else
      options['method'] = get_install_method_from_iso(options)
    end
  end
  eval"[configure_#{options['method']}_server(options)]"
  return
end

# Generate MAC address

def generate_mac_address(options)
  if options['vm'].to_s.match(/fusion|vbox/)
    mac_address = "00:05:"+(1..4).map{"%0.2X"%rand(256)}.join(":")
  else
    if options['vm'].to_s.match(/kvm/)
      mac_address = "52:54:00:"+(1..3).map{"%0.2X"%rand(256)}.join(":")
    else
      mac_address = (1..6).map{"%0.2X"%rand(256)}.join(":")
    end
  end
  return mac_address
end

# List all image services - needs code

def list_image_services(options)
  return
end

# List all image ISOs - needs code

def list_image_isos(options)
  return
end

# List images

def list_images(options)
  case options['vm'].to_s
  when /aws/
    list_aws_images(options)
  when /docker/
    list_docker_images(options)
  when /kvm/
    list_kvm_images(options)
  else
    if options['dir'] != options['empty']
      list_items(options)
    end
  end
  return
end

# List all services

def list_all_services(options)
  list_ai_services(options)
  list_ay_services(options)
  list_image_services(options)
  list_js_services(options)
  list_ks_services(options)
  list_cdom_services(options)
  list_ldom_services(options)
  list_gdom_services(options)
  list_lxc_services(options)
  list_ps_services(options)
  list_cc_services(options)
  list_zone_services(options)
  list_vs_services(options)
  list_xb_services(options)
  handle_output(options,"")
  return
end

# Check hostname validity

def check_hostname(options)
  host_chars = options['name'].split()
  host_chars.each do |char|
    if not char.match(/[a-z,A-Z,0-9]|-/)
      handle_output(options,"Invalid hostname: #{options['name'].join()}")
      quit(options)
    end
  end
end

# Get ISO list

def get_dir_item_list(options)
  full_list = get_base_dir_list(options)
  if options['search'].to_s.match(/all/)
    return full_list
  end
  if options['os-type'] == options['empty'] && options['search'] == options['empty'] && options['method'] == options['empty']
    return full_list
  end
  temp_list = []
  iso_list  = []
  case options['os-type'].downcase
  when /pe|win/
    options['os-type'] = "OEM|win|Win|EVAL|eval"
  when /oel|oraclelinux/
    options['os-type'] = "OracleLinux"
  when /sles/
    options['os-type'] = "SLES"
  when /centos/
    options['os-type'] = "CentOS"
  when /suse/
    options['os-type'] = "openSUSE"
  when /ubuntu/
    if options['vm'].to_s.match(/kvm/)
      options['os-type'] = "linux"
    else
      options['os-type'] = "ubuntu"
    end
  when /debian/
    options['os-type'] = "debian"
  when /purity/
    options['os-type'] = "purity"
  when /fedora/
    options['os-type'] = "Fedora"
  when /scientific|sl/
    options['os-type'] = "SL"
  when /redhat|rhel/
    options['os-type'] = "rhel"
  when /sol/
    options['os-type'] = "sol"
  when /^linux/
    options['os-type'] = "CentOS|OracleLinux|SLES|openSUSE|ubuntu|debian|Fedora|rhel|SL"
  when /vmware|vsphere|esx/
    options['os-type'] = "VMware-VMvisor"
  end
  case options['method']
  when /kick|ks/
    other_search = "CentOS|OracleLinux|Fedora|rhel|SL|VMware"
  when /jump|js/
    other_search = "sol-10"
  when /ai/
    other_search = "sol-11"
  when /yast|ay/
    other_search = "SLES|openSUSE"
  when /preseed|ps/
    other_search = "debian|ubuntu|purity"
  when /ci/
    other_search = "live"
  end
  if options['release'].to_s.match(/[0-9]/)
    case options['os-type']
    when "OracleLinux"
      if options['release'].to_s.match(/\./)
        (major,minor)   = options['release'].split(/\./)
        options['release'] = "-R"+major+"-U"+minor
      else
        options['release'] = "-R"+options['release']
      end
    when /sol/
      if options['release'].to_s.match(/\./)
        (major,minor)   = options['release'].split(/\./)
        if options['release'].to_s.match(/^10/)
          options['release'] = major+"-u"+minor
        else
          options['release'] = major+"_"+minor
        end
      end
      options['release'] = "-"+options['release']
    else
      options['release'] = "-"+options['release']
    end
  end
  if options['arch'].to_s.match(/[a-z,A-Z]/)
    if options['os-type'].to_s.match(/sol/)
      options['arch'] = options['arch'].gsub(/i386|x86_64/,"x86")
    end
    if options['os-type'].to_s.match(/ubuntu/)
      options['arch'] = options['arch'].gsub(/x86_64/,"amd64")
    else
      options['arch'] = options['arch'].gsub(/amd64/,"x86_64")
    end
  end
  search_strings = []
  [ options['os-type'], options['release'], options['arch'], other_search ].each do |search_string|
    if search_string
      if not search_string == options['empty']
        if search_string.match(/[a-z,A-Z,0-9]/)
          search_strings.push(search_string)
        end
      end
    end
  end
  search_strings.each do |search_string|
    search_list = full_list.grep(/#{search_string}/)
    if search_list
      search_list.each do |item|
        if options['method'].to_s.match(/ps/)
          if !item.to_s.match(/live/)
            temp_list.push(item)
          end
        else
          temp_list.push(item)
        end
      end
    end
  end
  if not options['search'] == options['empty'] 
    search_string = options['search'].to_s
    temp_list = temp_list.grep(/#{search_string}/)
  end
  if temp_list.length > 0
    iso_list = temp_list
  end
  return iso_list
end

# Get item version information (e.g. ISOs, images, etc)

def get_item_version_info(file_name)
  iso_info = File.basename(file_name)
  if file_name.match(/purity/)
    iso_info = iso_info.split(/_/)
  else
    iso_info = iso_info.split(/-/)
  end
  iso_distro = iso_info[0]
  iso_distro = iso_distro.downcase
  if file_name.match(/cloud/)
    iso_distro = "ubuntu"
  end
  if iso_distro.match(/^sle$/)
    iso_distro = "sles"
  end
  if iso_distro.match(/oraclelinux/)
    iso_distro = "oel"
  end
  if iso_distro.match(/centos|ubuntu|sles|sl|oel|rhel/)
    if file_name.match(/cloud/) and not file_name.match(/ubuntu/)
      iso_version = get_distro_version_from_distro_name(file_name)
    else
      if iso_distro.match(/sles/)
        if iso_info[2].to_s.match(/Server/)
          iso_version = iso_info[1]+".0"
        else
          iso_version = iso_info[1]+"."+iso_info[2]
          iso_version = iso_version.gsub(/SP/,"")
        end
      else
        if iso_distro.match(/sl$/)
          iso_version = iso_info[1].split(//).join(".")
          if iso_version.length == 1
            iso_version = iso_version+".0"
          end
        else
          if iso_distro.match(/oel|rhel/)
            if file_name =~ /-rc-/
              iso_version = iso_info[1..3].join(".")
              iso_version = iso_version.gsub(/server/,"")
            else
              iso_version = iso_info[1..2].join(".")
              iso_version = iso_version.gsub(/[a-z,A-Z]/,"")
            end
            iso_version = iso_version.gsub(/^\./,"")
          else
            iso_version = iso_info[1]
          end
        end
      end
    end
    if iso_version.match(/86_64/)
      iso_version = iso_info[1]
    end
    if file_name.match(/live/)
      iso_version = iso_version+"_live"
    end
    case file_name
    when /workstation|desktop/
      iso_version = iso_version+"_desktop"
    when /server/
      iso_version = iso_version+"_server"
    end
    if file_name.match(/cloud/)
      iso_version = iso_version+"_cloud"
    end
    case file_name
    when /i[3-6]86/
      iso_arch = "i386"
    when /x86_64|amd64/
      iso_arch = "x86_64"
    else
      if file_name.match(/ubuntu/)
        iso_arch = iso_info[-1].split(".")[0]
      else
        if iso_distro.match(/centos|sl$/)
          iso_arch = iso_info[2]
        else
          if iso_distro.match(/sles|oel/)
            iso_arch = iso_info[4]
          else
            iso_arch = iso_info[3]
          end
        end
      end
    end
  else
    case iso_distro
    when /fedora/
      iso_version = iso_info[1]
      iso_arch    = iso_info[2]
    when /purity/
      iso_version = iso_info[1]
      iso_arch    = "x86_64"
    when /vmware/
      iso_version = iso_info[3].split(/\./)[0..-2].join(".")
      iso_update  = iso_info[3].split(/\./)[-1]
      iso_release = iso_info[4].split(/\./)[-3]
      iso_version = iso_version+"."+iso_update+"."+iso_release
      iso_arch    = "x86_64"
    else
      iso_version = iso_info[2]
      iso_arch    = iso_info[3]
    end
  end
  return iso_distro,iso_version,iso_arch
end

# List ISOs

def list_isos(options)
  list_items(options)
  return
end

# List items (ISOs, images, etc)

def list_items(options)
  if !options['output'].to_s.match(/html/) && !options['vm'].to_s.match(/mp|multipass/)
    string = options['isodir'].to_s+":"
    handle_output(options,string)
  end
  if options['file'] == options['empty']
    iso_list = get_base_dir_list(options)
  else
    iso_list    = []
    iso_list[0] = options['file']
  end
  if iso_list.length > 0
    if options['output'].to_s.match(/html/)
      handle_output(options,"<h1>Available ISO(s)/Image(s):</h1>")
      handle_output(options,"<table border=\"1\">")
      handle_output(options,"<tr>")
      handle_output(options,"<th>ISO/Image File</th>")
      handle_output(options,"<th>Distribution</th>")
      handle_output(options,"<th>Version</th>")
      handle_output(options,"<th>Architecture</th>")
      handle_output(options,"<th>Service Name</th>")
      handle_output(options,"</tr>")
    else
      handle_output(options,"Available ISO(s)/Images(s):")
      handle_output(options,"") 
    end
    iso_list.each do |file_name|
      file_name = file_name.chomp
      if options['vm'].to_s.match(/mp|multipass/)
        iso_arch     = options['host-os-machine'].to_s
        linux_distro = file_name.split(/ \s+/)[-1]
        iso_version  = file_name.split(/ \s+/)[-2]
        file_name    = file_name.split(/ \s+/)[0]
      else
        (linux_distro,iso_version,iso_arch) = get_linux_version_info(file_name)
      end
      if options['output'].to_s.match(/html/)
        handle_output(options,"<tr>")
        handle_output(options,"<td>#{file_name}</td>")
        handle_output(options,"<td>#{linux_distro}</td>")
        handle_output(options,"<td>#{iso_version}</td>")
        handle_output(options,"<td>#{iso_arch}</td>")
      else
        handle_output(options,"ISO/Image file:\t#{file_name}")
        handle_output(options,"Distribution:\t#{linux_distro}")
        handle_output(options,"Version:\t#{iso_version}")
        handle_output(options,"Architecture:\t#{iso_arch}")
      end
      iso_version = iso_version.gsub(/\./,"_")
      options['service'] = linux_distro.downcase.gsub(/\s+|\.|-/,"_").gsub(/_lts_/,"")+"_"+iso_version+"_"+iso_arch
      options['repodir'] = options['baserepodir']+"/"+options['service']
      if File.directory?(options['repodir'])
        if options['output'].to_s.match(/html/)
          handle_output(options,"<td>#{options['service']} (exists)</td>")
        else
          handle_output(options,"Service Name:\t#{options['service']} (exists)")
        end
      else
        if options['output'].to_s.match(/html/)
          handle_output(options,"<td>#{options['service']}</td>")
        else
          handle_output(options,"Service Name:\t#{options['service']}")
        end
      end
      if options['output'].to_s.match(/html/)
        handle_output(options,"</tr>")
      else
        handle_output(options,"") 
      end
    end
    if options['output'].to_s.match(/html/)
      handle_output(options,"</table>")
    end
  end
  return
end

# Connect to virtual serial port

def connect_to_virtual_serial(options)
  if options['vm'].to_s.match(/ldom|gdom/)
    connect_to_gdom_console(options)
  else
    handle_output(options,"")
    handle_output(options,"Connecting to serial port of #{options['name']}")
    handle_output(options,"")
    handle_output(options,"To disconnect from this session use CTRL-Q")
    handle_output(options,"")
    handle_output(options,"If you wish to re-connect to the serial console of this machine,")
    handle_output(options,"run the following command:")
    handle_output(options,"")
    handle_output(options,"#{options['script']} --action=console --vm=#{options['vm']} --name = #{options['name']}")
    handle_output(options,"")
    handle_output(options,"or:")
    handle_output(options,"")
    handle_output(options,"socat UNIX-CONNECT:/tmp/#{options['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
    handle_output(options,"")
    handle_output(options,"")
    system("socat UNIX-CONNECT:/tmp/#{options['name']} STDIO,raw,echo=0,escape=0x11,icanon=0")
  end
  return
end

# Set some VMware ESXi VM defaults

def configure_vmware_esxi_defaults()
  options['memory']    = "4096"
  options['vcpus']     = "2"
  options['os-type']   = "ESXi"
  options['controller']= "ide"
  return
end

# Set some VMware vCenter defaults

def configure_vmware_vcenter_defaults()
  options['memory']    = "4096"
  options['vcpus']     = "2"
  options['os-type']   = "ESXi"
  options['controller']= "ide"
  return
end

# Get Install Service from client name

def get_install_service_from_client_name(options)
  options['service'] = ""
  message = "Information:\tFinding client configuration directory for #{options['name']}"
  command = "find #{options['clientdir']} -name #{options['name']} |grep '#{options['name']}$'"
  options['clientdir'] = execute_command(options,message,command)
  options['clientdir'] = options['clientdir'].chomp
  if options['verbose'] == true
    if File.directory?(options['clientdir'])
      handle_output(options,"Information:\tNo client directory found for #{options['name']}")
    else
      handle_output(options,"Information:\tClient directory found #{options['clientdir']}")
      if options['clientdir'].to_s.match(/packer/)
        handle_output = "Information:\tInstall method is Packer"
      end
    end
  end
  return options['service']
end


# Get client directory

def get_client_dir(options)
  message = "Information:\tFinding client configuration directory for #{options['name']}"
  command = "find #{options['clientdir']} -name #{options['name']} |grep '#{options['name']}$'"
  options['clientdir'] = execute_command(options,message,command).chomp
  if options['verbose'] == true
    if File.directory?(options['clientdir'])
      handle_output(options,"Information:\tNo client directory found for #{options['name']}")
    else
      handle_output(options,"Information:\tClient directory found #{options['clientdir']}")
    end
  end
  return options['clientdir']
end

# Delete client directory

def delete_client_dir(options)
  options['clientdir'] = get_client_dir(options)
  if File.directory?(options['clientdir'])
    if options['clientdir'].to_s.match(/[a-z]/)
      if options['host-os-name'].to_s.match(/SunOS/)
        destroy_zfs_fs(options['clientdir'])
      else
        message = "Information:\tRemoving client configuration files for #{options['name']}"
        command = "rm #{options['clientdir']}/*"
        execute_command(options,message,command)
        message = "Information:\tRemoving client configuration directory #{options['clientdir']}"
        command = "rmdir #{options['clientdir']}"
        execute_command(options,message,command)
      end
    end
  end
  return
end

# Unconfigure client

def unconfigure_client(options)
  if options['type'].to_s.match(/packer|ansible/)
    if options['type'].to_s.match(/packer/)
      unconfigure_packer_client(options)
    else
      unconfigure_ansible_client(options)
    end
  else
    case options['method']
    when /ai/
      unconfigure_ai_client(options)
    when /ay/
      unconfigure_ay_client(options)
    when /js/
      unconfigure_js_client(options)
    when /ks/
      unconfigure_ks_client(options)
    when /ps/
      unconfigure_ps_client(options)
    when /ci/
      unconfigure_cc_client(options)
    when /vs/
      unconfigure_vs_client(options)
    when /xb/
      unconfigure_xb_client(options)
    end
  end
  return
end

# Configure client

def configure_client(options)
  if options['type'].to_s.match(/packer|ansible/)
    if options['type'].to_s.match(/packer/)
      configure_packer_client(options)
    else
      configure_ansible_client(options)
    end
  else
    case options['method']
    when /ai/
      configure_ai_client(options)
    when /ay/
      configure_ay_client(options)
    when /js/
      configure_js_client(options)
    when /ks/
      configure_ks_client(options)
    when /ps/
      configure_ps_client(options)
    when /ci/
      configure_cc_client(options)
    when /vs/
      configure_vs_client(options)
    when /xb/
      configure_xb_client(options)
    when /mp|multipass/
      configure_multipass_client(options)
    end
  end
  return
end

def configure_server(options)
  case options['method']
  when /ai/
    configure_ai_server(options)
  when /ay/
    configure_ay_server(options)
  when /docker/
    configure_docker_server(options)
  when /js/
    configure_js_server(options)
  when /ks/
    configure_ks_server(options)
  when /ldom/
    configure_ldom_server(options)
  when /cdom/
    configure_cdom_server(options)
  when /lxc/
    configure_lxc_server(options)
  when /ps/
    configure_ps_server(options)
  when /ci/
    configure_cc_server(options)
  when /vs/
    configure_vs_server(options)
  when /xb/
    configure_xb_server(options)
  end
  return
end

# List clients for an install service

def list_clients(options)
  case options['method'].downcase
  when /ai/
    list_ai_clients()
    return
  when /js|jumpstart/
    search_string = "sol_6|sol_7|sol_8|sol_9|sol_10"
  when /ks|kickstart/
    search_string = "centos|redhat|rhel|scientific|fedora"
  when /ps|preseed/
    search_string = "debian|ubuntu"
  when /ci/
    search_string = "live"
  when /vmware|vsphere|esx|vs/
    search_string = "vmware"
  when /ay|autoyast/
    search_string = "suse|sles"
  when /xb/
    search_string = "bsd|coreos"
  end
  service_list = Dir.entries(options['clientdir'])
  service_list = service_list.grep(/#{search_string}|#{options['service']}/)
  if service_list.length > 0
    if options['output'].to_s.match(/html/)
      if options['service'].to_s.match(/[a-z,A-Z]/)
        handle_output(options,"<h1>Available #{options['service']} clients:</h1>")
      else
        handle_output(options,"<h1>Available clients:</h1>")
      end
      handle_output(options,"<table border=\"1\">")
      handle_output(options,"<tr>")
      handle_output(options,"<th>Client</th>")
      handle_output(options,"<th>Service</th>")
      handle_output(options,"<th>IP</th>")
      handle_output(options,"<th>MAC</th>")
      handle_output(options,"</tr>")
    else
      handle_output(options,"")
      if options['service'].to_s.match(/[a-z,A-Z]/)
        handle_output(options,"Available #{options['service']} clients:")
      else
        handle_output(options,"Available clients:")
      end
      handle_output(options,"")
    end
    service_list.each do |service_name|
      if service_name.match(/#{search_string}|#{service_name}/) and service_name.match(/[a-z,A-Z]/)
        options['repodir'] = options['clientdir']+"/"+options['service']
        if File.directory?(options['repodir']) or File.symlink?(options['repodir'])
          client_list = Dir.entries(options['repodir'])
          client_list.each do |client_name|
            if client_name.match(/[a-z,A-Z,0-9]/)
              options['clientdir']  = options['repodir']+"/"+client_name
              options['ip']  = get_install_ip(options)
              options['mac'] = get_install_mac(options)
              if File.directory?(options['clientdir'])
                if options['output'].to_s.match(/html/)
                  handle_output(options,"<tr>")
                  handle_output(options,"<td>#{client_name}</td>")
                  handle_output(options,"<td>#{service_name}</td>")
                  handle_output(options,"<td>#{client_ip}</td>")
                  handle_output(options,"<td>#{client_mac}</td>")
                  handle_output(options,"</tr>")
                else
                  handle_output(options,"#{client_name}\t[ service = #{service_name}, ip = #{client_ip}, mac = #{client_mac} ] ")
                end
              end
            end
          end
        end
      end
    end
    if options['output'].to_s.match(/html/)
      handle_output(options,"</table>")
    end
  end
  handle_output(options,"")
  return
end

# List appliances

def list_ovas()
  file_list = Dir.entries(options['isodir'])
  handle_output(options,"")
  handle_output(options,"Virtual Appliances:")
  handle_output(options,"")
  file_list.each do |file_name|
    if file_name.match(/ova$/)
      handle_output(file_name)
    end
  end
  handle_output(options,"")
end

# Check directory user ownership

def check_dir_owner(options,dir_name,uid)
  if dir_name.match(/^\/$/) or dir_name == ""
    handle_output(options,"Warning:\tDirectory name not set")
    quit(options)
  end
  test_uid = File.stat(dir_name).uid
  if test_uid.to_i != uid.to_i
    message = "Information:\tChanging ownership of "+dir_name+" to "+uid.to_s
    if dir_name.to_s.match(/^\/etc/)
      command = "sudo chown -R #{uid.to_s} \"#{dir_name}\""
    else
      command = "chown -R #{uid.to_s} \"#{dir_name}\""
    end
    execute_command(options,message,command)
    message = "Information:\tChanging permissions of "+dir_name+" to "+uid.to_s
    if dir_name.to_s.match(/^\/etc/)
      command = "sudo chmod -R u+w \"#{dir_name}\""
    else
      command = "chmod -R u+w \"#{dir_name}\""
    end
    execute_command(options,message,command)
  end
  return
end

# Check directory group read ownership

def check_dir_group(options,dir_name,dir_gid,dir_mode)
  if dir_name.match(/^\/$/) or dir_name == ""
    handle_output(options,"Warning:\tDirectory name not set")
    quit(options)
  end
  test_gid = File.stat(dir_name).gid
  if test_gid.to_i != dir_gid.to_i
    message = "Information:\tChanging group ownership of "+dir_name+" to "+dir_gid.to_s
    if dir_name.to_s.match(/^\/etc/)
      command = "sudo chgrp -R #{dir_gid.to_s} \"#{dir_name}\""
    else
      command = "chgrp -R #{dir_gid.to_s} \"#{dir_name}\""
    end
    execute_command(options,message,command)
    message = "Information:\tChanging group permissions of "+dir_name+" to "+dir_gid.to_s
    if dir_name.to_s.match(/^\/etc/)
      command = "sudo chmod -R g+#{dir_mode} \"#{dir_name}\""
    else
      command = "chmod -R g+#{dir_mode} \"#{dir_name}\""
    end
    execute_command(options,message,command)
  end
  return
end

# Check file user ownership

def check_file_owner(options,file_name,uid)
  test_uid = File.stat(file_name).uid
  if test_uid != uid.to_i
    message = "Information:\tChanging ownership of "+file_name+" to "+uid.to_s
    if file_name.to_s.match(/^\/etc/)
      command = "sudo chown #{uid.to_s} #{file_name}"
    else
      command = "chown #{uid.to_s} #{file_name}"
    end
    execute_command(options,message,command)
  end
  return
end

# Get group gid

def get_group_gid(options,group) 
  message = "Information:\tGetting GID of "+group
  command = "getent group #{group} |cut -f3 -d:"
  output  = execute_command(options,message,command)
  output  = output.chomp
  return(output)
end

# Check file user ownership

def check_file_group(options,file_name,file_gid,file_mode)
  test_gid = File.stat(file_name).gid
  if test_gid != file_gid.to_i
    message = "Information:\tChanging group ownership of "+file_name+" to "+file_gid.to_s
    command = "chgrp #{file_gid.to_s} \"#{file_name}\""
    execute_command(options,message,command)
    message = "Information:\tChanging group permissions of "+file_name+" to "+file_gid.to_s
    command = "chmod g+#{file_mode} \"#{file_name}\""
    execute_command(options,message,command)
  end
  return
end

# Check Python module is installed

def check_python_module_is_installed(install_module)
  exists = "no"
  module_list = %x[pip listi | awk '{print $1}'].split(/\n/)
  module_list.each do |module_name|
    if module_name.match(/^#{options['model']}$/)
      exists = "yes"
    end
  end
  if exists == "no"
    message = "Information:\tInstalling python model '#{install_module}'"
    command = "pip install #{install_module}"
    execute_command(options,message,command)
  end
  return
end

# Mask contents of file

def mask_contents_of_file(file_name)
  input  = File.readlines(file_name)
  output = []
  input.each do |line|
    if line.match(/secret_key|access_key/) and not line.match(/\{\{/)
      (param,value) = line.split(/:/)
      value = value.gsub(/[A-Z]|[a-z]|[0-9]/,"X")
      line  = param+":"+value
    end
    output.push(line)
  end
  return output
end

# Print contents of file

def print_contents_of_file(options,message,file_name)
  if options['verbose'] == true or options['output'].to_s.match(/html/)
    if File.exist?(file_name)
      if options['unmasked'] == false
        output = mask_contents_of_file(file_name)
      else
        output = File.readlines(file_name)
      end
      if options['output'].to_s.match(/html/)
        handle_output(options,"<table border=\"1\">")
        handle_output(options,"<tr>")
        if message.length > 1
          handle_output(options,"<th>#{message}</th>")
        else
          handle_output(options,"<th>#{file_name}</th>")
        end
        handle_output(options,"<tr>")
        handle_output(options,"<td>")
        handle_output(options,"<pre>")
        output.each do |line|
          handle_output(options,"#{line}")
        end
        handle_output(options,"</pre>")
        handle_output(options,"</td>")
        handle_output(options,"</tr>")
        handle_output(options,"</table>")
      else
        if options['verbose'] == true
          handle_output(options,"")
          if message.length > 1
            handle_output(options,"Information:\t#{message}")
          else
            handle_output(options,"Information:\tContents of file #{file_name}")
          end
          handle_output(options,"")
          output.each do |line|
            handle_output(options,line)
          end
          handle_output(options,"")
        end
      end
    else
      handle_output(options,"Warning:\tFile #{file_name} does not exist")
    end
  end
  return
end

# Show output of command

def show_output_of_command(message,output)
  if options['output'].to_s.match(/html/)
    handle_output(options,"<table border=\"1\">")
    handle_output(options,"<tr>")
    handle_output(options,"<th>#{message}</th>")
    handle_output(options,"<tr>")
    handle_output(options,"<td>")
    handle_output(options,"<pre>")
    handle_output(options,"#{output}")
    handle_output(options,"</pre>")
    handle_output(options,"</td>")
    handle_output(options,"</tr>")
    handle_output(options,"</table>")
  else
    if options['verbose'] == true
      handle_output(options,"")
      handle_output(options,"Information:\t#{message}:")
      handle_output(options,"")
      handle_output(options,output)
      handle_output(options,"")
    end
  end
  return
end

# Check TFTP server

def check_tftp_server(options)
  if options['host-os-name'].to_s.match(/SunOS/)
    if options['host-os-release'].match(/11/)
      if !File.exist?("/lib/svc/manifest/network/tftp-udp.xml")
        message  = "Checking:\tTFTP entry in /etc/inetd.conf"
        command  = "cat /etc/inetd.conf |grep '^tftp' |grep -v '^#'"
        output   = execute_command(options,message,command)
        if not output.match(/tftp/)
          message = "Information:\tCreating TFTP inetd entry"
          command = "echo \"tftp dgram udp wait root /usr/sbin/in.tftpd in.tftpd -s #{options['tftpdir']}\" >> /etc/inetd.conf"
          output  = execute_command(options,message,command)
          message = "Information:\tImporting TFTP inetd entry into service manifest"
          command = "inetconv -i /etc/inet/inetd.conf"
          output  = execute_command(options,message,command)
          message = "Information:\tImporting manifests"
          command = "svcadm restart svc:/system/manifest-import"
        end
      end
    end
  end
  return
end

# Check bootparams entry

def add_bootparams_entry(options)
  found1    = false
  found2    = false
  file_name = "/etc/bootparams"
  boot_info = "root=#{options['hostip']}:#{options['repodir']}/Solaris_#{options['release']}/Tools/Boot install=#{options['hostip']}:#{options['repodir']} boottype=:in sysid_config=#{options['clientdir']} install_config=#{options['clientdir']} rootopts=:rsize=8192"
  if !File.exist?(file_name)
    message = "Information:\tCreating #{file_name}"
    command = "touch #{file_name}"
    execute_command(options,message,command)
    check_file_owner(options,file_name,options['uid'])
    File.open(file_name, "w") { |f| f.write "#{options['mac']} #{options['name']}\n" }
    return
  else
    check_file_owner(options,file_name,options['uid'])
    file = IO.readlines(file_name)
    lines = []
    file.each do |line|
      if !line.match(/^#/)
        if line.match(/^#{options['name']}/) 
          if line.match(/#{boot_info}/)
            found1 = true
            lines.push(line)
          else
            new_line = "#{options['name']} #{boot_info}\n"
            lines.push(new_line)
          end
        else
          lines.push(line)
        end
        if line.match(/^#{options['ip']}/) 
          if line.match(/#{boot_info}/)
            found2 = true
            lines.push(line)
          else
            new_line = "#{options['ip']} #{boot_info}\n"
            lines.push(new_line)
          end
        else
          lines.push(line)
        end
      else
        lines.push(line)
      end
    end
  end
  if found1 == false or found2 == false
    File.open(file_name, "w") do |file|
      lines.each { |line| file.puts(line) }
    end
    if options['host-os-release'].to_s.match(/11/)
      message = "Information:\tRestarting bootparams service"
      command = "svcadm restart svc:/network/rpc/bootparams:default"
      execute_command(options,message,command)
    end
  end
  return
end

# Add NFS export

def add_nfs_export(options,export_name,export_dir)
  network_address = options['publisherhost'].split(/\./)[0..2].join(".")+".0"
  if options['host-os-name'].to_s.match(/SunOS/)
    if options['host-os-release'].match(/11/)
      message  = "Enabling:\tNFS share on "+export_dir
      command  = "zfs set sharenfs=on #{options['zpoolname']}#{export_dir}"
      output   = execute_command(options,message,command)
      message  = "Setting:\tNFS access rights on "+export_dir
      command  = "zfs set share=name=#{export_name},path=#{export_dir},prot=nfs,anon=0,sec=sys,ro=@#{network_address}/24 #{options['zpoolname']}#{export_dir}"
      output   = execute_command(options,message,command)
    else
      dfs_file = "/etc/dfs/dfstab"
      message  = "Checking:\tCurrent NFS exports for "+export_dir
      command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
      output   = execute_command(options,message,command)
      if not output.match(/#{export_dir}/)
        backup_file(options,dfs_file)
        export  = "share -F nfs -o ro=@#{network_address},anon=0 #{export_dir}"
        message = "Adding:\tNFS export for "+export_dir
        command = "echo '#{export}' >> #{dfs_file}"
        execute_command(options,message,command)
        message = "Refreshing:\tNFS exports"
        command = "shareall -F nfs"
        execute_command(options,message,command)
      end
    end
  else
    dfs_file = "/etc/exports"
    message  = "Checking:\tCurrent NFS exports for "+export_dir
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(options,message,command)
    if not output.match(/#{export_dir}/)
      if options['host-os-name'].to_s.match(/Darwin/)
        export = "#{export_dir} -alldirs -maproot=root -network #{network_address} -mask #{options['netmask']}"
      else
        export = "#{export_dir} #{network_address}/24(ro,no_root_squash,async,no_subtree_check)"
      end
      message = "Adding:\tNFS export for "+export_dir
      command = "echo '#{export}' >> #{dfs_file}"
      execute_command(options,message,command)
      message = "Refreshing:\tNFS exports"
      if options['host-os-name'].to_s.match(/Darwin/)
        command = "nfsd stop ; nfsd start"
      else
        command = "/sbin/exportfs -a"
      end
      execute_command(options,message,command)
    end
  end
  return
end

# Remove NFS export

def remove_nfs_export(export_dir)
  if options['host-os-name'].to_s.match(/SunOS/)
    zfs_test = %x[zfs list |grep #{export_dir}].chomp
    if zfs_test.match(/#{export_dir}/)
      message = "Disabling:\tNFS share on "+export_dir
      command = "zfs set sharenfs=off #{options['zpoolname']}#{export_dir}"
      execute_command(options,message,command)
    else
      if options['verbose'] == true
        handle_output(options,"Information:\tZFS filesystem #{options['zpoolname']}#{export_dir} does not exist")
      end
    end
  else
    dfs_file = "/etc/exports"
    message  = "Checking:\tCurrent NFS exports for "+export_dir
    command  = "cat #{dfs_file} |grep '#{export_dir}' |grep -v '^#'"
    output   = execute_command(options,message,command)
    if output.match(/#{export_dir}/)
      backup_file(options,dfs_file)
      tmp_file = "/tmp/dfs_file"
      message  = "Removing:\tExport "+export_dir
      command  = "cat #{dfs_file} |grep -v '#{export_dir}' > #{tmp_file} ; cat #{tmp_file} > #{dfs_file} ; rm #{tmp_file}"
      execute_command(options,message,command)
      if options['host-os-name'].to_s.match(/Darwin/)
        message  = "Restarting:\tNFS daemons"
        command  = "nfsd stop ; nfsd start"
        execute_command(options,message,command)
      else
        message  = "Restarting:\tNFS daemons"
        command  = "service nfsd restart"
        execute_command(options,message,command)
      end
    end
  end
  return
end

# Check we are running on the right architecture

def check_same_arch(options)
  if not options['host-os-arch'].to_s.match(/#{options['arch']}/)
    handle_output(options,"Warning:\tSystem and Zone Architecture do not match")
    quit(options)
  end
  return
end

# Delete file

def delete_file(options,file_name)
  if File.exist?(file_name)
    message = "Removing:\tFile "+file_name
    command = "rm #{file_name}"
    execute_command(options,message,command)
  end
end

# Get root password crypt

def get_root_password_crypt(options)
  password = $q_struct['root_password'].value
  result   = get_password_crypt(password)
  return result
end

# Get account password crypt

def get_admin_password_crypt(options)
  password = $q_struct['admin_password'].value
  result   = get_password_crypt(password)
  return result
end

# Check SSH keys

def check_ssh_keys(options)
  ssh_key = options['home']+"/.ssh/id_rsa.pub"
  if not File.exist?(ssh_key)
    if options['verbose'] == true
      handle_output(options,"Generating:\tPublic SSH key file #{ssh_key}")
    end
    system("ssh-keygen -t rsa")
  end
  return
end

# Check IPS tools installed on OS other than Solaris

def check_ips(options)
  if options['host-os-name'].to_s.match(/Darwin/)
    check_osx_ips(options)
  end
  return
end

# Check Apache enabled

def check_apache_config(options)
  if options['host-os-name'].to_s.match(/Darwin/)
    service = "apache"
    check_osx_service_is_enabled(service)
  end
  return
end

# Check DHCPd config

def check_dhcpd_config(options)
  network_address   = options['hostip'].to_s.split(/\./)[0..2].join(".")+".0"
  broadcast_address = options['hostip'].to_s.split(/\./)[0..2].join(".")+".255"
  gateway_address   = options['hostip'].to_s.split(/\./)[0..2].join(".")+".1"
  output = ""
  if File.exist?(options['dhcpdfile'])
    message = "Checking:\tDHCPd config for subnet entry"
    command = "cat #{options['dhcpdfile']} | grep -v '^#' |grep 'subnet #{network_address}'"
    output  = execute_command(options,message,command)
  end
  if !output.match(/subnet/) && !output.match(/#{network_address}/)
    tmp_file    = "/tmp/dhcpd"
    backup_file = options['dhcpdfile']+options['backupsuffix']
    file = File.open(tmp_file,"w")
    file.write("\n")
    if options['host-os-name'].to_s.match(/SunOS|Linux/)
      file.write("default-lease-time 900;\n")
      file.write("max-lease-time 86400;\n")
    end
    if options['host-os-name'].to_s.match(/Linux/)
      file.write("option space pxelinux;\n")
      file.write("option pxelinux.magic code 208 = string;\n")
      file.write("option pxelinux.configfile code 209 = text;\n")
      file.write("option pxelinux.pathprefix code 210 = text;\n")
      file.write("option pxelinux.reboottime code 211 = unsigned integer 32;\n")
      file.write("option architecture-type code 93 = unsigned integer 16;\n")
    end
    file.write("\n")
    if options['host-os-name'].to_s.match(/SunOS/)
      file.write("authoritative;\n")
      file.write("\n")
      file.write("option arch code 93 = unsigned integer 16;\n")
      file.write("option grubmenu code 150 = text;\n")
      file.write("\n")
      file.write("log-facility local7;\n")
      file.write("\n")
      file.write("class \"PXEBoot\" {\n")
      file.write("  match if (substring(option vendor-class-identifier, 0, 9) = \"PXEClient\");\n")
      file.write("  if option arch = 00:00 {\n")
      file.write("    filename \"default-i386/boot/grub/pxegrub2\";\n")
      file.write("  } else if option arch = 00:07 {\n")
      file.write("    filename \"default-i386/boot/grub/grub2netx64.efi\";\n")
      file.write("  }\n")
      file.write("}\n")
      file.write("\n")
      file.write("class \"SPARC\" {\n")
      file.write("  match if not (substring(option vendor-class-identifier, 0, 9) = \"PXEClient\");\n")
      file.write("  filename \"http://#{options['publisherhost'].to_s.strip}:5555/cgi-bin/wanboot-cgi\";\n")
      file.write("}\n")
      file.write("\n")
      file.write("allow booting;\n")
      file.write("allow bootp;\n")
    end
    if options['host-os-name'].to_s.match(/Linux/)
      file.write("class \"pxeclients\" {\n")
      file.write("  match if substring (option vendor-class-identifier, 0, 9) = \"PXEClient\";\n")
      file.write("  if option architecture-type = 00:07 {\n")
      file.write("    filename \"shimx64.efi\";\n")
      file.write("  } else {\n")
      file.write("    filename \"pxelinux.0\";\n")
      file.write("  }\n")
      file.write("}\n")
    end
    file.write("\n")
    if options['host-os-name'].to_s.match(/SunOS|Linux/)
      file.write("subnet #{network_address} netmask #{options['netmask']} {\n")
      if options['verbose'] == true

      end
      if options['dhcpdrange'] == options['empty']
        options['dhcpdrange'] = network_address.split(".")[0..-2].join(".")+".200"+" "+network_address.split(".")[0..-2].join(".")+"250"
      end
      file.write("  range #{options['dhcpdrange']};\n")
      file.write("  option broadcast-address #{broadcast_address};\n")
      file.write("  option routers #{gateway_address};\n")
      file.write("  next-server #{options['hostip']};\n")
      file.write("}\n")
    end
    file.write("\n")
    file.close
    if File.exist?(options['dhcpdfile'])
      message = "Information:\tArchiving DHCPd configuration file "+options['dhcpdfile']+" to "+backup_file
      command = "cp #{options['dhcpdfile']} #{backup_file}"
      execute_command(options,message,command)
    end
    message = "Information:\tCreating DHCPd configuration file "+options['dhcpdfile']
    command = "cp #{tmp_file} #{options['dhcpdfile']}"
    execute_command(options,message,command)
    if options['host-os-name'].to_s.match(/SunOS/) and options['host-os-release'].match(/5\.11/)
      message = "Information:\tSetting DHCPd listening interface to "+options['nic']
      command = "svccfg -s svc:/network/dhcp/server:ipv4 setprop config/listen_ifnames = astring: #{options['nic']}"
      execute_command(options,message,command)
      message = "Information:\tRefreshing DHCPd service"
      command = "svcadm refresh svc:/network/dhcp/server:ipv4"
      execute_command(options,message,command)
    end
    restart_dhcpd(options)
  end
  return
end

# Check package is installed

def check_rhel_package(options,package)
  message = "Information\tChecking "+package+" is installed"
  command = "rpm -q #{package}"
  output  = execute_command(options,message,command)
  if not output.match(/#{package}/)
    message = "installing:\t"+package
    command = "yum -y install #{package}"
    execute_command(options,message,command)
  end
  return
end

# Check firewall is enabled

def check_rhel_service(options,service)
  message = "Information:\tChecking "+service+" is installed"
  command = "service #{service} status |grep dead"
  output  = execute_command(options,message,command)
  if output.match(/dead/)
    message = "Enabling:\t"+service
    if options['host-os-release'].match(/^7/)
      command = "systemctl enable #{service}.service"
      command = "systemctl start #{service}.service"
    else
      command = "chkconfig --level 345 #{service} on"
    end
    execute_command(options,message,command)
  end
  return
end

# Check service is enabled

def check_rhel_firewall(options,service,port_info)
  if options['host-os-release'].match(/^7/)
    message = "Information:\tChecking firewall configuration for "+service
    command = "firewall-cmd --list-services |grep #{service}"
    output  = execute_command(options,message,command)
    if not output.match(/#{service}/)
      message = "Information:\tAdding firewall rule for "+service
      command = "firewall-cmd --add-service=#{service} --permanent"
      execute_command(options,message,command)
    end
    if port_info.match(/[0-9]/)
      message = "Information:\tChecking firewall configuration for "+port_info
      command = "firewall-cmd --list-all |grep #{port_info}"
      output  = execute_command(options,message,command)
      if not output.match(/#{port_info}/)
        message = "Information:\tAdding firewall rule for "+port_info
        command = "firewall-cmd --zone=public --add-port=#{port_info} --permanent"
        execute_command(options,message,command)
      end
    end
  else
    if port_info.match(/[0-9]/)
      (port_no,protocol) = port_info.split(/\//)
      message = "Information:\tChecking firewall configuration for "+service+" on "+port_info
      command = "iptables --list-rules |grep #{protocol} |grep #{port_no}"
      output  = execute_command(options,message,command)
      if not output.match(/#{protocol}/)
        message = "Information:\tAdding firewall rule for "+service
        command = "iptables -I INPUT -p #{protocol} --dport #{port_no} -j ACCEPT ; service iptables save"
        execute_command(options,message,command)
      end
    end
  end
  return
end

# Check httpd enabled on Centos / Redhat

def check_yum_xinetd(options)
  check_rhel_package(options,"xinetd")
  check_rhel_firewall(options,"xinetd","")
  check_rhel_service(options,"xinetd")
  return
end

# Check TFTPd enabled on CentOS / RedHat

def check_yum_tftpd(options)
  check_dir_exists(options,options['tftpdir'])
  check_rhel_package(options,"tftp-server")
  check_rhel_firewall(options,"tftp","")
  check_rhel_service(options,"tftp")
  return
end

# Check DHCPd enabled on CentOS / RedHat

def check_yum_dhcpd(options)
  check_rhel_package(options,"dhcp")
  check_rhel_firewall(options,"dhcp","69/udp")
  check_rhel_service(options,"dhcpd")
  return
end

# Check httpd enabled on Centos / Redhat

def check_yum_httpd()
  check_rhel_package(options,"httpd")
  check_rhel_firewall(options,"http","80/tcp")
  check_rhel_service(options,"httpd")
  return
end

# Check Ubuntu / Debian package is installed

def check_apt_package(options,package)
  message = "Information:\tChecking "+package+" is installed"
  command = "dpkg -l | grep '#{package}' |grep 'ii'"
  output  = execute_command(options,message,command)
  if not output.match(/#{package}/)
    message = "Information:\tInstalling "+package
    command = "apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew install #{package}"
    execute_command(options,message,command)
  end
  return
end

# Check Ubuntu / Debian firewall

def check_apt_firewall(options,service,port_info)
  if File.exist?("/usr/bin/ufw")
    message = "Information:\tChecking "+service+" is allowed by firewall"
    command = "ufw status |grep #{service} |grep ALLOW"
    output = execute_command(options,message,command)
    if not output.match(/ALLOW/)
      message = "Information:\tAdding "+service+" to firewall allow rules"
      command = "ufw allow #{service} #{port_info}"
      execute_command(options,message,command)
    end
  end
  return
end

# Check Ubuntu / Debian service

def check_apt_service(options,service)
  message = "Information:\tChecking "+service+" is installed"
  command = "service #{service} status |grep dead"
  output  = execute_command(options,message,command)
  if output.match(/dead/)
    message = "Information:\tEnabling: "+service
    command = "systemctl enable #{service}.service"
    execute_command(options,message,command)
    message = "Information:\tStarting: "+service
    command = "systemctl start #{service}.service"
    execute_command(options,message,command)
  end
  return
end

# Check TFTPd enabled on Debian / Ubuntu

def check_apt_tftpd(options)
  check_dir_exists(options,options['tftpdir'])
  check_apt_package(options,"tftpd-hpa")
  check_apt_firewall(options,"tftp","")
  check_apt_service(options,"tftp")
  return
end

# Check DHCPd enabled on Ubuntu / Debian

def check_apt_dhcpd(options)
  check_apt_package(options,"isc-dhcp-server")
  check_apt_firewall(options,"dhcp","69/udp")
  check_apt_service(options,"isc-dhcp-server")
  return
end

# Check httpd enabled on Ubunut / Debian

def check_apt_httpd(options)
  check_apt_package(options,"httpd")
  check_apt_firewall(options,"http","80/tcp")
  check_apt_service(options,"httpd")
  return
end

# Restart a service

def restart_service(options,service)
  refresh_service(options,service)
  return
end

# Restart xinetd

def restart_xinetd(options)
  service = "xinetd"
  service = get_service_name(options,service)
  refresh_service(options,service)
  return
end

# Restart tftpd

def restart_tftpd(options)
  if options['host-os-name'].to_s.match(/Linux/)
    service = "tftpd-hpa"
    refresh_service(options,service)
  else
    service = "tftp"
    service = get_service_name(options,service)
    refresh_service(options,service)
  end
  return
end

# Restart forewalld

def restart_firewalld(options)
  service = "firewalld"
  service = get_service_name(options,service)
  refresh_service(service)
  return
end

# Check tftpd config for Linux(turn on in xinetd config file /etc/xinetd.d/tftp)

def check_tftpd_config(options)
  if options['host-os-name'].to_s.match(/Linux/)
    tmp_file   = "/tmp/tftp"
    pxelinux_file = "/usr/lib/PXELINUX/pxelinux.0"
    if !File.exist?(pxelinux_file)
      options = install_package(options,"pxelinux")
      options = install_package(options,"syslinux")
    end
    syslinux_file = "/usr/lib/syslinux/modules/bios/ldlinux.c32"
    pxelinux_dir  = options['tftpdir']
    pxelinux_tftp = pxelinux_dir+"/pxelinux.0"
    syslinux_tftp = pxelinux_dir+"/ldlinux.c32"
    if options['verbose'] == true
      handle_output(options,"Information:\tChecking PXE directory")
    end
    check_dir_exists(options,pxelinux_dir)
    check_dir_owner(options,pxelinux_dir,options['uid'])
    if !File.exist?(pxelinux_tftp)
      if !File.exist?(pxelinux_file)
        options = install_package(options,"pxelinux")
      end
      if File.exist?(pxelinux_file)
        message = "Information:\tCopying '#{pxelinux_file}' to '#{pxelinux_tftp}'"
        command = "cp #{pxelinux_file} #{pxelinux_tftp}"
        execute_command(options,message,command)
      else
        handle_output(options,"Warning:\tTFTP boot file pxelinux.0 does not exist")
      end
    end
    if !File.exist?(syslinux_tftp)
      if !File.exist?(syslinux_tftp)
        options = install_package(options,"syslinux")
      end
      if File.exist?(syslinux_file)
        message = "Information:\tCopying '#{syslinux_file}' to '#{syslinux_tftp}'"
        command = "cp #{syslinux_file} #{syslinux_tftp}"
        execute_command(options,message,command)
      else
        handle_output(options,"Warning:\tTFTP boot file ldlinux.c32 does not exist")
      end
    end
    if options['host-os-uname'].match(/Ubuntu|Debian/)
      check_apt_tftpd(options)
    else
      check_yum_tftpd(options)
    end
    check_dir_exists(options,options['tftpdir'])
    if options['host-os-uname'].match(/RedHat|CentOS/)
      if Integer(options['host-os-version']) > 6
        message = "Checking SELinux tftp permissions"
        command = "getsebool -a | grep tftp |grep home"
        output  = execute_command(options,message,command)
        if output.match(/off/)
          message = "Setting SELinux tftp permissions"
          command = "setsebool -P tftp_home_dir 1"
          execute_command(options,message,command)
        end
        restart_firewalld(options)
      end
    end
  end
  restart_tftpd(options)
  return
end

# Check tftpd directory

def check_tftpd_dir(options)
  if options['host-os-name'].to_s.match(/SunOS/)
    old_tftp_dir = "/tftpboot"
    if options['verbose'] == true
      handle_output(options,"Information:\tChecking TFTP directory")
    end
    check_dir_exists(options,options['tftpdir'])
    check_dir_owner(options,options['tftpdir'],options['uid'])
    if not File.symlink?(old_tftp_dir)
      message = "Information:\tSymlinking #{old_tftp_dir} to #{options['tftpdir']}}"
      command = "ln -s #{options['tftpdir']} #{old_tftp_dir}"
      output  = execute_command(options,message,command)
#      File.symlink(options['tftpdir'],old_tftp_dir)
    end
    message = "Checking:\tTFTPd service boot directory configuration"
    command = "svcprop -p inetd_start/exec svc:network/tftp/udp"
    output  = execute_command(options,message,command)
    if not output.match(/netboot/)
      message = "Setting:\tTFTPd boot directory to "+options['tftpdir']
      command = "svccfg -s svc:network/tftp/udp setprop inetd_start/exec = astring: \"/usr/sbin/in.tftpd\\ -s\\ /etc/netboot\""
      execute_command(options,message,command)
    end
  end
  return
end

# Check tftpd

def check_tftpd(options)
  check_tftpd_dir(options)
  if options['host-os-name'].to_s.match(/SunOS/)
    enable_service(options,"svc:/network/tftp/udp:default")
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    check_osx_tftpd()
  end
  return
end

# Get client IP

def get_install_ip(options)
  options['ip']  = ""
  hosts_file = "/etc/hosts"
  if File.exist?(hosts_file) or File.symlink?(hosts_file)
    file_array = IO.readlines(hosts_file)
    file_array.each do |line|
      line = line.chomp
      if line.match(/#{options['name']}\s+/)
        options['ip'] = line.split(/\s+/)[0]
      end
    end
  end
  return options['ip']
end

# Get client MAC

def get_install_mac(options)
  options['mac']   = ""
  found_client = 0
  if File.exist?(options['dhcpdfile']) or File.symlink?(options['dhcpdfile'])
    file_array = IO.readlines(options['dhcpdfile'])
    file_array.each do |line|
      line = line.chomp
      if line.match(/#{options['name']} /)
        found_client = true
      end
      if line.match(/hardware ethernet/) and found_client == true
        options['mac'] = line.split(/\s+/)[3].gsub(/\;/,"")
        return options['mac']
      end
    end
  end
  return options['mac']
end

# Add hosts entry

def add_hosts_entry(options)
  hosts_file = "/etc/hosts"
  message    = "Checking:\tHosts file for "+options['name']
  command    = "cat #{hosts_file} |grep -v '^#' |grep '#{options['name']}' |grep '#{options['ip']}'"
  output     = execute_command(options,message,command)
  if not output.match(/#{options['name']}/)
    backup_file(options,hosts_file)
    message = "Adding:\t\tHost "+options['name']+" to "+hosts_file
    command = "echo \"#{options['ip']}\\t#{options['name']}.local\\t#{options['name']}\\t# #{options['adminuser']}\" >> #{hosts_file}"
    output  = execute_command(options,message,command)
    if options['host-os-name'].to_s.match(/Darwin/)
      pfile   = "/Library/LaunchDaemons/homebrew.mxcl.dnsmasq.plist"
      if File.exist?(pfile)
        service = "dnsmasq"
        service = get_service_name(options,service)
        refresh_service(service)
      end
    end
  end
  return
end

# Remove hosts entry

def remove_hosts_entry(options)
  tmp_file   = "/tmp/hosts"
  hosts_file = "/etc/hosts"
  message    = "Checking:\tHosts file for "+options['name']
  if options['ip'].to_s.match(/[0-9]/)
    command = "cat #{hosts_file} |grep -v '^#' |grep '#{options['name']}' |grep '#{options['ip']}'"
  else
    command = "cat #{hosts_file} |grep -v '^#' |grep '#{options['name']}'"
  end
  output = execute_command(options,message,command)
  copy   = []
  if output.match(/#{options['name']}/)
    file_info=IO.readlines(hosts_file)
    file_info.each do |line|
      if not line.match(/#{options['name']}/)
        if options['ip'].to_s.match(/[0-9]/)
          if not line.match(/^#{options['ip']}/)
            copy.push(line)
          end
        else
          copy.push(line)
        end
      end
    end
    File.open(tmp_file,"w") {|file| file.puts copy}
    message = "Updating:\tHosts file "+hosts_file
    if options['host-os-name'].to_s.match(/Darwin/)
      command = "sudo sh -c 'cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}'"
    else
      command = "cp #{tmp_file} #{hosts_file} ; rm #{tmp_file}"
    end
    execute_command(options,message,command)
  end
  return
end

# Add host to DHCP config

def add_dhcp_client(options)
  if not options['mac'].to_s.match(/:/)
    options['mac'] = options['mac'][0..1]+":"+options['mac'][2..3]+":"+options['mac'][4..5]+":"+options['mac'][6..7]+":"+options['mac'][8..9]+":"+options['mac'][10..11]
  end
  tmp_file = "/tmp/dhcp_"+options['name']
  if not options['arch'].to_s.match(/sparc/)
    tftp_pxe_file = options['mac'].gsub(/:/,"")
    tftp_pxe_file = tftp_pxe_file.upcase
    if options['service'].to_s.match(/sol/)
      suffix = ".bios"
    else
      if options['service'].to_s.match(/bsd/)
        suffix = ".pxeboot"
      else
        suffix = ".pxelinux"
      end
    end
    tftp_pxe_file = "01"+tftp_pxe_file+suffix
  else
    tftp_pxe_file = "http://#{options['publisherhost'].to_s.strip}:5555/cgi-bin/wanboot-cgi"
  end
  message = "Checking:\fIf DHCPd configuration contains "+options['name']
  command = "cat #{options['dhcpdfile']} | grep '#{options['name']}'"
  output  = execute_command(options,message,command)
  if not output.match(/#{options['name']}/)
    backup_file(options,options['dhcpdfile'])
    file = File.open(tmp_file,"w")
    file_info=IO.readlines(options['dhcpdfile'])
    file_info.each do |line|
      file.write(line)
    end
    file.write("\n")
    file.write("host #{options['name']} {\n")
    file.write("  fixed-address #{options['ip']};\n")
    file.write("  hardware ethernet #{options['mac']};\n")
    if options['service'].to_s.match(/[a-z,A-Z]/)
      #if options['biostype'].to_s.match(/efi/)
      #  if options['service'].to_s.match(/vmware|esx|vsphere/)
      #    file.write("  filename \"#{options['service'].to_s}/bootx64.efi\";\n")
      #  else
      #    file.write("  filename \"shimx64.efi\";\n")
      #  end
      #else
        file.write("  filename \"#{tftp_pxe_file}\";\n")
      #end
    end
    file.write("}\n")
    file.close
    message = "Updating:\tDHCPd file "+options['dhcpdfile']
    command = "cp #{tmp_file} #{options['dhcpdfile']} ; rm #{tmp_file}"
    execute_command(options,message,command)
    restart_dhcpd(options)
  end
  check_dhcpd(options)
  check_tftpd(options)
  return
end

# Remove host from DHCP config

def remove_dhcp_client(options)
  found     = 0
  copy      = []
  if !File.exist?(options['dhcpdfile'])
    if options['verbose'] == true
      handle_output(options,"Warning:\tFile #{options['dhcpdfile']} does not exist")
    end
  else
    check_file_owner(options,options['dhcpdfile'],options['uid'])
    file_info = IO.readlines(options['dhcpdfile'])
    file_info.each do |line|
      if line.match(/^host #{options['name']}/)
        found = true
      end
      if found == false
        copy.push(line)
      end
      if found == true and line.match(/\}/)
        found=0
      end
    end
    File.open(options['dhcpdfile'],"w") {|file| file.puts copy}
  end
  return
end

# Backup file

def backup_file(options,file_name)
  date_string = get_date_string(options)
  backup_file = File.basename(file_name)+"."+date_string
  backup_file = options['backupdir'].to_s+"/"+backup_file
  message     = "Archiving:\tFile "+file_name+" to "+backup_file
  command     = "cp #{file_name} #{backup_file}"
  execute_command(options,message,command)
  return
end

# Wget a file

def wget_file(options,file_url,file_name)
  if options['download'] == true
    wget_test = %[which wget].chomp
    if wget_test.match(/bin/)
      command  = "wget #{file_url} -O #{file_name}"
    else
      command  = "curl -o #{file_name } #{file_url}"
    end
    file_dir = File.dirname(file_name)
    check_dir_exists(options,file_dir)
    message  = "Fetching:\tURL "+file_url+" to "+file_name
    execute_command(options,message,command)
  end
  return
end

# Add to ethers file

def add_to_ethers_file(options)
  found     = false
  file_name = "/etc/ethers"
  if !File.exist?(file_name)
    message = "Information:\tCreating #{file_name}"
    command = "touch #{file_name}"
    execute_command(options,message,command)
    check_file_owner(options,file_name,options['uid'])
    File.open(file_name, "w") { |f| f.write "#{options['mac']} #{options['name']}\n" }
    return
  else
    check_file_owner(options,file_name,options['uid'])
    file = IO.readlines(file_name)
    lines = []
    file.each do |line|
      if !line.match(/^#/)
        if line.match(/#{options['name']}/) 
          if line.match(/#{options['mac']}/)
            found = true
            lines.push(line)
          else
            new_line = "#{options['name']} #{options['mac']}\n"
            lines.push(new_line)
          end
        else
          lines.push(line)
        end
      else
        lines.push(line)
      end
    end
  end
  if found == false
    File.open(file_name, "w") do |file|
      lines.each { |line| file.puts(line) }
    end
  end
  return
end

# Find client MAC

def get_install_mac(options)
  ethers_file = "/etc/ethers"
  output      = ""
  found       = 0
  if File.exist?(ethers_file)
    message = "Checking:\tFile "+ethers_file+" for "+options['name']+" MAC address"
    command = "cat #{ethers_file} |grep '#{options['name']} '|awk \"{print \\$2}\""
    mac_add = execute_command(options,message,command)
    mac_add = mac_add.chomp
  end
  if not output.match(/[0-9]/)
    file = IO.readlines(options['dhcpdfile'])
    file.each do |line|
      line = line.chomp
      if line.match(/#{options['name']}/)
        found = 1
      end
      if found == true
        if line.match(/ethernet/)
          mac_add = line.split(/ ethernet /)[1]
          mac_add = options['mac'].gsub(/\;/,"")
          return mac_add
        end
      end
    end
  end
  return mac_add
end

# Check if a directory exists
# If not create it

def check_dir_exists(options,dir_name)
  output = ""
  dir_name = dir_name.to_s
  if !File.directory?(dir_name) && !File.symlink?(dir_name)
    if dir_name.match(/[a-z]|[A-Z]/)
      message = "Information:\tCreating: "+dir_name
      if dir_name.match(/^\/etc/)
        command = "sudo mkdir -p \"#{dir_name}\""
      else
        command = "mkdir -p \"#{dir_name}\""
      end
      output  = execute_command(options,message,command)
    end
  end
  return output
end

# Check a filesystem / directory exists

def check_fs_exists(options,dir_name)
  output = ""
  if options['host-os-name'].to_s.match(/SunOS/)
    output = check_zfs_fs_exists(options,dir_name)
  else
    check_dir_exists(options,dir_name)
  end
  return output
end

# Check if a ZFS filesystem exists
# If not create it

def check_zfs_fs_exists(options,dir_name)
  output = ""
  if not File.directory?(dir_name)
    if options['host-os-name'].to_s.match(/SunOS/)
      if dir_name.match(/clients/)
        root_dir = dir_name.split(/\//)[0..-2].join("/")
        if not File.directory?(root_dir)
          check_zfs_fs_exists(root_dir)
        end
      end
      if dir_name.match(/ldoms|zones/)
        zfs_name = options['dpool']+dir_name
      else
        zfs_name = options['zpoolname']+dir_name
      end
      if dir_name.match(/vmware_|openbsd_|coreos_/) or options['host-os-release'].to_i > 10
        options['service'] = File.basename(dir_name)
        mount_dir    = options['tftpdir']+"/"+options['service']
        if not File.directory?(mount_dir)
          Dir.mkdir(mount_dir)
        end
      else
        mount_dir = dir_name
      end
      message      = "Information:\tCreating "+dir_name+" with mount point "+mount_dir
      command      = "zfs create -o mountpoint=#{mount_dir} #{zfs_name}"
      execute_command(options,message,command)
      if dir_name.match(/vmware_|openbsd_|coreos_/) or options['host-os-release'].to_i > 10
        message = "Information:\tSymlinking "+mount_dir+" to "+dir_name
        command = "ln -s #{mount_dir} #{dir_name}"
        execute_command(options,message,command)
      end
    else
      check_dir_exists(options,dir_name)
    end
  end
  return output
end

# Destroy a ZFS filesystem

def destroy_zfs_fs(options,ir_name)
  output = ""
  zfs_list = %x[zfs list |grep -v NAME |awk '{print $5}' |grep "^#{dir_name}$'].chomp
  if zfs_list.match(/#{dir_name}/)
    zfs_name = %x[zfs list |grep -v NAME |grep "#{dir_name}$" |awk '{print $1}'].chomp
    if options['yes'] == true
      if File.directory?(dir_name)
        if dir_name.match(/netboot/)
          service = "svc:/network/tftp/udp:default"
          disable_service(service)
        end
        message = "Warning:\tDestroying "+dir_name
        command = "zfs destroy -r -f #{zfs_name}"
        output  = execute_command(options,message,command)
        if dir_name.match(/netboot/)
          enable_service(service)
        end
      end
    end
  end
  if File.directory?(dir_name)
    Dir.rmdir(dir_name)
  end
  return output
end

# Routine to execute command
# Prints command if verbose switch is on
# Does not execute cerver/client import/create operations in test mode

def execute_command(options,message,command)
  if !command
    handle_output(options,"Warning:\tEmpty command")
    return
  end
  if command.match(/prlctl/) and !options['host-os-name'].to_s.match(/Darwin/)
    return
  else
    if command.match(/prlctl/)
      parallels_test = %x[which prlctl].chomp
      if not parallels_test.match(/prlctl/)
        return
      end
    end
  end
  output  = ""
  execute = 0
  if options['verbose'] == true
    if message.match(/[a-z,A-Z,0-9]/)
      handle_output(options,message)
    end
  end
  if options['test'] == true
    if not command.match(/create|id|groups|update|import|delete|svccfg|rsync|cp|touch|svcadm|VBoxManage|vboxmanage|vmrun|docker/)
      execute = true
    end
  else
    execute = true
  end
  if execute == true
    if options['uid'] != 0
      if !command.match(/brew |sw_vers|id |groups|hg|pip|VBoxManage|vboxmanage|netstat|df|vmrun|noVNC|docker|packer|ansible-playbook|virt-install|qemu|^ls|multipass/) && !options['host-os-name'].to_s.match(/NT/)
        if options['sudo'] == true
          command = "sudo sh -c '"+command+"'"
        else
          if command.match(/ufw|chown|chmod/)
            command = "sudo sh -c '"+command+"'"
          else
            if command.match(/ifconfig/) && command.match(/up$/)
              command = "sudo sh -c '"+command+"'"
            end
          end
        end
      else
        if command.match(/ifconfig/) && command.match(/up$/)
          command = "sudo sh -c '"+command+"'"
        end
        if command.match(/virt-install|snap/)
          command = "sudo sh -c '"+command+"'"
        end
        if command.match(/qemu/) && command.match(/chmod|chgrp/)
          command = "sudo sh -c '"+command+"'"
        end
        if options['vm'].to_s.match(/kvm/) && command.match(/libvirt/) && command.match(/ls/)
          command = "sudo sh -c '"+command+"'"
        end
      end
      if options['host-os-name'].to_s.match(/NT/) && command.match(/netsh/)
        batch_file = "/tmp/script.bat"
        File.write(batch_file,command)
        handle_output(options,"Information:\tCreating batch file '#{batch_file}' to run command '#{command}"'')
        command = "cygstart --action=runas "+batch_file
      end
    end
    if command.match(/^sudo/)
      if options['host-os-name'].to_s.match(/Darwin/)
        sudo_check = %x[dscacheutil -q group -a name admin |grep users]
      else
        sudo_check = %x[getent group #{options['sudogroup']}].chomp
      end
      if !sudo_check.match(/#{options['user']}/)
        handle_output(options,"Warning:\tUser #{options['user']} is not in sudoers group")
        exit
      end
    end
    if options['verbose'] == true
      handle_output(options,"Executing:\t#{command}")
    end
    if options['executehost'].to_s.match(/localhost/)
      output = %x[#{command}]
    else
#      Net::SSH.start(options['server'], options['serveradmin'], :password => options['serverpassword'], :verify_host_key => "never") do |ssh_session|
#        output = ssh_session.exec!(command)
#      end
    end
  end
  if options['verbose'] == true
    if output.length > 1
      if not output.match(/\n/)
        handle_output(options,"Output:\t\t#{output}")
      else
        multi_line_output = output.split(/\n/)
        multi_line_output.each do |line|
          handle_output(options,"Output:\t\t#{line}")
        end
      end
    end
  end
  return output
end

# Convert current date to a string that can be used in file names

def get_date_string(options)
  time        = Time.new
  time        = time.to_a
  date        = Time.utc(*time)
  date_string = date.to_s.gsub(/\s+/,"_")
  date_string = date_string.gsub(/:/,"_")
  date_string = date_string.gsub(/-/,"_")
  if options['verbose'] == true
    handle_output(options,"Information:\tSetting date string to #{date_string}")
  end
  return date_string
end

# Create an encrypted password field entry for a give password

def get_password_crypt(password)
  crypt = UnixCrypt::MD5.build(password)
  return crypt
end

# Restart DHCPd

def restart_dhcpd(options)
  if options['host-os-name'].to_s.match(/SunOS/)
    function = "refresh"
    service  = "svc:/network/dhcp/server:ipv4"
    output   = handle_smf_service(options,function,service)
  else
    if options['host-os-name'].to_s.match(/Linux/)
      service = "isc-dhcp-server"
    else
      service = "dhcpd"
    end
    refresh_service(options,service)
  end
  return output
end

# Check DHPCPd is running

def check_dhcpd(options)
  message = "Checking:\tDHCPd is running"
  if options['host-os-name'].to_s.match(/SunOS/)
    command = "svcs -l svc:/network/dhcp/server:ipv4"
    output  = execute_command(options,message,command)
    if output.match(/disabled/)
      function         = "enable"
      smf_install_service = "svc:/network/dhcp/server:ipv4"
      output           = handle_smf_service(function,smf_install_service)
    end
    if output.match(/maintenance/)
      function         = "refresh"
      smf_install_service = "svc:/network/dhcp/server:ipv4"
      output           = handle_smf_service(function,smf_install_service)
    end
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    command = "ps aux |grep '/usr/local/bin/dhcpd' |grep -v grep"
    output  = execute_command(options,message,command)
    if not output.match(/dhcp/)
      service = "dhcp"
      check_osx_service_is_enabled(options,service)
      service = "dhcp"
      refresh_service(options,service)
    end
    check_osx_tftpd()
  end
  return output
end

# Get service basename

def get_service_base_name(options)
  base_service = options['service'].to_s.gsub(/_i386|_x86_64|_sparc/,"")
  return base_service
end

# Get service name

def get_service_name(options,service)
  if options['host-os-name'].to_s.match(/SunOS/)
    if service.to_s.match(/apache/)
      service = "svc:/network/http:apache22"
    end
    if service.to_s.match(/dhcp/)
      service = "svc:/network/dhcp/server:ipv4"
    end
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    if service.to_s.match(/apache/)
      service = "org.apache.httpd"
    end
    if service.to_s.match(/dhcp/)
      service = "homebrew.mxcl.isc-dhcp"
    end
    if service.to_s.match(/dnsmasq/)
      service = "homebrew.mxcl.dnsmasq"
    end
  end
  return service
end

# Enable service

def enable_service(options,service_name)
  if options['host-os-name'].to_s.match(/SunOS/)
    output = enable_smf_service(options,service_name)
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    output = enable_osx_service(options,service_name)
  end
  if options['host-os-name'].to_s.match(/Linux/)
    output = enable_linux_service(options,service_name)
  end
  return output
end

# Disable service

def disable_service(options,service_name)
  if options['host-os-name'].to_s.match(/SunOS/)
    output = disable_smf_service(options,service_name)
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    output = disable_osx_service(options,service_name)
  end
  if options['host-os-name'].to_s.match(/Linux/)
    output = disable_linux_service(options,service_name)
  end
  return output
end

# Refresh / Restart service

def refresh_service(options,service_name)
  if options['host-os-name'].to_s.match(/SunOS/)
    output = refresh_smf_service(options,service_name)
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    output = refresh_osx_service(options,service_name)
  end
  if options['host-os-name'].to_s.match(/Linux/)
    restart_linux_service(options,service_name)
  end
  return output
end

# Calculate route

def get_ipv4_default_route(options)
  if !options['gateway'].to_s.match(/[0-9]/)
    octets    = options['ip'].split(/\./)
    octets[3] = options['gatewaynode']
    ipv4_default_route = octets.join(".")
  else
    ipv4_default_route = options['gateway']
  end
  return ipv4_default_route
end

# Create a ZFS filesystem for ISOs if it doesn't exist
# Eg /export/isos
# This could be an NFS mount from elsewhere
# If a directory already exists it will do nothing
# It will check that there are ISOs in the directory
# If none exist it will exit

def get_base_dir_list(options)
  if options['vm'].to_s.match(/mp|multipass/)
    iso_list = get_multipass_iso_list(options)
    return iso_list
  end
  search_string = options['search']
  if options['isodir'] == nil or options['isodir'] == "none" and options['file'] == options['empty']
    handle_output(options,"Warning:\tNo valid ISO directory specified")
    quit(options)
  end
  iso_list = []
  if options['verbose'] == true
    handle_output(options,"Checking:\t#{options['isodir']}")
  end
  if options['file'] == options['empty']
    check_fs_exists(options,options['isodir'])
    case options['type'].to_s
    when /iso/
      iso_list = Dir.entries(options['isodir']).grep(/iso$|ISO$/)
    when /image|img/
      iso_list = Dir.entries(options['isodir']).grep(/img$|IMG$|image$|IMAGE$/)
    when /service/
      iso_list = Dir.entries(options['repodir']).grep(/[a-z]|[A-Z]/)
    end
    if options['method'].to_s.match(/ps/)
      iso_list = iso_list.grep_v(/live/)
    end
    if options['method'].to_s.match(/ci/)
      iso_list = iso_list.grep(/live/)
    end
    if search_string.match(/sol_11/)
      if not iso_list.grep(/full/)
        handle_output(options,"Warning:\tNo full repository ISO images exist in #{options['isodir']}")
        if options['test'] != true
          quit(options)
        end
      end
    end
    iso_list
  else
    iso_list[0] = options['file']
  end
  return iso_list
end

# Check client architecture

def check_client_arch(options,opt)
  if not options['arch'].to_s.match(/i386|sparc|x86_64/)
    if opt['F'] or opt['O']
      if opt['A']
        handle_output(options,"Information:\tSetting architecture to x86_64")
        options['arch'] = "x86_64"
      end
    end
    if opt['n']
      options['service'] = opt['n']
      service_arch = options['service'].split("_")[-1]
      if service_arch.match(/i386|sparc|x86_64/)
        options['arch'] = service_arch
      end
    end
  end
  if not options['arch'].to_s.match(/i386|sparc|x86_64/)
    handle_output(options,"Warning:\tInvalid architecture specified")
    handle_output(options,"Warning:\tUse --arch i386, --arch x86_64 or --arch sparc")
    quit(options)
  end
  return options['arch']
end

# Check client MAC

def check_install_mac(options)
  if !options['mac'].to_s.match(/:/)
    if options['mac'].to_s.split(":").length != 6 
      handle_output(options,"Warning:\tInvalid MAC address")
      options['mac'] = generate_mac_address(options['vm'])
      handle_output(options,"Information:\tGenerated new MAC address: #{options['mac']}")
    else
      chars       = options['mac'].split(//)
      options['mac'] = chars[0..1].join+":"+chars[2..3].join+":"+chars[4..5].join+":"+chars[6..7].join+":"+chars[8..9].join+":"+chars[10..11].join
    end
  end
  macs = options['mac'].split(":")
  if macs.length != 6
    handle_output(options,"Warning:\tInvalid MAC address")
    quit(options)
  end
  macs.each do |mac|
    if mac =~ /[G-Z]|[g-z]/
      handle_output(options,"Warning:\tInvalid MAC address")
      options['mac'] = generate_mac_address(options['vm'])
      handle_output(options,"Information:\tGenerated new MAC address: #{options['mac']}")
    end
  end
  return options['mac']
end

# Check install IP

def check_install_ip(options)
  options['ips'] = []
  if options['ip'].to_s.match(/,/)
    options['ips'] = options['ip'].split(",")
  else
    options['ips'][0] = options['ip']
  end
  options['ips'].each do |test_ip|
    ips = test_ip.split(".")
    if ips.length != 4 
      handle_output(options,"Warning:\tInvalid IP Address")
    end
    ips.each do |ip|
      if ip =~ /[a-z,A-Z]/ or ip.length > 3 or ip.to_i > 254
        handle_output(options,"Warning:\tInvalid IP Address")
      end
    end
  end
  return
end


# Add apache proxy

def add_apache_proxy(options,service_base_name)
  service = "apache"
  if options['host-os-name'].to_s.match(/SunOS/)
    if options['osverstion'].to_s.match(/11/) && options['host-os-update'].to_s.match(/4/)
      apache_config_file = options['apachedir']+"/2.4/httpd.conf"
      service = "apache24"
    else
      apache_config_file = options['apachedir']+"/2.2/httpd.conf"
      service = "apache22"
    end
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    apache_config_file = options['apachedir']+"/httpd.conf"
  end
  if options['host-os-name'].to_s.match(/Linux/)
    apache_config_file = options['apachedir']+"/conf/httpd.conf"
    if !File.exist?(apache_config_file)
      options = install_package(options,"apache2")
    end
  end
  a_check = %x[cat #{apache_config_file} |grep #{service_base_name}]
  if not a_check.match(/#{service_base_name}/)
    message = "Information:\tArchiving "+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
    command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
    execute_command(options,message,command)
    message = "Adding:\t\tProxy entry to "+apache_config_file
    command = "echo 'ProxyPass /"+service_base_name+" http://"+options['publisherhost']+":"+options['publisherport']+" nocanon max=200' >>"+apache_config_file
    execute_command(options,message,command)
    enable_service(options,service)
    refresh_service(options,service)
  end
  return
end

# Remove apache proxy

def remove_apache_proxy(service_base_name)
  service = "apache"
  if options['host-os-name'].to_s.match(/SunOS/)
    if options['osverstion'].to_s.match(/11/) && options['host-os-update'].to_s.match(/4/)
      apache_config_file = options['apachedir']+"/2.4/httpd.conf"
      service = "apache24"
    else
      apache_config_file = options['apachedir']+"/2.2/httpd.conf"
      service = "apache22"
    end
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    apache_config_file = options['apachedir']+"/httpd.conf"
  end
  if options['host-os-name'].to_s.match(/Linux/)
    apache_config_file = options['apachedir']+"/conf/httpd.conf"
  end
  message = "Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
  command = "cat #{apache_config_file} |grep '#{service_base_name}'"
  a_check = execute_command(options,message,command)
  if a_check.match(/#{service_base_name}/)
    restore_file = apache_config_file+".no_"+service_base_name
    if File.exist?(restore_file)
      message = "Restoring:\t"+restore_file+" to "+apache_config_file
      command = "cp #{restore_file} #{apache_config_file}"
      execute_command(options,message,command)
      service = "apache"
      refresh_service(options,service)
    end
  end
end

# Add apache alias

def add_apache_alias(options,service_base_name)
  options = install_package(options,"apache2")
  if service_base_name.match(/^\//)
    apache_alias_dir  = service_base_name
    service_base_name = File.basename(service_base_name)
  else
    apache_alias_dir = options['baserepodir']+"/"+service_base_name
  end
  if options['host-os-name'].to_s.match(/SunOS/)
    if options['host-os-version'].to_s.match(/11/) && options['host-os-update'].to_s.match(/4/)
      apache_config_file = options['apachedir']+"/2.4/httpd.conf"
    else
      apache_config_file = options['apachedir']+"/2.2/httpd.conf"
    end
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    apache_config_file = options['apachedir']+"/httpd.conf"
  end
  if options['host-os-name'].to_s.match(/Linux/)
    if options['host-os-uname'].match(/CentOS|RedHat/)
      apache_config_file = options['apachedir']+"/conf/httpd.conf"
      apache_doc_root = "/var/www/html"
      apache_doc_dir  = apache_doc_root+"/"+service_base_name
    else
      apache_config_file = "/etc/apache2/apache2.conf"
    end
  end
  if options['host-os-name'].to_s.match(/SunOS|Linux/)
    tmp_file = "/tmp/httpd.conf"
    message  = "Checking:\tApache confing file "+apache_config_file+" for "+service_base_name
    command  = "cat #{apache_config_file} |grep '/#{service_base_name}'"
    a_check  = execute_command(options,message,command)
    message  = "Information:\tChecking Apache Version"
    command  = "apache2 -V 2>&1 |grep version |tail -1"
    a_vers   = execute_command(options,message,command)
    if not a_check.match(/#{service_base_name}/)
      message = "Information:\tArchiving Apache config file "+apache_config_file+" to "+apache_config_file+".no_"+service_base_name
      command = "cp #{apache_config_file} #{apache_config_file}.no_#{service_base_name}"
      execute_command(options,message,command)
      if options['verbose'] == true
        handle_output(options,"Adding:\t\tDirectory and Alias entry to #{apache_config_file}")
      end
      message = "Copying:\tApache config file so it can be edited"
      command = "cp #{apache_config_file} #{tmp_file} ; chown #{options['uid']} #{tmp_file}"
      execute_command(options,message,command)
      output = File.open(tmp_file,"a")
      output.write("<Directory #{apache_alias_dir}>\n")
      output.write("Options Indexes FollowSymLinks\n")
      if a_vers.match(/2\.4/)
        output.write("Require ip #{options['apacheallow']}\n")
      else
        output.write("Allow from #{options['apacheallow']}\n")
      end
      output.write("</Directory>\n")
      output.write("Alias /#{service_base_name} #{apache_alias_dir}\n")
      output.close
      message = "Updating:\tApache config file"
      command = "cp #{tmp_file} #{apache_config_file} ; rm #{tmp_file}"
      execute_command(options,message,command)
    end
    if options['host-os-name'].to_s.match(/SunOS|Linux/)
      if options['host-os-name'].to_s.match(/Linux/)
        if options['host-os-uname'].to_s.match(/CentOS|RedHat/)
          service = "httpd"
        else
          service = "apache2"
        end
      else
        if options['host-os-name'].match(/SunOS/) && options['host-os-version'].to_s.match(/11/)
          if options['host-os-update'].to_s.match(/4/)
            service = "apache24"
          else
            service = "apache2"
          end
        else
          service = "apache"
        end
      end
      enable_service(options,service)
      refresh_service(options,service)
    end
    if options['host-os-name'].to_s.match(/Linux/)
      if options['host-os-uname'].match(/RedHat/)
        if options['host-os-version'].match(/^7|^6\.7/)
          httpd_p = "httpd_sys_rw_content_t"
          message = "Information:\tFixing permissions on "+options['clientdir']
          command = "chcon -R -t #{httpd_p} #{options['clientdir']}"
          execute_command(options,message,command)
        end
      end
    end
  end
  return
end

# Remove apache alias

def remove_apache_alias(service_base_name)
  remove_apache_proxy(service_base_name)
end

# Mount full repo isos under iso directory
# Eg /export/isos
# An example full repo file name
# /export/isos/sol-11_1-repo-full.iso
# It will attempt to mount them
# Eg /cdrom
# If there is something mounted there already it will unmount it

def mount_iso(options)
  handle_output(options,"Information:\tProcessing: #{options['file']}")
  output  = check_dir_exists(options,options['mountdir'])
  message = "Checking:\tExisting mounts"
  command = "df |awk '{print $NF}' |grep '^#{options['mountdir']}$'"
  output  = execute_command(options,message,command)
  if output.match(/[a-z,A-Z]/)
    message = "Information:\tUnmounting: "+options['mountdir']
    command = "umount "+options['mountdir']
    output  = execute_command(options,message,command)
  end
  message = "Information:\tMounting ISO "+options['file']+" on "+options['mountdir']
  if options['host-os-name'].to_s.match(/SunOS/)
    command = "mount -F hsfs "+options['file']+" "+options['mountdir']
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    command = "hdiutil attach -nomount \"#{options['file']}\" |head -1 |awk \"{print \\\$1}\""
    if options['verbose'] == true
      handle_output(options,"Executing:\t#{command}")
    end
    disk_id = %x[#{command}]
    disk_id = disk_id.chomp
    command = "mount -t cd9660 -o ro "+disk_id+" "+options['mountdir']
  end
  if options['host-os-name'].to_s.match(/Linux/)
    command = "mount -t iso9660 -o loop "+options['file']+" "+options['mountdir']
  end
  output = execute_command(options,message,command)
  readme = options['mountdir']+"/README.TXT"
  if File.exist?(readme)
    text = IO.readlines(readme)
    if text.grep(/UDF/)
      umount_iso(options)
      if options['host-os-name'].to_s.match(/Darwin/)
        command = "hdiutil attach -nomount \"#{options['file']}\" |head -1 |awk \"{print \\\$1}\""
        if options['verbose'] == true
          handle_output(options,"Executing:\t#{command}")
        end
        disk_id = %x[#{command}]
        disk_id = disk_id.chomp
        command = "sudo mount -t udf -o ro "+disk_id+" "+options['mountdir']
        output  = execute_command(options,message,command)
      end
    end
  end
  if options['file'].to_s.match(/sol/)
    if options['file'].to_s.match(/\-ga\-/)
      if options['file'].to_s.match(/sol\-10/)
        iso_test_dir = options['mountdir']+"/boot"
      else
        iso_test_dir = options['mountdir']+"/installer"
      end
    else
      iso_test_dir = options['mountdir']+"/repo"
    end
  else
    case options['file']
    when /VM/
      iso_test_dir = options['mountdir']+"/upgrade"
    when /Win|Srv|[0-9][0-9][0-9][0-9]/
      iso_test_dir = options['mountdir']+"/sources"
    when /SLE/
      iso_test_dir = options['mountdir']+"/suse"
    when /CentOS|SL/
      iso_test_dir = options['mountdir']+"/repodata"
    when /rhel|OracleLinux|Fedora/
      if options['file'].to_s.match(/rhel-server-5/)
        iso_test_dir = options['mountdir']+"/Server"
      else
        if options['file'].to_s.match(/rhel-8/)
          iso_test_dir = options['mountdir']+"/BaseOS/Packages"
        else
          iso_test_dir = options['mountdir']+"/Packages"
        end
      end
    when /VCSA/
      iso_test_dir = options['mountdir']+"/vcsa"
    when /install|FreeBSD/
      iso_test_dir = options['mountdir']+"/etc"
    when /coreos/
      iso_test_dir = options['mountdir']+"/coreos"
    else
      iso_test_dir = options['mountdir']+"/install"
    end
  end
  if not File.directory?(iso_test_dir) and not File.exist?(iso_test_dir) and not options['file'].to_s.match(/DVD2\.iso|2of2\.iso|repo-full|VCSA/)
    handle_output(options,"Warning:\tISO did not mount, or this is not a repository ISO")
    handle_output(options,"Warning:\t#{iso_test_dir} does not exist")
    if options['test'] != true
      umount_iso(options)
      quit(options)
    end
  end
  return
end

# Check my directory exists

def check_my_dir_exists(options,dir_name)
  if not File.directory?(dir_name) and not File.symlink?(dir_name)
    if options['verbose'] == true
      handle_output(options,"Information:\tCreating directory '#{dir_name}'")
    end
    system("mkdir #{dir_name}")
  else
    if options['verbose'] == true
      handle_output(options,"Information:\tDirectory '#{dir_name}' already exists")
    end
  end
  return
end

# Check ISO mounted for OS X based server

def check_osx_iso_mount(options)
  check_dir_exists(options,options['mountdir'])
  test_dir = options['mountdir']+"/boot"
  if not File.directory?(test_dir)
    message = "Mounting:\ISO "+options['file']+" on "+options['mountdir']
    command = "hdiutil mount #{options['file']} -mountpoint #{options['mountdir']}"
    output  = execute_command(options,message,command)
  end
  return output
end

# Copy repository from ISO to local filesystem

def copy_iso(options)
  if options['verbose'] == true
    handle_output(options,"Checking:\tIf we can copy data from full repo ISO")
  end
  if options['file'].to_s.match(/sol/)
    iso_test_dir = options['mountdir']+"/repo"
    if File.directory?(iso_test_dir)
      iso_repo_dir = iso_test_dir
    else
      iso_test_dir = options['mountdir']+"/publisher"
      if File.directory?(iso_test_dir)
        iso_repo_dir = options['mountdir']
      else
        handle_output(options,"Warning:\tRepository source directory does not exist")
        if options['test'] != true
          quit(options)
        end
      end
    end
    test_dir = options['repodir']+"/publisher"
  else
    iso_repo_dir = options['mountdir']
    case options['file']
    when /CentOS|rhel|OracleLinux|Fedora/
      test_dir = options['repodir']+"/isolinux"
    when /VCSA/
      test_dir = options['repodir']+"/vcsa"
    when /VM/
      test_dir = options['repodir']+"/upgrade"
    when /install|FreeBSD/
      test_dir = options['repodir']+"/etc"
    when /coreos/
      test_dir = options['repodir']+"/coreos"
    when /SLES/
      test_dir = options['repodir']+"/suse"
    else
      test_dir = options['repodir']+"/install"
    end
  end
  if not File.directory?(options['repodir']) and not File.symlink?(options['repodir']) and not options['file'].to_s.match(/\.iso/)
    handle_output(options,"Warning:\tRepository directory #{options['repodir']} does not exist")
    if options['test'] != true
      quit(options)
    end
  end
  if not File.directory?(test_dir) or options['file'].to_s.match(/DVD2\.iso|2of2\.iso/)
    if options['file'].to_s.match(/sol/)
      if not File.directory?(iso_repo_dir)
        handle_output(options,"Warning:\tRepository source directory #{iso_repo_dir} does not exist")
        if options['test'] != true
          quit(options)
        end
      end
      message = "Copying:\t"+iso_repo_dir+" contents to "+options['repodir']
      command = "rsync -a #{iso_repo_dir}/. #{options['repodir']}"
      output  = execute_command(options,message,command)
      if options['host-os-name'].to_s.match(/SunOS/)
        message = "Rebuilding:\tRepository in "+options['repodir']
        command = "pkgrepo -s #{options['repodir']} rebuild"
        output  = execute_command(options,message,command)
      end
    else
      check_dir_exists(options,test_dir)
      message = "Copying:\t"+iso_repo_dir+" contents to "+options['repodir']
      command = "rsync -a #{iso_repo_dir}/. #{options['repodir']}"
      if options['repodir'].to_s.match(/sles_12/)
        if not options['file'].to_s.match(/2\.iso/)
          output  = execute_command(options,message,command)
        end
      else
        handle_output(options,message)
        output  = execute_command(options,message,command)
      end
    end
  end
  return
end

# List domains/zones/etc instances

def list_doms(options,dom_type,dom_command)
  message = "Information:\nAvailable #{dom_type}(s)"
  command = dom_command
  output  = execute_command(options,message,command)
  output  = output.split("\n")
  if output.length > 0
    if options['output'].to_s.match(/html/)
      handle_output(options,"<h1>Available #{dom_type}(s)</h1>")
      handle_output(options,"<table border=\"1\">")
      handle_output(options,"<tr>")
      handle_output(options,"<th>Service</th>")
      handle_output(options,"</tr>")
    else
      handle_output(options,"")
      handle_output(options,"Available #{dom_type}(s):")
      handle_output(options,"")
    end
    output.each do |line|
      line = line.chomp
      line = line.gsub(/\s+$/,"")
      if options['output'].to_s.match(/html/)
        handle_output(options,"<tr>")
        handle_output(options,"<td>#{line}</td>")
        handle_output(options,"</tr>")
      else
        handle_output(options,line)
      end
    end
    if options['output'].to_s.match(/html/)
      handle_output(options,"</table>")
    end
  end
  return
end

# List services

def list_services(options)
  if options['os-type'].to_s != options['empty'].to_s
    search = options['os-type'].to_s
  else
    if options['method'].to_s != options['empty'].to_s
      search = options['method'].to_s
    else
      if options['search'].to_s != options['empty'].to_s
        search = options['search'].to_s
      else
        search = "all"
      end
    end
  end
  case search
  when /ai/
    list_ai_services(options)
  when /ay|sles/
    list_ay_services(options)
  when /image/
    list_image_services(options)
  when /all/
    list_all_services(options)
  when /js/
    list_js_services(options)
  when /ks|rhel|centos|scientific/
    list_ks_services(options)
  when /cdom/
    list_cdom_services(options)
  when /ldom/
    list_ldom_services(options)
  when /gdom/
    list_gdom_services(options)
  when /lxc/
    list_lxc_services(options)
  when /ps|ubuntu|debian/
    list_ps_services(options)
  when /ci/
    list_cc_services(options)
  when /zone/
    list_zone_services(options)
  when /vs|vmware|vsphere/
    list_vs_services(options)
  when /xb/
    list_xb_services(options)
  end
  return
end

# Unmount ISO

def umount_iso(options)
  if options['host-os-name'].to_s.match(/Darwin/)
    command = "df |grep \"#{options['mountdir']}$\" |head -1 |awk \"{print \\\$1}\""
    if options['verbose'] == true
      handle_output(options,"Executing:\t#{command}")
    end
    disk_id = %x[#{command}]
    disk_id = disk_id.chomp
  end
  if options['host-os-name'].to_s.match(/Darwin/)
    message = "Detaching:\tISO device "+disk_id
    command = "sudo hdiutil detach #{disk_id}"
    execute_command(options,message,command)
  else
    message = "Unmounting:\tISO mounted on "+options['mountdir']
    command = "umount #{options['mountdir']}"
    execute_command(options,message,command)
  end
  return
end

# Clear a service out of maintenance mode

def clear_service(options,smf_service)
  message    = "Checking:\tStatus of service "+smf_service
  command    = "sleep 5 ; svcs -a |grep \"#{options['service']}\" |awk \"{print \\\$1}\""
  output     = execute_command(options,message,command)
  if output.match(/maintenance/)
    message    = "Clearing:\tService "+smf_service
    command    = "svcadm clear #{smf_service}"
    output     = execute_command(options,message,command)
  end
  return
end


# Occassionally DHCP gets stuck if it's restart to often
# Clear it out of maintenance mode

def clear_solaris_dhcpd(options)
  smf_service = "svc:/network/dhcp/server:ipv4"
  clear_service(options,smf_service)
  return
end

# Brew install a package on OS X

def brew_install(options,pkg_name)
  command = "brew install #{pkg_name}"
  message = "Information:\tInstalling #{pkg_name}"
  execute_command(options,message,command)
  return
end

# Get method from service

def get_method_from_service(service)
  case service
  when /rhel|fedora|centos/
    method = "ks"
  when /sol_10/
    method = "js"
  when /sol_11/
    method = "ai"
  when /ubuntu|debian/
    if service.match(/live/)
      method = "ci"
    else 
      method = "ps"
    end
  when /sles|suse/
    method = "ay"
  when /vmware/
    method = "vs"
  end
  return method
end

def check_perms(options)
  if options['verbose'] == true
    handle_output(options,"Information:\tChecking client directory")
  end
  check_dir_exists(options,options['clientdir'])
  check_dir_owner(options,options['clientdir'],options['uid'])
  return
end
