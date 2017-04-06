
DB = YAML.load_file(File.expand_path('../aws.yml', __FILE__))

module Terraform
  class Cartograph
    attr_accessor :cluster_counter
    attr_accessor :resources

    def initialize(json)
      self.cluster_counter = 0
      self.resources = {}

      @modules = json["modules"].map do |mod|
        Terraform::Module.new(self, mod)
      end
    end

    def register_resource(res)
      if resources.key? res.id
        # raise "id: #{res.id} has duplicated."
        res.id = "#{res.type}/#{res.id}"
      end
      resources[res.id] = res
    end

    def graphviz
      g = ::GraphViz.new(:terraform, type: :digraph, rankdir: "LR")

      top_cluster = g.subgraph("cluster#{cluster_counter}", label: 'staging', style: :dotted)
      self.cluster_counter += 1

      resources.each do |(id, res)|
        res.create_subgraph(top_cluster)
      end

      resources.each do |(id, res)|
        res.create_node(top_cluster)
      end

      resources.each do |(id, res)|
        res.create_edges(top_cluster)
      end

      # use: dot / neato / twopi / circo / fdp
      g.output(use: :dot, png: "./Cartograph.png" )
    end
  end
end
