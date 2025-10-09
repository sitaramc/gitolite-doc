# help for emergencies

<center><span class="red">**"Don't Panic!"**</span></center>

----

!!! danger "IMPORTANT"
    Almost nothing in gitolite requires `root` (with some obvious exceptions).
    Unless the documentation says "do this from `root`", assume it is to be
    done from the [hosting user][hu] account.

## install/setup issues

Most install/setup issues in ssh mode are caused by lack of ssh knowledge.
Ssh is a complex beast, and can cause problems for people who are not familiar
with its quirks.

**Be prepared to spend some time reading the [ssh](ssh.md) documentation that comes
with gitolite**.

## lost admin key/access

If you lost your gitolite **admin** key or access, here's what you do.  We'll
assume your username is "alice" (i.e., alice has RW or RW+ permissions on the
gitolite-admin repo).

  * Make yourself a new keypair and copy the public key to the server as
    'alice.pub'.

  * Log on to the server, and run `gitolite setup -pk alice.pub`.

That's it; the new alice.pub file replaces whatever existed in the repo
before.

## bypassing gitolite

You may have lost access because of a conf file error, in which case the above
trick (which merely changes a pubkey) won't help.  What you want is to make
changes to the gitolite-admin repo (or perhaps just rewind) and push that.
Here's how to do that:

  * Log on to the server.

  * Clone the admin repo using the full path:

        git clone $HOME/repositories/gitolite-admin.git temp

  * 'cd' to this clone and make whatever changes you want -- add/replace a
    key, 'git revert' or 'git reset --hard' to an older commit, etc.  Anything
    you need to fix the problem, really.

  * Run `gitolite push` (or possibly `gitolite push -f`).  <span class="red">**Note that's
    'gitolite push', not 'git push'**.</span>

<font color="red">
**NOTE**: gitolite does **no access checking** when you do this!
</font>

## botched something?

### fixing botched repos

If you copied some repos from somewhere else, or mucked with the hooks for
some reason, or deleted any gitolite-specific files, or tried any other
"behind the scenes" stunts, the quickest, sanest, way to fix everything up is:

  * Make sure any new repos you copied in are mentioned in the gitolite.conf
    in some 'repo' line and the change pushed.

  * Run the following three commands:

        gitolite compile
        gitolite setup --hooks-only
        gitolite trigger POST_COMPILE

If the repo you botched is a wild repo, there's a bit more to be done.  Wild
repos store the creator name in a file called gl-creator, and the data managed
by the [perms][] command in a file called "gl-perms".  If these files got
deleted, you may have to manually recreate them.  The format is very simple
and guessable by looking at those files on any other wild repo.

[perms]: user.md#setget-additional-permissions-for-repos-you-created

### cleaning out a botched install

Here's a list of files and directories to deal with:

  * **Gitolite sources** -- can be found by running `which gitolite`.  If it's
    a symlink, go to its target directory.

    If the `which` command does not work, you'll have to find this info from
    looking at the 'command=' option in pubkey lines in
    `~/.ssh/authorized_keys`.

  * **Gitolite admin directory** -- `$HOME/.gitolite`.  Save the 'logs'
    directory if you want to preserve them for any reason.

  * **The rc file** -- `$HOME/.gitolite.rc`.  If you made any changes to it
    you can save it as some other name instead of deleting it.

  * **The gitolite-admin repo** -- `$HOME/repositories/gitolite-admin.git`.
    You can clone it somewhere to save it before blowing it away if you wish.

  * **Git repositories** -- `$HOME/repositories`.  The install process will
    not touch any existing repos except 'gitolite-admin.git', so you do not
    have to blow away (or move) your work repos to fix a botched install.

    Only when you update the conf to include those repos and push the changes
    will those repos be touched.  And even then all that happens is that the
    update hook, if any, is replaced with gitolite's own hook.

  * **Ssh stuff** -- exercise caution when doing this, but in general it
    should be safe to delete all lines between the "gitolite start" and
    "gitolite end" markers in `$HOME/.ssh/authorized_keys`.

    Gitolite does not touch any other files in the ssh directory.

