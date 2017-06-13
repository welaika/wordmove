# 2.1.3

- bugfix #402

# 2.1.0

## Features

- SqlAdapter::Wpcli

# 2.0.0

## Features
- Implemented compression of sql files before and after transfers
- Implemented compression of sql backup files inside wp-content
- Implemented support to mu-plugins directory
- Updated `dump.php` library to support database VIEWS
- Added `--debug` option: do not automatically delete FTP dumps file so you can inspect errors (if any)
- Better support for large dbs import
- Allow ruby code in `Movefile` (`erb`)
- Added ability to pass mysqldump options via `mysqldump_options` in `Movefile`


## Bugfixes
- Ignore php error for `date()` while dumping database via FTP
- Better escape for Windows paths
- Show a warning if no `Movefile` found
- Fix ruby warnings for `PATH` module
- Fix FTP dump bug introduced in `1.3.1`

## Thanks to

@amchoukir @ChuckMac @connormckelvey @delphaber @dsgnr @esad @inamoth @JimmY2K
@kenchan0130 @matjack1 @miya0001 @Mte90 @mukkoo @pioneerskiees @spanndemic
@StefanoOrdine @tiojoca @xrmx

# 1.3.1 (yanked)
- Fix typo in dump.php.erb

# 1.3.0
- Fix UTF-8 encoding issue when `wordmove init` with a wrong .sample file
- Fix problem with ftp password and special chars
- Fix duplicated wordpress tree in languages folder (ftp only)
- Update db import / export php libraries
- Add `--version` option
- Required ruby version ~> 2.0
- Updated test suite with rspec 3.x
