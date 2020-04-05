module Wordmove
  module Deployer
    class Base
      protected

      # It was used by FTP deployer. Keeping here as memorandum
      def download(url, local_path)
        logger.task_step true, "download #{url} > #{local_path}"

        return true if simulate?

        File.open(local_path, 'w') do |file|
          file << URI.open(url).read
        end
      end
    end
  end
end
