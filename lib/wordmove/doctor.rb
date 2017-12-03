module Wordmove
  class Doctor
    def self.start
      movefile
    end

    def self.movefile
      movefile_doctor = Wordmove::Doctor::Movefile.new
      movefile_doctor.validate!
    end
  end
end
