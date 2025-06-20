# frozen_string_literal: true

# VC client code

# Handle VCSA OVA

def handle_vcsa_ova(values)
  if values['file'].to_s.match(/iso$/)
    uid = values['uid']
    check_dir_exists(values, values['baserepodir'])
    check_dir_owner(values, values['baserepodir'], uid)
    values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
    check_dir_exists(values, values['repodir'])
    check_dir_owner(values, values['repodir'], uid)
    mount_iso(values)
    copy_iso(values)
    values['file'] = "#{values['repodir']}/vcsa/vmware-vcsa"
    umount_iso(values)
  end
  values['file']
end

# Deploy VCSA image

def deploy_vcsa_vm(values)
  populate_vcsa_questions(values)
  process_questions(values)
  values['server']         = values['answers']['esx.hostname'].value
  values['datastore']      = values['answers']['esx.datastore'].value
  values['serveradmin']    = values['answers']['esx.username'].value
  values['serverpassword'] = values['answers']['esx.password'].value
  values['size']           = values['answers']['deployment.option'].value
  values['servernetmask']  = values['answers']['deployment.network'].value
  values['name']           = values['answers']['appliance.name'].value
  values['rootpassword']   = values['answers']['root.password'].value
  values['timeserver']     = values['answers']['ntp.servers'].value
  values['adminpassword']  = values['answers']['password'].value
  values['domainname']     = values['answers']['domain-name'].value
  values['sitename']       = values['answers']['site-name'].value
  values['ipfamil']        = values['answers']['ip.family'].value
  values['ip']             = values['answers']['ip'].value
  values['netmask']        = values['answers']['prefix'].value
  values['vmgateway']      = values['answers']['gateway'].value
  values['nameserver']     = values['answers']['dns.servers'].value
  vcsa_json_file = create_vcsa_json(values)
  # create_vcsa_deploy_script(values)
  values['repodir'] = "#{values['baserepodir']}/#{values['service']}"
  deployment_dir = "#{values['repodir']}/vcsa-cli-installer/mac" if values['host-os-uname'].to_s.match(/Darwin/)
  deployment_dir = "#{values['repodir']}/vcsa-cli-installer/lin64" if values['host-os-uname'].to_s.match(/Linux/)
  if File.directory?(deployment_dir)
    message = "Information:\tDeploying VCSA OVA"
    command = case deployment_dir
              when /6_0_0_3040890/
                "cd #{deployment_dir} ; echo yes | ./vcsa-deploy install #{vcsa_json_file} --accept-eula -v"
              when /6_[5-6]/
                "cd #{deployment_dir} ; echo 1 | ./vcsa-deploy install #{vcsa_json_file} --accept-eula -v"
              when /6_7/
                "cd #{deployment_dir} ; echo 1 | ./vcsa-deploy install #{vcsa_json_file}  --no-ssl-certificate-verification --accept-eula --acknowledge-ceip -v"
              else
                "cd #{deployment_dir} ; echo yes | ./vcsa-deploy install #{vcsa_json_file} -v"
              end
    execute_command(values, message, command)
  end
  nil
end

# Create deployment script

