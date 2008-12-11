module DataMapperSalesforce
  module SQL
    class << self
      def from_condition(condition, repository)
        op, prop, value = condition
        operator = case op
          when String then operator
          when :eql, :in then equality_operator(value)
          when :not      then inequality_operator(value)
          when :like     then "LIKE #{quote_value(value)}"
          when :gt       then "> #{quote_value(value)}"
          when :gte      then ">= #{quote_value(value)}"
          when :lt       then "< #{quote_value(value)}"
          when :lte      then "<= #{quote_value(value)}"
          else raise "CAN HAS CRASH?"
        end
        case prop
        when Property
          "#{prop.field} #{operator}"
        when Query::Path
          rels = prop.relationships
          names = rels.map {|r| storage_name(r, repository) }.join(".")
          "#{names}.#{prop.field} #{operator}"
        end
      end

      def storage_name(rel, repository)
        rel.parent_model.storage_name(repository.name)
      end

      def order(direction)
        "#{direction.property.field} #{direction.direction.to_s.upcase}"
      end

      private
      def equality_operator(value)
        case value
        when Array then "IN #{quote_value(value)}"
        else "= #{quote_value(value)}"
        end
      end

      def inequality_operator(value)
        case value
        when Array then "NOT IN #{quote_value(value)}"
        else "!= #{quote_value(value)}"
        end
      end

      def quote_value(value)
        case value
        when Array then "(#{value.map {|v| quote_value(v)}.join(", ")})"
        when NilClass then "NULL"
        when String then "'#{value.gsub(/'/, "\\'").gsub(/\\/, %{\\\\})}'"
        else "#{value}"
        end
      end
    end
  end
end
