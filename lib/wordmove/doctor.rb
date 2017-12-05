module Wordmove
  class Doctor
    def self.start
      movefile
      mysql
    end

    def self.movefile
      movefile_doctor = Wordmove::Doctor::Movefile.new
      movefile_doctor.validate!
    end

    def self.mysql
      mysql_doctor = Wordmove::Doctor::Mysql.new
      mysql_doctor.check!
    end
  end
end
