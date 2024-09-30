
# Cloud Formation common code

# Initiate Cloud Formation Stack

def initiate_aws_cf_client(values)
  cf = Aws::CloudFormation::Client.new(
    :region             =>  values['region'], 
    :access_key_id      =>  values['access'],
    :secret_access_key  =>  values['secret']
  )
  return cf
end 

# Get list of AWS CF stacks

def get_aws_cf_stacks(values)
  cf = initiate_aws_cf_client(values['access'], values['secret'], values['region'])
  begin
    stacks = cf.describe_stacks.stacks 
  rescue Aws::CloudFormation::Errors::AccessDenied
    verbose_message(values,"Warning:\tUser needs to be given appropriate rights in AWS IAM")
    quit(values)
  end
  return stacks
end

# Check if AWS CF Stack exists

def check_if_aws_cf_stack_exists(values)
  exists = false
  stacks = get_aws_cf_stacks(values)
  stacks.each do |stack|
    stack_name  = stack.stack_name
    if stack_name.match(/#{values['name']}/)
      exists = true
      return exists
    end
  end
  return exists
end

