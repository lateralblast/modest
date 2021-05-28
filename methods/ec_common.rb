# AWS common code

# Initiates AWS EC2 Image connection

def initiate_aws_ec2_image(options)
  begin
    ec2 = Aws::EC2::Image.new(
      :region             =>  options['region'], 
      :access_key_id      =>  options['access'],
      :secret_access_key  =>  options['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    handle_output(options,"Warning:\tInvalid region, or keys")
  end
  return ec2
end

# Initiate AWS EC2 Instance connection

def initiate_aws_ec2_instance(options)
  begin
    ec2 = Aws::EC2::Instance.new(
      :region             =>  options['region'], 
      :access_key_id      =>  options['access'],
      :secret_access_key  =>  options['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    handle_output(options,"Warning:\tInvalid region, or keys")
  end
  return ec2
end

# Initiate AWS EC2 Client connection

def initiate_aws_ec2_client(options)
  begin
    ec2 = Aws::EC2::Client.new(
      :region             =>  options['region'], 
      :access_key_id      =>  options['access'],
      :secret_access_key  =>  options['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    handle_output(options,"Warning:\tInvalid region, or keys")
  end
  return ec2
end

# Initiate an AWS EC2 Resource connection

def initiate_aws_ec2_resource(options)
  begin
    ec2 = Aws::EC2::Resource.new(
      :region             =>  options['region'], 
      :access_key_id      =>  options['access'],
      :secret_access_key  =>  options['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    handle_output(options,"Warning:\tInvalid region, or keys")
  end
  return ec2
end 

# Initiate an EWS EC2 KeyPair connection

def initiate_aws_ec2_resource(options)
  begin
    ec2 = Aws::EC2::KeyPair.new(
      :region             =>  options['region'], 
      :access_key_id      =>  options['access'],
      :secret_access_key  =>  options['secret']
    )
  rescue Aws::Errors::NoSuchEndpointError
    handle_output(options,"Warning:\tInvalid region, or keys")
  end
  return ec2
end 

# Initiate IAM client connection

def initiate_aws_iam_client(options)
  iam = Aws::IAM::Client.new(
    :region             =>  options['region'], 
    :access_key_id      =>  options['access'],
    :secret_access_key  =>  options['secret']
  )
  return iam
end 

# Initiate IAM client connection

def initiate_aws_cw_client(options)
  cw = Aws::CloudWatch::Client.new(
    :region             =>  options['region'], 
    :access_key_id      =>  options['access'],
    :secret_access_key  =>  options['secret']
  )
  return cw
end

# Check AWS VM exists - Dummy function for packer

def check_aws_vm_exists(options)
  exists = "no"
  return exists
end

def get_aws_ip_service_info(options)
  case options['service']
  when /ssh/
    options['proto'] = "tcp"
    options['from']  = "22"
    options['to']    = "22"
  when /ping|icmp/
    options['proto'] = "icmp"
    options['from']  = "-1"
    options['to']    = "-1"
  when /https/
    options['proto'] = "tcp"
    options['from']  = "443"
    options['to']    = "443"
  when /http/
    options['proto'] = "tcp"
    options['from']  = "80"
    options['to']    = "80"
  end
  if not options['cidr']
    options['cidr'] = "0.0.0.0/0"
  else
    if options['cidr'].to_s.match(/^#{options['empty']}/)
      options['cidr'] = "0.0.0.0/0"
    end
  end
  return options
end

# Set AWS keyfile

def set_aws_key_file(options)
  if options["keyfile"] == options["empty"]
    if options['name'].to_s.match(/#{options['region'].to_s}/)
      options['keyfile'] = options["home"]+"/.ssh/aws/"+options["name"]+".pem"
    else
      options['keyfile'] = options["home"]+"/.ssh/aws/"+options["name"]+options["region"]+".pem"
    end
    puts options['keyfile']
  end
  return options
end

# Handle AWS values

def handle_aws_values(options)
  if options['ports']== options['empty']
    options['ports'] = "22"
  end
  if options['name']== options['empty']
    if not options['ami'].to_s.match(/^#{options['empty']}/)
      options['name'] = options['ami']
    else
      handle_output(options,"Warning:\tNo name specified for AWS image")
      quit(options)
    end
  end
  if options['key'].to_s.match(/^#{options['empty']}$|^none$/)
    handle_output(options,"Warning:\tNo key pair specified")
    if options['keyfile'] == options['empty']
      if options['name'].to_s.match(/^#{options['empty']}/)
        if options['group'].to_s.match(/^#{}options['empty']/)
          handle_output(options,"Warning:\tCould not determine key pair")
          quit(options)
        else
          options['key'] = options['group']
        end
      else
        options['key'] = options['name']
      end
    else
      options['key'] = File.basename(options['keyfile'])
      options['key'] = options['key'].split(/\./)[0..-2].join
    end
    handle_output(options,"Information:\tSetting key pair to #{options['key']}")
  end
  if options['group'].to_s.match(/^default$/)
    options['group'] = options['key']
    handle_output(options,"Information:\tSetting security group to #{options['group']}")
  end
  if options['nosuffix'] == false
    options['name'] = get_aws_uniq_name(options)
    options['key']  = get_aws_uniq_name(options)
  end
  if options['keyfile'] == options['empty']
    options = set_aws_key_file(options)
    puts options['keyfile']
    handle_output(options,"Information:\tSetting key file to #{options['keyfile']}")
  end
  if not File.exist?(options['keyfile'])
    options = create_aws_key_pair(options)
  end
  if not File.exist?(options['keyfile'])
    handle_output(options,"Warning:\tKey file '#{options['keyfile']}' does not exist")
    quit(options)
  end
  exists = check_if_aws_security_group_exists(options)
  if exists == "no"
    create_aws_security_group(options)
  end
  add_ssh_to_aws_security_group(options)
  return options
end

# Get Prefix List ID

def get_aws_prefix_list_id(options)
  ec2 = initiate_aws_ec2_client(options)
  id  = ec2.describe_prefix_lists.prefix_lists[0].prefix_list_id
  return id
end

# Get AWS billing

def get_aws_billing(options)
  cw    = initiate_aws_cw_client(options)
  stats = cw.get_metric_statistics({
   :namespace   => 'AWS/Billing',
   :metric_name => 'EstimatedCharges',
   :statistics  => ['Maximum'],
   :dimensions  => [{ :name => 'Currency', :value => 'AUD' }],
   :start_time  => (Time.now - (8*60*60)).iso8601,
   :end_time    => Time.now.iso8601,
   :period      => 300
  })
  pp stats
  return
end

# Get AWS snapshots

def get_aws_snapshots(options)
  ec2 = initiate_aws_ec2_client(options)
  begin
    snapshots = ec2.describe_snapshots.snapshots
  rescue Aws::EC2::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be specified appropriate rights in AWS IAM")
    quit(options)
  end
  return snapshots
end

# List AWS snapshots

def list_aws_snapshots(options)
  owner_id  = get_aws_owner_id(options)
  snapshots = get_aws_snapshots(options)
  snapshots.each do |snapshot|
    snapshot_id    = snapshot.snapshot_id
    snapshot_owner = snapshot.owner_id
    if snapshot_owner == owner_id
      if options['snapshot'].to_s.match(/[0-9]/)
        if snapshot_id.match(/^#{options['snapshot']}$/)
          handle_output(options,"#{snapshot_id}")
        end
      else
        handle_output(options,"#{snapshot_id}")
      end
    end
  end
  return
end

# Delete AWS snapshot

def delete_aws_snapshot(options)
  if not options['snapshot'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output(options,"Warning:\tNo Snapshot ID specified")
    return
  end
  owner_id  = get_aws_owner_id(options)
  snapshots = get_aws_snapshots(options)
  ec2       = initiate_aws_ec2_client(options)
  snapshots.each do |snapshot|
    snapshot_id    = snapshot.snapshot_id
    snapshot_owner = snapshot.owner_id
    if snapshot_owner == owner_id
      if snapshot_id.match(/^#{options['snapshot']}$/) || options['snapshot'] == "all"
        handle_output(options,"Information:\tDeleting Snapshot ID #{snapshot_id}")
        begin
          ec2.delete_snapshot({snapshot_id: snapshot_id})
        rescue 
          handle_output(options,"Warning:\tUnable to delete Snapshot ID #{snapshot_id}")
        end
      end
    end
  end
  return
end

# Get AWS unique name

def get_aws_uniq_name(options)
  if not options['name'].to_s.match(/#{options['suffix']}/)
    value = options['name']+"-"+options['suffix']+"-"+options['region']
  else
    value = options['name']
  end
  return value
end

# Get AWS reservations

def get_aws_reservations(options)
  ec2 = initiate_aws_ec2_client(options)
  begin
    reservations = ec2.describe_instances({ }).reservations
  rescue Aws::EC2::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be specified appropriate rights in AWS IAM")
    quit(options)
  end
  return ec2,reservations
end

# Get AWS Key Pairs

def get_aws_key_pairs(options)
  ec2 = initiate_aws_ec2_client(options)
  begin
    key_pairs = ec2.describe_key_pairs({ }).key_pairs
  rescue Aws::EC2::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be specified appropriate rights in AWS IAM")
    quit(options)
  end
  return ec2,key_pairs
end

# Get instance security group 

def get_aws_instance_security_group(options)
  group = "none"
  ec2,reservations = get_aws_reservations(options)
  reservations.each do |reservation|
    reservation['instances'].each do |instance|
      instance_id = instance.instance_id
      group       = instance.security_groups[0].group_name
      if instance_id.match(/#{options['id']}/)
        return group
      end
    end
  end
  return group
end

# Check if AWS EC2 security group exists


def check_if_aws_security_group_exists(options)
  exists = "no"
  groups = get_aws_security_groups(options)
  groups.each do |group|
    group_name = group.group_name
    if options['group'].to_s.match(/^#{group_name}$/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

# Get AWS EC2 security groups

def get_aws_security_groups(options)
  ec2    = initiate_aws_ec2_client(options)
  groups = ec2.describe_security_groups.security_groups 
  return groups
end

# Get AWS EC2 security group IF

def get_aws_security_group_id(options)
  group_id = "none"
  groups   = get_aws_security_groups(options)
  groups.each do |group|
    group_name = group.group_name
    group_id   = group.group_id
    if options['group'].to_s.match(/^#{group_name}$/)
      return group_id
    end
  end
  return group_id
end

# Add ingress rule to AWS EC2 security group

def remove_ingress_rule_from_aws_security_group(options)
  ec2 = initiate_aws_ec2_client(options)
  prefix_list_id = get_aws_prefix_list_id(options)
  handle_output(options,"Information:\tDeleting ingress rule to security group #{options['group']} (Protocol: #{options['proto']} From: #{options['from']} To: #{options['to']} CIDR: #{options['cidr']})")
  ec2.revoke_security_group_ingress({
    group_id: options['group'],
    ip_permissions: [
      {
        ip_protocol:  options['proto'],
        from_port:    options['from'],
        to_port:      options['to'],
        ip_ranges: [
          {
            cidr_ip: options['cidr'],
          },
        ],
      },
    ],
  })
  return
end

# Add egress rule to AWS EC2 security group

def remove_egress_rule_from_aws_security_group(options)
  ec2 = initiate_aws_ec2_client(options)
  prefix_list_id = get_aws_prefix_list_id(options['access'],options['secret'],options['region'])
  handle_output(options,"Information:\tDeleting egress rule to security group #{options['group']} (Protocol: #{options['proto']} From: #{options['from']} To: #{options['to']} CIDR: #{options['cidr']})")
  ec2.revoke_security_group_egress({
    group_id: options['group'],
    ip_permissions: [
      {
        ip_protocol:  options['proto'],
        from_port:    options['from'],
        to_port:      options['to'],
        ip_ranges: [
          {
            cidr_ip: options['cidr'],
          },
        ],
      },
    ],
  })
  return
end

# Add rule to AWS EC2 security group

def remove_rule_from_aws_security_group(options)
  if not options['service'].to_s.match(/^#{empty_value}$/)
    options = get_aws_ip_service_info(options)
  end
  if not options['group'].to_s.match(/^sg/)
    options['group'] = get_aws_security_group_id(options)
  end
  if options['dir'].to_s.match(/egress/)
    remove_egress_rule_from_aws_security_group(options)
  else
    remove_ingress_rule_from_aws_security_group(options)
  end
  return
end

# Add ingress rule to AWS EC2 security group

def add_ingress_rule_to_aws_security_group(options)
  ec2 = initiate_aws_ec2_client(options)
  prefix_list_id = get_aws_prefix_list_id(options)
  handle_output(options,"Information:\tAdding ingress rule to security group #{options['group']} (Protocol: #{options['proto']} From: #{options['from']} To: #{options['to']} CIDR: #{options['cidr']})")
  begin
    ec2.authorize_security_group_ingress({
      group_id: options['group'],
      ip_permissions: [
        {
          ip_protocol:  options['proto'],
          from_port:    options['from'],
          to_port:      options['to'],
          ip_ranges: [
            {
              cidr_ip: options['cidr'],
            },
          ],
        },
      ],
    })
  rescue Aws::EC2::Errors::InvalidPermissionDuplicate
    handle_output(options,"Warning:\tRule already exists")
  end
  return
end

# Add egress rule to AWS EC2 security group

def add_egress_rule_to_aws_security_group(options)
  ec2 = initiate_aws_ec2_client(options)
  prefix_list_id = get_aws_prefix_list_id(options)
  handle_output(options,"Information:\tAdding egress rule to security group #{options['group']} (Protocol: #{options['proto']} From: #{options['from']} To: #{options['to']} CIDR: #{options['cidr']})")
  begin
    ec2.authorize_security_group_egress({
      group_id: options['group'],
      ip_permissions: [
        {
          ip_protocol:  options['proto'],
          from_port:    options['from'],
          to_port:      options['to'],
          ip_ranges: [
            {
              cidr_ip: options['cidr'],
            },
          ],
        },
      ],
    })
  rescue Aws::EC2::Errors::InvalidPermissionDuplicate
    handle_output(options,"Warning:\tRule already exists")
  end
  return
end

# Add SSH to AWS EC2 security group

def add_ssh_to_aws_security_group(options)
  options['service'] = "none"
  options['dir']     = "ingress"
  options['proto']   = "tcp"
  options['from']    = "22"
  options['to']      = "22"
  options['cidr']    = "0.0.0.0/0"
  options = add_rule_to_aws_security_group(options)
  return options
end

# Add HTTP to AWS EC2 security group

def add_http_to_aws_security_group(options)
  options['service'] = "none"
  options['dir']     = "ingress"
  options['proto']   = "tcp"
  options['from']    = "80"
  options['to']      = "80"
  options['cidr']    = "0.0.0.0/0"
  options = add_rule_to_aws_security_group(options)
  return options
end

# Add HTTPS to AWS EC2 security group

def add_https_to_aws_security_group(options)
  options['service'] = "none"
  options['dir']     = "ingress"
  options['proto']   = "tcp"
  options['from']    = "80"
  options['to']      = "80"
  options['cidr']    = "0.0.0.0/0"
  options = add_rule_to_aws_security_group(options)
  return options
end

# Add HTTPS to AWS EC2 security group

def add_icmp_to_aws_security_group(options)
  options['service'] = "none"
  options['dir']     = "ingress"
  options['proto']   = "icmp"
  options['from']    = "-1"
  options['to']      = "-1"
  options['cidr']    = "0.0.0.0/0"
  options = add_rule_to_aws_security_group(options)
  return options
end

# Add rule to AWS EC2 security group

def add_rule_to_aws_security_group(options)
  if not options['service']== options['empty']
    options = get_aws_ip_service_info(options)
  end
  if not options['group'].to_s.match(/^sg/)
    options['group'] = get_aws_security_group_id(options)
  end
  if options['dir'].to_s.match(/egress/)
    add_egress_rule_to_aws_security_group(options)
  else
    add_ingress_rule_to_aws_security_group(options)
  end
  return options
end

# Create AWS EC2 security group

def create_aws_security_group(options)
  if not options['desc'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    handle_output(options,"Information:\tNo description specified, using group name '#{options['group']}'")
    options['desc'] = options['group']
  end
  exists = check_if_aws_security_group_exists(options)
  if exists == "yes"
    handle_output(options,"Warning:\tSecurity group '#{options['group']}' already exists")
  else
    handle_output(options,"Information:\tCreating security group '#{options['group']}'")
    ec2 = initiate_aws_ec2_client(options)
    ec2.create_security_group({ group_name: options['group'], description: options['desc'] })
  end
  return
end

# Delete AWS EC2 security group

def delete_aws_security_group(options)
  exists = check_if_aws_security_group_exists(options)
  if exists == "yes"
    handle_output(options,"Information:\tDeleting security group '#{options['group']}'")
    ec2 = initiate_aws_ec2_client(options)
    ec2.delete_security_group({ group_name: options['group'] })
  else
    handle_output(options,"Warning:\tSecurity group '#{options['group']}' doesn't exist")
  end
  return
end

def handle_ip_perms(options,ip_perms,type,group_name)
  name_length = group_name.length
  name_spacer = ""
  name_length.times do
    name_spacer = name_spacer+" "
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
    cidr_ip = cidr_ip.join(",")
    if ip_protocol and from_port and to_port
      if ip_protocol.match(/[a-z]/) and cidr_ip.match(/[0-9]/)
        ip_rule = ip_protocol+","+from_port+","+to_port
        handle_output(options,"#{name_spacer} rule=#{ip_rule} range=#{cidr_ip} (IPv4 #{type})")
      end
    end
    cidr_ip = []
    ipv_6_ranges.each do |ip_range|
      range = ip_range.cidr_ip
      cidr_ip.push(range)
    end
    cidr_ip = cidr_ip.join(",")
    if ip_protocol and from_port and to_port
      if ip_protocol.match(/[a-z]/) and cidr_ip.match(/[0-9]/)
        ip_rule = ip_protocol+","+from_port+","+to_port
        handle_output(options,"#{name_spacer} rule=#{ip_rule} range=#{cidr_ip} (IPv4 #{type})")
      end
    end
  end
  return
end

# List AWS EC2 security groups

def list_aws_security_groups(options)
  groups = get_aws_security_groups(options)
  groups.each do |group|
    group_name = group.group_name
    if options['group'].to_s.match(/^all$|^#{group_name}$/)
      description = group.description
      handle_output(options,"#{group_name} desc=\"#{description}\"")
      ip_perms = group.ip_permissions
      handle_ip_perms(options,ip_perms,"Ingress",group_name)
      ip_perms = group.ip_permissions_egress
      handle_ip_perms(options,ip_perms,"Egress",group_name)
    end
  end
  return
end


# Get instance key pair

def get_aws_instance_key_name(options)
  key_name = "none"
  ec2,reservations = get_aws_reservations(options)
  reservations.each do |reservation|
    reservation['instances'].each do |instance|
      instance_id = instance.instance_id
      key_name    = instance.key_name
      if instance_id.match(/#{options['id']}/)
        return key_name
      end
    end
  end
  return key_name
end

# Get instance IP

def get_aws_instance_ip(options)
  public_ip = "none"
  ec2,reservations = get_aws_reservations(options)
  reservations.each do |reservation|
    reservation['instances'].each do |instance|
      instance_id = instance.instance_id
      public_ip  = instance.public_ip_address
      if instance_id.match(/#{options['id']}/)
        return public_ip
      end
    end
  end
  return public_ip
end

# Get AWS owner ID

def get_aws_owner_id(options)
  iam = initiate_aws_iam_client(options)
  begin
    user = iam.get_user()
  rescue Aws::EC2::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be specified appropriate rights in AWS IAM")
    quit(options)
  end
  owner_id = user[0].arn.split(/:/)[4]
  return owner_id
end

# Get list of AWS images

def get_aws_images(options)
  ec2 = initiate_aws_ec2_client(options)
  begin
    images = ec2.describe_images({ owners: ['self'] }).images
  rescue Aws::EC2::Errors::AccessDenied
    handle_output(options,"Warning:\tUser needs to be specified appropriate rights in AWS IAM")
    quit(options)
  end
  return ec2,images
end

# List AWS images

def list_aws_images(options)
  ec2,images = get_aws_images(options)
  images.each do |image|
    image_name = image.name
    image_id   = image.image_id
    handle_output(options,"#{image_name} id=#{image_id}")
  end
  return
end

# Get AWS image ID

def get_aws_image(options)
  image_id   = "none"
  ec2,images = get_aws_images(options)
  images.each do |image|
    image_name = image.image_location.split(/\//)[1]
    if image_name.match(/^#{options['name']}$/)
      image_id = image.image_id
      return ec2,image_id
    end
  end
  return ec2,image_id
end

# Delete AWS image

def delete_aws_image(options)
  ec2,image_id = get_aws_image(options)
  if image_id == "none"
    handle_output(options,"Warning:\tNo AWS Image exists for '#{options['name']}'")
    quit(options)  
  else
    handle_output(options,"Information:\tDeleting Image ID #{image_id} for '#{options['name']}'")
    ec2.deregister_image({ dry_run: false, image_id: image_id, })
  end
  return
end

# Check if AWS image exists

def check_aws_image_exists(options)
  exists     = "no"
  ec2,images = get_aws_images(options)
  images.each do |image|
    if image.name.match(/^#{options['name']}/)
      exists = "yes"
      return exists
    end
  end
  return exists
end

# Get vagrant version

def get_vagrant_version()
  vagrant_version = %x[$vagrant_bin --version].chomp
  return vagrant_version
end

# Check vagrant aws plugin is installed

def check_vagrant_aws_is_installed()
  check_vagrant_is_installed()
  plugin_list = %x[vagrant plugin list]
  if not plugin_list.match(/aws/)
    message = "Information:\tInstalling Vagrant AWS Plugin"
    command = "vagrant plugin install vagrant-aws"
    execute_command(options,message,command)
  end
  return
end

# Check vagrant is installed

def check_vagrant_is_installed(options,osinfo)
  $vagrant_bin = %x[which vagrant].chomp
  if not $vagrant_bin.match(/vagrant/)
    if options['osname'].to_s.match(/Darwin/)
      vagrant_pkg = "vagrant_"+$vagrant_version+"_"+options['osname'].downcase+".dmg"
      vagrant_url = "https://releases.hashicorp.com/vagrant/"+$vagrant_version+"/"+vagrant_pkg
    else
      if options['osmachine'].to_s.match(/64/)
        vagrant_pkg = "vagrant_"+$vagrant_version+"_"+options['osname'].downcase+"_amd64.zip"
        vagrant_url = "https://releases.hashicorp.com/vagrant/"+$vagrant_version+"/"+vagrant_pkg
      else
        vagrant_pkg = "vagrant_"+$vagrant_version+"_"+options['osname'].downcase+"_386.zip"
        vagrant_url = "https://releases.hashicorp.com/vagrant/"+$vagrant_version+"/"+vagrant_pkg
      end
    end
    tmp_file = "/tmp/"+vagrant_pkg
    if not File.exist?(tmp_file)
      wget_file(options,vagrant_url,tmp_file)
    end
    if not File.directory?("/usr/local/bin") and not File.symlink?("/usr/local/bin")
      message = "Information:\tCreating /usr/local/bin"
      command = "mkdir /usr/local/bin"
      execute_command(options,message,command)
    end
    if options['osname'].to_s.match(/Darwin/)
      message = "Information:\tMounting Vagrant Image"
      command = "hdiutil attach #{vagrant_pkg}"
      execute_command(options,message,command)
      message = "Information:\tInstalling Vagrant Image"
      command = "installer -package /Volumes/Vagrant/Vagrant.pkg -target /"
      execute_command(options,message,command)
    else
      message = "Information:\tInstalling Vagrant"
    end
    execute_command(options,message,command)
  end
  return
end

# get AWS credentials

def get_aws_creds(options)
  options['access'] = ""
  options['secret'] = ""
  if File.exist?(options['creds'])
    file_creds = File.readlines(options['creds'])
    file_creds.each do |line|
      line = line.chomp
      if not line.match(/^#/)
        if line.match(/:/)
          (options['access'],options['secret']) = line.split(/:/)
        end
        if line.match(/AWS_ACCESS_KEY|aws_access_key_id/)
          options['access'] = line.gsub(/export|AWS_ACCESS_KEY|aws_access_key_id|=|"|\s+/,"")
        end
        if line.match(/AWS_SECRET_KEY|aws_secret_access_key/)
          options['secret'] = line.gsub(/export|AWS_SECRET_KEY|aws_secret_access_key|=|"|\s+/,"")
        end
      end
    end
  else
    handle_output(options,"Warning:\tCredentials file '#{options['creds']}' does not exist")
  end
  return options['access'],options['secret']
end

# Check AWS CLI is installed

def check_if_aws_cli_is_installed()
  aws_cli = %x[which aws]
  if not aws_cli.match(/aws/)
    handle_output(options,"Warning:\tAWS CLI not installed")
    if options['osname'].to_s.match(/Darwin/)
      handle_output(options,"Information:\tInstalling AWS CLI")
      brew_install("awscli")
    end
  end
  return
end

# Create AWS Creds file

def create_aws_creds_file(options)
  file = File.open(options['creds'],"w")
  file.write("[default]\n")
  file.write("aws_access_key_id = #{options['access']}\n")
  file.write("aws_secret_access_key = #{options['secret']}\n")
  file.close
  return
end

# Check if AWS Key Pair exists

def check_aws_key_pair_exists(options)
  exists = "no"
  ec2,key_pairs = get_aws_key_pairs(options)
  key_pairs.each do |key_pair|
    key_name = key_pair.key_name
    if key_name.match(/^#{options['key']}$/)
      exists = "yes"
    end
  end
  return exists
end

# Check if AWS key file exists

def check_aws_ssh_key_file_exists(options)
  aws_ssh_key = options['keydir']+"/"+options['key']+".pem"
  if File.exist?(aws_ssh_key)
    exists = "yes"
  else
    exists = "no"
  end
  return exists
end

# Create AWS Key Pair

def create_aws_key_pair(options)
  aws_ssh_dir = options['home']+"/.ssh/aws"
  check_my_dir_exists(options,aws_ssh_dir)
  if options['nosuffix'] == false
    options['keyname'] = get_aws_uniq_name(options)
  end
  exists = check_aws_key_pair_exists(options)
  if exists == "yes"
    handle_output(options,"Warning:\tKey Pair '#{options['keyname']}' already exists")
    if options['type'].to_s.match(/key/)
      quit(options)
    end
  else
    handle_output(options,"Information:\tCreating Key Pair '#{options['keyname']}'")
    ec2      = initiate_aws_ec2_client(options)
    key_pair = ec2.create_key_pair({ key_name: options['keyname'] }).key_material
    key_file = aws_ssh_dir+"/"+options['keyname']+".pem"
    handle_output(options,"Information:\tSaving Key Pair '#{options['keyname']}' to '#{key_file}'")
    file = File.open(key_file,"w")
    file.write(key_pair)
    file.close
    message = "Information:\tSetting permissions on '#{key_file}' to 600"
    command = "chmod 600 #{key_file}"
    execute_command(options,message,command)
  end
  return options
end

# Delete AWS Key Pair

def delete_aws_key_pair(options)
  aws_ssh_dir = options['home']+"/.ssh/aws"
  if options['nosuffix'] == false
    options['keyname'] = get_aws_uniq_name(options)
  end
  exists = check_aws_key_pair_exists(options)
  if exists == "no"
    handle_output(options,"Warning:\tAWS Key Pair '#{options['keyname']}' does not exist")
    quit(options)
  else
    handle_output(options,"Information:\tDeleting AWS Key Pair '#{options['keyname']}'")
    ec2      = initiate_aws_ec2_client(options)
    key_pair = ec2.delete_key_pair({ key_name: options['keyname'] })
    key_file = aws_ssh_dir+"/"+options['keyname']+".pem"
    if File.exist?(key_file)
      handle_output(options,"Information:\tDeleting AWS Key Pair file '#{key_file}'")
      File.delete(key_file)
    end
  end
  return options
end

# List AWS Key Pairs

def list_aws_key_pairs(options)
  ec2,key_pairs = get_aws_key_pairs(options)
  key_pairs.each do |key_pair|
    key_name = key_pair.key_name
    if options['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
      if key_name.match(/^#{options['key']}$/) or options['key'].to_s.match(/^all$|^none$/)
        handle_output(key_name)
      end
    else
      handle_output(key_name)
    end
  end
  return
end
