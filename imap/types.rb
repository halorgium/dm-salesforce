module DataMapper
  module Adapters
    
    module Imap
      class ImapType < DataMapper::Type
        class << self
          attr_reader :query_details
          def imap_query(name)
            @query_details = name
          end
          
          attr_reader :envelope_name
          def envelope(name)
            self.field "ENVELOPE"
            @envelope_name = name
          end
          
          def envelope?
            !!@envelope_name
          end
        end
      end

      class Uid < ImapType
        primitive String
        field "UID"
        imap_query(:eql => ["UID"], :like => ["UID"])
      end

      class Body < ImapType
        primitive String
        field "RFC822.TEXT"
        imap_query(:eql => ["BODY"], :like => ["BODY"])
      end

      class InternalDate < ImapType
        primitive DateTime
        field "INTERNALDATE"
        imap_query(:lt => ["BEFORE"], :eql => ["ON"], :gt => ["SINCE"])
      end

      class EnvelopeDate < ImapType
        primitive DateTime
        envelope :date
        imap_query(:lt => ["SENTBEFORE"], :eql => ["SENTON"], :gt => ["SENTSINCE"])
      end

      class Size < ImapType
        primitive Integer
        field "RFC822.SIZE"
        imap_query(:lt => ["SMALLER"], :gt => ["LARGER"])
      end

      class Header < ImapType
        primitive String
        field "BODY.PEEK[HEADER]"
        imap_query(:eql => ["HEADER"])
      end

      {:from => ["FROM"], :sender => ["HEADER", "Sender"], 
       :to => ["TO"], :reply_to => ["HEADER", "Reply-To"],
       :cc => ["CC"], :bcc => ["BCC"]}.each do |kind, imap_query|
          self.class_eval <<-HERE
            class #{Inflection.camelize(kind.to_s)} < ImapType
              primitive Object
              envelope :#{kind}
              imap_query(:eql => #{imap_query.inspect}, :like => #{imap_query.inspect})
            end
          HERE
      end

      {:subject => ["SUBJECT"], :in_reply_to => ["HEADER", "In-Reply-To"],
       :message_id => ["HEADER", "Message-ID"]}.each do |kind, imap_query|
          self.class_eval <<-HERE
            class #{Inflection.camelize(kind.to_s)} < ImapType
              primitive String
              envelope :#{kind}
              imap_query(:eql => #{imap_query.inspect}, :like => #{imap_query.inspect})
            end
          HERE
      end

    end

  end
end
    