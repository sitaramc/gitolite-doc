# Making repositories available to both ssh and http mode clients

Copyright Thomas Hager (duke at sigsegv dot at).  Licensed under CC-BY-NC-SA
unported 3.0, <https://creativecommons.org/licenses/by-nc-sa/3.0/>

Assumptions:

  * Apache 2.x with CGI and Suexec support installed.
  * Git and Gitolite installed with user "git" and group "git", and pubkey SSH
    access configured and working.
  * Git plumbing installed to /usr/libexec/git-core
  * Gitolite base located at /opt/git
  * Apache `DOCUMENT_ROOT` set to /var/www
  * Apache runs with user www and group www

Please adjust the instructions below to reflect your setup (users and paths).

Edit your .gitolite.rc and add

    $ENV{PATH} .= ":/opt/git/bin";

at the very top (as described in `t/smart-http.root-setup`).

Next, check which document root your Apache's suexec accepts:

    # suexec -V
     -D AP_DOC_ROOT="/var/www"
     -D AP_GID_MIN=100
     -D AP_HTTPD_USER="www"
     -D AP_LOG_EXEC="/var/log/apache/suexec.log"
     -D AP_SAFE_PATH="/usr/local/bin:/usr/bin:/bin"
     -D AP_UID_MIN=100
     -D AP_USERDIR_SUFFIX="public_html"

We're interested in `AP_DOC_ROOT`, which is set to `/var/www` in our case.

Create a `bin` and a `git` directory in `AP_DOC_ROOT`:

    install -d -m 0755 -o git -g git /var/www/bin
    install -d -m 0755 -o www -g www /var/www/git

`/var/www/git` is just a dummy directory used as Apache's document root (see below).

Next, create a shell script inside `/var/www/bin` named `gitolite-suexec-wrapper.sh`,
with mode **0700** and owned by user and group **git**. Add the following content:

    #!/bin/bash
    #
    # Suexec wrapper for gitolite-shell
    #

    export GIT_PROJECT_ROOT="/opt/git/repositories"
    export GITOLITE_HTTP_HOME="/opt/git"
    # WARNING: do not add a trailing slash to the value of GITOLITE_HTTP_HOME

    exec ${GITOLITE_HTTP_HOME}/gitolite-source/src/gitolite-shell

Edit your Apache's config to add http pull/push support, preferably in
a dedicated `VirtualHost` section:

    <VirtualHost *:80>
        ServerName        git.example.com
        ServerAlias       git
        ServerAdmin       you@example.com

        DocumentRoot /var/www/git
        <Directory /var/www/git>
            Options       None
            AllowOverride none
            Order         allow,deny
            Allow         from all
        </Directory>

        SuexecUserGroup git git
        ScriptAlias /git/ /var/www/bin/gitolite-suexec-wrapper.sh/
        ScriptAlias /gitmob/ /var/www/bin/gitolite-suexec-wrapper.sh/

        <Location /git>
            AuthType Basic
            AuthName "Git Access"
            Require valid-user
            AuthUserFile /etc/apache/git.passwd
        </Location>
    </VirtualHost>

This Apache config is just an example, you probably should adapt the authentication
section and use https instead of http!

Finally, add an `R = daemon` access rule to all repositories you want to
make available via http.

