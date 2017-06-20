module Terraform
  class Resource
    attr_accessor :id, :name, :type
    attr_accessor :graphviz_subgraph, :graphviz_node

    def initialize(cart, name, json)
      @cart = cart
      self.name = name

      self.type = json["type"].to_sym
      self.id = if identity = DB.dig(type.to_s, 'identity')
                  json["primary"]["attributes"][identity]
                else
                  json["primary"]["id"]
                end
      @attributes = Attributes.new(json["primary"]["attributes"])
      @depends = json["depends_on"].uniq
      # @meta = json["primary"]["meta"]
    end

    def icon
      path = DB.dig(type.to_s, 'icon')
      return unless path
      File.expand_path("../#{path}", __FILE__)
    end

    def shortname
      name.gsub(/data\./, '').gsub(/#{type}\./, '')
    end

    def create_subgraph(graphviz)
      return if DB.dig(type.to_s, 'subgraph_like') != true

      graphviz = parent.graphviz_subgraph if parent
      label = @attributes[DB.dig(type.to_s, 'subgraph', 'label')] || shortname
      self.graphviz_subgraph = graphviz.subgraph("cluster#{@cart.cluster_counter}", label: label, style: :solid)
      @cart.cluster_counter += 1
    end

    def inspect
      "#<Resource:#{type} #{id}>"
    end

    def parent
      rs = neighbors.values.select{|r| r.graphviz_subgraph }
      return rs.first if rs.size == 1
      nil
    end

    def aws_security_group_label
      table = []
      table << '<TABLE CELLSPACING="0">'
      table << %[<TR><TD COLSPAN="4">#{id}</TD></TR>]
      ['ingress', 'egress'].each do |inout|
        @attributes.dig(inout).each do |i|
          inout = (inout == 'ingress' ? 'in' : 'out')
          protocol = i['protocol']
          protocol = '*' if protocol == '-1'
          port =
            if i['from_port'] == '0' && i['to_port'] == '65535'
              '*'
            elsif i['from_port'] == i['to_port']
              i['from_port']
            else
              "#{i['from_port']}-#{i['to_port']}"
            end
          port = '*' if port == '0'
          port = '*' if port == '-1'
          i["cidr_blocks"].sort.each do |ip|
            # ip = '*' if ip == "0.0.0.0/0"
            table << "<TR>"
            table << [inout, protocol, ip, port].map{|x| "<TD ALIGN=\"LEFT\">#{x}</TD>"}.join
            table << "</TR>"
          end
          i['security_groups'].sort.each do |sg|
            table << "<TR>"
            table << [inout, protocol, sg, port].map{|x| "<TD ALIGN=\"LEFT\">#{x}</TD>"}.join
            table << "</TR>"
          end
        end
      end
      table << '</TABLE>'
      "<#{table.join}>"
    end

    def create_node(graphviz)
      return if DB.dig(type.to_s, 'ignore') == true
      return if DB.dig(type.to_s, 'edge_like') == true

      node_opt =
        if icon
          {
            shape: :none,
            label: '',
            xlabel: DB.dig(type.to_s, 'label') || shortname,
            image: icon,
            # xlabel: id,
          }
        else
          label =
            if (renderer = DB.dig(type.to_s, 'label_renderer')) && respond_to?(renderer)
              send(renderer)
            else
              DB.dig(type.to_s, 'typename') || type.to_s
            end
          {
            shape: DB.dig(type.to_s, 'shape') || :box,
            label: label,
            xlabel: DB.dig(type.to_s, 'label') || shortname,
          }
        end

      graphviz = parent.graphviz_subgraph if parent

      self.graphviz_node = graphviz.add_node(id, node_opt)
    end

    def create_edges(graphviz)
      return if DB.dig(type.to_s, 'ignore') == true

      if DB.dig(type.to_s, 'edge_like') == true
        db = DB.dig(type.to_s, 'edge')

        unless db
          ap @attributes
          raise InvalidArgument.new
        end

        from = @cart.resources[@attributes[db["from"]]].graphviz_node
        to = @cart.resources[@attributes[db["to"]]].graphviz_node
        label = @attributes[db["label"]]

        graphviz.add_edge(from, to, label: label) if from && to
        return
      end

      return unless graphviz_node # ignored

      from = graphviz_node

      drew = []
      neighbors.each do |key, resource|
        label =
          if DB.dig(type.to_s, 'edge', 'label_is_key')
            key.split('.').first
          else
            ''
          end
        to = resource.graphviz_node
        next unless to
        next if from == to
        next if resource == parent

        drew << resource

        inv = DB.dig(type.to_s, 'inverse')
        if inv && inv.include?(key.to_s)
          graphviz.add_edge(to, from, label: label)
        else
          graphviz.add_edge(from, to, label: label)
        end
      end

      if DB.dig(type.to_s, 'draw_depends') == true
        @depends.each do |name|
          name = name.gsub(".*", '')
          r, *_ = @cart.resources.values.select{|r| !drew.include?(r) && r.name.start_with?(name)}
          if r && r.graphviz_node
            graphviz.add_edge(from, r.graphviz_node)
          end
        end
      end
    end

    def neighbors
      return @neighbors if @neighbors
      ret = {}
      @attributes.each_pair do |key, val|
        r = @cart.resources[val]
        ret[key] = r if r
      end
      @neighbors = ret
    end
  end
end
