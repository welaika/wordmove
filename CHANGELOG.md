# 1.4.0
- Implemented compression of sql files before and after transfers
- Implemented compression of sql backup files inside wp-content
- Implemented support to mu-plugins directory. Thanks connormckelvey

# 1.3.1
- fix typo in dump.php.erb

# 1.3.0
- fix UTF-8 encoding issue when `wordmove init` with a wrong .sample file
- fix problem with ftp password and special chars
- fix duplicated wordpress tree in languages folder (ftp only)
- update db import / export php libraries
- add `--version` option
- required ruby version ~> 2.0
- updated test suite with rspec 3.x
