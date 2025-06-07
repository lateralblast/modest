# frozen_string_literal: true

# Windows related code

# List PE clients

def list_pe_clients(values)
  values['method'] = 'pe'
  list_clients(values)
  nil
end

# Populate post install commands

def populate_pe_post_list(admin_username, admin_password, values)
  post_list = []
  post_list.push('cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force",Set Execution Policy 64 Bit,true')
  post_list.push('C:\\Windows\\SysWOW64\\cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force",Set Execution Policy 32 Bit,true')
  if values['winshell'].to_s.match(/winrm/)
    post_list.push('cmd.exe /c winrm quickconfig -q,winrm quickconfig -q,true')
    post_list.push('cmd.exe /c winrm quickconfig -transport:http,winrm quickconfig -transport:http,true')
    post_list.push('cmd.exe /c winrm set winrm/config @{MaxTimeoutms="1800000"},Win RM MaxTimoutms,true')
    if values['label'].to_s.match(/20[1,2][0-9]/)
      post_list.push("cmd.exe /c winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"800\"}',Win RM MaxMemoryPerShellMB,true")
    else
      post_list.push("cmd.exe /c winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"0\"}',Win RM MaxMemoryPerShellMB,true")
    end
    post_list.push('cmd.exe /c winrm set winrm/config/service @{AllowUnencrypted="true"},Win RM AllowUnencrypted,true')
    post_list.push('cmd.exe /c winrm set winrm/config/service/auth @{Basic="true"},Win RM auth Basic,true')
    post_list.push('cmd.exe /c winrm set winrm/config/client/auth @{Basic="true"},Win RM client auth Basic,true')
    post_list.push('cmd.exe /c winrm set winrm/config/listener?Address=*+Transport=HTTP @{Port="5985"},Win RM listener Address/Port,true')
    post_list.push('cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes,Win RM adv firewall enable,true')
    post_list.push('cmd.exe /c netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow,Allow WinRM HTTP,true')
    post_list.push("cmd.exe /c winrm set winrm/config/winrs '@{MaxProcessesPerShell=\"0\"}',Win RM MaxProcessesPerShell,true") if values['label'].to_s.match(/2008/)
    post_list.push('cmd.exe /c net stop winrm,Stop Win RM Service,true')
    post_list.push('cmd.exe /c sc config winrm start= auto,Win RM Autostart,true')
    post_list.push('cmd.exe /c net start winrm,Start Win RM Service,true')
  end
  if values['winshell'].to_s.match(/ssh/)
    post_list.push('cmd.exe /c netsh advfirewall firewall add rule name="INSTALL-HTTP" dir=out localport=8888 protocol=TCP action=allow,Allow WinRM HTTP,true')
    post_list.push('cmd.exe /c C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -File  A:\\openssh.ps1,Install OpenSSH,true')
  end
  post_list.push('%SystemRoot%\\System32\\reg.exe ADD HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\ /v HideFileExt /t REG_DWORD /d 0 /f,Show file extensions in Explorer,false')
  post_list.push('%SystemRoot%\\System32\\reg.exe ADD HKCU\\Console /v QuickEdit /t REG_DWORD /d 1 /f,Enable QuickEdit mode,false')
  post_list.push('%SystemRoot%\\System32\\reg.exe ADD HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\ /v Start_ShowRun /t REG_DWORD /d 1 /f,Show Run command in Start Menu,false')
  post_list.push('%SystemRoot%\\System32\\reg.exe ADD HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced\\ /v StartMenuAdminTools /t REG_DWORD /d 1 /f,Show Administrative Tools in Start Menu,false')
  post_list.push('%SystemRoot%\\System32\\reg.exe ADD HKLM\\SYSTEM\\CurrentControlSet\\Control\\Power\\ /v HibernateFileSizePercent /t REG_DWORD /d 0 /f,Zero Hibernation File,false')
  post_list.push('%SystemRoot%\\System32\\reg.exe ADD HKLM\\SYSTEM\\CurrentControlSet\\Control\\Power\\ /v HibernateEnabled /t REG_DWORD /d 0 /f,Zero Hibernation File,false')
  if values['label'].to_s.match(/20[1,2][0-9]/)
    post_list.push('cmd.exe /c reg add "HKLM\\SYSTEM\\CurrentControlSet\\Control\\Network\\NewNetworkWindowOff",Turn off Network Location Wizard,false')
    post_list.push('%SystemRoot%\\System32\\reg.exe ADD HKLM\\SYSTEM\\CurrentControlSet\\Control\\Network\\NetworkLocationWizard\\ /t REG_DWORD /d 1 /f,Hide Network Wizard,false')
  end
  post_list.push("cmd.exe /c net user #{admin_username} #{admin_password},Set #{admin_username} password,true")
  post_list.push("cmd.exe /c wmic useraccount where \"name='#{admin_username}'\" set PasswordExpires=FALSE,Disable password expiration for #{admin_username} user,false")
  post_list
