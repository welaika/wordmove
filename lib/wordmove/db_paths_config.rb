class DbPathsConfig
  extend Dry::Configurable

  setting :local, reader: true do
    setting :path
    setting :gzipped_path
    setting :adapted_path
    setting :gzipped_adapted_path
  end

  setting :remote, reader: true do
    setting :path
    setting :gzipped_path
  end

  setting :backup, reader: true do
    setting :local do
      setting :path
      setting :gzipped_path
    end

    setting :remote do
      setting :path
      setting :gzipped_path
    end
  end
end
