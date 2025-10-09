# the "rc" file (`$HOME/.gitolite.rc`)

----

**IMPORTANT**: if you have a v3.0-v3.3 rc file it is documented [here](rc-33),
and it will still work.  Please see appendix A below for details.

----

The rc file is designed to be the only thing unique to your site for most
setups.

The rc file is well commented.  Please look at the `~/.gitolite.rc` file that
gets installed when you setup gitolite.  **You can always get a default copy
for your current version by running `gitolite print-default-rc`.**  (Please
see appendix A for upgrade instructions.)

# structure of the rc file

The rc file is perl code, but you do NOT need to know perl to edit it.  Just
mind the commas, use single quotes unless you know what you're doing, and make
sure the brackets and braces stay matched up!

As you can see there are 3 types of variables in it:

  * A lot of simple variables (like `UMASK`, `GIT_CONFIG_KEYS`, etc.).
  * A hash or two (like `ROLES`).
  * And one large list of features to be enabled (`ENABLE`).

This page documents only some of them; for most of them it's best to look in
the actual rc file or in each of their individual documentation files around;
start with ["non-core" gitolite](non-core).  If a setting is used by a command
then running that command with '-h' may give you additional information.

# specific variables

  * `$UMASK`, octal, default `0077`

    The default UMASK that gitolite uses gives `rwx------` permissions to all
    the repos and their contents.  People who want to run gitweb (or cgit,
    redmine, etc) realise that this will not do.

    The correct way to deal with this is to give this variable a value like
    `0027` (note the syntax: the leading 0 is required), and then make the
    user running the webserver (apache, www-data, whatever) a member of the
    'git' group.

    If you've already installed gitolite then existing files will have to be
    fixed up manually (for a umask or 0027, that would be `chmod -R g+rX`).
    This is because umask only affects permissions on newly created files, not
    existing ones.

  * `$GIT_CONFIG_KEYS`, string, default empty

    <span class="box-r">See the [security note][privesc] at the end of this
    page for why we do this.</span>

    This setting allows the repo admin to define acceptable gitconfig keys.

    Gitolite allows you to set git config values using the "config" keyword;
    see [here](git-config) for details and syntax.

    You have 3 choices.  By default `$GIT_CONFIG_KEYS` is left empty, which
    completely disables this feature (meaning you cannot set git configs via
    the repo config).

    The second choice is to give it a space separated list of settings you
    consider safe.  (These are actually treated as a set of [regular
    expressions](regex), and any one of them must match).

    For example:

        $GIT_CONFIG_KEYS = 'core\.logAllRefUpdates core\..*compression';

    Each regex should match the *whole* key (in other words, there
    is an implicit `^` at the start of each regex, and a `$` at the
    end).

    The third choice (which you may have guessed already if you're familiar
    with regular expressions) is to allow anything and everything:
    `$GIT_CONFIG_KEYS = '.*';`

  * `ROLES`, hash, default keys 'READERS' and 'WRITERS'

    This specifies the role names allowed to be used by users running the
    [perms][] command.  The [wild](wild) repos doc has more info on roles.

  * `OWNER_ROLENAME`, string, default undef

    (requires v3.5 or later)

    By default, permissions on a wild repo can only be set by the *creator* of
    the repo (using the [perms][] command).  But some sites want to allow
    other people to do this as well.

    To enable this behaviour, the server admin must first set this variable to
    some string, say 'OWNERS'.  (He must also add 'OWNERS' to the ROLES hash
    described in the previous bullet).

    The creator of the repo can then add other users to the OWNERS role using
    the [perms][] command.

    The [perms][] command, the new "owns" command, and possibly other commands
    in future, will then give these users the same privileges that they give
    to the creator of the repo.

    (Also see the full documentation on [roles][]).

  * `LOCAL_CODE`, string

    This is described in more detail [here][localcode].  Please be aware
    **this must be a FULL path**, not a relative path.

[privesc]: rc#security-note-gitolite-admin-and-shell-access
[perms]: user#setget-additional-permissions-for-repos-you-created
[roles]: wild#roles
[localcode]: non-core#for-your-non-core-programs

# security note: gitolite admin and shell access

People sometimes ask why this file is also not revision controlled.  Here's
why.

Gitolite maintains a clear distinction between

*   people who can push to the gitolite-admin repo, and
*   people who can get a shell or run arbitrary commands on the server.

This may not matter to many (small) sites, but in large installations, the
former is often a much larger set of people that you really don't want to give
shell access to.

Therefore, gitolite tries very hard to make sure that people in the first set
are not allowed to do anything that gets them into the second set.

!!! note ""

    If you *must* revision control it, you can.  Just add it to your admin
    repo, push the change, then replace `~/.gitolite.rc` with a symlink to
    `~/.gitolite/.gitolite.rc`.</span>

# appendix A: upgrading the rc file

