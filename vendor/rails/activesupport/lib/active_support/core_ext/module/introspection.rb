class Module
  # Returns the module which contains this one according to its name.
  #
  #   module M
  #     module N
  #     end
  #   end
  #   X = M::N
  #   
  #   p M::N.parent # => M
  #   p X.parent    # => M
  #
  # The parent of top-level and anonymous modules is Object.
  #
  #   p M.parent          # => Object
  #   p Module.new.parent # => Object
  #
  def parent
    parent_name = name.split('::')[0..-2] * '::'
    parent_name.empty? ? Object : parent_name.constantize
  end

  # Returns all the parents of this module according to its name, ordered from
  # nested outwards. The receiver is not contained within the result.
  #
  #   module M
  #     module N
  #     end
  #   end
  #   X = M::N
  #   
  #   p M.parents    # => [Object]
  #   p M::N.parents # => [M, Object]
  #   p X.parents    # => [M, Object]
  #
  def parents
    parents = []
    parts = name.split('::')[0..-2]
    until parts.empty?
      parents << (parts * '::').constantize
      parts.pop
    end
    parents << Object unless parents.include? Object
    parents
  end

  if RUBY_VERSION < '1.9'
    # Returns the constants that have been defined locally by this object and
    # not in an ancestor. This method is exact if running under Ruby 1.9. In
    # previous versions it may miss some constants if their definition in some
    # ancestor is identical to their definition in the receiver.
    def local_constants
      inherited = {}

      ancestors.each do |anc|
        next if anc == self
        anc.constants.each { |const| inherited[const] = anc.const_get(const) }
      end

      constants.select do |const|
        !inherited.key?(const) || inherited[const].object_id != const_get(const).object_id
      end
    end
  else
    def local_constants #:nodoc:
      constants(false)
    end
  end

  # Returns the names of the constants defined locally rather than the
  # constants themselves. See <tt>local_constants</tt>.
  def local_constant_names
    local_constants.map(&:to_s)
  end
end
