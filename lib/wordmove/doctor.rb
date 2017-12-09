module Wordmove
  class Doctor
    def self.start
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
  end
end
