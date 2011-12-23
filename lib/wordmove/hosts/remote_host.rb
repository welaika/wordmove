require 'net/ssh'
require 'net/scp'

module Wordmove
  class RemoteHost < LocalHost

    alias :locally_run :run

    attr_reader :session

    def initialize(options = {})
      super
    end

    def session
      logger.verbose "Connecting to #{options.ssh.host}..." unless @session.present?
      @session ||= Net::SSH.start(options.ssh.host, options.ssh.username, @ssh_extras )
    end

    def close
      session.close
    end

    def upload_file(source_file, destination_file)
      logger.verbose "Copying remote #{source_file} to #{destination_file}..."
      Net::SSH.start options.ssh.host, options.ssh.username, @ssh_extras do |ssh|
        ssh.scp.download! source_file, destination_file
      end
    end

    def download_file(source_file, destination_file)
      logger.verbose "Copying local #{source_file} to #{destination_file}..."
      Net::SSH.start options.ssh.host, options.ssh.username, @ssh_extras do |ssh|
        ssh.scp.upload! source_file, destination_file
      end
    end

    def download_dir(source_dir, destination_dir)
      rsync "#{source_dir}/", "#{options.ssh.username}@#{options.ssh.host}:#{destination_dir}"
    end

    def upload_dir(source_dir, destination_dir)
      rsync "#{options.ssh.username}@#{options.ssh.host}:#{source_dir}/", destination_dir
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

      arguments = [ "-azLK" ]

      password_file = nil
      if options.ssh

        if options.ssh.port
          arguments << [ '-e', "ssh -p #{options.ssh.port}" ]
        end

        if options.ssh.password
          password_file = Tempfile.new('rsync_password')
          password_file.write(options.ssh.password)
          password_file.close
          arguments << "--password-file=#{password_file.path}"
        end
      end

      arguments <<  [ "--exclude-from=#{exclude_file.path}", "--delete", source_dir, destination_dir ]
      arguments.flatten!
      locally_run "rsync", *arguments

      password_file.unlink if password_file
      exclude_file.unlink
    end

  end
end
