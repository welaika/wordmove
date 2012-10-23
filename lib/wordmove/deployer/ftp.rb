require 'wordmove/deployer/base'
require 'photocopier/ftp'

module Wordmove
  module Deployer
    class FTP < Base
      delegate :put_directory, to: :"@copier"
      delegate :get_directory, to: :"@copier"

      def initialize(options)
        super
        @copier = Photocopier::FTP.new(options[:remote][:ftp])
      end

      def push_db

      end

      def pull_db

      end

    end
  end
end

