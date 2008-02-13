module ActsAsSolr #:nodoc:
  
  module InstanceMethods

    # Solr id is <class.name>:<id> to be unique across all models
    def solr_id
      "#{self.class.name}:#{record_id(self)}"
    end

    # saves to the Solr index
    def solr_save
      return true unless configuration[:if] 
      if evaluate_condition(configuration[:if], self) 
        logger.debug "solr_save: #{self.class.name} : #{record_id(self)}"
        solr_add to_solr_doc
        solr_commit if configuration[:auto_commit]
        true
      else
        solr_destroy
      end
    end

    # remove from index
    def solr_destroy
      logger.debug "solr_destroy: #{self.class.name} : #{record_id(self)}"
      solr_delete solr_id
      solr_commit if configuration[:auto_commit]
      true
    end

    # convert instance to Solr document
    def to_solr_doc
      logger.debug "to_solr_doc: creating doc for class: #{self.class.name}, id: #{record_id(self)}"
      doc = Solr::Document.new
      doc.boost = validate_boost(configuration[:boost]) if configuration[:boost]
      
      doc << {:id => solr_id,
              solr_configuration[:type_field] => self.class.name,
              solr_configuration[:primary_key_field] => record_id(self).to_s}

      add_fields(doc, self, self.class)
      add_includes(doc, self, self.class) if configuration[:include]
      add_spellword(doc) if configuration[:spellcheck]
      logger.debug doc.to_xml.to_s
      return doc
    end

    def add_fields(doc, obj, klass, stack = [], multivalued = false)
      # iterate through the fields and add them to the document,
      klass.configuration[:solr_fields].each do |field|
        field_name = field
        field_type = klass.configuration[:facets] && klass.configuration[:facets].include?(field) ? :facet : :text
        field_boost= klass.solr_configuration[:default_boost]
        if field.is_a?(Hash)
          field_name = field.keys.pop
          if field.values.pop.respond_to?(:each_pair)
            attributes  = field.values.pop
            field_type  = get_solr_field_type(attributes[:type]) if attributes[:type]
            field_boost = attributes[:boost] if attributes[:boost]
            mulitvalued = attributes[:multivalued] if attributes[:multivalued]
          else
            field_type = get_solr_field_type(field.values.pop)
            field_boost= field[:boost] if field[:boost]
          end
        end
        value = obj.send("#{field_name}_for_solr")
        value = set_value_if_nil(field_type) if value.to_s == ""

        # add the field to the document, but only if it's not the id field
        # or the type field (from single table inheritance), since these
        # fields have already been added above.
        if field_name.to_s != obj.class.primary_key and field_name.to_s != "type"
          suffix = get_solr_field_type(field_type, multivalued)
          # This next line ensures that e.g. nil dates are excluded from the
          # document, since they choke Solr. Also ignores e.g. empty strings,
          # but these can't be searched for anyway:
          # http://www.mail-archive.com/solr-dev@lucene.apache.org/msg05423.html
          next if value.nil? || value.to_s.strip.empty?
          [value].flatten.each do |v|
            v = set_value_if_nil(suffix) if value.to_s == ""
            field_name = "#{stack.join('_')}_#{field_name}" if stack.size > 0
            field = Solr::Field.new("#{field_name}_#{suffix}" => ERB::Util.html_escape(v.to_s))
            field.boost = validate_boost(field_boost)
            doc << field
          end
        end

      end
    end

    private
    def add_includes(doc, obj, klass, stack = [])
      if klass.configuration[:include] and klass.configuration[:include].is_a?(Array)
        klass.configuration[:include].each do |association|
          data = ""
          if association.is_a?(Hash) and association.has_key?(:name)
            association_name = association[:name]
            association_fields = association.values.pop
          else
            association_name = association 
            association_fields = nil
          end
          associated_klass = association_name.to_s.singularize
          case obj.class.reflect_on_association(association_name).macro
          when :has_many, :has_and_belongs_to_many
            records = self.send(association_name).to_a
            unless records.empty?
              if association_fields.nil?
                association_fields = records.first.attributes.keys
              end
              if records.first.respond_to?(:to_solr_doc) and stack.size < 6
                stack << records.first.class.name.underscore
                records.each do | record |
                  add_fields(doc, record, record.class, stack, true)
                end
                stack.pop
              else
                records.each{|r| data << r.attributes.inject([]){|k,v| k << "#{v.first}=#{ERB::Util.html_escape(v.last)}"}.join(" ")}
                doc["#{associated_klass}_t"] = data
              end
            end
          when :has_one, :belongs_to
            record = obj.send(association_name)
            unless record.nil?
              if record.respond_to?(:to_solr_doc) and stack.size < 6
                stack << record.class.name.underscore
                add_fields(doc, record, record.class, stack)
                stack.pop
              else
                data = record.attributes.inject([]){|k,v| k << "#{v.first}=#{ERB::Util.html_escape(v.last)}"}.join(" ")
                doc["#{associated_klass}_t"] = data
              end
            end
          end
        end
      end
    end


    def add_spellword(doc)
      if configuration[:spellcheck].is_a?(Array)
        spellword = configuration[:spellcheck].collect {| field_name | self.send("#{field_name}_for_solr")}.join(' ')
        doc << Solr::Field.new("spellword" => spellword)
      end
    end
    
    def validate_boost(boost)
      if boost.class != Float || boost < 0
        logger.warn "The boost value has to be a float and posisive, but got #{boost}. Using default boost value."
        return solr_configuration[:default_boost]
      end
      boost
    end
    
    def condition_block?(condition)
      condition.respond_to?("call") && (condition.arity == 1 || condition.arity == -1)
    end
    
    def evaluate_condition(condition, field)
      case condition
        when Symbol: field.send(condition)
        when String: eval(condition, binding)
        else
          if condition_block?(condition)
            condition.call(field)
          else
            raise(
              ArgumentError,
              "The :if option has to be either a symbol, string (to be eval'ed), proc/method, or " +
              "class implementing a static validation method"
            )
          end
        end
    end
  end
end