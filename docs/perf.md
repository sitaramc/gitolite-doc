# gitolite performance

----

TOP TIP: If you have more than 2000 or so repos, then you should be using v3.2
or later; there was a bit of code that went in there that makes a *huge*
difference for really large sites.

----

## factors affecting gitolite performance

A lot of the following discussion involves understanding these factors:

*   the number of **lines** in gitolite.conf (plus all its "include" files, if
    any).

*   the number of **normal repos** in the conf.  A normal repo is one that is
    *directly named* in a `repo ...` line.

    ```gitolite
    repo foo bar
        # ...rules...
    ```

    The rules for a normal repo is compiled into a file called `gl-conf` in
    the repo directory (i.e., one `gl-conf` file per normal repo).

*   the number of **group repos** -- repos that are part of repo *groups*:

    ```gitolite
    @foss = git gitolite linux
    repo @foss
        # ...rules...
    ```

    The rules for group repos are compiled into a "common" compiled rules file
    which resides in `~/.gitolite/conf`.

*   the number of **wild repos** -- repos that match a *wild repo* pattern and
    were created by a user.

    ```gitolite
    repo dev/CREATOR/..*
        C   =   @team
        # ...rules...
    # actual repos created by users using git clone/push commands
    ```

    The compiled rules for wild repos also go into the "common" compiled rules
    file.  However, these rules often consist of just ["role names"][role],
    not actual user names.  The user who owns the repo will map other users to
    various roles by running the [perms][] command.

    This mapping is saved in a file called `gl-perms` in the repo directory.

[role]: wild.md#roles
[perms]: user.md#setget-additional-permissions-for-repos-you-created

## types of performance issues

Gitolite performance can be discussed in four different scenarios:

### normal git activity

A user accesses a git repo using git clone, fetch, push, etc.

Gitolite is heavily optimised for the day to day "developer" activity by
users.  You should *never* have any issues with this, regardless of what mix
of factors (affecting performance; see above) you have.

### admin push

An admin does a "push" to the "gitolite-admin" repo (or does the
equivalent when [administering gitolite directly on the server][agds]).

What happens then can be divided into two distinct parts.

#### `gitolite compile`

The first part is `gitolite compile`.  This is influenced by the conf file
size as well as the number of normal repos.  For each normal repo, gitolite
has to write the `gl-conf` file in that repo's directory.

That's a whole bunch of small-file writes.

Over the past few weeks (as of Oct 2017), mainly driven by Fedora's mammoth
560,000+ line conf file containing 42,000 or so repos, there have been a
couple of attempts to mitigate this.

1.  Extend the wild repos concept:

    See the [templates][] document for details on this.  The section that is
    directly relevant to the topic of performance is the one dealing with
    "bypassing gitolite.conf for huge sites", but really, you should read the
    whole document in order to understand what is happening there.

    !!! note "Note"
        Although the templates feature was inspired by performance issues, I
        now realise it's a much nicer way to organise repos and rules, and --
        on my comparatively puny production setup -- I have reorganised all
        the rules to use templates instead.  The result is much easier to
        maintain, because I can farm out the maintenance to folks who are less
        gitolite-savvy.  See the "advantages" section in that page for more.

2.  Compile repo rules separately:

    A much less interesting, probably even somewhat kludgey, outcome of the
    Fedora exercise was the `compile-1` command.

    It's in `contrib` because I do not encourage its use unless you really
    really (**really!**) need it.  Instructions and caveats are in the source
    file itself.

[templates]: templates.md

#### `gitolite trigger POST_COMPILE`

The second part runs all the `POST_COMPILE` triggers scripts.  On a default
installation, this includes maintaining `~/.ssh/authorised_keys`, updating
[gitweb and daemon][gwd] permissions, and updating ["config"][gc] values.

[gc]: git-config.md
[gwd]: gitweb-daemon.md

This is influenced by the total number of repos in the system (normal *and*
other repos), *and* what options are enabled in your `~/.gitolite.rc` file.

