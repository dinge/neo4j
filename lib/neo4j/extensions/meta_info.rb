module Neo4j
  module MetaInfo

    def self.included(base)
      base.class_eval do
        property  :created_at, :type => DateTime
        property  :updated_at, :type => DateTime
        property  :version
        property  :uuid

        index     :created_at, :type => DateTime
        index     :updated_at, :type => DateTime
        index     :version
        index     :uuid

        ::Neo4j.event_handler.add( EventHandlerHooks.new(base) )
      end
    end


    class EventHandlerHooks
      MetaMethods = %w(created_at updated_at version uuid)

      def initialize(node_klass)
        @node_klass = node_klass
      end

      def on_node_created(node)
        if node.is_a?(@node_klass)
          node[:created_at] = self.class.current_time
          node[:updated_at] = self.class.current_time
          node[:version]    = 1
          node[:uuid]       = java.util.UUID.randomUUID.to_s
        end
      end

      def on_property_changed(node, key, old_value, new_value)
        if node.is_a?(@node_klass) && ! MetaMethods.include?(key) # don't update when a meta attribute itself changed
          node[:updated_at] = self.class.current_time
          node[:version]    = node[:version] += 1
        end
      end

      if DateTime.now.respond_to?(:utc)
        def self.current_time
          DateTime.now.utc
        end
      else
        def self.current_time
          DateTime.now
        end
      end

    end

  end
end