First, note that upgrading the rc file is always *optional*.  However, it may
help if you want to use any of the new features available in later gitolite
releases, in the sense that the lines you need to add may already be present
(commented out) in the rc file, so you just need to uncomment them instead of
typing them in yourself.

If you have a v3.0-v3.3 rc file it is documented [here](rc-33), and it will
still work.  In fact internally the v3.4 rc file data gets converted to the
v3.3 format.  There's a simple program to help you upgrade a v3.3 (or prior)
rc file (in <span class="gray">v3.6.1+</span>, see contrib/utils/rc-format-v3.4), but it has
probably not seen too much testing; please tread carefully and report any
problems you find.

Upgrading from any v3.4+ rc file to any later gitolite is fairly easy, though
still manual.  One useful aid is that, as of v3.6.4, you can run `gitolite query-rc -d`
to dump the entire rc structure to STDOUT.  **This only requires
that gitolite be v3.6.4+; your rc file can still be the old one.**  You can
use this to confirm you did not miss something during the manual rc upgrade.

*   dump the current rc by running `gitolite query-rc -d > old.dump` (assuming
    you upgraded to v3.6.4 or higher)

*   save your old rc file: `mv ~/.gitolite.rc ~/old.gitolite.rc`

*   get a "default" rc for your current gitolite by running

        gitolite print-default-rc > ~/.gitolite.rc

*   use your favourite diff-ing editor on the old and the new files and figure
    out what to carry over from the old rc file to the new one.

        vimdiff ~/old.gitolite.rc ~/.gitolite.rc
        # or maybe kdiff3 or whatever

    This is the tricky part of course!  Watch out for configs that got *moved*
    around, or in some cases removed completely, not just new config items.

*   dump the new rc by running `gitolite query-rc -d > new.dump`

*   compare the 2 rc dumps to make sure you've got everything covered.

# appendix B: making a trigger run *after* the built-in ones

For most purposes, the section on [adding your own scripts to a
trigger][addtrig] works fine.

[addtrig]: triggers#adding-your-own-scripts-to-a-trigger

But triggers added that way, run *before* the built-in triggers, which you can
also confirm by running `gitolite query-rc -d` and looking for your trigger in
the output.

If you need your trigger to run *after* the built-in ones, it *is* possible,
it's a wee bit more work.

Let's say you have a post-compile script called "my-custom-config", and you
want it to run *after* the shipped post-compile scripts. Here's what you do:

*   add something like 'my-cust' (could be anything you like, as long as
    it matches the next step) to the ENABLE list in the rc file. Dont
    forget the trailing comma if it's not the last element (and in perl
    you can add a trailing comma even if it *is* the last element)

*   after the ENABLE list, but still within the RC hash, add this:

        NON_CORE => "
        my-cust POST_COMPILE post-compile/my-custom-config
        ",

    The words in caps are fixed. The others you know, and as you can see
    the "my-cust" here matches the "my-cust" in the ENABLE list.

After you do this, you can test whether it worked or not:

    gitolite query-rc POST_COMPILE

and it should show you what it thinks are the items in that list, in the
order it has them.

<!--
-   from https://groups.google.com/forum#!searchin/gitolite/NON_CORE/gitolite/2kZaqLohSz0/LsIo_W8B2I8J

-   document 'before' option (default: goes to the end)
-   document arguments supplied via ENABLE list
-->

# appendix C: overriding safety-net patterns

Apart from [`UNSAFE_PATT`][unsafepatt], there are other patterns that
gitolite uses to prevent various attacks.  They're all defined in `Rc.pm` in
the source, but you can override any of them in `~/.gitolite.rc` if needed.

[unsafepatt]: git-config.html#compensating-for-unsafe_patt-and-other-patterns

!!! danger "DANGER!"

    Overriding any of these regexes may impact the security of the
    installation severly if you are not careful.  You have been warned!

The patterns are:

    $REMOTE_COMMAND_PATT  =                qr(^[-0-9a-zA-Z._\@/+ :,\%=]*$);
    $REF_OR_FILENAME_PATT =     qr(^[0-9a-zA-Z][-0-9a-zA-Z._\@/+ :,]*$);
    $REPONAME_PATT        =  qr(^\@?[0-9a-zA-Z][-0-9a-zA-Z._\@/+]*$);
    $REPOPATT_PATT        = qr(^\@?[[0-9a-zA-Z][-0-9a-zA-Z._\@/+\\^$|()[\]*?{},]*$);
    $USERNAME_PATT        =  qr(^\@?[0-9a-zA-Z][-0-9a-zA-Z._\@+]*$);

To override any of them, just add a new definition for the pattern at the
**very end** of your rc file, just before the `1;` line.  E.g., to allow
usernames to have a leading underscore, you might add:

    $USERNAME_PATT        =  qr(^\@?[_0-9a-zA-Z][-0-9a-zA-Z._\@+]*$);

Needless to say you should be very comfortable with regexes to attempt this :)
