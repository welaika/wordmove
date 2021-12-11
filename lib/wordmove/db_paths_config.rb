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

  setting :ftp, reader: true do
    setting :remote_dump_script_path
    setting :remote_import_script_path
    setting :one_time_password
    setting :dump_script
    # TBD
  end
end
