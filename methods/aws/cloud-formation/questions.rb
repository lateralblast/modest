# frozen_string_literal: true

# AWS CloudFormation questions

# Populate AWS CF questions

def populate_aws_cf_questions(values)
  # values['answers'] = {}
  # values['order']  = []

  name   = 'stack_name'
  config = Ks.new(
    '',
    'Stack Name',
    'yes',
    '',
    values['name'],
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

  name   = 'ssh_location'
  config = Ks.new(
    '',
    'SSH Location',
    'yes',
    '',
    values['cidr'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'template_url'
  config = Ks.new(
    '',
    'Template Location',
    'yes',
    '',
    values['file'],
    '',
    'no'
  )
  values['answers'][name] = config
  values['order'].push(name)

  name   = 'security_groups'
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

  nil
end
