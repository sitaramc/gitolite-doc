# the users' view

----

This page talks about what gitolite looks like to non-admins, and the commands
and features available to them.

# accessing gitolite

The most common setup is based on ssh, where your admin asks you to send him
your public key, and uses that to setup your access.

Your actual access is either a git command (like `git clone git@server:reponame`,
or an ssh command (like `ssh git@server info`).

Note that you do *not* get a shell on the server -- the whole point of
gitolite is to prevent that!

**Note to people who think gitolite requires or can only handle a specific
syntax for the URL**: Gitolite is designed in such a way that, unless there is
an access violation, the *client* need not even *know* that something called
gitolite is sitting between it and git on the server.  In particular, this
means *any* URL syntax listed in 'man git-clone' for ssh and/or http will
work.  The only things to note are:

  * In ssh mode, you *must* use key-based authentication (i.e., passwords
    won't work; see the two pages linked from the [ssh](ssh) page for why).
  * The path of the repo is what you put into the conf file (e.g., "testing",
    and not "repositories/testing" or "/home/git/repositories/testing" or
    such).  A good rule of thumb is to use the exact name the `info` command
    (see below) shows you.
  * The ".git" at the end is optional for **git** commands (i.e., you can use
    "testing.git" instead of "testing" for clone, fetch, push, etc., if you
    like) but **gitolite** commands in general (see below) will not like the
    additional ".git" at the end.

# the info command

The only command that is *always* available to every user is the `info`
command (run `ssh git@host info -h` for help), which tells you what version of
gitolite and git are on the server, and what repositories you have access to.
The list of repos is very useful if you have doubts about the spelling of some
new repo that you know was setup.

# normal and wild repos

Gitolite has two kinds of repos.  Normal repos are specified by their full
names in the config file.  "Wildcard" repos are specified by a regex in the
config file.  Try the [`info` command][info] and see if it shows any lines
that look like regex patterns, (with a "C" permission).

[info]: user#the-info-command

If you see any, it means you are allowed to create brand new repos whose names
fit that regex.  Normally, you create such repos simply by cloning them or
pushing to them -- gitolite automatically creates the repo on the server side.
(If your site is different, your admin will tell you).

When you create such a repo, your "ownership" of it (as far as gitolite is
concerned) is automatically recorded by gitolite.

# other commands

## set/get additional permissions for repos you created

The gitolite config may have several permissions lines for your repo, like so:

```gitolite
repo pub/CREATOR/..*
    C       =   ...some list of users allowed to create repos...
    RW+     =   CREATOR
    RW      =   user1 user2
    R       =   user3
```

If that's all it had, you really can't do much.  Any changes to access must be
done by the administrator.  (Note that "CREATOR" is a reserved word that gets
expanded to your userid in some way, so the admin can literally add just the
first three lines, and *every* user listed in the second line (or *every
authenticated user*, if you specified `@all` there) has his own personal repo
namespace, starting with `pub/<username>/`).

To give some flexibility to users, the admin could add rules like this:

```gitolite
    RW      =   WRITERS
    R       =   READERS
```

<span class="gray">(he could also add other [roles](wild#roles) but then he
needs to read the documentation).</span>

Once he does this, you can then use the `perms` command (run `ssh git@host perms -h`
for help) to set permissions for other users by specifying which
users are in the list of "READERS", and which in "WRITERS".

If you think of READERS and WRITERS as "roles", it will help.  You can't
change what access a role has, but you *can* say which users have that role.

!!! note "Note:"

    There isn't a way for you to see the actual rule list unless you're given
    read access to the special 'gitolite-admin' repo.  Sorry.  The idea is
    that your admin will tell you what "roles" he added into rules for your
    repos, and what permissions those roles have.

## adding a description to repos you created

The `desc` command is extremely simple.  Run `ssh git@host desc -h` for help.

# "site-local" commands

The main purpose of gitolite is to prevent you from getting a shell.  But
there are commands that you often need to run on the server (i.e., cannot be
done by pushing something to a repo).

To enable this, gitolite allows the admin to setup scripts in a special
directory that users can then run.  Gitolite comes with a set of working
scripts that your admin may install, or may use as a starting point for his
own, if he chooses.

Think of these commands as equivalent to those in `COMMAND_DIR` in `man git-shell`.

You can get a list of available commands by running `ssh git@host help`.

# "personal" branches

"personal" branches are great for environments where developers need to share
work but can't directly pull from each other (usually due to either a
networking or authentication related reason, both common in corporate setups).

Personal branches exist **in a sub-tree** of the `ref/heads/[...]` hierarchy.
The syntax is

```gitolite
    RW+ personal/USER/  =   @userlist
```

where (a) the "personal" can be anything you like, but cannot be empty, (b) the
"/USER/" part is **necessary (including both slashes)**, and (c) the trailing
slash can be optionally followed by additional restrictions on the ref name.

A user "alice" (if she's in the userlist) can then push any branches inside
`personal/alice/` (i.e., she can push `personal/alice/foo` and
`personal/alice/bar`, but NOT `personal/alice`).  As another example
`personal/USER/[a-zA-Z0-9_]+$` would mean that alice can create
`personal/alice/foo`, but not `personal/alice/foo/bar`, because a `/` is not
allowed by the expression following the `/USER/`.

(Background: at runtime the "USER" component will be replaced by the name of
the invoking user.  Access is determined by the right hand side, as usual).

Compared to using arbitrary branch names on the same server, this:

  * Reduces namespace pollution by corralling all these ad hoc branches into
    the "personal/" namespace.
  * Reduces branch name collision by giving each developer her own
    sub-hierarchy within that.
  * Removes the need to think about access control, because a user can push
    only to his own sub-hierarchy.

