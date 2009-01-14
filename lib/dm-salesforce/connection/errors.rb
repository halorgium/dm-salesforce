module DataMapperSalesforce
  class Connection
    class Error          < StandardError; end
    class FieldNotFound  < Error; end
    class LoginFailed    < Error; end
    class SessionTimeout < Error; end

    class SOAPError      < Error
      def initialize(message, result)
        @result = result
        super("#{message}: #{result_message}")
      end

      def records
        @result.to_a
      end

      def failed_records
        @result.reject {|r| r.success}
      end

      def successful_records
        @result.select {|r| r.success}
      end

      def result_message
        failed_records.map do |r|
          message_for_record(r)
        end.join("; ")
      end

      def message_for_record(record)
        record.errors.map {|e| "#{e.statusCode}: #{e.message}"}.join(", ")
      end
    end
    class CreateError    < SOAPError; end
    class QueryError     < SOAPError; end
    class DeleteError    < SOAPError; end
    class UpdateError    < SOAPError; end
  end
end
