module Terraform
  class Attributes
    def initialize(json)
      @raw = json
      @attrs = parse_attrributes_sub(parse_attrributes(json))
    end

    def [](path)
      @raw[path]
    end

    def dig(args)
      @attrs.dig(args)
    end

    def each_pair(&block)
      @raw.each_pair(&block)
    end

    private

    def parse_attrributes_sub(raw)
      return raw.map{|r| parse_attrributes_sub(r)} if raw.is_a? Array
      return raw unless raw.is_a? Hash

      if raw.key?('#')
        # to array
        raw.delete('#')
        raw.map{|index, v| [index, parse_attrributes_sub(v)]}.sort_by(&:first).map(&:last)
      else
        # to hash
        raw.delete('%')
        raw.map{|k,v| [k, parse_attrributes_sub(v)]}.to_h
      end
    end

    def parse_attrributes(json)
      ret = {}

      json.each_pair do |key, val|
        *path, last = key.split('.')
        cur = ret
        path.each do |seg|
          cur[seg] ||= {}
          cur = cur[seg]
        end
        cur[last] = val
      end
      ret
    end
  end
end