end

# Create Autounattend.xml

def output_pe_client_profile(values, output_file)
  xml_output      = []
  command         = ''
  description     = ''
  userinput       = ''
  counter         = 1
  number          = ''
  locale          = values['answers']['locale'].value
  timezone        = values['answers']['timezone'].value
  boot_disk_size  = values['answers']['boot_disk_size'].value
  admin_fullname  = values['answers']['admin_fullname'].value
  admin_username  = values['answers']['admin_username'].value
  admin_password  = values['answers']['admin_password'].value
  organisation    = values['answers']['organisation'].value
  cpu_arch        = values['answers']['cpu_arch'].value
  values['license']   = values['answers']['license_key'].value
  values['vmnetwork'] = values['answers']['network_type'].value
  if values['vmnetwork'].to_s.match(/hostonly|bridged/)
    network_name = values['answers']['network_name'].value
    values['answers']['network_cidr'].value
    network_ip    = values['answers']['ip_address'].value
    gateway_ip    = values['answers']['gateway_address'].value
    nameserver_ip = values['answers']['nameserver_ip'].value
    search_domain = values['answers']['search_domain'].value
  end
  # Put in some Microsoft Eval Keys if no license specified
  unless values['license'].to_s.match(/[0-9]/)
    case values['label'].to_s
    when /2008/
      values['license'] = if values['label'].to_s.match(/R2/)
                            'YC6KT-GKW9T-YTKYR-T4X34-R7VHC'
                          else
                            'TM24T-X9RMF-VWXK6-X8JC9-BFGM2'
                          end
    when /2012/
      values['license'] = if values['label'].to_s.match(/R2/)
                            'D2N9P-3P6X9-2R39C-7RTCD-MDVJX'
                          else
                            'BN3D2-R7TKB-3YPBD-8DRP2-27GG4'
                          end
    when /2016|2019|2020/
      values['license'] = ''
    end
  end
  post_list = populate_pe_post_list(admin_username, admin_password, values)
  xml       = Builder::XmlMarkup.new(target: xml_output, indent: 2)
  xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
  xml.unattend(xmlns: 'urn:schemas-microsoft-com:unattend') do
    if values['label'].to_s.match(/20[1,2][0-9]/)
      xml.settings(pass: 'windowsPE') do
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-International-Core-WinPE', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.SetupUILanguage do
            xml.UILanguage(locale.to_s)
          end
          xml.InputLocale(locale.to_s)
          xml.SystemLocale(locale.to_s)
          xml.UILanguage(locale.to_s)
          xml.UILanguageFallback(locale.to_s)
          xml.UserLocale(locale.to_s)
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-Setup', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.DiskConfiguration do
            xml.Disk("wcm:action": 'add') do
              xml.CreatePartitions do
                xml.CreatePartition("wcm:action": 'add') do
                  xml.Type('Primary')
                  xml.Order('1')
                  xml.Size(boot_disk_size.to_s)
                end
                xml.CreatePartition("wcm:action": 'add') do
                  xml.Order('2')
                  xml.Type('Primary')
                  xml.Extend('true')
                end
              end
              xml.ModifyPartitions do
                xml.ModifyPartition("wcm:action": 'add') do
                  xml.Active('true')
                  xml.Format('NTFS')
                  xml.Label('boot')
                  xml.Order('1')
                  xml.PartitionID('1')
                end
                xml.ModifyPartition("wcm:action": 'add') do
                  xml.Format('NTFS')
                  xml.Label('Windows')
                  xml.Letter('C')
                  xml.Order('2')
                  xml.PartitionID('2')
                end
              end
              xml.DiskID('0')
              xml.WillWipeDisk('true')
            end
          end
          xml.ImageInstall do
            xml.OSImage do
              xml.InstallFrom do
                xml.MetaData("wcm:action": 'add') do
                  xml.Key('/IMAGE/NAME')
                  xml.Value(values['label'].to_s)
                end
              end
              xml.InstallTo do
                xml.DiskID('0')
                xml.PartitionID('2')
              end
            end
          end
          xml.UserData do
            if values['license'].to_s.match(/[A-Z]|[0-9]/)
              xml.ProductKey do
                xml.Key(values['license'].to_s)
                xml.WillShowUI('Never')
              end
            end
            xml.AcceptEula('true')
            xml.FullName(admin_fullname.to_s)
            xml.Organization(organisation.to_s)
          end
        end
      end
      xml.settings(pass: 'specialize') do
        if values['vmnetwork'].to_s.match(/hostonly|bridged/) && network_ip.match(/[0-9]/)
          xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                        "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-TCPIP', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
            xml.Interfaces do
              xml.Interface("wcm:action": 'add') do
                xml.Ipv4Settings do
                  xml.DhcpEnabled('false')
                end
                xml.Identifier(network_name.to_s)
                xml.UnicastIpAddresses do
                  xml.IpAddress("#{network_ip}/#{values['cidr']}", "wcm:action": 'add', "wcm:keyValue": '1')
                end
                xml.Routes do
                  xml.Route("wcm:action": 'add') do
                    xml.Identifier('0')
                    xml.Prefix('0.0.0.0/0')
                    xml.Metric('20')
                    xml.NextHopAddress(gateway_ip.to_s)
                  end
                end
              end
            end
          end
        end
        if values['vmnetwork'].to_s.match(/hostonly|bridged/) && nameserver_ip.match(/[0-9]/)
          xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                        "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-DNS-Client', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
            xml.Interfaces do
              xml.Interface("wcm:action": 'add') do
                xml.DNSServerSearchOrder do
                  xml.IpAddress(nameserver_ip.to_s, "wcm:action": 'add', "wcm:keyValue": '1')
                end
                xml.Identifier(network_name.to_s)
                xml.EnableAdapterDomainNameRegistration('false')
                xml.DNSDomain(search_domain.to_s)
                xml.DisableDynamicUpdate('false')
              end
            end
            xml.UseDomainNameDevolution('false')
            xml.DNSDomain(search_domain.to_s)
          end
        end
        xml.component(name: 'Microsoft-Windows-Shell-Setup', processorArchitecture: cpu_arch.to_s,
                      publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.OEMInformation do
            xml.HelpCustomized('false')
          end
          xml.ComputerName(values['name'].to_s)
          xml.TimeZone(timezone.to_s)
          xml.RegisteredOwner
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-ServerManager-SvrMgrNc', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.DoNotOpenServerManagerAtLogon('true')
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-IE-ESC', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.IEHardenAdmin('false')
          xml.IEHardenUser('false')
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-OutOfBoxExperience', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.DoNotOpenInitialConfigurationTasksAtLogon('true')
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-Security-SPP-UX', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.SkipAutoActivation('true')
        end
      end
      xml.settings(pass: 'oobeSystem') do
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-Shell-Setup', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.UserAccounts do
            xml.AdministratorPassword do
              xml.Value(admin_password.to_s)
              xml.PlainText('true')
            end
            xml.LocalAccounts do
              xml.LocalAccount("wcm:action": 'add') do
                xml.Password do
                  xml.Value(admin_password.to_s)
                  xml.PlainText('true')
                end
                xml.DisplayName(admin_fullname.to_s)
                xml.Description("#{admin_fullname} User")
                xml.Group('administrators')
                xml.Name(admin_username.to_s)
              end
            end
          end
          xml.OOBE do
            xml.HideEULAPage('true')
            xml.HideLocalAccountScreen('true')
            xml.HideOEMRegistrationScreen('true')
            xml.HideOnlineAccountScreens('true')
            xml.HideWirelessSetupInOOBE('true')
            xml.NetworkLocation('Home')
            xml.ProtectYourPC('1')
          end
          xml.AutoLogon do
            xml.Password do
              xml.Value(admin_password.to_s)
              xml.PlainText('true')
            end
            xml.Username(admin_username.to_s)
            xml.Enabled('true')
          end
          xml.FirstLogonCommands do
            post_list.each do |item|
              (command, description, userinput) = item.split(/,/)
              xml.SynchronousCommand("wcm:action": 'add') do
                xml.CommandLine(command.to_s)
                xml.Description(description.to_s)
                number = counter.to_s
                xml.Order(number.to_s)
                counter += 1
                xml.RequiresUserInput('true') if userinput.match(/true/)
              end
            end
          end
        end
      end
      xml.settings(pass: 'offlineServicing') do
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-LUA-Settings', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.EnableLUA('false')
        end
      end
      xml.tag!(:"cpi:offlineImage", "xmlns:cpi": 'urn:schemas-microsoft-com:cpi',
                                    "cpi:source": "catalog:d:/sources/#{values['label']}.clg")
    end
    if values['label'].to_s.match(/2008/)
      xml.servicing
      xml.settings(pass: 'windowsPE') do
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-Setup', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.DiskConfiguration do
            xml.Disk("wcm:action": 'add') do
              xml.CreatePartitions do
                xml.CreatePartition("wcm:action": 'add') do
                  xml.Order('1')
                  xml.Type('Primary')
                  xml.Extend('true')
                end
              end
              xml.ModifyPartitions do
                xml.ModifyPartition("wcm:action": 'add') do
                  xml.Active('false')
                  xml.Format('NTFS')
                  xml.Letter('C')
                  xml.Order('1')
                  xml.PartitionID('1')
                  xml.Label('Windows')
                end
              end
              xml.DiskID('0')
              xml.WillWipeDisk('true')
            end
            xml.WillShowUI('OnError')
          end
          xml.UserData do
            xml.AcceptEula('true')
            xml.FullName(admin_fullname.to_s)
            xml.Organization(organisation.to_s)
            xml.ProductKey do
              xml.Key(values['license'].to_s)
              xml.WillShowUI('Never')
            end
          end
          xml.ImageInstall do
            xml.OSImage do
              xml.InstallTo do
                xml.DiskID('0')
                xml.PartitionID('1')
              end
              xml.WillShowUI('OnError')
              xml.InstallToAvailablePartition('false')
              xml.InstallFrom do
                xml.MetaData("wcm:action": 'add') do
                  xml.Key('/IMAGE/NAME')
                  xml.Value(values['label'].to_s)
                end
              end
            end
          end
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-International-Core-WinPE', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.SetupUILanguage do
            xml.UILanguage(locale.to_s)
          end
          xml.InputLocale(locale.to_s)
          xml.SystemLocale(locale.to_s)
          xml.UILanguage(locale.to_s)
          xml.UILanguageFallback(locale.to_s)
          xml.UserLocale(locale.to_s)
        end
      end
      xml.settings(pass: 'offlineServicing') do
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-LUA-Settings', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.EnableLUA('false')
        end
      end
      xml.settings(pass: 'oobeSystem') do
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-Shell-Setup', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.UserAccounts do
            xml.AdministratorPassword do
              xml.Value(admin_password.to_s)
              xml.PlainText('true')
            end
            xml.LocalAccounts do
              xml.LocalAccount("wcm:action": 'add') do
                xml.Password do
                  xml.Value(admin_password.to_s)
                  xml.PlainText('true')
                end
                xml.DisplayName(admin_fullname.to_s)
                xml.Description("#{admin_fullname} User")
                xml.Group('administrators')
                xml.Name(admin_username.to_s)
              end
            end
          end
          xml.OOBE do
            xml.HideEULAPage('true')
            xml.HideWirelessSetupInOOBE('true')
            xml.NetworkLocation('Home')
          end
          xml.AutoLogon do
            xml.Password do
              xml.Value(admin_password.to_s)
              xml.PlainText('true')
            end
            xml.Username(admin_username.to_s)
            xml.Enabled('true')
          end
          xml.FirstLogonCommands do
            post_list.each do |item|
              (command, description, userinput) = item.split(/,/)
              xml.SynchronousCommand("wcm:action": 'add') do
                xml.CommandLine(command.to_s)
                xml.Description(description.to_s)
                number = counter.to_s
                xml.Order(number.to_s)
                counter += 1
                xml.RequiresUserInput('true') if userinput.match(/true/)
              end
            end
          end
        end
      end
      xml.settings(pass: 'specialize') do
        if values['vmnetwork'].to_s.match(/hostonly|bridged/) && network_ip.match(/[0-9]/)
          xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                        "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-TCPIP', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
            xml.Interfaces do
              xml.Interface("wcm:action": 'add') do
                xml.Ipv4Settings do
                  xml.DhcpEnabled('false')
                end
                xml.Identifier(network_name.to_s)
                xml.UnicastIpAddresses do
                  xml.IpAddress("#{network_ip}/#{values['cidr']}", "wcm:action": 'add', "wcm:keyValue": '1')
                end
                xml.Routes do
                  xml.Route("wcm:action": 'add') do
                    xml.Identifier('0')
                    xml.Prefix('0.0.0.0/0')
                    xml.Metric('20')
                    xml.NextHopAddress(gateway_ip.to_s)
                  end
                end
              end
            end
          end
        end
        if values['vmnetwork'].to_s.match(/hostonly|bridged/) && nameserver_ip.match(/[0-9]/)
          xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                        "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-DNS-Client', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
            xml.Interfaces do
              xml.Interface("wcm:action": 'add') do
                xml.DNSServerSearchOrder do
                  xml.IpAddress(nameserver_ip.to_s, "wcm:action": 'add', "wcm:keyValue": '1')
                end
                xml.Identifier(network_name.to_s)
                xml.EnableAdapterDomainNameRegistration('false')
                xml.DNSDomain(search_domain.to_s)
                xml.DisableDynamicUpdate('false')
              end
            end
            xml.UseDomainNameDevolution('false')
            xml.DNSDomain(search_domain.to_s)
          end
        end
        xml.component(name: 'Microsoft-Windows-Shell-Setup', processorArchitecture: cpu_arch.to_s,
                      publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.OEMInformation do
            xml.HelpCustomized('false')
          end
          xml.ComputerName(values['name'].to_s)
          xml.TimeZone(timezone.to_s)
          xml.RegisteredOwner
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-ServerManager-SvrMgrNc', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.DoNotOpenServerManagerAtLogon('true')
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-IE-ESC', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.IEHardenAdmin('false')
          xml.IEHardenUser('false')
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-OutOfBoxExperience', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.DoNotOpenInitialConfigurationTasksAtLogon('true')
        end
        xml.component("xmlns:wcm": 'http://schemas.microsoft.com/WMIConfig/2002/State',
                      "xmlns:xsi": 'http://www.w3.org/2001/XMLSchema-instance', name: 'Microsoft-Windows-Security-SPP-UX', processorArchitecture: cpu_arch.to_s, publicKeyToken: '31bf3856ad364e35', language: 'neutral', versionScope: 'nonSxS') do
          xml.SkipAutoActivation('true')
        end
      end
      xml.tag!(:"cpi:offlineImage", "xmlns:cpi": 'urn:schemas-microsoft-com:cpi',
                                    "cpi:source": "catalog:d:/sources/#{values['label']}.clg")
    end
  end
  file = File.open(output_file, 'w')
  xml_output.each do |item|
    file.write(item)
  end
  file.close
  message = "Information:\tValidating Windows configuration for #{values['name']}"
  command = "xmllint #{output_file}"
  execute_command(values, message, command)
  nil
end

# Populate Windows winrm powershell script

def populate_winrm_psh(_values)
  winrm_psh = []
  winrm_psh.push('netsh advfirewall firewall set rule group="remote administration" new enable=yes')
  winrm_psh.push('netsh advfirewall firewall add rule name="Open Port 5985" dir=in action=allow protocol=TCP localport=5985')
  winrm_psh.push('')
  winrm_psh.push('winrm quickconfig -q')
  winrm_psh.push('winrm quickconfig -transport:http')
  winrm_psh.push("winrm set winrm/config '@{MaxTimeoutms=\"7200000\"}'")
  winrm_psh.push("winrm set winrm/config/winrs '@{MaxMemoryPerShellMB=\"0\"}'")
  winrm_psh.push("winrm set winrm/config/winrs '@{MaxProcessesPerShell=\"0\"}'")
  winrm_psh.push("winrm set winrm/config/winrs '@{MaxShellsPerUser=\"0\"}'")
  winrm_psh.push("winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'")
  winrm_psh.push("winrm set winrm/config/service/auth '@{Basic=\"true\"}'")
  winrm_psh.push("winrm set winrm/config/client/auth '@{Basic=\"true\"}'")
  winrm_psh.push('')
  winrm_psh.push('net stop winrm')
  winrm_psh.push('sc.exe config winrm start= auto')
  winrm_psh.push('net start winrm')
  winrm_psh.push('')
  winrm_psh.push('Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force')
  winrm_psh
end

# Populate Windows VM Tools powershell script

def populate_vmtools_psh(values)
  vmtools_psh = []
  vmtools_psh.push('')
  if values['vmtools'] == true
    vmtools_psh.push('$isopath = "C:\\Windows\\Temp\\windows.iso"')
    vmtools_psh.push('Mount-DiskImage -ImagePath $isopath')
    vmtools_psh.push('function vmware {')
    vmtools_psh.push("$exe = ((Get-DiskImage -ImagePath $isopath | Get-Volume).Driveletter + ':\\setup.exe')")
    vmtools_psh.push("$parameters = '/S /v \"/qr REBOOT=R\"'")
    vmtools_psh.push('Start-Process $exe $parameters -Wait')
    vmtools_psh.push('}')
    vmtools_psh.push('function virtualbox {')
    vmtools_psh.push("$certpath = ((Get-DiskImage -ImagePath $isopath | Get-Volume).Driveletter + ':\\cert\\oracle-vbox.cer')")
    vmtools_psh.push('certutil -addstore -f "TrustedPublisher" $certpath')
    vmtools_psh.push("$exe = ((Get-DiskImage -ImagePath $isopath | Get-Volume).Driveletter + ':\\VBoxWindowsAdditions.exe')")
    vmtools_psh.push("$parameters = '/S'")
    vmtools_psh.push('Start-Process $exe $parameters -Wait')
    vmtools_psh.push('}')
    vmtools_psh.push('if ($ENV:PACKER_BUILDER_TYPE -eq "vmware-iso") {')
    vmtools_psh.push('    vmware')
    vmtools_psh.push('} else {')
    vmtools_psh.push('    virtualbox')
    vmtools_psh.push('}')
    vmtools_psh.push('Dismount-DiskImage -ImagePath $isopath')
    vmtools_psh.push('Remove-Item $isopath')
  end
  vmtools_psh
end

# Populate Windows OpenSSH powershell script

def populate_openssh_psh(_values)
  openssh_psh = []
  openssh_psh.push('')
  openssh_psh
end

# Output Windows winrm powershell script

def output_psh(values, output_psh, output_file)
  file = File.open(output_file, 'a')
  output_psh.each do |item|
    line = "#{item}\n"
    file.write(line)
  end
  file.close
  print_contents_of_file(values, '', output_file)
  nil
end
