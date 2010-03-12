require 'neo4j/extensions/reindexer'
require "yaml"
require "ruby-debug"

module Neo4j
  module Exportable


    def self.included(base)
      base.extend  SingletonMethods
      base.class_eval do
        include InstanceMethods
      end
    end


    module SingletonMethods

      def export_to_yaml
        all.nodes.inject({}) do |hash, node|
          hash[( '%s_%s' % [to_s, node.neo_id])] = node.export_to_hash
          hash
        end.to_yaml
      end

    # classname.split("::").inject(Kernel) do |container, name|
    #   container.const_get(name.to_s)
    # end

      def import_from_yaml(yaml)
        YAML.load(yaml).each do |ident, properties|
          node = properties['_classname'] ? const_get(properties['_classname']).new : Neo4j::Node.new
          properties.keys.each do |property_name|
            case
            when property_name == '__outgoing_rels'

            when node.class.property?(property_name)
              node.send('%s=' % property_name, properties[property_name])
            else
              node[property_name] = properties[property_name]
            end
          end
        end
      end

      def export_node_to_hash(node)
        attributes = {}
        node.props.keys.each do |property_name|
          attributes[property_name] = node.respond_to?(property_name) ? node.send(property_name) : node[property_name]
        end
        attributes['_neo_id'] = node.neo_id
        attributes
      end


    end

    module InstanceMethods


      def export_to_yaml
        export_to_hash.to_yaml
      end

      def import_from_yaml

      end

      def export_to_hash
        hash = self.class.export_node_to_hash(self)
        hash['__outgoing_rels'] = self.rels.outgoing.map do |rel|
          self.class.export_node_to_hash(rel)
        end
        hash
      end

    end

  end
end