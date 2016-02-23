Vagrant Based Test Environment
==============================

This is a set of scripts to create a quick testing
environment for wordmove based on **Vagrant** virtual machines.

Running ``vagrant up`` will create two virtual machines:

   * ``workplace`` (192.168.50.91): Where a wordpress website is available on http://192.168.50.91/wordpress
     and **WordMove** is installed. The server IP is ``192.168.50.91``.
   * ``prodplace`` (192.168.50.92): This is an example production machine which is used as target for
     wordmove. Here lies an unconfigured wordpress ( accessible on http://192.168.50.92/wordpress ) 
     and is used as target when ``wordmove push --all`` is run.

Wordpress on ``workplace`` is accessible with ``admin`` user and ``admin`` password on
http://192.168.50.91/wordpress/wp-login.php url.

Each server is accessible using ``vagrant ssh workplace`` and ``vagrant ssh prodplace``.

Content:

    * ``Vagrantfile``: Describes the virtual machines configuration.
    * ``Movefile``: This is the wordmove configuration file which is copied on ``workplace`` machine.
    * ``run_wordmove.sh``: This runs a wordmove from ``workplace`` to ``prodplace``.

Testing Wordmove
----------------

To test wordmove you can connect to http://192.168.50.91/wordpress, login with previously
stated credentials and perform any change.

When you are satisfied just run ``run_wordmove.sh`` and check that all your changes
have properly been replicated to http://192.168.50.92/wordpress
