module ActiveSP
  
  module Caching
    
    def cache(name, options = {})
      duplicate = options.delete(:dup)
      options.empty? or raise ArgumentError, "unsupported options #{options.keys.map { |k| k.inspect }.join(", ")}"
      (@cached_methods ||= []) << name
      alias_method("#{name}__uncached", name)
      module_eval <<-RUBY
        def #{name}(*a, &b)
          if defined? @#{name}
            @#{name}
          else
            @#{name} = #{name}__uncached(*a, &b)
          end#{".dup" if duplicate}
        end
        def reload
          #{@cached_methods.map { |m| "remove_instance_variable(:@#{m}) if defined?(@#{m})" }.join(';')}
          super if defined? super
        end
      RUBY
    end
    
  end
  
end
