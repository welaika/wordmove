require 'net/ssh'
require 'net/scp'
require 'net/ssh/gateway'

module Wordmove
  class RemoteHost < LocalHost

    alias :locally_run :run

    attr_reader :session

    def initialize(options = {})
      super
    end

    def session
      if options.ssh.nil?
        raise Thor::Error, "No SSH credentials provided on Movefile!"
      end

      ssh_extras = {}
      [ :port, :password ].each do |p|
        ssh_extras.merge!( { p => options.ssh[p] } ) if options.ssh[p]
      end

      if options.ssh.gateway.nil?
        logger.verbose "Connecting to #{options.ssh.host}..." unless @session.present?
        @session ||= Net::SSH.start(options.ssh.host, options.ssh.username, ssh_extras)
      else
        logger.verbose "Connecting to #{options.ssh.host} through the gateway..." unless @session.present?
        @session ||= gateway.ssh(options.ssh.host, options.ssh.username, ssh_extras)
      end

      @session
    end

    def gateway
      if options.ssh.gateway.nil?
        raise Thor::Error, "No SSH credentials provided on Movefile!"
      end

      ssh_extras = {}
      [ :port, :password ].each do |p|
        ssh_extras.merge!( { p => options.ssh.gateway[p] } ) if options.ssh.gateway[p]
      end

      logger.verbose "Connecting to #{options.ssh.gateway.host}..." unless @gateway.present?
      @gateway ||= Net::SSH::Gateway.new(options.ssh.gateway.host, options.ssh.gateway.username, ssh_extras )

      @gateway
    end

    def close
      session.close
      if options.ssh.gateway.present?
        gateway.close(session.transport.port)
      end
    end

    def upload_file(source_file, destination_file)
      logger.verbose "Copying remote #{source_file} to #{destination_file}..."
      session.scp.download! source_file, destination_file
    end

    def download_file(source_file, destination_file)
      logger.verbose "Copying local #{source_file} to #{destination_file}..."
      session.scp.upload! source_file, destination_file
    end

    def download_dir(source_dir, destination_dir)
      destination_dir = ":#{destination_dir}"
      destination_dir = "#{options.ssh.username}@#{destination_dir}" if options.ssh.username
      rsync "#{source_dir}/", destination_dir
    end

    def upload_dir(source_dir, destination_dir)
      source_dir = ":#{source_dir}/"
      rsync source_dir, destination_dir
    end

    def run(*args)
      command = shell_command(*args)
      logger.verbose "Executing remotely #{command}"
      session.exec!(command)
    end

    private

    def rsync(source_dir, destination_dir)

      exclude_file = Tempfile.new('exclude')
      exclude_file.write(options.exclude.join("\n"))
      exclude_file.close

      arguments = [ "-azLKO" ]

      if options.ssh && (options.ssh.port || options.ssh.password || options.ssh.gateway)

        remote_shell_arguments = []

        if options.ssh.gateway
          host = options.ssh.gateway.host
          host = "#{options.ssh.gateway.username}@#{host}" if options.ssh.gateway.username
          remote_shell_arguments << [ "ssh", host ]
          if options.ssh.gateway.port
            remote_shell_arguments << [ "-p", options.ssh.gateway.port ]
          end
        end

        remote_shell_arguments << [ "ssh" ]

        if options.ssh.port
          remote_shell_arguments << [ "-p", options.ssh.port ]
        end

        if options.ssh.password
          remote_shell_arguments = [ "sshpass", "-p", options.ssh.password ] + remote_shell_arguments
        end

        host = options.ssh.host
        host = "#{options.ssh.username}@#{host}" if options.ssh.username
        remote_shell_arguments << host

        arguments << [ "-e", remote_shell_arguments.join(" ") ]
      end

      arguments <<  [ "--exclude-from=#{exclude_file.path}", "--delete", source_dir, destination_dir ]
      arguments.flatten!
      locally_run "rsync", *arguments

      exclude_file.unlink
    end

  end
end
