module Wordmove
  module Generators
    class Movefile
      include MovefileAdapter

      def self.generate
        new.copy_movefile
      end

      def copy_movefile
        content = ERB.new(File.read(File.join(__dir__, 'movefile.yml'))).result(binding)
        files = Dry::Files.new

        files.write('movefile.yml', content)
      end
    end
  end
end
