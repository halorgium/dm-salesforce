module DataMapper
  module Adapters
    
    class ImapAdapter < AbstractAdapter

      def typecast_load(obj, prop)
        if [Date, Time, DateTime].include?(prop.primitive)
          Time.parse(obj)
        else
          obj
        end
      end
      
      def typecast_dump(obj)
        case obj
        when Date, Time, DateTime
          obj.strftime("%d-%b-%Y")
        else
          obj
        end
      end
      
    end
    
  end
end