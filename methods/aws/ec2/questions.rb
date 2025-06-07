# frozen_string_literal: true

# Questions for AWS EC2 creation

# Populate AWS questions

def populate_aws_questions(values, user_data_file)
  # values['answers'] = {}
  # values['order']  = []

  if values['type'].to_s.match(/packer|ansible/)

    name   = 'name'
    config = Ks.new(
      '',
      'AMI Name',
      'no',
      '',
      'aws',
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'access_key'
    config = Ks.new(
      '',
      'Access Key',
      'yes',
      '',
      values['access'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name = 'secret_key'
    if values['unmasked'] == true

      config = Ks.new(
        '',
        'Secret Key',
        'yes',
        '',
        values['secret'],
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

      name   = 'keyfile'
      config = Ks.new(
        '',
        'AWS Key file',
        'yes',
        '',
        values['keyfile'],
        '',
        'no'
      )

    else

      config = Ks.new(
        '',
        'Secret Key',
        'no',
        '',
        values['secret'],
        '',
        'no'
      )
      values['answers'][name] = config
      values['order'].push(name)

      name   = 'keyfile'
      config = Ks.new(
        '',
        'AWS Key file',
        'no',
        '',
        values['keyfile'],
        '',
        'no'
      )

    end
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'type'
    config = Ks.new(
      '',
      'AWS Type',
      'yes',
      '',
      values['type'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'region'
    config = Ks.new(
      '',
      'Region',
      'yes',
      '',
      values['region'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'ssh_username'
    config = Ks.new(
      '',
      'SSH Username',
      'yes',
      '',
      values['adminuser'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'ami_name'
    config = Ks.new(
      '',
      'AMI Name',
      'yes',
      '',
      values['name'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

  end

  if values['type'].to_s.match(/packer/)

    name   = 'user_data_file'
    config = Ks.new(
      '',
      'User Data File',
      'yes',
      '',
      user_data_file,
      '',
      'no'
    )

  else

    name   = 'min_count'
    config = Ks.new(
      '',
      'Minimum Instances',
      'yes',
      '',
      values['number'].split(/,/)[0],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'max_count'
    config = Ks.new(
      '',
      'Maximum Instances',
      'yes',
      '',
      values['number'].split(/,/)[1],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'key_name'
    config = Ks.new(
      '',
      'Key Name',
      'yes',
      '',
      values['key'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'security_group'
    config = Ks.new(
      '',
      'Security Groups',
      'yes',
      '',
      values['group'],
      '',
      'no'
    )
    values['answers'][name] = config
    values['order'].push(name)

    name   = 'dry_run'
    config = Ks.new(
      '',
      'Dry run',
      'yes',
      '',
      values['dryrun'],
      '',
      'no'
    )

  end
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'source_ami'
  config = Ks.new(
    '',
    'Source AMI',
    'yes',
    '',
    values['ami'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'instance_type'
  config = Ks.new(
    '',
    'Instance Type',
    'yes',
    '',
    values['size'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'open_ports'
  config = Ks.new(
    '',
    'Open ports',
    'yes',
    '',
    values['ports'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'default_cidr'
  config = Ks.new(
    '',
    'Default CIDR',
    'yes',
    '',
    values['cidr'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  nil
end
