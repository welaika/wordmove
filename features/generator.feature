Feature: Generating Movefile
  In order to configure Wordmove
  As a WP developer
  I want Wordmove to generate me a Wordmove skeleton file

  Scenario: Wordmove creation
    When I run "wordmove init"
    Then the following files should exist:
      | Movefile |
    Then the file "Movefile" should contain:
      """
      local:
        vhost: "http://vhost.local"
        wordpress_path: "~/dev/sites/your_site"
        database:
          user: "user"
          password: "password"
          host: "host"
      remote:
        vhost: "http://remote.com"
        wordpress_path: "/var/www/your_site"
        database:
          user: "user"
          password: "password"
          host: "host"
        ssh:
          user: "user"
          password: "password"
          host: "host"
      """
