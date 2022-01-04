module Wordmove
  module Generators
    class Movefile
      def self.generate
        copy_movefile
      end

      def self.copy_movefile
        wordpress_path = File.expand_path(Dir.pwd)
        content = ERB.new(File.read(File.join(__dir__, 'movefile.yml'))).result(binding)

        files = Dry::Files.new
        files.write('movefile.yml', content)
      end
    end
  end
end
