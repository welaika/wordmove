module Wordmove
  class Doctor
    def self.start
      banner
      movefile
      mysql
      wpcli
      rsync
      ssh
    end

    def self.movefile
      movefile_doctor = Wordmove::Doctor::Movefile.new
      movefile_doctor.validate!
    end

    def self.mysql
      mysql_doctor = Wordmove::Doctor::Mysql.new
      mysql_doctor.check!
    end

    def self.wpcli
      wpcli_doctor = Wordmove::Doctor::Wpcli.new
      wpcli_doctor.check!
    end

    def self.rsync
      rsync_doctor = Wordmove::Doctor::Rsync.new
      rsync_doctor.check!
    end

    def self.ssh
      ssh_doctor = Wordmove::Doctor::Ssh.new
      ssh_doctor.check!
    end

    # rubocop:disable Metrics/MethodLength
    def self.banner
      paint = <<-'ASCII'
        .------------------------.
        |       PSYCHIATRIC      |
        |         HELP  5¢       |
        |________________________|
        ||     .-"""--.         ||
        ||    /        \.-.     ||
        ||   |     ._,     \    ||
        ||   \_/`-'   '-.,_/    ||
        ||   (_   (' _)') \     ||
        ||   /|           |\    ||
        ||  | \     __   / |    ||
        ||   \_).,_____,/}/     ||
      __||____;_--'___'/ (      ||
     |\ ||   (__,\\    \_/------||
     ||\||______________________||
     ||||                        |
     ||||       THE DOCTOR       |
     \|||         IS [IN]   _____|
      \||                  (______)
       `|___________________//||\\
                           //=||=\\
                           `  ``  `
      ASCII

      puts paint
    end
    # rubocop:enable Metrics/MethodLength
  end
end
