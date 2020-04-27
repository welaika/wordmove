module Wordmove
  module Actions
    module Ssh
      module WpcliAdapter
        class PullDb
          extend ::LightService::Action
          extend ::LightService::Organizer
          include Wordmove::Actions::Helpers
          include WordpressDirectory::LocalHelperMethods
          expects :cli_options
          expects :local_options
          expects :remote_options
          expects :logger
          expects :photocopier
          expects :movefile

          executed do |context|
            context.logger.task 'Pulling Database'

            next context if simulate?(cli_options: context.cli_options)

            content_dir = local_wp_content_dir(local_options: context.local_options)
            backup_path = content_dir.path("local-backup-#{Time.now.to_i}.sql")
            gzipped_backup_path = backup_path + '.gz'
            local_dump_path = content_dir.path('dump.sql')
            local_gzipped_dump_path = local_dump_path + '.gz'

            with(
              backup_path: backup_path,
              gzipped_backup_path: gzipped_backup_path,
              local_dump_path: local_dump_path,
              local_gzipped_dump_path: local_gzipped_dump_path,
              local_options: context.local_options,
              remote_options: context.remote_options,
              cli_options: context.cli_options,
              logger: context.logger,
              movefile: context.movefile,
              photocopier: context.photocopier
            ).reduce(
              [
                BackupLocalDb,
                AdaptRemoteDb,
                CleanupAfterPull
              ]
            )
          end
        end
      end
    end
  end
end
