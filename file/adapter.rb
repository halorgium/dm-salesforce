require "rubygems"
gem "dm-core"
require "data_mapper"
require "fileutils"
require "digest/sha1"

module DataMapper
  module Adapters
    
    class FileAdapter < AbstractAdapter
      
      def read(repository, resource, key)
        properties = resource.properties(repository.name).select { |property| !property.lazy? }
        properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]
        
        set = Collection.new(repository, resource, properties_with_indexes)

        begin
          set.load [key, File.read(File.join(key_to_path(key), key))]
          set.first
        rescue
          nil
        end
      end
      
      def create(repository, instance)
        update(repository, instance)
      end
      
      def update(repository, instance)
        dirty_attributes = instance.dirty_attributes
        properties = instance.class.properties(name).select { |property| dirty_attributes.include?(property) }

        begin
          FileUtils.mkdir_p key_to_path(instance.key)
          file = File.open(File.join(key_to_path(instance.key), instance.key), "w") do |f|
            text_col = dirty_attributes[properties.find {|x| !x.key?}.name]
            f.print text_col
            f.flush
          end
          true
        rescue
          false
        end
      end
      
      def delete(repository, instance)
        begin
          FileUtils.rm(File.join(key_to_path(instance.key), instance.key))
          true
        rescue
          false
        end
      end
      
      def read_one(repository, query)
        read_set(repository, query, true)
      end
      
      def read_set(repository, query, one = false)
        properties = query.fields
        properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]
        
        set = Collection.new(repository, query.model, properties_with_indexes)
        
        key_cond, text_cond = query.conditions.partition {|kind, prop, cond| prop.key?}
        key_cond.flatten!; text_cond.flatten!
        
        filename = case key_cond.first
        when :eql     then key_cond.last
        when :like    then "*#{key_cond.last}*"
        when nil
        else          raise ArgumentError, "You can only use equals or .like on the filename"
        end || "*"
        
        contents = case text_cond.first
        when :eql
          /#{text_cond.last}/
        when :like
          /.*#{text_cond.last}.*/
        when nil
        else
          raise ArgumentError, "You can only use equals or .like on the contents"
        end || /.*/
        
        contents = Dir["#{@uri.path}/**/#{filename}"].each do |file|
          next unless File.file?(file)
          txt = File.read(file)
          if txt =~ contents
            item = set.load [File.basename(file), txt]
            return item if one
          end
        end
        set.entries
      end
      
      private
      def key_to_path(key)
        File.join(@uri.path, Digest::SHA1.hexdigest(key.join('+')).scan(/.{5}/))
      end
      
    end
    
  end
end

class Foo
  include DataMapper::Resource
  property :name, String, :key => true
  property :text, String
  
  def inspect
    self.class.properties(:default).inject({}) {|s,x| s.merge(x.name => self.instance_variable_get("@#{x.name}"))}.inspect
  end
end

DataMapper.setup(:default, "file:///Users/wycats/textmate/dm/adapters")