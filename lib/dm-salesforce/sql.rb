module DataMapper::Salesforce
  module SQL
    def conditions_statement(conditions, repository)
      case conditions
      when DataMapper::Query::Conditions::NotOperation       then negate_operation(conditions.operand, repository)
      when DataMapper::Query::Conditions::AbstractOperation  then conditions.operands.first # ignores AND/OR grouping for now.
      when DataMapper::Query::Conditions::AbstractComparison then comparison_statement(conditions, repository)
      else raise("Unkown condition type #{conditions.class}: #{conditions.inspect}")
      end
    end

    def comparison_statement(comparison, repository)
      subject = comparison.subject
      value = comparison.value

      if comparison.relationship?
        return conditions_statement(comparison.foreign_key_mapping, repository)
      elsif comparison.slug == :in && value.empty?
        return []  # match everything
      end

      operator    = comparison_operator(comparison)
      column_name = property_to_column_name(subject, repository)

      "#{column_name} #{operator} #{quote_value(value,subject)}"
    end

    def comparison_operator(comparison)
      subject = comparison.subject
      value   = comparison.value

      case comparison.slug
      when :eql    then equality_operator(subject, value)
      when :in     then include_operator(subject, value)
      when :not    then inequality_operator(subject, value)
      when :regexp then regexp_operator(value)
      when :like   then like_operator(value)
      when :gt     then '>'
      when :lt     then '<'
      when :gte    then '>='
      when :lte    then '<='
      end
    end

    def negate_operation(operand, repository)
      statement = conditions_statement(operand, repository)
      statement = "NOT(#{statement})" unless statement.nil?
      statement
    end

    def property_to_column_name(prop, repository)
      case prop
      when DataMapper::Property
        prop.field
      when DataMapper::Query::Path
        rels = prop.relationships
        names = rels.map {|r| storage_name(r, repository) }.join(".")
        "#{names}.#{prop.field}"
      end
    end

    def storage_name(rel, repository)
      rel.parent_model.storage_name(repository.name)
    end

    def order(direction)
      "#{direction.target.field} #{direction.operator.to_s.upcase}"
    end

    def equality_operator(property, operand)
      operand.nil? ? 'IS' : '='
    end

    def include_operator(property, operand)
      case operand
      when Array then 'IN'
      when Range then 'BETWEEN'
      end
    end

    def like_operator(operand)
      "LIKE"
    end

    def quote_value(value, property)
      if property.type == DataMapper::Salesforce::Property::Boolean
        # True on salesforce needs to be TRUE/FALSE for WHERE clauses but not for inserts.
        return value == DataMapper::Salesforce::Property::Boolean::TRUE ? 'TRUE' : 'FALSE'
      end

      case value
      when Array then "(#{value.map {|v| quote_value(v, property)}.join(", ")})"
      when NilClass then "NULL"
      when String then "'#{value.gsub(/'/, "\\'").gsub(/\\/, %{\\\\})}'"
      else "#{value}"
      end
    end
  end
end
