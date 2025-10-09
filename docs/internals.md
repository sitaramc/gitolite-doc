# gitolite internals

This page is for people who may want to hack on **core** gitolite itself.
This is **not** the page for people who merely want to customise their site
(i.e., write their own VREFs, triggers, etc.); for that please start with the
[non-core](non-core.md) page.

----

This document assumes you're familiar with the material in the [how does it
work](overview.md#how-does-it-work) section in the "overview" document, as well
as the [concepts](concepts.md) page.  If you're not familiar with ssh, and in particular
how programs like gitolite use ssh to simulate many users over one Unix user,
the [ssh](ssh.md) page has useful info.

<!--

I can't over-stress the importance of discussing any changes you propose on
the mailing list.  I'm pretty conservative about adding code to core, so
expect lots of push-back.  In general, if it can be done outside "core",
that's what I will suggest!

-->

## what is "core"

The core code consists mainly of `src/gitolite`, `src/gitolite-shell`, and all
the perl modules in `src/lib/Gitolite` except `src/lib/Gitolite/Triggers`.

That said, there are parts of non-core that, in a default (ssh) install, are
used frequently enough to be important (for example if you are reviewing
gitolite):

*   commands in `src/commands`: access, git-config, info, mirror, option,
    owns, perms
*   triggers in `src/lib/Gitolite/Triggers`: Mirroring.pm, Shell.pm
*   triggers in `src/triggers` and `src/triggers/post-compile`: ssh-authkeys,
    ssh-authkeys-shell-users, update-git-configs, set-default-roles, 

## entry points

### gitolite

Most server-side operations that gitolite supports are invoked via the
`gitolite` command.  This includes initial setup and maintenance, some
built-in commands (run 'gitolite -h' to see them), and finally the commands in
`src/commands` (run 'gitolite help' to get a list).

### gitolite-shell

All remote access is via the `gitolite-shell` command, (invoked, of course, by
sshd).  This includes both git operations (clone, fetch, push) as well as
gitolite commands that have been enabled for remote invocation.

For git operations, gitolite-shell does the initial access check ("is the user
even allowed to read/write this repo at all?") and then calls git proper.

Most of the code in this is housekeeping; the real action happens in one of
the modules.

## the Conf module

The `Conf` module and its child modules deal with the gitolite.conf file.

`Conf` is where the 'compile' command lands.  The parser for the conf file is
also in this module; each "recognised" line is passed to appropriate functions
in `Conf::Store`.

Please note the parser is a very simple line-oriented parser using simple
regexes; the DSL for the gitolite.conf file is intentionally very simple.

### `Conf::Explode`

This deals with "exploding" the main gitolite.conf file into a single perl
list with all 'include' files recursively expanded.

### `Conf::Sugar`

This calls `Conf::Explode` to get the full set of conf lines, then applies a
series of "syntactic sugar" transformations to them.  This keeps the main
parser simple, while allowing the administrator to take some shortcuts in
writing the rules.

Some transformations are built-in and hardcoded, but a site can add their own
site-local transformations if they like.

### `Conf::Store`

`Conf::Store` is one of the two workhorses of gitolite.  It exports functions
related to processing parsed lines and storing the parsed output for later
use.  It also exports functions that deal with creating and setting up new
repos.

!!! note ""
    The output of the compile step is essentially a set of perl hashes in
    `Data::Dumper` format.  Rules that apply to more than one repo (i.e., the
    repo name was a regex pattern or a group name) go into a "common" output
    file (`~/.gitolite/conf/gitolite.conf-compiled.pm`), while rules that
    apply to specific repos go into their own files
    (`~/repositories/$REPONAME.git/gl-conf`).

From a security perspective, dealing with 'subconf' (see [delegation](deleg.md)
for details) happens in this module.

### `Conf::Load`

`Conf::Load` is the other of the two workhorses of gitolite.

The most important function it exports is `access`, which is used by
`gitolite-shell` as well as by the update hook code to check for permissions.
This code has a few optimisations, including very simple, localised, caching
of parsed conf files when needed.

TODO: How the `access` function does its thing will be written up in more
detail as I find time, but TLDR: it calls `rules` which builds up a list of
the rules that apply.  Also see [this](conf.md#defining-user-and-repo) until I
manage to write it up in more detail.

Other functions are `git_config`, which returns a list of config values
specified in the conf file.

Finally, this is where all the "list-" commands that 'gitolite -h' shows you
(e.g., 'gitolite list-repos') land up.

## the Rc module

The rc file (`~/.gitolite.rc`) is processed here.  In addition, it also
declares a bunch of constants (like the all-important regex patterns to
validate user inputs of various kinds; all ending in `_PATT`).

The only complicated part of this is how the `non_core_expand` function takes
the `$non_core` variable (currently 63 lines long!) and converts it into a set
of arrays, one for each of the [triggers](triggers.md) types.  You can see the effect of
this logic by uncommenting something in the ENABLE list in the rc file, then
running `gitolite query-rc PRE_GIT`, etc.

(From a security point of view this is irrelevant.  Any inputs it receives
come from totally trusted sources -- either the gitolite source code or the rc
file).

Finally, the trigger function is also exported by this module.  This is the
function that actually runs all the programs tied to each trigger.

## the Hooks module

This is where the code for the update hook (all repos) and the post-update
hook (gitolite-admin repo only) can be found.

The post-update hook code is fairly straightforward, consisting essentially of
three shell commands.

The update hook code has a lot more "action", since this is where all access
checking for 'git push' goes.  Even that would not be much if it weren't for
VREFs, because then it's just one call to the access function (from the
`Conf::Load` module).

The only other thing of note in this module is how the "attempted access" is
determined.  Externally, we only know it's a "push" (i.e., a "W" in gitolite
permission terms).  We need to compare the old and the new SHAs in various
ways to determine if it's a rewind, or a delete, or a create, etc., which may
make a difference to the access.

TODO: expand on VREF handling.  For now please read [vref](vref.md) to get the
general idea of *what* it does, while I find time to write up the *how*.

## the rest...

...is TBD (to be done).  Briefly, the Test module is for testing, the Common
module contains a whole bunch of common routines used all over -- many of them
not gitolite specific at all, Cache is not to be used for now (sorry,
bitrotted by now I think... I may need to take it out behind the woodshed one
of these days).

## security notes

All security issues should be reported directly to me (sitaramc@gmail.com),
and not to the mailing list.

(In the following text, the words MUST, SHOULD, etc. are loosely as defined in
RFC 2119).

1.  Gitolite MUST protect everything in `~/repositories` from people who do
    not have command line access to the user hosting the service, and do not
    have "push" access rights to the gitolite-admin repository.

    Specifically, gitolite MUST prevent such users from doing anything except
    the following:

    *   perform git operations they are allowed to by gitolite.conf
    *   run *gitolite* commands that are enabled for remote use

2.  People who have command line access are considered to be "in"; nothing in
    gitolite attempts to protect from them (it's impossible anyway!)

    But someone who does not have command line access, but *does* have push
    access rights to the gitolite-admin repo (a "gitolite admin"), is a
    special case.

    Gitolite SHOULD prevent a gitolite admin from using that to pivot to
    executing arbitrary commands on the server.  (This is why, for example,
    the gitolite-admin repo can't have arbitrary "config" lines.)

    However, many sites don't care about this distinction -- all their
    gitolite admins already have shell access.

    Thus, a violation of this is important and should be fixed, but not
    considered critical.

3.  Gitolite SHOULD try to make sure that the *gitolite* commands shipped with
    gitolite do not indirectly enable violation of the restrictions in the
    first bullet.  The seriousness of failing this depends on the command in
    question (is the command enabled in the default setup, or even if it is
    not, is it a popular and widely used command, etc.)

4.  Gitolite SHOULD protect the local sysadmin from his own errors to some
    extent.  For example, it should be possible to write a new "command" in
    shell, without worrying about shell meta-characters sneaking in and
    executing something; gitolite should prevent this from happening.

5.  As you probably [knew][auth] already, gitolite does not do authentication;
    it only deals with authorisation.  Still, gitolite MAY help the
    administrator to setup authentication (as the default setup does when used
    in ssh mode), but it is not mandatory.  In particular, use in http-mode
    leaves gitolite completely out of the authentication picture.

In order to achieve these goals, gitolite expects the files and directories on
the server to have sane permissions and ownerships.  A decent POSIX file
system, and a reasonable sshd config are also expected.

[auth]: concepts.md#authentication-and-authorisation

Finally, a note on a couple of related items:

*   Gitolite's stance on DOS (by authenticated users) is that if it is
    fixable, it will be fixed, but it is not a critical issue, as long as the
    log files cannot be tampered with.

    A DOS by un-authenticated users is completely out of scope.

*   Gitolite cannot benefit from perl's taint mode, which was made for a
    different threat model.

    Gitolite's threat model implicitly trusts anyone who has shell access to
    the server, including all programs already on the server.  It's only
    remote users that are considered a threat.

    Perl's taint mode treats *anything* outside the program itself as suspect.
    So, the rc file, the compiled config, the various internal files gitolite
    stores housekeeping information in, etc., would all need to be untainted.

    Since gitolite gets "suspicious" input only in one place, it's easier to
    check that rigorously enough rather than use taint mode.

## appendix A: accessing the documentation offline

The source code for the documentation is in
<https://github.com/sitaramc/gitolite-doc>.  Rendering it requires some work
(TBD: details).

For most purposes, it's simpler to clone
<https://github.com/sitaramc/sitaramc.github.com> and use the 'gitolite'
subdirectory within as your pre-rendered document base.  Open it in a
JS-enabled browser and you can even do searches.

