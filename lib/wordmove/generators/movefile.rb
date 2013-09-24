require 'thor/group'
require 'wordmove/generators/movefile_adapter'

module Wordmove
  module Generators
    class Movefile < Thor::Group
      include Thor::Actions
      include MovefileAdapter

      def self.source_root
        File.dirname(__FILE__)
      end

      def copy_movefile
        template "Movefile"
      end

    end
  end
end