## common errors

  * `WARNING: keydir/<yourname>.pub duplicates a non-gitolite key, sshd will ignore it`

    You used a key that is already set to give you shell access.  You cannot
    use the same key to get shell access as well as access gitolite repos.

    Solution: use a different keypair for gitolite.  There's a wee bit more on
    this in the [setup](install.md#setup) section of the install page.  Also see
    [why bypassing causes a problem][ybpfail] and both the pages linked from
    [ssh](ssh.md) for background.

  * `Empty compile time value given to use lib at hooks/update line 6`

    (followed by `Can't locate Gitolite/Hooks/Update.pm in @INC` a couple of
    lines later).

    You're bypassing gitolite.  You cloned the repo using the full path (i.e.,
    including the `repositories/` prefix), either directly on the server, or
    via ssh with a key that gives you **shell** access.

    Solution: same as for the previous bullet.

    NOTE: If you really *must* do it, and this is on the server and is a
    one-time thing, you can try `gitolite push` instead of `git push`.
    **BUT**... this defeats all gitolite access control, so if you're going to
    do this often, maybe you don't need gitolite!

[ybpfail]: sts.md#appendix-5-why-bypassing-gitolite-causes-a-problem

## uncommon errors

(This page intentionally left blank)

## non-standard configs that'll trip you up

  * **IMPORTANT**: although a default openssh config will not do this (AFAIK),
    **do not** allow the user to set environment variables if you care about
    security at all.

  * If your 'git' binary is in a non-PATH location, or you have more than one
    version and want a specific one to be picked up, you will have to add a
    line like this at the end of the rc file (outside the `%RC` hash, but
    before the `1;` line):

        $ENV{PATH} = "/your/git/path:$ENV{PATH}";

  * If you have your sshd configured to put the authorized\_keys file
    somewhere other than the default (which is in .ssh in the [hosting
    user][hu]'s home directory), you'll probably have to roll your own ssh
    handling, either disabling 'ssh-authkeys' in the rc file, or building on
    that somehow (maybe a post-processing step that copies the relevant auth
    keys lines from the default file to the other).

  * If you have sshd setup to not allow incoming ssh for the hosting user,
    gitolite won't work.  Check things like `Allowusers` setting in
    `/etc/ssh/sshd_config` etc. to make sure.

  * If you have the home directory in a partition that is mounted noexec,
    gitolite won't work.  I believe it would be sufficient if the ".gitolite"
    directory were moved to a different mount and symlinked, but please test
    thoroughly.  A failure to execute a hook does not throw up any errors or
    warnings for you to notice!

  * If the default shell is something like /bin/false, and/or not listed in
    /etc/shells, there might be problems.

[hu]: concepts.md#the-hosting-user

## things that are not gitolite problems

There are several things that appear to be gitolite problems but are not.  I
cannot help with most of these (although the good folks on irc or the mailing
list -- see [contact][] -- might be able to; they certainly appear to have a
lot more patience than I do, bless 'em!)

  * **Client side software**

      * putty/plink
      * jgit/Eclipse
      * Mac OS client **or** server
      * putty/plink
      * windows as a server
      * ...probably some more I forgot; will update this list as I remember...
      * did I mention putty/plink?

  * **Ssh**

    The *superstar* of the "not a gitolite problem" category is actually ssh.

    Surprised?  It's a common misunderstanding; see [this section][auth] in
    the concepts page, and then [this page](ssh.md) for details.

    Everything I know is in that latter link, and the two more pages it points
    to.  Please email me about ssh ONLY if you find something wrong or missing
    in those pages.

  * **Git**

    I wish I had a dollar for each time someone did a *first push* on a new
    repo, got an error because there were "no refs in common (etc.)", and
    asked me why gitolite was not allowing the push.

    Gitolite is designed to look like just another bare repo server to a
    client (except requiring public keys -- no passwords allowed).  It is
    *completely transparent* when there is no authorisation failure (i.e.,
    when the access is allowed, the remote client has no way of knowing
    gitolite was even installed!)

    Even "on disk", apart from reserving the `update` hook for itself,
    gitolite does nothing to your bare repos unless you tell it to (for
    example, adding 'gitweb.owner' and such to the config file).

    BEFORE you think gitolite is the problem, try the same thing with a normal
    bare repo.  In most cases you can play with it just by doing something
    like this:

        mkdir /tmp/throwaway
        cd    /tmp/throwaway
        git clone --mirror <some repo you have a URL for> bare.git
        git clone bare.git worktree
        cd worktree
        <...try stuff>

[contact]: index.md#contactsupport
[auth]: concepts.md#authentication-and-authorisation

