# 1.4.0
- Implemented compression of sql files before and after transfers
- Implemented compression of sql backup files inside wp-content
- Implemented support to mu-plugins directory. Thanks connormckelvey
- Update `dump.php` library to support database VIEWS


# 1.3.1
- Fix typo in dump.php.erb

# 1.3.0
- Fix UTF-8 encoding issue when `wordmove init` with a wrong .sample file
- Fix problem with ftp password and special chars
- Fix duplicated wordpress tree in languages folder (ftp only)
- Update db import / export php libraries
- Add `--version` option
- Required ruby version ~> 2.0
- Updated test suite with rspec 3.x
