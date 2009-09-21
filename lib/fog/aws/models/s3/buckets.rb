module Fog
  module AWS
    class S3

      def buckets
        Fog::AWS::S3::Buckets.new(:connection => self)
      end

      class Buckets < Fog::Collection

        def all
          data = connection.get_service.body
          owner = Fog::AWS::S3::Owner.new(data.delete('Owner').merge!(:connection => connection))
          buckets = Fog::AWS::S3::Buckets.new(:connection => connection)
          data['Buckets'].each do |bucket|
            buckets << Fog::AWS::S3::Bucket.new({
              :buckets    => buckets,
              :connection => connection,
              :owner      => owner
            }.merge!(bucket))
          end
          buckets
        end

        def create(attributes = {})
          bucket = new(attributes)
          bucket.save
          bucket
        end

        def get(name, options = {})
          remap_attributes(options, {
            :max_keys     => 'max-keys',
          })
          data = connection.get_bucket(name, options).body
          bucket = Fog::AWS::S3::Bucket.new({
            :buckets    => self,
            :connection => connection,
            :name       => data['Name']
          })
          options = {}
          for key, value in data
            if ['Delimiter', 'IsTruncated', 'Marker', 'MaxKeys', 'Prefix'].include?(key)
              options[key] = value
            end
          end
          bucket.objects.merge_attributes(:options => options)
          data['Contents'].each do |object|
            owner = Fog::AWS::S3::Owner.new(object.delete('Owner').merge!(:connection => connection))
            bucket.objects << Fog::AWS::S3::Object.new({
              :bucket     => bucket,
              :connection => connection,
              :objects    => self,
              :owner      => owner
            }.merge!(object))
          end
          bucket
        rescue Fog::Errors::NotFound
          nil
        end

        def new(attributes = {})
          Fog::AWS::S3::Bucket.new(
            attributes.merge!(
              :connection => connection,
              :buckets    => self
            )
          )
        end

        def reload
          all
        end

      end

    end
  end
end
