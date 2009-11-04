module DataMapper::Salesforce
  module SQL
    def from_condition(condition, repository)
      slug = condition.class.slug
      condition = case condition
                  when DataMapper::Query::Conditions::AbstractOperation then condition.operands.first
                  when DataMapper::Query::Conditions::AbstractComparison
                    if condition.subject.kind_of?(DataMapper::Associations::Relationship)
                      foreign_key_conditions(condition)
                    else
                      condition
                    end
                  else raise("Unkown condition type #{condition.class}: #{condition.inspect}")
                  end

      value = condition.value
      prop = condition.subject
      operator = case slug
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
      when DataMapper::Property
        "#{prop.field} #{operator}"
      when DataMapper::Query::Path
        rels = prop.relationships
        names = rels.map {|r| storage_name(r, repository) }.join(".")
        "#{names}.#{prop.field} #{operator}"
      end
    end

    def foreign_key_conditions(condition)
      subject = condition.subject.child_key.first
      case condition.value
      when Array
        value = condition.value.map {|m| m.send(m.model.key.first.name) }
        DataMapper::Query::Conditions::InclusionComparison.new(subject, value)
      else
        value = condition.value.send(condition.value.model.key.first.name)
        DataMapper::Query::Conditions::EqualToComparison.new(subject, value)
      end
    end

    def storage_name(rel, repository)
      rel.parent_model.storage_name(repository.name)
    end

    def order(direction)
      "#{direction.target.field} #{direction.operator.to_s.upcase}"
    end

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
