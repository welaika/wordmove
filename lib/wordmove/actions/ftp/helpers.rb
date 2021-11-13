module Wordmove
  module Actions
    module Ftp
      module Helpers
        extend ActiveSupport::Concern

        class_methods do # rubocop:disable Metrics/BlockLength
          #
          # (In)Utility method to retrieve ftp options from the superset of remote options
          #
          # @param [Hash] remote_options Remote host options fetched from movefile
          #               (with symbolized keys)
          #
          # @return [Hash] Ftp options from the movefile
          #
          def ftp_options(remote_options:)
            remote_options[:ftp]
          end

          #
          # Escape a string to be printed into PHP files
          #
          # @param [String] string The string to escape
          #
          # @return [String] The escaped string
          #
          def escape_php(string:)
            return '' unless string

            # replaces \ with \\
            # replaces ' with \'
            string.gsub('\\', '\\\\\\').gsub(/'/, '\\\\\'')
          end

          #
          # Generate a token
          #
          # @return [String] A random hexadecimal string
          #
          def remote_php_scripts_token
            SecureRandom.hex(40)
          end

          #
          # Generate THE PHP dump script, protected by a token to ensure only Wordmove will run it
          #
          # @param [Hash] remote_db_options The remote DB configurations fetched from movefile
          # @param [String] token The token that will be used to protect the execution of the script
          #
          # @return [String] The PHP file as string
          #
          def generate_dump_script(remote_db_options:, token:)
            template = ERB.new(
              File.read(File.join(File.dirname(__FILE__), '../../assets/dump.php.erb'))
            )
            template.result(binding)
          end

          #
          # Generate THE PHP import script, protected by a token to ensure only Wordmove will run it
          #
          # @param [Hash] remote_db_options The remote DB configurations fetched from movefile
          # @param [String] token The token that will be used to protect the execution of the script
          #
          # @return [String] The PHP file as string
          #
          def generate_import_script(remote_db_options:, token:)
            template = ERB.new(
              File.read(File.join(File.dirname(__FILE__), '../../assets/import.php.erb'))
            )
            template.result(binding)
          end

          #
          # Download a file from the internet making a simple GET request
          #
          # @param [String] url The URL of the resource to download
          # @param [String] local_path The local path where the resource will be saved
          #
          # @return [nil]
          #
          def download(url:, local_path:)
            File.open(local_path, 'w') do |file|
              file << URI.parse(url).read
            end
          end
        end
      end
    end
  end
end
