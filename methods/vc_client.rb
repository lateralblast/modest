# VC client code

# Handle VCSA OVA

def handle_vcsa_ova(options)
  if options['file'].to_s.match(/iso$/)
    uid = options['uid']
    check_dir_exists(options,options['baserepodir'])
    check_dir_owner(options,options['baserepodir'],uid)
    options['repodir'] = options['baserepodir']+"/"+options['service']
    check_dir_exists(options,options['repodir'])
    check_dir_owner(options,options['repodir'],uid)
    mount_iso(options)
    copy_iso(options)
    options['file'] = options['repodir']+"/vcsa/vmware-vcsa"
    umount_iso(options)
  end
  return options['file']
end

# Deploy VCSA image

def deploy_vcsa_vm(options)
  populate_vcsa_questions(options)
  process_questions(options)
  options['server']          = $q_struct['esx.hostname'].value
  options['datastore']       = $q_struct['esx.datastore'].value
  options['serveradmin']     = $q_struct['esx.username'].value
  options['serverpassword']  = $q_struct['esx.password'].value
  options['size']            = $q_struct['deployment.option'].value
  options['servernetmask']  = $q_struct['deployment.network'].value
  options['name']          = $q_struct['appliance.name'].value
  options['rootpassword']   = $q_struct['root.password'].value
  options['timeserver']      = $q_struct['ntp.servers'].value
  options['adminpassword']  = $q_struct['password'].value
  options['domainname']      = $q_struct['domain-name'].value
  options['sitename']        = $q_struct['site-name'].value
  options['ipfamil']        = $q_struct['ip.family'].value
  options['ip']              = $q_struct['ip'].value
  options['netmask']         = $q_struct['prefix'].value
  options['vmgateway']         = $q_struct['gateway'].value
  options['nameserver']      = $q_struct['dns.servers'].value
  vcsa_json_file = create_vcsa_json(options)
  #create_cvsa_deploy_script(options)
  options['repodir'] = options['baserepodir']+"/"+options['service']
  if options['osname'].to_s.match(/Darwin/)
    deployment_dir = options['repodir']+"/vcsa-cli-installer/mac"
  end
  if options['osname'].to_s.match(/Linux/)
    deployment_dir = options['repodir']+"/vcsa-cli-installer/lin64"
  end
  if File.directory?(deployment_dir)
    message = "Information:\tDeploying VCSA OVA"
    if deployment_dir.match(/6_0_0_3040890/)
      command = "cd #{deployment_dir} ; echo yes | ./vcsa-deploy install #{vcsa_json_file} --accept-eula -v"
    else
      if deployment_dir.match(/6_[5-6]/)
        command = "cd #{deployment_dir} ; echo 1 | ./vcsa-deploy install #{vcsa_json_file} --accept-eula -v"
      else
        if deployment_dir.match(/6_7/)
          command = "cd #{deployment_dir} ; echo 1 | ./vcsa-deploy install #{vcsa_json_file}  --no-ssl-certificate-verification --accept-eula --acknowledge-ceip -v"
        else
          command = "cd #{deployment_dir} ; echo yes | ./vcsa-deploy install #{vcsa_json_file} -v"
        end
      end
    end
    execute_command(options,message,command)
  end
  return
end

# Create deployment script

