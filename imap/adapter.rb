require "rubygems"
gem "dm-core"
require "data_mapper"
require "net/imap"
require "#{File.dirname(__FILE__)}/types"
require "#{File.dirname(__FILE__)}/typecast"

# DataMapper.setup(:default, "imap://wycats%40gmail.com:pass@imap.gmail.com/INBOX")

module DataMapper
  module Adapters
    
    class ImapAdapter < AbstractAdapter
      def connect
        @imap = Net::IMAP.new(@uri.host, 993, true)
        begin
          @imap.send(:send_command, "authenticate", "login")
        rescue
        ensure
          @imap.send(:send_command, "login", URI.unescape(@uri.user), @uri.password)
        end
        @imap.select(@uri.path.gsub(%r{^/}, ""))
      end
            
      def read(repository, resource, key)
        properties = resource.properties(name).defaults
        properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]

        set = Collection.new(repository, resource, properties_with_indexes)        
        
        connect
        
        imap_results = @imap.uid_fetch(key, imap_props(properties))
        materialize_imap_results(set, imap_results, properties_with_indexes)
        set.first
      end
      
      def read_set(repository, query, one = false)
        properties = query.fields
        properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]

        set = Collection.new(repository, query.model, properties_with_indexes)
        
        query_array = query_to_array(query)
        query_array.unshift "ALL"
        
        begin
          connect unless @imap
          if one
            imap_results = @imap.fetch(1, imap_props(properties))
          else
            imap_seqs = @imap.search(query_array)
            puts "@imap.fetch(#{imap_seqs.inspect}, #{imap_props(properties).inspect})"
            imap_results = @imap.fetch(imap_seqs, imap_props(properties))
          end
        rescue Net::IMAP::NoResponseError
          connect
          retry
        end
        
        materialize_imap_results(set, imap_results, properties_with_indexes, query.reload?)
        set
      end
      
      def read_one(repository, query)
        read_set(repository, query, true).first
      end
      
      def query_to_array(query)
        result = []
        query.conditions.each do |op, prop, val|
          result += (prop.type.query_details[op] + [typecast_dump(val)])
        end
        result
      end
      
      def materialize_imap_results(set, results, properties_with_indexes, reload = false)
        results.each do |result|
          props = properties_with_indexes.inject([]) do |accum, prop_idx|
            prop, idx = prop_idx
            prop_result = result.attr[prop.field.upcase]
            prop_result = prop_result.send(prop.type.envelope_name) if prop.type.envelope?
            accum[idx] = typecast_load(prop_result, prop)
            accum
          end
          set.load props, reload
        end
      end
      
      def imap_props(properties)
        properties.map {|prop| prop.field.upcase}.uniq
      end
      
    end
    
  end  
end

ImapTypes = DataMapper::Adapters::Imap

class Gmail
  include DataMapper::Resource
  
  property :id, ImapTypes::Uid, :key => true
  property :subject, ImapTypes::Subject
  property :sender, ImapTypes::Sender
  property :date, ImapTypes::InternalDate
  property :body, ImapTypes::Body, :lazy => true

  def inspect
    self.class.properties(:default).inject({}) {|s,x| s.merge(x.name => self.instance_variable_get("@#{x.name}"))}.inspect
  end  
end