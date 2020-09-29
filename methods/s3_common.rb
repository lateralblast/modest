# S3 common code

# Initiate an AWS S3 Bucket connection

def initiate_aws_s3_client(options)
  s3 = Aws::S3::Client.new(
    :region             =>  options['region'], 
    :access_key_id      =>  options['access'],
    :secret_access_key  =>  options['secret']
  )
  return s3
end 

# Initiate an AWS S3 Resource connection

def initiate_aws_s3_resource(options)
  s3 = Aws::S3::Resource.new(
    :region             =>  options['region'], 
    :access_key_id      =>  options['access'],
    :secret_access_key  =>  options['secret']
  )
  return s3
end 

# Initiate an AWS S3 Resource connection

def initiate_aws_s3_bucket(options)
  s3 = Aws::S3::Bucket.new(
    :region             =>  options['region'], 
    :access_key_id      =>  options['access'],
    :secret_access_key  =>  options['secret']
  )
  return s3
end 

# Initiate an AWS S3 Object connection

def initiate_aws_s3_object(options)
  s3 = Aws::S3::Object.new(
    :region             =>  options['region'], 
    :access_key_id      =>  options['access'],
    :secret_access_key  =>  options['secret']
  )
  return s3
end 

# Initiate an AWS S3 Presigner connection

def initiate_aws_s3_presigner(options)
  s3 = Aws::S3::Presigner.new(
    :region             =>  options['region'], 
    :access_key_id      =>  options['access'],
    :secret_access_key  =>  options['secret']
  )
  return s3
end 

# Get private URL for S3 bucket item

def get_s3_bucket_private_url(options)
 s3  = initiate_aws_s3_presigner(options)
 url = s3.presigned_url( :get_object, bucket: options['bucket'], key: options['object'] )
 return url
end

# Get public URL for S3 bucket item

def get_s3_bucket_public_url(options)
 s3  = initiate_aws_s3_resource(options)
 url = s3.bucket(options['bucket']).object(options['object']).public_url
 return url
end

# Show URL for S3 bucket

def show_s3_bucket_url(options)
  if options['type'].to_s.match(/public/)
    url = get_s3_bucket_public_url(options)
  else
    url = get_s3_bucket_private_url(options)
  end
  handle_output(url)
  return
end

# List AWS buckets

def list_aws_buckets(options)
  buckets = get_aws_buckets(options)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if options['bucket'].to_s.match(/^all$|#{bucket_name}|^none$/)
      bucket_date = bucket.creation_date
      handle_output(options,"#{bucket_name}\tcreated=#{bucket_date}")
    end
  end
  return
end

# List AWS bucket objects

def list_aws_bucket_objects(options)
  buckets = get_aws_buckets(options)
  buckets.each do |bucket|
    bucket_name = bucket.name
    if options['bucket'].to_s.match(/^all$|#{bucket_name}/)
      handle_output(options,"")
      handle_output(options,"#{bucket_name}:")
      s3 = initiate_aws_s3_client(options['access'],options['secret'],options['region'])
      objects = s3.list_objects_v2({ bucket: bucket_name })
      objects.contents.each do |object|
        object_key = object.key
        handle_output(object_key)
      end
    end
  end
  return
end
