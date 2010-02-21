#  == Synopsis
#
#  Processes a series of document references according to a given CSL style.
#  Builds a directed graph of ProcessedNodes, which can be used by a Formatter.
#
#  == Author
#
#  Liam Magee
#
#  == Copyright
#
#  Copyright (c) 2008, Liam Magee.
#  Licensed under the same terms as Ruby - see http://www.ruby-lang.org/en/LICENSE.txt.
#
 
module Citeproc
  
  # Represents a processed part of the CSL tree with results
  class ProcessedNode
    attr_reader :element, :results, :children
    
    def initialize(element, results, children)
      @element = element
      @results = results
      @children = children
    end
    
    def empty?
      results.empty?
    end
  end
  
  class CslProcessor
    
    def init_process(filter, style, locale)
      @substitutions = []
      @filter = filter
      @style = style
      @locale = locale
      
      # Citation number & label
      @citation_number = 1
      @citation_label = "#"
    end
    
    
    def process_citation(filter, style, locale)
      process_top_node(style.citation, filter, style, locale)
    end
    
    
    def process_bibliography(filter, style, locale)
      process_top_node(style.bibliography, filter, style, locale)
    end

    
    def process_top_node(node, filter, style, locale)
      init_process(filter, style, locale)
      nodes = []
      if node
        @filter.each_sorted_citation(generate_sort_keys(node)) do |citation|
          nodes << process_layout(node.layout) if node.layout
          @citation_number += 1
        end
      end
      nodes
    end

    def process_all(filter, style, locale)
      results = []
      results << process_citation(filter, style, locale)
      results << process_bibliography(filter, style, locale)
      results
    end

    
    def generate_sort_keys(node)
      key_sets = []
      if node.sort
        @filter.each_citation do |citation|
          keys = []
          keys << citation
          node.sort.keys.each do |key|
            tmp = find_keys(process_element(key))
            keys << tmp.flatten if tmp
          end
          key_sets << keys
        end
      end
      key_sets
    end
    
    
    def find_keys(node)
      results = []
      node.children.compact.each do |n| 
        results << n.results
        results << find_keys(n) 
      end
      results.flatten
    end

    
    
    def process_layout(layout)
      elements = process_elements(layout.elements)
      process(layout, [], elements)
    end
    
    
    def process_elements(elements, context = nil)
      results = []
      elements.each do |element|
        results << process_element(element, context) unless substituted?(element)
      end
      results
    end

    # Less than ideal... Checks if an element has already been substituted.
    # In the case of variables, this is complicated due to the possibility
    # of multiple variable names in the one attribute.
    def substituted?(element)
      return true if @substitutions.include?(element)
      @substitutions.each do |sub|
        if sub.kind_of?(ShortNames) and element.kind_of?(ShortNames)
          element.variable.split.each do |e|
            return true if e == sub.variable
          end
        end
      end
      false
    end
    
    
    def process_element(element, context = nil)
      case 
      when element.kind_of?(Names)
        process_names(element)
        # This is a special case for names declared within the substitute node of another names context.
      when (element.kind_of?(ShortNames) and context)
        process_name_series(element.variable, context)
      when element.kind_of?(Date)
        process_date(element)
      when element.kind_of?(Text)
        process_text(element)
      when element.kind_of?(Label)
        process_label(element, context)
      when element.kind_of?(Group)
        process_group(element)
      when element.kind_of?(ConditionGroup)
        process_group_conditions(element)
      end
    end

      
    def process_names(names)
      result = process_name_series(names.variable, names)
      
      # Process the rest of the substitute node, if the result is blank
      if !result or result.empty? 
        names.substitute.elements.each do |sub|
          tmp = process_element(sub, names)
          if tmp and !tmp.empty?
            # Put this node on the substitutions stack 
            @substitutions << sub
            result = tmp
            break
          end
        end if names.substitute 
      end
      result
    end
    
    
    def process_name_series(variable, name_context)
      name_def = name_context.name

      # Format the names
      name_groups = []
      
      process_name(name_context, variable) do |name_strs, role| 
        labels = []
        name_context.labels.each do |label|
          labels << process_label(label, role)
        end
        tmp = process(name_def, name_strs, labels)
        name_groups << tmp
      end
      result = process(name_context, [], name_groups)
      result
    end
      
    def process_name(name_context, roles)
      name_str = ''
      name_def = name_context.name
      roles.split.each do |r|
        names = []
        et_al_counter = 0
        @filter.extract_contributor(r, name_def.name_as_sort_order) do |n|
          given_names = n.given_name
          if name_def.form == "short"
            name_str = "#{n.family_name}"
          elsif name_def.name_as_sort_order
            sep = name_def.sort_separator ? name_def.sort_separator : " "
            name_str = n.family_name + sep + process_given_name(name_def, given_names)
          else
            name_str = process_given_name(name_def, given_names) + n.family_name
          end
          names << name_str.strip
        end
        # TODO: place et-al, collapse and disambiguate logic here
        yield names, r if !names.empty?
      end
    end
    
    # Need to add sort
    def process_given_name(name_def, given_names)
      if given_names
        if name_def.initialize_with
          given_names.split.collect{|n| n[0..0].upcase + name_def.initialize_with }.join
        else
          given_names
        end
      end
    end
    
    
    def process_label(label, variable = nil)
      results = []
      if label.kind_of?(Label) and label.variable
        var, singular = @filter.extract_label(label)
        results << @locale.term_text(var, label.form, singular) if var and @locale
      elsif variable
        tmp = @locale.term_text(variable, label.form, singular) if @locale
        results << tmp if tmp
      end
      results << '.' if label.include_period and !results.empty? 
      process(label, results, [])
    end

    
    def process_date(date)
      d = @filter.extract_date(date.variable)
      elements = []
      date.dateparts.each do |datepart|
        elements << process_datepart(datepart, d)
      end
      #puts elements
      process(date, [], elements)
    end

    
    def process_datepart(datepart, date)
      process(datepart, [get_datepart(datepart, date)], []) if date
    end


    def get_datepart(datepart, date)
      #puts date.class
      #puts date
      if date.is_a?(String)
        # Can't do much here for now...
        date
      else
        case datepart.name
        when "month"
          case datepart.form
          when "short"
            date.strftime("%b") + (datepart.include_period ? '.' : '')
          when "numeric"
            date.month.to_s
          when "numeric-leading-zeros"
            date.strftime("%d")
          else
            date.strftime("%B")
          end
        when "day"
          if datepart.form == "numeric"
            date.day.to_s
          elsif datepart.form == "numeric-leading-zeros" # Leading zeros
            date.strftime("%d")
          else # Ordinal - NB: not internationalised
            if date.day % 10 == 1 and date.day / 10 != 1
              date.day.to_s + "st"
            elsif date.day % 10 == 2 and date.day / 10 != 1
              date.day.to_s + "nd"
            elsif date.day % 10 == 3 and date.day / 10 != 1
              date.day.to_s + "rd"
            else
              date.day.to_s + "th"
            end
          end
        when "year"
          if datepart.form == "short"
            date.strftime("%y")
          else
            date.strftime("%Y")
          end
        else 
          date.to_s
        end
      end
    end
    
    
    def process_text(text)
      node = nil
      case
      when text.kind_of?(VariableText)
        tmp = text.variable.split.collect { |e| process_variable(e) } 
        node = process(text, tmp, [])
      when text.kind_of?(MacroText)
        node = expand_macro(text)
      when text.kind_of?(TermText)
        # Fix
        node = process(text, [text.value], [])
      when text.kind_of?(ValueText)
        node = process(text, [text.value], [])
      end
      node
    end
    
    
    def process_variable(variable)
      case variable
      when "citation-number"
        @citation_number
      when "citation-label"
        @citation_label
      else
        @filter.extract_variable(variable)
      end
    end
    
    
    
    
    def process_group(group)
      process(group, [], process_elements(group.elements)) if eval_group_variable(group)
    end
    
    
    # Test whether there is a non-blank variable in this group
    # TODO: Very poor perfomance (forces 2-time evaluation of all rules) and
    # incorrect treatment of conditions - evaluates ALL for variable resolution.
    def eval_group_variable(group)
      group.elements.flatten.each do |element|
        if element.kind_of? VariableText
          var = element.variable
          return true if eval_variable(var)
        elsif element.kind_of? Date
          var = element.variable
          return true if eval_variable(var)
        elsif element.kind_of? Names
          var = element.variable
          return true if eval_variable(var)
          element.substitute.names.each do |name|
            var = name.variable
            return true if eval_variable(var)
          end if element.substitute
        elsif element.kind_of? MacroText
          macro = get_macro(element)
          if macro
            return true if eval_group_variable(macro) 
          else
            raise "Could not find macro with the name of: #{element.value}."
          end
        elsif element.kind_of? Group
          return true if eval_group_variable(element)
        elsif element.kind_of? ConditionGroup
          element.conditions.each do |c|
            return true if eval_group_variable(c)
          end
        end
      end if group.elements
      false
    end
    
    def eval_variable(var)
      var.split.each do |v|
        tmp = @filter.extract_variable(v)
        if tmp and !tmp.to_s.empty?
          return true
        end
      end
      false
    end
   
    
    def process_group_conditions(conditions)
      node = nil
      conditions.each do |condition|
        if met?(condition)
          node = process(condition, [], process_elements(condition.elements)) 
          break
        end
      end
      node
    end
    
    def met?(condition)
      if condition.type
        met_type?(condition)
      elsif condition.variable
        met_variable?(condition)
      elsif condition.position
        met_position?(condition)
      elsif condition.disambiguate
        met_disambiguate?(condition)
      elsif condition.locator
        met_locator?(condition)
      else
        true
      end
    end
    
    def met_type?(condition)
      conditions = condition.type.split
      if condition.match == "none"
        !conditions.include?(@filter.resolve_type)
      else
        conditions.include?(@filter.resolve_type)
      end
    end
    
    def met_variable?(condition)
      conditions = condition.variable.split
      if condition.match == "none"
        conditions.each do |c|
          return false if @filter.extract_variable(c)
        end
        return true
      else
        conditions.each do |c|
          tmp = @filter.extract_variable(c)
          return false if !tmp
          case tmp.class
          when Array
            return !tmp.empty?
          when String
            return !tmp.strip.empty?
          else
            return false
          end
          #return true if (tmp != nil and (tmp.is_a?(Array) ? !tmp.empty? : true))
        end
        return false
      end
    end
    
    
    def met_position?(condition)
      false # TODO
    end
    
    def met_disambiguate?(condition)
      false # TODO
    end
    
    def met_locator?(condition)
      false # TODO
    end

    
    def get_macro(macro)
      @style.macros.each do |m|
        return m if m.name == macro.macro
      end
      nil
    end
    
    def expand_macro(macro)
      results = []
      m = get_macro(macro)
      results = process_elements(m.elements) if m
      process(macro, [], results)
    end
    
    
    def process(element, results, children)
      ProcessedNode.new(element, results, children)
    end
    
  end
end
