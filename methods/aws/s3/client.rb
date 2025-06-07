# frozen_string_literal: true

# S3 related code

# Create AWS S3 bucket

def create_aws_s3_bucket(values)
  s3 = initiate_aws_s3_resource(values)
  if s3.bucket(values['bucket']).exists?
    information_message(values, "Bucket: #{values['bucket']} already exists")
    s3 = initiate_aws_s3_client(values['access'], values['secret'], values['region'])
    begin
      s3.head_bucket({ bucket: values['bucket'] })
    rescue StandardError
      warning_message(values, "Do not have permissions to access bucket: #{values['bucket']}")
      quit(values)
    end
  else
    information_message(values, "Creating S3 bucket: #{values['bucket']}")
    s3.create_bucket({ acl: values['acl'], bucket: values['bucket'],
                       create_bucket_configuration: { location_constraint: values['region'] } })
  end
  s3
end

# Get AWS S3 bucket ACL

def get_aws_s3_bucket_acl(values)
  s3 = initiate_aws_s3_client(values)
  begin
    acl = s3.get_bucket_acl(bucket: values['bucket'])
  rescue Aws::S3::Errors::AccessDenied
    warning_message(values, 'User needs to be given appropriate rights in AWS IAM')
    quit(values)
  end
  acl
end

# Show AWS S3 bucket ACL

def show_aws_s3_bucket_acl(values)
  acl    = get_aws_s3_bucket_acl(values)
  owner  = acl.owner.display_name
  verbose_message(values, "#{values['bucket']}\towner=#{owner}")
  acl.grants.each_with_index do |grantee, counter|
    owner = grantee[0].display_name
    email = grantee[0].email_address
    id    = grantee[0].id
    type  = grantee[0].type
    uri   = grantee[0].uri
    perms = grantee.permission
    verbose_message(values,
                    "grants[#{counter}]\towner=#{owner}\temail=#{email}\ttype=#{type}\turi=#{uri}\tid=#{id}\tperms=#{perms}")
  end
  nil
end

# Set AWS S3 bucket ACL

def set_aws_s3_bucket_acl(values)
  initiate_aws_s3_resource(values)
  nil
end

# Upload file to S3 bucker

def upload_file_to_aws_bucket(values)
  if values['file'].to_s.match(/^http/)
    download_file = "/tmp/#{File.basename(values['file'])}"
    download_http = open(values['file'])
    IO.copy_stream(download_http, download_file)
    values['file'] = download_file
  end
  unless File.exist?(values['file'])
    warning_message(values, "File '#{values['file']}' does not exist")
    quit(values)
  end
  unless values['bucket'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    warning_message(values, 'No Bucket name given')
    values['bucket'] = values['bucket']
    information_message(values, "Setting Bucket to default bucket '#{values['bucket']}'")
  end
  exists = check_if_aws_bucket_exists(values['access'], values['secret'], values['region'], values['bucket'])
  create_aws_s3_bucket(values['access'], values['secret'], values['region'], values['bucket']) if exists == false
  values['key'] = "#{values['object']}/#{File.basename(values['file'])}" unless values['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
  s3 = initiate_aws_s3_resource(values['access'], values['secret'], values['region'])
  information_message(values,
                      "Uploading: File '#{values['file']}' with key: '#{values['key']}' to bucket: '#{values['bucket']}'")
  s3.bucket(values['bucket']).object(values['key']).upload_file(values['file'])
  nil
end

# Download file from S3 bucket

def download_file_from_aws_bucket(values)
  unless values['bucket'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
    warning_message(values, 'No Bucket name given')
    values['bucket'] = values['bucket']
    information_message(values, "Setting Bucket to default bucket '#{values['bucket']}'")
  end
  values['key'] = "#{values['object']}/#{File.basename(values['file'])}" unless values['key'].to_s.match(/[A-Z]|[a-z]|[0-9]/)
  if values['file'].to_s.match(%r{/})
    dir_name = Pathname.new(values['file'])
    dir_name = dir_name.dirname
    FileUtils.mkdir_p(dir_name) if !File.directory?(dir_name) && !File.symlink?(dir_name)
  end
  s3 = initiate_aws_s3_client(values)
  information_message(values,
                      "Downloading: Key '#{values['key']}' from bucket: '#{values['bucket']}' to file: '#{values['file']}'")
  s3.get_object({ bucket: values['bucket'], key: values['key'] }, target: values['file'])
  nil
end

# Get buckets

def get_aws_buckets(values)
  s3 = initiate_aws_s3_client(values)
  begin
    buckets = s3.list_buckets.buckets
  rescue Aws::S3::Errors::AccessDenied
    warning_message(values, 'User needs to be given appropriate rights in AWS IAM')
    quit(values)
  end
  buckets
end

# Check if AWS bucket exists

def check_if_aws_bucket_exists(values)
  exists  = false
  buckets = get_aws_buckets(values)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if bucket_name.match(/#{values['bucket']}/)
      exists = true
      return exists
    end
  end
  exists
end
