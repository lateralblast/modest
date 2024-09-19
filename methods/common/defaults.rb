# Set defaults

def set_defaults(values, defaults)
  # Declare OS defaults
  defaults['home'] = ENV['HOME']
  defaults['user'] = ENV['USER']
  defaults['host-os-uname']  = %x[uname].chomp
  defaults['host-os-unamep'] = %x[uname -p].chomp
  defaults['host-os-unamem'] = %x[uname -m].chomp
  defaults['host-os-unamea'] = %x[uname -a].chomp
  defaults['host-os-unamer'] = %x[uname -r].chomp
  defaults['host-os-packages'] = []
  if defaults['host-os-uname'].to_s.match(/Darwin/)
    defaults['host-os-unamep']   = %x[uname -m].chomp
    defaults['host-os-memory'] = %x[system_profiler SPHardwareDataType |grep Memory |awk '{print $2}'].chomp
    defaults['host-os-cpu'] = %x[sysctl hw.ncpu |awk '{print $2}']
    if File.exist?("/usr/local/bin/brew")
      defaults['host-os-packages'] = %x[/usr/local/bin/brew list].split(/\s+|\n/)
    end
  else
    if defaults['host-os-uname'].to_s.match(/Linux/)
      if defaults['host-os-unamea'].to_s.match(/Ubuntu/)
        defaults['host-os-packages'] = %x[dpkg -l |awk '{print $2}'].split(/\s+|\n/)
      else
        if defaults['host-os-unamea'].to_s.match(/arch/)
          defaults['host-os-packages'] = %x[pacman -Q |awk '{print $1}'].split(/\s+|\n/)
        end
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
      defaults['host-os'] = defaults['host-os-unamea'].to_s
    end
  else
    defaults['host-os'] = defaults['host-os-unamea'].to_s
  end
  if defaults['host-os-uname'].to_s.match(/SunOS|Darwin|NT/)
    if defaults['host-os-uname'].to_s.match(/SunOS/)
      if File.exist?("/etc/release")
        defaults['host-os-revision'] = %x[cat /etc/release |grep Solaris |head -1].chomp.gsub(/^\s+/, "")
      end
      if defaults['host-os-unamer'].to_s.match(/\./)
        if defaults['host-os-unamer'].to_s.match(/^5/)
          defaults['host-os-version'] = defaults['host-os-unamer'].to_s.split(/\./)[1]
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
  if defaults['host-os-unamer'].to_s.match(/\./)
    defaults['host-os-major'] = defaults['host-os-unamer'].to_s.split(/\./)[0]
    defaults['os-minor']      = defaults['host-os-unamer'].to_s.split(/\./)[1]
  else
    defaults['host-os-major'] = defaults['host-os-unamer']
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
  defaults['valid-arch']    = [ 'x86_64', 'i386', 'sparc', 'arm64' ]
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
  if defaults['host-os-unamep'].to_s.match(/sparc/)
    if defaults['host-os-major'] = %x[uname -r].split(/\./)[1].to_i > 9
      defaults['valid-vm']       = [ 'zone', 'cdom', 'gdom', 'aws' ]
    end
  else
    case defaults['host-os-uname']
    when /not recognised/
      verbose_output(values,"Information:\tAt the moment Cygwin is required to run on Windows")
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
      defaults['host-lsb-all']         = %x[#{defaults['lsb']} -a].chomp
      defaults['host-lsb-id']          = %x[#{defaults['lsb']} -i -s].chomp
      defaults['host-lsb-release']     = %x[#{defaults['lsb']} -r -s].chomp
      defaults['host-lsb-version']     = %x[#{defaults['lsb']} -v -s].chomp
      defaults['host-lsb-codename']    = %x[#{defaults['lsb']} -c -s].chomp
      defaults['host-lsb-distributor'] = %x[#{defaults['lsb']} -i -s].chomp
      defaults['host-lsb-description'] = %x[#{defaults['lsb']} -d -s].chomp.gsub(/"/,"")
    when /Darwin/
      defaults['nic']      = "en0"
      defaults['ovfbin']   = "/Applications/VMware OVF Tool/ovftool"
      defaults['valid-vm'] = [ 'vbox', 'vmware', 'fusion', 'parallels', 'aws', 'docker', 'qemu', 'multipass', 'kvm'  ]
    end
    case defaults['host-os-platform']
    when /VMware/
      if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
        if values['vmnetwork'].to_s.match(/nat/)
          defaults['vmgateway']  = "192.168.158.1"
          defaults['hostonlyip'] = "192.168.158.1"
        else
          if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 11
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
      if defaults['host-os-uname'].to_s.match(/Linux/)
        defaults['nic'] = %x[netstat -rn |grep UG |head -1].chomp.split()[-1]
      end
    when /VirtualBox/
      defaults['vmgateway']  = "192.168.56.1"
      defaults['hostonlyip'] = "192.168.56.1"
      defaults['nic']        = "eth0"
    when /Parallels/
      if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
        defaults['vmgateway']  = "10.211.55.1"
        defaults['hostonlyip'] = "10.211.55.1"
      else
        defaults['vmgateway']  = "192.168.54.1"
        defaults['hostonlyip'] = "192.168.54.1"
      end
    else
      defaults['vmgateway']  = "192.168.55.1"
      defaults['hostonlyip'] = "192.168.55.1"
      if defaults['host-os-uname'].to_s.match(/Linux/)
        defaults['nic'] = "eth0"
        network_test = %x[ifconfig -a |grep eth0].chomp
        if !network_test.match(/eth0/)
          defaults['nic'] = %x[ip r |grep default |awk '{print $5}']
        end
      end
    end
    if values['vm'].to_s.match(/kvm/)
      defaults['vmgateway']  = "192.168.122.1"
      defaults['hostonlyip'] = "192.168.122.1"
    end
  end
  # Declare other defaults
  defaults['virtdir'] = ""
  defaults['basedir'] = ""
  if defaults['host-os-uname'].match(/Darwin/) && defaults['host-os-major'].to_i > 18
    #defaults['basedir']  = "/System/Volumes/Data"
    #defaults['mountdir'] = '/System/Volumes/Data/cdrom'
    defaults['basedir']  = defaults['home'].to_s+"/Documents/modest"
    defaults['mountdir'] = defaults['home'].to_s+"/Documents/modest/cdrom"
    if values['vm'].to_s.match(/kvm/)
      if values['host-os-uname'].to_s.match(/Darwin/)
        if Dir.exist?("/opt/homebrew/Cellar")
          defaults['virtdir'] = "/opt/homebrew/Cellar/libvirt/images"
        else
          defaults['virtdir'] = "/usr/local/Cellar/libvirt/images"
        end
      end
    end
  else
    if values['vm'].to_s.match(/kvm/)
      if values['host-os-uname'].to_s.match(/Darwin/)
        if Dir.exist?("/opt/homebrew/Cellar")
          defaults['virtdir'] = "/opt/homebrew/Cellar/libvirt/images"
        else
          defaults['virtdir'] = "/usr/local/Cellar/libvirt/images"
        end
      else
        defaults['virtdir'] = "/var/lib/libvirt/images"
      end
    end
    defaults['mountdir'] = '/cdrom'
  end
  # Set up some volume information
  defaults['accelerator']     = "kvm"
  defaults['audio']           = "none"
  defaults['auditfs']         = "ext4"
  defaults['auditsize']       = "8192"
  defaults['unattendedfile']  = ""
  defaults['autoyastfile']    = ""
  defaults['bootfs']          = "ext4"
  defaults['bootsize']        = "512"
  defaults['bridge']          = "virbr0"
  defaults['netbridge']       = defaults['bridge']
  defaults['communicator']    = "winrm"
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
  defaults['adminuser']       = "modest"
  defaults['admingroup']      = "wheel"
  defaults['adminhome']       = "/home/"+defaults['adminuser'].to_s
  defaults['adminname']       = "modest"
  defaults['adminpassword']   = "P455w0rd"
  defaults['adminuid']        = "200"
  defaults['adminshell']      = "/bin/bash"
  defaults['adminsudo']       = "ALL=(ALL) NOPASSWD:ALL"
  defaults['apachedir']       = '/etc/apache2'
  defaults['aidir']           = defaults['basedir'].to_s+'/export/auto_install'
  defaults['aiport']          = '10081'
  defaults['bename']          = "solaris"
  defaults['backupsuffix']    = ".pre-modest"
  defaults['baserepodir']     = defaults['basedir'].to_s+"/export/repo"
  defaults['biosdevnames']    = true
  defaults['boot']            = "disk"
  defaults['bootsize']        = "512"
  defaults['bootwait']        = "5s"
  defaults['bucket']          = defaults['scriptname'].to_s+".bucket"
  defaults['check']           = "perms"
  defaults['checksum']        = false
  defaults['checknat']        = false
  defaults['cidr']            = "24"
  defaults['clientrootdir']   = defaults['basedir'].to_s+'/export/clients'
  defaults['clientdir']       = defaults['basedir'].to_s+'/export/clients'
  defaults['cloudinitfile']   = ""
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
  defaults['diskinterface']   = "ide"
  defaults['dnsmasq']         = false
  defaults['domainname']      = "lab.net"
  defaults['download']        = false
  defaults['installdrivers']  = false
  defaults['installupdates']  = false
  defaults['installupgrades'] = false
  defaults['installsecurity'] = false
  defaults['preservesources'] = false
  defaults['dpool']           = "dpool"
  defaults['dryrun']         = false
  defaults['empty']           = "none"
  defaults['enableethernet']  = true
  defaults['enablevnc']       = false
  defaults['enablevhv']       = true
  defaults['environment']     = "en_US.UTF-8"
  defaults['exportdir']       = defaults['basedir'].to_s+"/export/"+defaults['scriptname'].to_s
  defaults['ethernetdevice']  = "e1000e"
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
  defaults['httpportmax']     = defaults['httpport']
  defaults['httpportmin']     = defaults['httpport']
  defaults['hwvirtex']        = "on"
  defaults['imagedir']        = defaults['basedir'].to_s+'/export/images'
  defaults['install']         = "initial_install"
  defaults['kernel']          = "linux-generic"
  defaults['instances']       = "1,1"
  defaults['ipfamily']        = "ipv4"
  defaults['isodir']          = defaults['basedir'].to_s+'/export/isos'
  defaults['region']          = "ap-southeast-2"
  defaults['packersshport']   = "2222"
  if values['vm']
    if values['vm'].to_s.match(/aws/)
      defaults['keydir'] = ENV['HOME'].to_s+"/.ssh/aws"
    else
      defaults['keydir'] = ENV['HOME'].to_s+"/.ssh"
    end
    if values['vm'].to_s.match(/kvm/)
      defaults['method'] = "ci"
    end
  end
  if values['clientnic'].to_s.match(/[0-9]/)
    defaults['vmnic'] = values['clientnic'].to_s
  else
    if values['vm'].to_s.match(/kvm|mp|multipass/)
      if values['biosdevnames'] == false
        defaults['vmnic'] = "enp1s0"
      else
        defaults['vmnic'] = "eth0"
      end
    else
      if values['vm'].to_s.match(/fusion/) and defaults['host-os-unamep'].to_s.match(/arm/)
        if values['biosdevnames'] == false
          defaults['vmnic'] = "ens160"
        else
          defaults['vmnic'] = "eth0"
        end
      else
        defaults['vmnic'] = "eth0"
      end
    end
  end
  defaults['keyboard']        = "US"
  defaults['keyfile']         = "none"
  defaults['keymap']          = "US-English"
  defaults['kvmgroup']        = "kvm"
  defaults['kvmgid']          = get_group_gid(values,defaults['kvmgroup'].to_s)
  defaults['language']        = "en_US"
  defaults['livecd']          = false
  defaults['ldomdir']         = '/ldoms'
  defaults['local']           = "local"
  defaults['locale']          = "en_US"
  defaults['lxcdir']          = "/export/clients/lxc"
  defaults['lxcimagedir']     = "/export/clients/lxc/images"
  defaults['mac']             = ""
  defaults['maasadmin']       = "root"
  defaults['maasemail']       = defaults['maasadmin'].to_s+"@"+defaults['hostip'].to_s
  defaults['maaspassword']    = defaults['adminpassword'].to_s
  defaults['manifest']        = "modest"
  defaults['masked']          = false
  defaults['memory']          = "2048"
  defaults['vcpus']           = "2"
  defaults['mirror']          = defaults['country'].to_s.downcase+'.archive.ubuntu.com'
  defaults['mirrordir']       = "/ubuntu"
  defaults['mirrorurl']       = defaults['mirror'].to_s+defaults['mirrordir'].to_s
  defaults['mirrordisk']      = false
  defaults['mode']            = 'client'
  defaults['mouse']           = "ps2"
  defaults['nameserver']      = "8.8.8.8"
  defaults['nameservice']     = "none"
  defaults['net']             = "net0"
  defaults['netmask']         = "255.255.255.0"
  defaults['nfs4domain']      = "dynamic"
  defaults['nokeys']          = false
  defaults['nomirror']        = true
  defaults['nosuffix']        = false
  defaults['notice']          = false
  defaults['noreboot']        = false
  defaults['nobuild']         = false
  defaults['noboot']          = false
  defaults['reboot']          = true
  defaults['novncdir']        = "/usr/local/novnc"
  defaults['number']          = "1,1"
  defaults['object']          = "uploads"
  defaults['opencsw']         = "http://mirror.opencsw.org/opencsw/"
  defaults['opensshwinurl']   = "http://www.mls-software.com/files/setupssh-7.2p2-1-v1.exe"
  defaults['organisation']    = "Multi OS Deployment Server"
  defaults['output']          = 'text'
  defaults['ovftarurl']       = "https://github.com/richardatlateralblast/ottar/blob/master/vmware-ovftools.tar.gz?raw=true"
  defaults['ovfdmgurl']       = "https://github.com/richardatlateralblast/ottar/blob/master/VMware-ovftool-4.1.0-2459827-mac.x64.dmg?raw=true"
  defaults['packerversion']   = "1.9.4"
  defaults['pkgdir']          = defaults['basedir'].to_s+'/export/pkgs'
  defaults['postscript']      = ""
  defaults['preseedfile']     = ""
  defaults['proto']           = "tcp"
  defaults['publisherhost']   = defaults['hostip'].to_s
  defaults['publisherport']   = "10081"
  defaults['biostype']        = "bios"
  defaults['repodir']         = defaults['basedir'].to_s+'/export/repo'
  defaults['rpoolname']       = 'rpool'
  defaults['rootdisk']        = "/dev/sda"
  defaults['rootpassword']    = "P455w0rd"
  defaults['rpm2cpiobin']     = ""
  defaults['rtcuseutc']       = "on"
  defaults['search']          = ""
  defaults['security']        = "none"
  defaults['server']          = defaults['hostip'].to_s
  defaults['severadmin']      = "root"
  defaults['servernetwork']   = "vmnetwork1"
  defaults['serverpassword']  = "P455w0rd"
  defaults['sshpassword']     = defaults['serverpassword']
  defaults['serversize']      = "small"
  defaults['serial']          = false
  defaults['sitename']        = defaults['domainname'].to_s.split(".")[0]
  defaults['size']            = "100G"
  defaults['slice']           = "8192"
  defaults['sharedfolder']    = defaults['home'].to_s+"/Documents"
  if values['host-os-uname'].to_s.match(/Darwin/)
    defaults['sharedmount']   =  defaults['home'].to_s+"/Documents/modest/mnt"
  else
    defaults['sharedmount']   = "/mnt"
  end
  defaults['shutdowntimeout'] = "1h"
  defaults['splitvols']       = false
  defaults['sshconfig']       = defaults['home'].to_s+"/.ssh/config"
  defaults['sshenadble']      = "true"
  defaults['sshkeydir']       = defaults['home'].to_s+"/.ssh"
  defaults['sshkeytype']      = "rsa"
  defaults['sshkeyfile']      = defaults['home'].to_s+"/.ssh/id_"+defaults['sshkeytype'].to_s+".pub"
  defaults['sshkeybits']      = "2048"
  defaults['sshport']         = "22"
  defaults['sshpty']          = true
  defaults['sshtimeout']      = "1h"
  defaults['sudo']            = true
  if defaults['host-lsb-description'].to_s.match(/Endeavour|Arch/)
    defaults['sudogroup'] = "wheel"
  else
    defaults['sudogroup'] = "sudo"
  end
  defaults['sudoers']         = "ALL=(ALL) NOPASSWD:ALL"
  defaults['suffix']          = defaults['scriptname'].to_s
  defaults['systemlocale']    = "C"
  defaults['target']          = "vmware"
  defaults['terminal']        = "sun"
  defaults['techpreview']     = false
  defaults['text']            = false
  defaults['timeserver']      = "0."+defaults['country'].to_s.downcase+".pool.ntp.org"
  defaults['tmpdir']          = "/tmp"
  defaults['tftpdir']         = "/etc/netboot"
  defaults['thindiskmode']    = "true"
  defaults['time']            = "Eastern Standard Time"
  defaults['timezone']        = "Australia/Victoria"
  defaults['trunk']           = 'stable'
  defaults['ubuntumirror']    = "mirror.aarnet.edu.au"
  defaults['ubuntudir']       = "/ubuntu"
  defaults['uid']             = %x[/usr/bin/id -u].chomp
  defaults['uid']             = Integer(defaults['uid'])
  defaults['uuid']            = ""
  defaults['unmasked']        = false
  defaults['usemirror']       = false
  defaults['usb']             = true
  defaults['usbxhci']         = true
  defaults['user']            = %x[whoami].chomp
  defaults['utc']             = "off"
  defaults['vboxadditions']   = "/Applications/VirtualBox.app//Contents/MacOS/VBoxGuestAdditions.iso"
  defaults['vboxmanage']      = "/usr/local/bin/VBoxManage"
  defaults['vcpu']            = "1"
  defaults['vgname']          = "vg01"
  defaults['vnc']             = false
  defaults['verbose']         = "false"
  defaults['virtiofile']      = ""
  defaults['virtualdevice']   = "lsilogic"
  defaults['vmntools']        = false
  defaults['vmnetwork']       = "hostonly"
  defaults['vncpassword']     = "P455w0rd"
#  defaults['vncport']         = "5961"
  defaults['vncport']         = "5900"
  defaults['vlanid']          = "0"
#  defaults['vm']              = "vbox"
  defaults['vmnet']           = "vboxnet0"
  defaults['vmnetdhcp']       = false
  defaults['vmnetwork']       = "hostonly"
  defaults['vmtools']         = "disable"
  defaults['vmtype']          = ""
  defaults['vswitch']         = "vSwitch0"
  defaults['vtxvpid']         = "on"
  defaults['vtxux']           = "on"
  defaults['wikidir']         = defaults['scriptdir'].to_s+"/"+File.basename(defaults['script'],".rb")+".wiki"
  defaults['wikiurl']         = "https://github.com/lateralblast/mode.wiki.git"
  defaults['winrmport']       = "5985"
  defaults['winshell']        = "winrm"
  defaults['winrmusessl']     = false
  defaults['winrminsecure']   = true
  defaults['workdir']         = defaults['home'].to_s+"/.modest"
  defaults['backupdir']       = defaults['workdir'].to_s+"/backup"
  defaults['bindir']          = defaults['workdir'].to_s+"/bin"
  defaults['rpmdir']          = defaults['workdir'].to_s+"/rpms"
  defaults['zonedir']         = '/zones'
  defaults['yes']             = false
  defaults['zpoolname']       = 'rpool'
  if values['vm'].to_s.match(/kvm/)
    defaults['cdrom']           = "none"
    defaults['install']         = "none"
    defaults['controller']      = "none"
    defaults['container']       = false
    defaults['destroy-on-exit'] = false
    defaults['check']           = false
  end
  # Set Host OS specific information
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
  return values, defaults
end

# Set some parameter once we have more details

def reset_defaults(values, defaults)
  if values['file'].to_s.match(/[a-z]/)
    defaults['arch'] = get_install_arch_from_file(values)
    if !values['service'].to_s.match(/[a-z]/)
      defaults['service'] = get_install_service_from_file(values)
    end
  end
  if values['file'].to_s.match(/VMware-VMvisor-Installer/)
    defaults['vcpus']  = "4"
    defaults['memory'] = "4096"
  end
  if defaults['host-os-unamep'].to_s.match(/^arm/)
    defaults['machine']  = "arm64"
    defaults['arch']     = "arm64"
    defaults['biostype'] = "efi"
  end
  if values['vm'].to_s.match(/kvm/) && values['file'].to_s.match(/cloudimg/)
    defaults['method'] = "ci"
  end
  if values['service'].to_s.match(/live/) || values['file'].to_s.match(/live/)
    defaults['livecd'] = true
  end
  if values['ip'].to_s.match(/[0-9]/)
    defaults['dhcp'] = false
  else
    defaults['dhcp'] = true
  end
  if values['os-type'].to_s.match(/win/)
    defaults['adminuser'] = "Administrator"
    defaults['adminname'] = "Administrator"
  end
  if values['vm'].to_s.match(/kvm/)
    if values['host-os-uname'].to_s.match(/Darwin/)
      if Dir.exist?("/opt/homebrew/Cellar")
        defaults['imagedir'] = "/opt/homebrew/Cellar/libvirt/images"
      else
        defaults['imagedir'] = "/usr/local/Cellar/libvirt/images"
      end
    else
      defaults['imagedir'] = "/var/lib/libvirt/images"
    end
    defaults['console']  = "pty,target_type=virtio"
    defaults['mac']      = generate_mac_address(values)
    if !values['bridge'].to_s.match(/br[0-9]/)
      defaults['network'] = "bridge="+defaults['bridge'].to_s
    else
      defaults['network'] = "bridge="+values['bridge'].to_s
    end
    defaults['features']  = "kvm_hidden=on"
    defaults['vmnetwork'] = "hostonly"
    if defaults['host-os-unamep'].to_s.match(/^x/)
      defaults['machine'] = "q35"
      defaults['arch']    = "x86_64"
    end
    if not values['disk']
      if values['name'].to_s.match(/\,/)
        host_name = values['name'].to_s.split(/\,/)[0]
      else
        host_name = values['name'].to_s
      end
      defaults['disk'] = "path="+defaults['imagedir'].to_s+"/"+host_name+"-seed.qcow2 path="+defaults['imagedir'].to_s+"/"+host_name+".qcow2,device=disk"
    end
    defaults['cpu']  = "host-passthrough"
    defaults['boot'] = "hd,menu=on"
    if !values['type'].to_s.match(/packer/) && values['action'].to_s.match(/create/)
      defaults['import'] = true
    end
    defaults['rootdisk'] = "/dev/vda"
  end
  if values['vmnetwork'].to_s.match(/nat/)
    if values['ip'] == values['empty']
      defaults['dhcp'] = true
    end
  end
  if values['noreboot'] == true
    defaults['reboot'] = false
  end
  if values['type'].to_s.match(/bucket|ami|instance|object|snapshot|stack|cf|cloud|image|key|securitygroup|id|iprule/) && values['dir'] == values['empty'] && values['vm'] == values['empty']
    values['vm'] = "aws"
  end
  defaults['timeserver'] = "0."+defaults['country'].to_s.downcase+".pool.ntp.org"
  if values['vm'] != values['empty']
    vm_type = values['vm'].to_s
  else
    vm_type = defaults['vm'].to_s
  end
  case vm_type
  when /mp|multipass/
    if values['biosdevnames'] == true
      values['vmnic'] = "eth0"
    end
    defaults['size']  = "20G"
    defaults['dhcp']  = true
    if defaults['host-os-uname'].to_s.match(/Darwin/)
      defaults['vmnet'] = "bridge100"
    else
      defaults['vmnet'] = "mpqemubr0"
      defaults['vmgateway']  = "10.251.24.1"
      defaults['hostonlyip'] = "10.251.24.1"
    end
    defaults['memory']  = "1G"
    defaults['release'] = "20.04"
    defaults['vmnetwork'] = "hostonly"
    if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 11
      defaults['vmgateway']  = "192.168.64.1"
      defaults['hostonlyip'] = "192.168.64.1"
    else
      defaults['vmgateway']  = "172.16.10.1"
      defaults['hostonlyip'] = "172.16.10.1"
    end
  when /parallels/
    if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      defaults['vmgateway']  = "10.211.55.1"
      defaults['hostonlyip'] = "10.211.55.1"
    else
      defaults['vmgateway']  = "192.168.54.1"
      defaults['hostonlyip'] = "192.168.54.1"
    end
  when /fusion/
    defaults['hwversion'] = get_fusion_version(values)
    if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 10
      if values['vmnetwork'].to_s.match(/nat/)
        defaults['vmgateway']  = "192.168.158.1"
        defaults['hostonlyip'] = "192.168.158.1"
      else
        if defaults['host-os-uname'].to_s.match(/Darwin/) && defaults['host-os-version'].to_i > 11
          defaults['vmgateway']  = "192.168.2.1"
          defaults['hostonlyip'] = "192.168.2.1"
        else
          if values['vmnetwork'].to_s.match(/bridged/)
            defaults['vmgateway']  = get_ipv4_default_route(values)
            defaults['hostonlyip'] = defaults['hostip']
          else
            defaults['vmgateway']  = "192.168.104.1"
            defaults['hostonlyip'] = "192.168.104.1"
          end
        end
      end
      if File.exist?("/usr/local/bin/multipass")
        defaults['vmnet'] = "bridge101"
      else
        defaults['vmnet'] = "bridge100"
      end
    else
      defaults['vmnet'] = "vmnet1"
    end
  when /kvm/
    defaults['vmnet'] = "virbr0"
  when /vbox/
    defaults['vmnet'] = "vboxnet0"
  when /dom/
    defaults['vmnet']  = "net0"
    defaults['mau']    = "1"
    defaults['memory'] = "1"
    defaults['vmnic']  = "vnet0"
    defaults['vcpu']   = "8"
    defaults['size']   = "20G"
  when /aws/
    defaults['type'] = "instance"
    if values['action'].to_s.match(/list/)
      defaults['group']    = "all"
      defaults['secgroup'] = "all"
      defaults['key']      = "all"
      defaults['keypair']  = "all"
      defaults['stack']    = "all"
      defaults['awsuser']  = "ec2-user"
    else
      values['group']      = "default"
      values['secgroup']   = "default"
      values['service']    = "amazon-ebs"
      values['size']       = "t2.micro"
      defaults['importid'] = "c4d8eabf8db69dbe46bfe0e517100c554f01200b104d59cd408e777ba442a322"
    end
    case values['os-type']
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
  case values['type']
  when /vcsa/
    defaults['size'] = "tiny"
  when /packer/
    if values['vmnetwork'].to_s.match(/hostonly/)
      defaults['sshport'] = "22"
    else
      if values['method'].to_s.match(/vs/)
        defaults['sshport'] = "22"
      else
        defaults['sshport'] = "2222"
      end
    end
    defaults['sshportmax'] = defaults['sshport']
    defaults['sshportmin'] = defaults['sshport']
  end
  case values['method']
  when /ai/
    if values['type'].to_s.match(/packer/)
      defaults['size'] = "20G"
    else
      defaults['size'] = "large"
    end
  when /pe/
    if values['type'].to_s.match(/packer/)
      defaults['size'] = "20G"
    else
      defaults['size'] = "500"
    end
  when /ps/
    defaults['software'] = "openssh-server"
    defaults['language'] = "en"
  end
  case values['service']
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
  case values['vm']
  when /aws/
    defaults['cidr'] = "0.0.0.0/0"
  end
  if values['os-type'].to_s.match(/vmware/)
    defaults['size'] = "40G"
  end
  if values['test'] == true
    defaults['test']     = true
    defaults['download'] = false
  else
    defaults['download'] = true
    defaults['test']     = false
  end
  if values['keyname'] == values['empty']
    if values['name'] != values['empty']
      if values['region'] != values['empty']
        defaults['keyname'] = values['name'].to_s+"-"+values['region'].to_s
      else
        defaults['keyname'] = values['name'].to_s+"-"+defaults['region'].to_s
      end
    else
      if values['region'] != values['empty']
        defaults['keyname'] = values['region'].to_s
      else
        defaults['keyname'] = defaults['region'].to_s
      end
    end
  end
  if values['vmnetwork'].to_s.match(/hostonly/)
    values['packersshport'] = "22"
  end
  return defaults
end
