# frozen_string_literal: true

# S3 common code

# Initiate an AWS S3 Bucket connection

def initiate_aws_s3_client(values)
  Aws::S3::Client.new(
    region: values['region'],
    access_key_id: values['access'],
    secret_access_key: values['secret']
  )
end

# Initiate an AWS S3 Resource connection

def initiate_aws_s3_resource(values)
  Aws::S3::Resource.new(
    region: values['region'],
    access_key_id: values['access'],
    secret_access_key: values['secret']
  )
end

# Initiate an AWS S3 Resource connection

def initiate_aws_s3_bucket(values)
  Aws::S3::Bucket.new(
    region: values['region'],
    access_key_id: values['access'],
    secret_access_key: values['secret']
  )
end

# Initiate an AWS S3 Object connection

def initiate_aws_s3_object(values)
  Aws::S3::Object.new(
    region: values['region'],
    access_key_id: values['access'],
    secret_access_key: values['secret']
  )
end

# Initiate an AWS S3 Presigner connection

def initiate_aws_s3_presigner(values)
  Aws::S3::Presigner.new(
    region: values['region'],
    access_key_id: values['access'],
    secret_access_key: values['secret']
  )
end

# Get private URL for S3 bucket item

def get_s3_bucket_private_url(values)
  s3 = initiate_aws_s3_presigner(values)
  s3.presigned_url(:get_object, bucket: values['bucket'], key: values['object'])
end

# Get public URL for S3 bucket item

def get_s3_bucket_public_url(values)
  s3 = initiate_aws_s3_resource(values)
  s3.bucket(values['bucket']).object(values['object']).public_url
end

# Show URL for S3 bucket

def show_s3_bucket_url(values)
  url = if values['type'].to_s.match(/public/)
          get_s3_bucket_public_url(values)
        else
          get_s3_bucket_private_url(values)
        end
  verbose_message(url)
  nil
end

# List AWS buckets

def list_aws_buckets(values)
  buckets = get_aws_buckets(values)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if values['bucket'].to_s.match(/^all$|#{bucket_name}|^none$/)
      bucket_date = bucket.creation_date
      verbose_message(values, "#{bucket_name}\tcreated=#{bucket_date}")
    end
  end
  nil
end

# List AWS bucket objects

def list_aws_bucket_objects(values)
  buckets = get_aws_buckets(values)
  buckets.each do |bucket|
    bucket_name = bucket.name
    next unless values['bucket'].to_s.match(/^all$|#{bucket_name}/)

    verbose_message(values, '')
    verbose_message(values, "#{bucket_name}:")
    s3 = initiate_aws_s3_client(values['access'], values['secret'], values['region'])
    objects = s3.list_objects_v2({ bucket: bucket_name })
    objects.contents.each do |object|
      object_key = object.key
      verbose_message(object_key)
    end
  end
  nil
end
