module Wordmove
  class RemoteHost < LocalHost

    alias :locally_run :run

    def initialize(options = {})
      super
      pa "Connecting to #{options.ssh.host}...", :green, :bright
      @session = Net::SSH.start(options.ssh.host, options.ssh.username, :password => options.ssh.password)
    end

    def close
      @session.close
    end

    def upload_file(source_file, destination_file)
      pa "Copying remote #{source_file} to #{destination_file}...", :green, :bright
      Net::SCP.download!(options.ssh.host, options.ssh.username, source_file, destination_file, :password => options.ssh.password)
    end

    def download_file(source_file, destination_file)
      pa "Copying local #{source_file} to #{destination_file}...", :green, :bright
      Net::SCP.upload!(options.ssh.host, options.ssh.username, source_file, destination_file, :password => options.ssh.password)
    end

    def download_dir(source_dir, destination_dir)
      rsync "#{source_dir}/", "#{options.ssh.username}@#{options.ssh.host}:#{destination_dir}"
    end

    def upload_dir(source_dir, destination_dir)
      rsync "#{options.ssh.username}@#{options.ssh.host}:#{source_dir}/", destination_dir
    end

    def run(*args)
      command = shell_command(*args)
      pa "Executing remotely #{command}", :green, :bright
      @session.exec!(command)
    end

    private

    def rsync(source_dir, destination_dir)
      password_file = Tempfile.new('rsync_password')
      password_file.write(options.ssh.password)
      password_file.close

      exclude_file = Tempfile.new('exclude')
      exclude_file.write(options.exclude.join("\n"))
      exclude_file.close

      locally_run "rsync", "-avz", "--password-file=#{password_file.path}", "--exclude-from=#{exclude_file.path}", "--delete", source_dir, destination_dir

      password_file.unlink
      exclude_file.unlink
    end

  end
end
