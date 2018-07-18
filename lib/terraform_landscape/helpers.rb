# Provides Helpers for Project
module TerraformLandscape::Helpers
  class << self
    def recursive_sort(obj)
      case obj

      when Array
        recursive_sort_array_object(obj)

      when Hash
        recursive_sort_hash_object(obj)

      else
        obj

      end
    end

    private

    def recursive_sort_hash_object(obj)
      Hash[
        obj.map do |key, value|
          [if key.respond_to? :sort
             recursive_sort(key)
           else
             key
           end,
           if value.respond_to? :sort
             recursive_sort(value)
           else
             value
           end]
        end.sort].extend HashDeepSortCompare
    end

    def recursive_sort_array_object(obj)
      obj.map do |val|
        if val.respond_to? :sort
          recursive_sort(val)
        else
          val
        end
      end.sort
    end
  end

  # Mixin Module for #recursive_sort
  module HashDeepSortCompare
    def <=>(other)
      super(other) || to_a <=> other.to_a || to_s <=> other.to_s
    end
  end
end
