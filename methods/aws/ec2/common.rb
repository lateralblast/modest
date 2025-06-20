# frozen_string_literal: true

# AWS common code

# Initiates AWS EC2 Image connection

def initiate_aws_ec2_image(values)
  begin
    ec2 = Aws::EC2::Image.new(
      region: values['region'],
      access_key_id: values['access'],
      secret_access_key: values['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    verbose_message(values, "Warning:\tInvalid region, or keys")
  end
  ec2
end

# Initiate AWS EC2 Instance connection

def initiate_aws_ec2_instance(values)
  begin
    ec2 = Aws::EC2::Instance.new(
      region: values['region'],
      access_key_id: values['access'],
      secret_access_key: values['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    verbose_message(values, "Warning:\tInvalid region, or keys")
  end
  ec2
end

# Initiate AWS EC2 Client connection

def initiate_aws_ec2_client(values)
  begin
    ec2 = Aws::EC2::Client.new(
      region: values['region'],
      access_key_id: values['access'],
      secret_access_key: values['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    verbose_message(values, "Warning:\tInvalid region, or keys")
  end
  ec2
end

# Initiate an AWS EC2 Resource connection

def initiate_aws_ec2_resource(values)
  begin
    ec2 = Aws::EC2::Resource.new(
      region: values['region'],
      access_key_id: values['access'],
      secret_access_key: values['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    verbose_message(values, "Warning:\tInvalid region, or keys")
  end
  ec2
end

# Initiate an EWS EC2 KeyPair connection

def initiate_aws_ec2_keypair(values)
  begin
    ec2 = Aws::EC2::KeyPair.new(
      region: values['region'],
      access_key_id: values['access'],
      secret_access_key: values['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    verbose_message(values, "Warning:\tInvalid region, or keys")
  end
  ec2
end

# Initiate IAM client connection

def initiate_aws_iam_client(values)
  Aws::IAM::Client.new(
    region: values['region'],
    access_key_id: values['access'],
    secret_access_key: values['secret']
  )
end

# Initiate IAM client connection

def initiate_aws_cw_client(values)
  Aws::CloudWatch::Client.new(
    region: values['region'],
    access_key_id: values['access'],
    secret_access_key: values['secret']
  )
end

# Check AWS VM exists - Dummy function for packer

def check_aws_vm_exists(_values)
  false
end

def get_aws_ip_service_info(values)
  case values['service']
  when /ssh/
    values['proto'] = 'tcp'
    values['from']  = '22'
    values['to']    = '22'
  when /ping|icmp/
    values['proto'] = 'icmp'
    values['from']  = '-1'
    values['to']    = '-1'
  when /https/
    values['proto'] = 'tcp'
    values['from']  = '443'
    values['to']    = '443'
  when /http/
    values['proto'] = 'tcp'
    values['from']  = '80'
    values['to']    = '80'
  end
  if !values['cidr']
    values['cidr'] = '0.0.0.0/0'
  elsif values['cidr'].to_s.match(/^#{values['empty']}/)
    values['cidr'] = '0.0.0.0/0'
  end
  values
end

# Set AWS keyfile

def set_aws_key_file(values)
  if values['keyfile'] == values['empty']
    if values['name'].to_s.match(/#{values['region']}/)
      "#{values['home']}/.ssh/aws/#{values['name']}.pem"
    else
      "#{values['home']}/.ssh/aws/#{values['name']}#{values['region']}.pem"
    end
    puts values['keyfile']
  end
  values
end

# Handle AWS values

def handle_aws_values(values)
  values['ports'] = '22' if values['ports'] == values['empty']
  if values['name'] == values['empty']
    if !values['ami'].to_s.match(/^#{values['empty']}/)
      values['name'] = values['ami']
    else
      warning_message(values, 'No name specified for AWS image')
      quit(values)
    end
  end
  if values['key'].to_s.match(/^#{values['empty']}$|^none$/)
    warning_message(values, 'No key pair specified')
    if values['keyfile'] == values['empty']
      if values['name'].to_s.match(/^#{values['empty']}/)
        if values['group'].to_s.match(/^#{values['empty']}/)
          warning_message(values, 'Could not determine key pair')
          quit(values)
        else
          values['key'] = values['group']
        end
      else
        values['key'] = values['name']
      end
    else
      values['key'] = File.basename(values['keyfile'])
      values['key'] = values['key'].split(/\./)[0..-2].join
    end
    information_message(values, "Setting key pair to #{values['key']}")
  end
  if values['group'].to_s.match(/^default$/)
    values['group'] = values['key']
    information_message(values, "Setting security group to #{values['group']}")
  end
  if values['nosuffix'] == false
    values['name'] = get_aws_uniq_name(values)
    values['key']  = get_aws_uniq_name(values)
  end
  if values['keyfile'] == values['empty']
    values = set_aws_key_file(values)
    puts values['keyfile']
    information_message(values, "Setting key file to #{values['keyfile']}")
  end
  values = create_aws_key_pair(values) unless File.exist?(values['keyfile'])
  unless File.exist?(values['keyfile'])
    warning_message(values, "Key file '#{values['keyfile']}' does not exist")
    quit(values)
  end
  exists = check_if_aws_security_group_exists(values)
  create_aws_security_group(values) if exists == false
  add_ssh_to_aws_security_group(values)
  values
end

# Get Prefix List ID

def get_aws_prefix_list_id(values)
  ec2 = initiate_aws_ec2_client(values)
  ec2.describe_prefix_lists.prefix_lists[0].prefix_list_id
end

# Get AWS billing

def get_aws_billing(values)
  cw    = initiate_aws_cw_client(values)
  stats = cw.get_metric_statistics({  namespace:    'AWS/Billing',
                                      metric_name:  'EstimatedCharges',
                                      statistics:   ['Maximum'],
                                      dimensions:   [{ name: 'Currency', value: 'AUD' }],
                                      start_time:   (Time.now - (8 * 60 * 60)).iso8601,
                                      end_time:     Time.now.iso8601,
                                      period:       300 })
  pp stats
  nil
end

# Get AWS snapshots

def get_aws_snapshots(values)
  ec2 = initiate_aws_ec2_client(values)
  begin
    snapshots = ec2.describe_snapshots.snapshots
  rescue Aws::EC2::Errors::AccessDenied
    warning_message(values, 'User needs to be specified appropriate rights in AWS IAM')
    quit(values)
  end
  snapshots
end

# List AWS snapshots

def list_aws_snapshots(values)
  owner_id  = get_aws_owner_id(values)
  snapshots = get_aws_snapshots(values)
  snapshots.each do |snapshot|
    snapshot_id    = snapshot.snapshot_id
    snapshot_owner = snapshot.owner_id
    if snapshot_owner == owner_id
      if values['snapshot'].to_s.match(/[0-9]/)
        verbose_message(values, snapshot_id.to_s) if snapshot_id.match(/^#{values['snapshot']}$/)
      else
        verbose_message(values, snapshot_id.to_s)
      end
    end
  end
  nil
end

# Delete AWS snapshot

def delete_aws_snapshot(values)
  unless values['snapshot'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    warning_message(values, 'No Snapshot ID specified')
    return
  end
  owner_id  = get_aws_owner_id(values)
  snapshots = get_aws_snapshots(values)
  ec2       = initiate_aws_ec2_client(values)
  snapshots.each do |snapshot|
    snapshot_id    = snapshot.snapshot_id
    snapshot_owner = snapshot.owner_id
    next unless snapshot_owner == owner_id

    next unless snapshot_id.match(/^#{values['snapshot']}$/) || values['snapshot'] == 'all'

    information_message(values, "Deleting Snapshot ID #{snapshot_id}")
    begin
      ec2.delete_snapshot({ snapshot_id: snapshot_id })
    rescue StandardError
      warning_message(values, "Unable to delete Snapshot ID #{snapshot_id}")
    end
  end
  nil
end

# Get AWS unique name

def get_aws_uniq_name(values)
  if !values['name'].to_s.match(/#{values['suffix']}/)
    "#{values['name']}-#{values['suffix']}-#{values['region']}"
  else
    values['name']
  end
end

# Get AWS reservations

def get_aws_reservations(values)
  ec2 = initiate_aws_ec2_client(values)
  begin
    reservations = ec2.describe_instances({}).reservations
  rescue Aws::EC2::Errors::AccessDenied
    warning_message(values, 'User needs to be specified appropriate rights in AWS IAM')
    quit(values)
  end
  [ec2, reservations]
end

# Get AWS Key Pairs

def get_aws_key_pairs(values)
  ec2 = initiate_aws_ec2_client(values)
  begin
    key_pairs = ec2.describe_key_pairs({}).key_pairs
  rescue Aws::EC2::Errors::AccessDenied
    warning_message(values, 'User needs to be specified appropriate rights in AWS IAM')
    quit(values)
  end
  [ec2, key_pairs]
end

# Get instance security group

def get_aws_instance_security_group(values)
  group = 'none'
  _, reservations = get_aws_reservations(values)
  reservations.each do |reservation|
    reservation['instances'].each do |instance|
      instance_id = instance.instance_id
      group       = instance.security_groups[0].group_name
      return group if instance_id.match(/#{values['id']}/)
    end
  end
  group
end

# Check if AWS EC2 security group exists

def check_if_aws_security_group_exists(values)
  exists = false
  groups = get_aws_security_groups(values)
  groups.each do |group|
    group_name = group.group_name
    if values['group'].to_s.match(/^#{group_name}$/)
      exists = true
      return exists
    end
  end
  exists
end

# Get AWS EC2 security groups

def get_aws_security_groups(values)
  ec2 = initiate_aws_ec2_client(values)
  ec2.describe_security_groups.security_groups
end

# Get AWS EC2 security group IF

def get_aws_security_group_id(values)
  group_id = 'none'
  groups   = get_aws_security_groups(values)
  groups.each do |group|
    group_name = group.group_name
    group_id   = group.group_id
    return group_id if values['group'].to_s.match(/^#{group_name}$/)
  end
  group_id
end

# Add ingress rule to AWS EC2 security group

def remove_ingress_rule_from_aws_security_group(values)
  ec2 = initiate_aws_ec2_client(values)
  get_aws_prefix_list_id(values)
  information_message(values,
                      "Deleting ingress rule to security group #{values['group']} \
                      (Protocol: #{values['proto']} From: #{values['from']} \
                      To: #{values['to']} CIDR: #{values['cidr']})")
  ec2.revoke_security_group_ingress({
                                      group_id: values['group'],
                                      ip_permissions: [
                                        {
                                          ip_protocol: values['proto'],
                                          from_port: values['from'],
                                          to_port: values['to'],
                                          ip_ranges: [
                                            {
                                              cidr_ip: values['cidr']
                                            }
                                          ]
                                        }
                                      ]
                                    })
  nil
end

# Add egress rule to AWS EC2 security group

def remove_egress_rule_from_aws_security_group(values)
  ec2 = initiate_aws_ec2_client(values)
  get_aws_prefix_list_id(values['access'], values['secret'], values['region'])
  information_message(values,
                      "Deleting egress rule to security group #{values['group']} \
                      (Protocol: #{values['proto']} From: #{values['from']} \
                      To: #{values['to']} CIDR: #{values['cidr']})")
  ec2.revoke_security_group_egress({
                                     group_id: values['group'],
                                     ip_permissions: [
                                       {
                                         ip_protocol: values['proto'],
                                         from_port: values['from'],
                                         to_port: values['to'],
                                         ip_ranges: [
                                           {
                                             cidr_ip: values['cidr']
                                           }
                                         ]
                                       }
                                     ]
                                   })
  nil
end

# Add rule to AWS EC2 security group

def remove_rule_from_aws_security_group(values)
  values = get_aws_ip_service_info(values) unless values['service'].to_s.match(/^#{empty_value}$/)
  values['group'] = get_aws_security_group_id(values) unless values['group'].to_s.match(/^sg/)
  if values['dir'].to_s.match(/egress/)
    remove_egress_rule_from_aws_security_group(values)
  else
    remove_ingress_rule_from_aws_security_group(values)
  end
  nil
end

# Add ingress rule to AWS EC2 security group

def add_ingress_rule_to_aws_security_group(values)
  ec2 = initiate_aws_ec2_client(values)
  get_aws_prefix_list_id(values)
  information_message(values,
                      "Adding ingress rule to security group #{values['group']} \
                      (Protocol: #{values['proto']} From: #{values['from']} \
                      To: #{values['to']} CIDR: #{values['cidr']})")
  begin
    ec2.authorize_security_group_ingress({
                                           group_id: values['group'],
                                           ip_permissions: [
                                             {
                                               ip_protocol: values['proto'],
                                               from_port: values['from'],
                                               to_port: values['to'],
                                               ip_ranges: [
                                                 {
                                                   cidr_ip: values['cidr']
                                                 }
                                               ]
                                             }
                                           ]
                                         })
  rescue Aws::EC2::Errors::InvalidPermissionDuplicate
    warning_message(values, 'Rule already exists')
  end
  nil
end

# Add egress rule to AWS EC2 security group

def add_egress_rule_to_aws_security_group(values)
  ec2 = initiate_aws_ec2_client(values)
  get_aws_prefix_list_id(values)
  information_message(values,
                      "Adding egress rule to security group #{values['group']} \
                      (Protocol: #{values['proto']} From: #{values['from']} \
                      To: #{values['to']} CIDR: #{values['cidr']})")
  begin
    ec2.authorize_security_group_egress({
                                          group_id: values['group'],
                                          ip_permissions: [
                                            {
                                              ip_protocol: values['proto'],
                                              from_port: values['from'],
                                              to_port: values['to'],
                                              ip_ranges: [
                                                {
                                                  cidr_ip: values['cidr']
                                                }
                                              ]
                                            }
                                          ]
                                        })
  rescue Aws::EC2::Errors::InvalidPermissionDuplicate
    warning_message(values, 'Rule already exists')
  end
  nil
end

# Add SSH to AWS EC2 security group

def add_ssh_to_aws_security_group(values)
  values['service'] = 'none'
  values['dir']     = 'ingress'
  values['proto']   = 'tcp'
  values['from']    = '22'
  values['to']      = '22'
  values['cidr']    = '0.0.0.0/0'
  add_rule_to_aws_security_group(values)
end

# Add HTTP to AWS EC2 security group

def add_http_to_aws_security_group(values)
  values['service'] = 'none'
  values['dir']     = 'ingress'
  values['proto']   = 'tcp'
  values['from']    = '80'
  values['to']      = '80'
  values['cidr']    = '0.0.0.0/0'
  add_rule_to_aws_security_group(values)
end

# Add HTTPS to AWS EC2 security group

def add_https_to_aws_security_group(values)
  values['service'] = 'none'
  values['dir']     = 'ingress'
  values['proto']   = 'tcp'
  values['from']    = '80'
  values['to']      = '80'
  values['cidr']    = '0.0.0.0/0'
  add_rule_to_aws_security_group(values)
end

# Add HTTPS to AWS EC2 security group

def add_icmp_to_aws_security_group(values)
  values['service'] = 'none'
  values['dir']     = 'ingress'
  values['proto']   = 'icmp'
  values['from']    = '-1'
  values['to']      = '-1'
  values['cidr']    = '0.0.0.0/0'
  add_rule_to_aws_security_group(values)
end

# Add rule to AWS EC2 security group

def add_rule_to_aws_security_group(values)
  values = get_aws_ip_service_info(values) unless values['service'] == values['empty']
  values['group'] = get_aws_security_group_id(values) unless values['group'].to_s.match(/^sg/)
  if values['dir'].to_s.match(/egress/)
    add_egress_rule_to_aws_security_group(values)
  else
    add_ingress_rule_to_aws_security_group(values)
  end
  values
end

# Create AWS EC2 security group

def create_aws_security_group(values)
  unless values['desc'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    information_message(values, "No description specified, using group name '#{values['group']}'")
    values['desc'] = values['group']
  end
  exists = check_if_aws_security_group_exists(values)
  if exists == 'yes'
    warning_message(values, "Security group '#{values['group']}' already exists")
  else
    information_message(values, "Creating security group '#{values['group']}'")
    ec2 = initiate_aws_ec2_client(values)
    ec2.create_security_group({ group_name: values['group'], description: values['desc'] })
  end
  nil
end

# Delete AWS EC2 security group

def delete_aws_security_group(values)
  exists = check_if_aws_security_group_exists(values)
  if exists == 'yes'
    information_message(values, "Deleting security group '#{values['group']}'")
    ec2 = initiate_aws_ec2_client(values)
    ec2.delete_security_group({ group_name: values['group'] })
  else
    warning_message(values, "Security group '#{values['group']}' does not exist")
  end
  nil
end

def handle_ip_perms(values, ip_perms, type, group_name)
  name_length = group_name.length
  name_spacer = ''
  name_length.times do
    name_spacer += ' '
  end
  ip_perms.each do |ip_perm|
    ip_protocol  = ip_perm.ip_protocol
    from_port    = ip_perm.from_port.to_s
    to_port      = ip_perm.to_port.to_s
    cidr_ip      = []
    ip_ranges    = ip_perm.ip_ranges
    ipv_6_ranges = ip_perm.ipv_6_ranges
    ip_ranges.each do |ip_range|
      range = ip_range.cidr_ip
      cidr_ip.push(range)
    end
    cidr_ip = cidr_ip.join(',')
    if ip_protocol && from_port && to_port && ip_protocol.match(/[a-z]/) && cidr_ip.match(/[0-9]/)
      ip_rule = "#{ip_protocol},#{from_port},#{to_port}"
      verbose_message(values, "#{name_spacer} rule=#{ip_rule} range=#{cidr_ip} (IPv4 #{type})")
    end
    cidr_ip = []
    ipv_6_ranges.each do |ip_range|
      range = ip_range.cidr_ip
      cidr_ip.push(range)
    end
    cidr_ip = cidr_ip.join(',')
    next unless ip_protocol && from_port && to_port

    if ip_protocol.match(/[a-z]/) && cidr_ip.match(/[0-9]/)
      ip_rule = "#{ip_protocol},#{from_port},#{to_port}"
      verbose_message(values, "#{name_spacer} rule=#{ip_rule} range=#{cidr_ip} (IPv4 #{type})")
    end
  end
  nil
end

# List AWS EC2 security groups

def list_aws_security_groups(values)
  groups = get_aws_security_groups(values)
  groups.each do |group|
    group_name = group.group_name
    next unless values['group'].to_s.match(/^all$|^#{group_name}$/)

    description = group.description
    verbose_message(values, "#{group_name} desc=\"#{description}\"")
    ip_perms = group.ip_permissions
    handle_ip_perms(values, ip_perms, 'Ingress', group_name)
    ip_perms = group.ip_permissions_egress
    handle_ip_perms(values, ip_perms, 'Egress', group_name)
  end
  nil
end

# Get instance key pair

def get_aws_instance_key_name(values)
  key_name = 'none'
  _, reservations = get_aws_reservations(values)
  reservations.each do |reservation|
    reservation['instances'].each do |instance|
      instance_id = instance.instance_id
      key_name    = instance.key_name
      return key_name if instance_id.match(/#{values['id']}/)
    end
  end
  key_name
end

# Get instance IP

def get_aws_instance_ip(values)
  public_ip = 'none'
  _, reservations = get_aws_reservations(values)
  reservations.each do |reservation|
    reservation['instances'].each do |instance|
      instance_id = instance.instance_id
      public_ip = instance.public_ip_address
      return public_ip if instance_id.match(/#{values['id']}/)
    end
  end
  public_ip
end

# Get AWS owner ID

def get_aws_owner_id(values)
  iam = initiate_aws_iam_client(values)
  begin
    user = iam.get_user(values)
  rescue Aws::EC2::Errors::AccessDenied
    warning_message(values, 'User needs to be specified appropriate rights in AWS IAM')
    quit(values)
  end
  user[0].arn.split(/:/)[4]
end

# Get list of AWS images

def get_aws_images(values)
  ec2 = initiate_aws_ec2_client(values)
  begin
    images = ec2.describe_images({ owners: ['self'] }).images
  rescue Aws::EC2::Errors::AccessDenied
    warning_message(values, 'User needs to be specified appropriate rights in AWS IAM')
    quit(values)
  end
  [ec2, images]
end

# List AWS images

def list_aws_images(values)
  _, images = get_aws_images(values)
  images.each do |image|
    image_name = image.name
    image_id   = image.image_id
    verbose_message(values, "#{image_name} id=#{image_id}")
  end
  nil
end

# Get AWS image ID

def get_aws_image(values)
  image_id = 'none'
  ec2, images = get_aws_images(values)
  images.each do |image|
    image_name = image.image_location.split(%r{/})[1]
    if image_name.match(/^#{values['name']}$/)
      image_id = image.image_id
      return ec2, image_id
    end
  end
  [ec2, image_id]
end

# Delete AWS image

def delete_aws_image(values)
  ec2, image_id = get_aws_image(values)
  if image_id == 'none'
    warning_message(values, "No AWS Image exists for '#{values['name']}'")
    quit(values)
  else
    information_message(values, "Deleting Image ID #{image_id} for '#{values['name']}'")
    ec2.deregister_image({ dry_run: false, image_id: image_id })
  end
  nil
end

# Check if AWS image exists

def check_aws_image_exists(values)
  exists = false
  _, images = get_aws_images(values)
  images.each do |image|
    if image.name.match(/^#{values['name']}/)
      exists = true
      return exists
    end
  end
  exists
end

# Get vagrant version

def get_vagrant_version(_values)
  `$vagrant_bin --version`.chomp
end

# Check vagrant aws plugin is installed

def check_vagrant_aws_is_installed(values)
  check_vagrant_is_installed(values)
  plugin_list = `vagrant plugin list`
  unless plugin_list.match(/aws/)
    message = "Information:\tInstalling Vagrant AWS Plugin"
    command = 'vagrant plugin install vagrant-aws'
    execute_command(values, message, command)
  end
  nil
end

# Check vagrant is installed

def check_vagrant_is_installed(values, _osinfo)
  $vagrant_bin = `which vagrant`.chomp
  unless $vagrant_bin.match(/vagrant/)
    vagrant_pkg = if values['host-os-uname'].to_s.match(/Darwin/)
                    "vagrant_#{values['vagrantversion']}_#{values['host-os-uname'].downcase}.dmg"
                  elsif values['host-os-unamem'].to_s.match(/64/)
                    "vagrant_#{values['vagrantversion']}_#{values['host-os-uname'].downcase}_amd64.zip"
                  else
                    "vagrant_#{values['vagrantversion']}_#{values['host-os-uname'].downcase}_386.zip"
                  end
    vagrant_url = "https://releases.hashicorp.com/vagrant/#{values['vagrantversion']}/#{vagrant_pkg}"
    tmp_file = "/tmp/#{vagrant_pkg}"
    wget_file(values, vagrant_url, tmp_file) unless File.exist?(tmp_file)
    if !File.directory?('/usr/local/bin') && !File.symlink?('/usr/local/bin')
      message = "Information:\tCreating /usr/local/bin"
      command = 'mkdir /usr/local/bin'
      execute_command(values, message, command)
    end
    if values['host-os-uname'].to_s.match(/Darwin/)
      message = "Information:\tMounting Vagrant Image"
      command = "hdiutil attach #{vagrant_pkg}"
      execute_command(values, message, command)
      message = "Information:\tInstalling Vagrant Image"
      command = 'installer -package /Volumes/Vagrant/Vagrant.pkg -target /'
      execute_command(values, message, command)
    else
      message = "Information:\tInstalling Vagrant"
    end
    execute_command(values, message, command)
  end
  nil
end

# get AWS credentials

def get_aws_creds(values)
  values['access'] = ''
  values['secret'] = ''
  if File.exist?(values['creds'])
    file_creds = File.readlines(values['creds'])
    file_creds.each do |line|
      line = line.chomp
      next if line.match(/^#/)

      (values['access'], values['secret']) = line.split(/:/) if line.match(/:/)
      values['access'] = line.gsub(/export|AWS_ACCESS_KEY|aws_access_key_id|=|"|\s+/, '') if line.match(/AWS_ACCESS_KEY|aws_access_key_id/)
      values['secret'] = line.gsub(/export|AWS_SECRET_KEY|aws_secret_access_key|=|"|\s+/, '') if line.match(/AWS_SECRET_KEY|aws_secret_access_key/)
    end
  else
    warning_message(values, "Credentials file '#{values['creds']}' does not exist")
  end
  [values['access'], values['secret']]
end

# Check AWS CLI is installed

def check_if_aws_cli_is_installed(values)
  aws_cli = `which aws`
  unless aws_cli.match(/aws/)
    warning_message(values, 'AWS CLI not installed')
    if values['host-os-uname'].to_s.match(/Darwin/)
      information_message(values, 'Installing AWS CLI')
      brew_install('awscli')
    end
  end
  nil
end

# Create AWS Creds file

def create_aws_creds_file(values)
  creds_dir = File.dirname(values['creds'])
  if !values['access'].to_s.match(/[a-z]/) || !values['secret'].to_s.match(/[a-z]/)
    warning_message(values, 'No access key or secret specified')
    quit(values)
  end
  unless File.exist?(creds_dir)
    check_dir_exists(values, creds_dir)
    check_dir_owner(values, creds_dir, values['uid'])
  end
  file = File.open(values['creds'], 'w')
  file.write("[default]\n")
  file.write("aws_access_key_id = #{values['access']}\n")
  file.write("aws_secret_access_key = #{values['secret']}\n")
  file.close
  nil
end

# Check if AWS Key Pair exists

def check_aws_key_pair_exists(values)
  exists = false
  _, key_pairs = get_aws_key_pairs(values)
  key_pairs.each do |key_pair|
    key_name = key_pair.key_name
    exists = true if key_name.match(/^#{values['key']}$/)
  end
  exists
end

# Check if AWS key file exists

def check_aws_ssh_key_file_exists(values)
  aws_ssh_key = "#{values['keydir']}/#{values['key']}.pem"
  File.exist?(aws_ssh_key) || false
end

# Create AWS Key Pair

def create_aws_key_pair(values)
  aws_ssh_dir = "#{values['home']}/.ssh/aws"
  check_my_dir_exists(values, aws_ssh_dir)
  values['keyname'] = get_aws_uniq_name(values) if values['nosuffix'] == false
  exists = check_aws_key_pair_exists(values)
  if exists == true
    warning_message(values, "Key Pair '#{values['keyname']}' already exists")
    quit(values) if values['type'].to_s.match(/key/)
  else
    information_message(values, "Creating Key Pair '#{values['keyname']}'")
    ec2      = initiate_aws_ec2_client(values)
    key_pair = ec2.create_key_pair({ key_name: values['keyname'] }).key_material
    key_file = "#{aws_ssh_dir}/#{values['keyname']}.pem"
    information_message(values, "Saving Key Pair '#{values['keyname']}' to '#{key_file}'")
    file = File.open(key_file, 'w')
    file.write(key_pair)
    file.close
    message = "Information:\tSetting permissions on '#{key_file}' to 600"
    command = "chmod 600 #{key_file}"
    execute_command(values, message, command)
  end
  values
end

# Delete AWS Key Pair

def delete_aws_key_pair(values)
  aws_ssh_dir = "#{values['home']}/.ssh/aws"
  values['keyname'] = get_aws_uniq_name(values) if values['nosuffix'] == false
  exists = check_aws_key_pair_exists(values)
  if exists == false
    warning_message(values, "AWS Key Pair '#{values['keyname']}' does not exist")
    quit(values)
  else
    information_message(values, "Deleting AWS Key Pair '#{values['keyname']}'")
    ec2 = initiate_aws_ec2_client(values)
    ec2.delete_key_pair({ key_name: values['keyname'] })
    key_file = "#{aws_ssh_dir}/#{values['keyname']}.pem"
    if File.exist?(key_file)
      information_message(values, "Deleting AWS Key Pair file '#{key_file}'")
      File.delete(key_file)
    end
  end
  values
end

# List AWS Key Pairs

def list_aws_key_pairs(values)
  _, key_pairs = get_aws_key_pairs(values)
  key_pairs.each do |key_pair|
    key_name = key_pair.key_name
    if values['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      verbose_message(key_name) if key_name.match(/^#{values['key']}$/) || values['key'].to_s.match(/^all$|^none$/)
    else
      verbose_message(key_name)
    end
  end
  nil
end