def create_vcsa_deploy_script(values)
  values['netmask'] = values['netmask'].gsub(%r{/}, '')
  uid = `id -u`.chomp
  information_message(values, 'Checking VCSA client directory')
  check_dir_exists(values, values['clientdir'])
  check_dir_owner(values, values['clientdir'], uid)
  service_dir = "#{values['clientdir']}/#{values['service']}"
  check_dir_exists(values, service_dir)
  values['clientdir'] = "#{service_dir}/#{values['name']}"
  check_dir_exists(values, values['clientdir'])
  output_file = "#{values['clientdir']}/#{values['name']}.sh"
  check_dir_exists(values, values['clientdir'])
  file = File.open(output_file, 'w')
  file.write("#!/bin/bash\n")
  file.write("\n")
  file.write("OVFTOOL=\"#{values['ovfbin']}\"\n")
  file.write("VCSA_OVA=#{values['file']}\n")
  file.write("\n")
  file.write("ESXI_HOST=#{values['server']}\n")
  file.write("ESXI_USERname = #{values['serveradmin']}\n")
  file.write("ESXI_PASSWORD=#{values['serverpassword']}\n")
  file.write("VM_NETWORK=\"#{values['servernetmask']}\"\n")
  file.write("VM_DATASTORE=#{values['datastore']}\n")
  file.write("\n")
  file.write("# Configurations for VC Management Node\n")
  file.write("VCSA_VMname = #{values['name']}\n")
  file.write("VCSA_ROOT_PASSWORD=#{values['adminpassword']}\n")
  file.write("VCSA_NETWORK_MODE=static\n")
  file.write("VCSA_NETWORK_FAMILY=#{values['ipfamil']}\n")
  file.write("## IP Network Prefix (CIDR notation)\n")
  file.write("VCSA_NETWORK_PREFIX=#{values['netmask']}\n")
  file.write("## Same value as VCSA_IP if no DNS\n")
  file.write("VCSA_HOSTNAME = #{values['ip']}\n")
  file.write("VCSA_IP=#{values['ip']}\n")
  file.write("VCSA_GATEWAY=#{values['vmgateway']}\n")
  file.write("VCSA_DNS=#{values['nameserver']}\n")
  file.write("VCSA_ENABLE_SSH=True\n")
  file.write("VCSA_DEPLOYMENT_SIZE=#{values['size']}\n")
  file.write("\n")
  file.write("# Configuration for SSO\n")
  file.write("SSO_DOMAIN_name = #{values['domainname']}\n")
  file.write("SSO_SITE_name = #{values['sitename']}\n")
  file.write("SSO_ADMIN_PASSWORD=#{values['adminpassword']}\n")
  file.write("\n")
  file.write("# NTP Servers\n")
  file.write("NTP_SERVERS=#{values['timeserver']}\n")
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
  file.close
  `chmod +x #{output_file}` if File.exist?(output_file)
  output_file
end

# Create VCSA JSON file

