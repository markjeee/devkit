module Devkit
  module Helper
    def self.symbolize_keys(v)
      case v
      when Hash
        v.inject({ }) do |h, (k, v)|
          new_v = symbolize_keys(v)

          case k
          when String
            # NOTE: This is intentional, so we get the side-effect
            # of accessing keys as either string or symbol.
            #
            h[k.to_sym] = h[k.to_s] = new_v
          else
            h[k] = new_v
          end

          h
        end
      when Array
        v.collect { |va| symbolize_keys(va) }
      else
        v
      end
    end
  end
end