def create_cvsa_deploy_script(options)
  options['netmask'] = options['netmask'].gsub(/\//,"")
  uid = %x[id -u].chomp
  check_dir_exists(options,options['clientdir'])
  check_dir_owner(options,options['clientdir'],uid)
  service_dir = options['clientdir']+"/"+options['service']
  check_dir_exists(options,service_dir)
  options['clientdir']  = service_dir+"/"+options['name']
  check_dir_exists(options,options['clientdir'])
  output_file = options['clientdir']+"/"+options['name']+".sh"
  check_dir_exists(options,options['clientdir'])
  file = File.open(output_file,"w")
  file.write("#!/bin/bash\n")
  file.write("\n")
  file.write("OVFTOOL=\"#{options['ovfbin']}\"\n")
  file.write("VCSA_OVA=#{options['file']}\n")
  file.write("\n")
  file.write("ESXI_HOST=#{options['server']}\n")
  file.write("ESXI_USERname = #{options['serveradmin']}\n")
  file.write("ESXI_PASSWORD=#{options['serverpassword']}\n")
  file.write("VM_NETWORK=\"#{options['servernetmask']}\"\n")
  file.write("VM_DATASTORE=#{options['datastore']}\n")
  file.write("\n")
  file.write("# Configurations for VC Management Node\n")
  file.write("VCSA_VMname = #{options['name']}\n")
  file.write("VCSA_ROOT_PASSWORD=#{options['adminpassword']}\n")
  file.write("VCSA_NETWORK_MODE=static\n")
  file.write("VCSA_NETWORK_FAMILY=#{options['ipfamil']}\n")
  file.write("## IP Network Prefix (CIDR notation)\n")
  file.write("VCSA_NETWORK_PREFIX=#{options['netmask']}\n")
  file.write("## Same value as VCSA_IP if no DNS\n")
  file.write("VCSA_HOSTNAME = #{options['ip']}\n")
  file.write("VCSA_IP=#{options['ip']}\n")
  file.write("VCSA_GATEWAY=#{options['vmgateway']}\n")
  file.write("VCSA_DNS=#{options['nameserver']}\n")
  file.write("VCSA_ENABLE_SSH=True\n")
  file.write("VCSA_DEPLOYMENT_SIZE=#{options['size']}\n")
  file.write("\n")
  file.write("# Configuration for SSO\n")
  file.write("SSO_DOMAIN_name = #{options['domainname']}\n")
  file.write("SSO_SITE_name = #{options['sitename']}\n")
  file.write("SSO_ADMIN_PASSWORD=#{options['adminpassword']}\n")
  file.write("\n")
  file.write("# NTP Servers\n")
  file.write("NTP_SERVERS=#{options['timeserver']}\n")
  file.write("\n")
  file.write("### DO NOT EDIT BEYOND HERE ###\n")
  file.write("\n")
  file.write("echo -e \"\nDeploying vCenter Server Appliance Embedded w/PSC ${VCSA_VMNAME} ...\"\n")
  file.write("\"${OVFTOOL}\" --acceptAllEulas --skipManifestCheck --X:injectOvfEnv --allowExtraConfig --X:enableHiddenProperties --X:waitForIp --sourceType=OVA --powerOn \\\n")
  file.write("\"--net:Network 1=${VM_NETWORK}\" --datastore=${VM_DATASTORE} --diskMode=thin --name = ${VCSA_VMNAME} \\\n")
  file.write("\"--deploymentOption=${VCSA_DEPLOYMENT_SIZE}\" \\\n")
  file.write("\"--prop:guestinfo.cis.vmdir.domain-name = ${SSO_DOMAIN_NAME}\" \\\n")
  file.write("\"--prop:guestinfo.cis.vmdir.site-name = ${SSO_SITE_NAME}\" \\\n")
  file.write("\"--prop:guestinfo.cis.vmdir.password=${SSO_ADMIN_PASSWORD}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.addr.family=${VCSA_NETWORK_FAMILY}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.addr=${VCSA_IP}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.pnid=${VCSA_HOSTNAME}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.prefix=${VCSA_NETWORK_PREFIX}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.mode=${VCSA_NETWORK_MODE}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.dns.servers=${VCSA_DNS}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.net.gateway=${VCSA_GATEWAY}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.root.passwd=${VCSA_ROOT_PASSWORD}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.ssh.enabled=${VCSA_ENABLE_SSH}\" \\\n")
  file.write("\"--prop:guestinfo.cis.appliance.ntp.servers=${NTP_SERVERS}\" \\\n")
  file.write("${VCSA_OVA} \"vi://${ESXI_USERNAME}:${ESXI_PASSWORD}@${ESXI_HOST}/\"\n")
  file.close()
  if File.exist?(output_file)
    %x[chmod +x #{output_file}]
  end
  return output_file
end

# Create VCSA JSON file

def create_vcsa_json(options)
  options['netmask'] = options['netmask'].gsub(/\//,"")
  if options['service'].to_s.match(/6_[5-6]/)
    json_version = "2.3.0"
  end
  if options['service'].to_s.match(/6_7/)
    json_version = "2.13.0"
    options['cidr'] = netmask_to_cidr(options['netmask'])
  end
  if options['service'].to_s.match(/6_[5-6]/)
    string = "{
                \"__version\": \"#{json_version}\",
                \"new.vcsa\": {
                  \"esxi\": {
                    \"hostname\": \"#{options['server']}\",
                    \"username\": \"#{options['serveradmin']}\",
                    \"password\": \"#{options['serverpassword']}\",
                    \"deployment.network\": \"#{options['servernetmask']}\",
                    \"datastore\": \"#{options['datastore']}\"
                  },
                  \"appliance\": {
                    \"thin.disk.mode\": true,
                    \"deployment.option\": \"tiny\",
                    \"name\": \"#{options['name']}\"
                  },
                  \"network\": {
                    \"ip.family\": \"ipv4\",
                    \"mode\": \"static\",
                    \"ip\": \"#{options['ip']}\",
                    \"dns.servers\": \"#{options['nameserver']}\",
                    \"prefix\": \"#{options['netmask']}\",
                    \"gateway\": \"#{options['vmgateway']}\",
                    \"system.name\": \"#{options['ip']}\"
                  },
                  \"os\": {
                    \"password\": \"#{options['adminpassword']}\",
                    \"ntp.servers\": \"#{options['timeserver']}\",
                    \"ssh.enable\": true
                  },
                  \"sso\": {
                    \"password\": \"#{options['adminpassword']}\",
                    \"domain-name\": \"#{options['domainname']}\",
                    \"site-name\": \"#{options['sitename']}\"
                  }
                },
                \"ceip\": {
                  \"settings\": {
                    \"ceip.enabled\": false
                  }
                }
              }"
  else
    if options['service'].to_s.match(/6_7/)
      system_name = options['name']+"."+options['domainname']
      string = "{
                  \"__version\": \"#{json_version}\",
                  \"new_vcsa\": {
                    \"esxi\": {
                      \"hostname\": \"#{options['server']}\",
                      \"username\": \"#{options['serveradmin']}\",
                      \"password\": \"#{options['serverpassword']}\",
                      \"deployment_network\": \"#{options['servernetmask']}\",
                      \"datastore\": \"#{options['datastore']}\"
                    },
                    \"appliance\": {
                      \"thin_disk_mode\": true,
                      \"deployment_option\": \"tiny\",
                      \"name\": \"#{options['name']}\"
                    },
                    \"network\": {
                      \"ip_family\": \"ipv4\",
                      \"mode\": \"static\",
                      \"ip\": \"#{options['ip']}\",
                      \"dns_servers\": [
                        \"#{options['nameserver']}\"
                      ],
                      \"prefix\": \"#{options['cidr']}\",
                      \"gateway\": \"#{options['vmgateway']}\",
                      \"system_name\": \"#{options['ip']}\"
                    },
                      \"os\": {
                      \"password\": \"#{options['adminpassword']}\",
                      \"ntp_servers\": \"#{options['timeserver']}\",
                      \"ssh_enable\": true
                    },
                      \"sso\": {
                      \"password\": \"#{options['adminpassword']}\",
                      \"domain_name\": \"#{options['domainname']}\"
                    }
                  },
                  \"ceip\": {
                    \"settings\": {
                      \"ceip_enabled\": false
                    }
                  }
                }"
    else
      string = "{ 
                  \"__comments\":
                  [
                    \"VCSA deployment\"
                  ],
  
                  \"deployment\":
                  {
                    \"esx.hostname\":\"#{options['server']}\",
                    \"esx.datastore\":\"#{options['datastore']}\",
                    \"esx.username\":\"#{options['serveradmin']}\",
                    \"esx.password\":\"#{options['serverpassword']}\",
                    \"deployment.option\":\"#{options['size']}\",
                    \"deployment.network\":\"#{options['servernetmask']}\",
                    \"appliance.name\":\"#{options['name']}\",
                    \"appliance.thin.disk.mode\":#{options['thindiskmode']}
                 }, 
                 
                 
                  \"vcsa\":
                  {
  
                    \"system\":
                    {
                      \"root.password\":\"#{options['rootpassword']}\",
                      \"ssh.enable\":true,
                      \"ntp.servers\":\"#{options['timeserver']}\"
                    },
  
                    \"sso\":
                    {
                      \"password\":\"#{options['adminpassword']}\",
                      \"domain-name\":\"#{options['domainname']}\",
                      \"site-name\":\"#{options['sitename']}\"
                    },
  
                    \"networking\":
                    {
                      \"ip.family\":\"#{options['ipfamil']}\",
                      \"mode\":\"static\",
                      \"ip\":\"#{options['ip']}\",
                      \"prefix\":\"#{options['netmask']}\",
                      \"gateway\":\"#{options['vmgateway']}\",
                      \"dns.servers\":\"#{options['nameserver']}\",
                      \"system.name\":\"#{options['ip']}\"
                    }
                  }
               }"
      end
    end
    uid = %x[id -u].chomp
    check_dir_exists(options,options['clientdir'])
    check_dir_owner(options,options['clientdir'],uid)
    service_dir = options['clientdir']+"/"+options['service']
    check_dir_exists(options,service_dir)
    check_dir_owner(options,service_dir,uid)
    options['clientdir']  = service_dir+"/"+options['name']
    check_dir_exists(options,options['clientdir'])
    check_dir_owner(options,options['clientdir'],uid)
    output_file = options['clientdir']+"/"+options['name']+".json"
    check_dir_exists(options,options['clientdir'])
    json   = JSON.parse(string)
    output = JSON.pretty_generate(json)
    file   = File.open(output_file,"w")
    file.write(output)
    file.close()
  return output_file
end
