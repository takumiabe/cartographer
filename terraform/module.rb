module Terraform
  class Module
    def initialize(cart, json)
      @cart = cart
      json['resources'].each_pair do |name, res|
        @cart.register_resource Resource.new(@cart, name, res)
      end
    end
  end
end