def create_vcsa_json(values)
  values['netmask'] = values['netmask'].gsub(%r{/}, '')
  json_version = '2.3.0' if values['service'].to_s.match(/6_[5-6]/)
  if values['service'].to_s.match(/6_7/)
    json_version = '2.13.0'
    values['cidr'] = netmask_to_cidr(values['netmask'])
  end
  if values['service'].to_s.match(/6_[5-6]/)
    string = "{
                \"__version\": \"#{json_version}\",
                \"new.vcsa\": {
                  \"esxi\": {
                    \"hostname\": \"#{values['server']}\",
                    \"username\": \"#{values['serveradmin']}\",
                    \"password\": \"#{values['serverpassword']}\",
                    \"deployment.network\": \"#{values['servernetmask']}\",
                    \"datastore\": \"#{values['datastore']}\"
                  },
                  \"appliance\": {
                    \"thin.disk.mode\": true,
                    \"deployment.option\": \"tiny\",
                    \"name\": \"#{values['name']}\"
                  },
                  \"network\": {
                    \"ip.family\": \"ipv4\",
                    \"mode\": \"static\",
                    \"ip\": \"#{values['ip']}\",
                    \"dns.servers\": \"#{values['nameserver']}\",
                    \"prefix\": \"#{values['netmask']}\",
                    \"gateway\": \"#{values['vmgateway']}\",
                    \"system.name\": \"#{values['ip']}\"
                  },
                  \"os\": {
                    \"password\": \"#{values['adminpassword']}\",
                    \"ntp.servers\": \"#{values['timeserver']}\",
                    \"ssh.enable\": true
                  },
                  \"sso\": {
                    \"password\": \"#{values['adminpassword']}\",
                    \"domain-name\": \"#{values['domainname']}\",
                    \"site-name\": \"#{values['sitename']}\"
                  }
                },
                \"ceip\": {
                  \"settings\": {
                    \"ceip.enabled\": false
                  }
                }
              }"
  elsif values['service'].to_s.match(/6_7/)
    values['name']
    values['domainname']
    string = "{
                  \"__version\": \"#{json_version}\",
                  \"new_vcsa\": {
                    \"esxi\": {
                      \"hostname\": \"#{values['server']}\",
                      \"username\": \"#{values['serveradmin']}\",
                      \"password\": \"#{values['serverpassword']}\",
                      \"deployment_network\": \"#{values['servernetmask']}\",
                      \"datastore\": \"#{values['datastore']}\"
                    },
                    \"appliance\": {
                      \"thin_disk_mode\": true,
                      \"deployment_option\": \"tiny\",
                      \"name\": \"#{values['name']}\"
                    },
                    \"network\": {
                      \"ip_family\": \"ipv4\",
                      \"mode\": \"static\",
                      \"ip\": \"#{values['ip']}\",
                      \"dns_servers\": [
                        \"#{values['nameserver']}\"
                      ],
                      \"prefix\": \"#{values['cidr']}\",
                      \"gateway\": \"#{values['vmgateway']}\",
                      \"system_name\": \"#{values['ip']}\"
                    },
                      \"os\": {
                      \"password\": \"#{values['adminpassword']}\",
                      \"ntp_servers\": \"#{values['timeserver']}\",
                      \"ssh_enable\": true
                    },
                      \"sso\": {
                      \"password\": \"#{values['adminpassword']}\",
                      \"domain_name\": \"#{values['domainname']}\"
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
                    \"esx.hostname\":\"#{values['server']}\",
                    \"esx.datastore\":\"#{values['datastore']}\",
                    \"esx.username\":\"#{values['serveradmin']}\",
                    \"esx.password\":\"#{values['serverpassword']}\",
                    \"deployment.option\":\"#{values['size']}\",
                    \"deployment.network\":\"#{values['servernetmask']}\",
                    \"appliance.name\":\"#{values['name']}\",
                    \"appliance.thin.disk.mode\":#{values['thindiskmode']}
                 },


                  \"vcsa\":
                  {

                    \"system\":
                    {
                      \"root.password\":\"#{values['rootpassword']}\",
                      \"ssh.enable\":true,
                      \"ntp.servers\":\"#{values['timeserver']}\"
                    },

                    \"sso\":
                    {
                      \"password\":\"#{values['adminpassword']}\",
                      \"domain-name\":\"#{values['domainname']}\",
                      \"site-name\":\"#{values['sitename']}\"
                    },

                    \"networking\":
                    {
                      \"ip.family\":\"#{values['ipfamil']}\",
                      \"mode\":\"static\",
                      \"ip\":\"#{values['ip']}\",
                      \"prefix\":\"#{values['netmask']}\",
                      \"gateway\":\"#{values['vmgateway']}\",
                      \"dns.servers\":\"#{values['nameserver']}\",
                      \"system.name\":\"#{values['ip']}\"
                    }
                  }
               }"
  end
  uid = `id -u`.chomp
  information_message(values, 'Checking VCSA JSON configuration directory')
  check_dir_exists(values, values['clientdir'])
  check_dir_owner(values, values['clientdir'], uid)
  service_dir = "#{values['clientdir']}/#{values['service']}"
  check_dir_exists(values, service_dir)
  check_dir_owner(values, service_dir, uid)
  values['clientdir'] = "#{service_dir}/#{values['name']}"
  check_dir_exists(values, values['clientdir'])
  check_dir_owner(values, values['clientdir'], uid)
  output_file = "#{values['clientdir']}/#{values['name']}.json"
  check_dir_exists(values, values['clientdir'])
  json   = JSON.parse(string)
  output = JSON.pretty_generate(json)
  file   = File.open(output_file, 'w')
  file.write(output)
  file.close
  output_file
end