Many of these these require scanning all the repositories and doing something
to each of them (see "scan ALL repos" section later).  For example, the
trigger script that updates the "projects.list" file for gitweb needs to check
every repo to see if the user `gitweb` is allowed `R`ead access to it.

### new wild repo

A user creates a brand new "wild" repo.

If you use only the default set of options enabled in the rc file, this
should be pretty fast, though some of the non-default options may still be
slow.

!!! note ""
    However, the commit that *finally* fixed this issue for the default
    options is pretty recent as of the time of writing.  In tag terms, you
    should see it in 3.6.8.  If you're really affected by this, bug me on the
    mailing list to make a release, and then bug your package maintainers :-)
    Or just upgrade from github!

How can you tell which program is slowing you down?  Look in the log file
after a user runs a wild repo create -- any subtask of that 'create' that
takes more than a second is a problem.  Send details to the mailing list so we
can discuss and fix whatever can be fixed.

### scan ALL repos

There are a few activities that scan **all** repos, looking for a given
user's permission on **each** of them:

-   a user runs the `info` command
-   a user accesses gitweb on a site where [repo specific authorisation][rsag] is in place
-   the `POST_COMPILE` triggers in an "admin push" are invoked (as briefly
    explained above).

In general, this is the slowest part of gitolite.  It's work load is
influenced by two things: the number of normal repos, and the number of wild
repos, because (as we saw up above) those are the two types of repos for which
certain individual files in the repo directory need to be read.

So, on a system with *lots of* of normal and/or wild repos, this operation
needs to read *lots of* small files (one in each repo directory)... which
takes time.  And depends on how fast your disk is, too.

The appendix has a solution for this, using a perl module called Memoize
(comes standard with perl); check down there for details.

[agds]: odds-and-ends.md#administering-gitolite-directly-on-the-server
[rsag]: gitweb-daemon.md#repo-specific-authorisation-in-gitweb
[lff]: dev-notes.md#appendix-2-log-file-format

## appendix 1: using `memoize`

It seems that perl's Memoize module does a great job at helping with the "scan
ALL repos" use case, at least after the first time a user accesses gitweb or
runs the 'info' command.

### gitweb

To start with, here's tested code to add into gitweb.conf:

```perl
# ----------------------------------------------------------------------
# caching section

use Fcntl;
use DB_File;
use Memoize;

# the actual file on disk
my $dbf = "$rc{GL_ADMIN_BASE}/$ENV{GL_USER}-canread.db";
# set up persistence
tie(%disk_cache, 'DB_File', $dbf, O_RDWR|O_CREAT, 0666)
    or die "Tie '$dbf' failed: $!";
memoize 'can_read', SCALAR_CACHE => [ HASH => \%disk_cache ];

# ----------------------------------------------------------------------
```

You can add this at the end of the code linked from the [repo specific
authorisation][rsag] section.

The maintenance of these cache files is tricky.  I suggest:

-   delete all of them when a gitolite-admin push happens (easy enough to add
    a new `POST_COMPILE` trigger for it -- a simple 1-line shell script will
    do)

-   run a cron job at midnight that also does the same thing

-   create a gitolite command (maybe "flush-canread-cache"?) to allow a user
    to flush his/her own cache file.  The basic code is pretty simple (you can
    embellish it with proper error messages etc., if you like):

    ```sh
    #!/bin/sh

    [ -n "$GL_USER" ] && rm -vf $GL_ADMIN_BASE/$GL_USER-canread.db
    ```

The biggest complication is "wild" repos and users running the "perms"
command.  That gets a little messy (you'd have to add code to the perms
command to delete just this repo, from *all* user's cache files!), so I
suggest ignoring this.  The worst that can happen is that, *until the next
morning* (when your cron job fires) (a) he retains access to a repo that he
has been removed from, and (b) he does *not* get access to a repo to which he
has been just added.

The first issue is unlikely to generate any complaints from the users, though
you may have to run it by your security team (but remember these are
**user-assigned** privileges, so just pretend the user did not get around to
removing the permission till the next morning!)

The second is easily solved by asking them to run that command we created.

That's it.

### the `info` command

TODO: see if the info command can also benefit from something similar!
