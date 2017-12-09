module Wordmove
  class Doctor
    def self.start
      banner
      movefile
      mysql
      wpcli
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

    def self.rsync; end

    def self.ssh; end

    def self.lftp; end

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
