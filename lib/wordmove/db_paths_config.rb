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

  # FTP settings are intentionally taken apart
  setting :ftp, reader: true do
    setting :remote, reader: true do
      setting :dump_script_path
      setting :dump_script_url
      setting :dumped_path
      setting :import_script_path
      setting :import_script_url
    end
    setting :local, reader: true do
      setting :generated_dump_script_path
      setting :generated_import_script_path
      setting :temp_path
    end
    setting :token
  end
end
