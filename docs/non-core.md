# "non-core" gitolite

----

Much of gitolite's functionality comes from programs and scripts that are not
considered "core".  This keeps the core simpler, and allows you to enhance
gitolite for your own site without too much fuss.

Documentation for non-core gitolite is organised as follows:

  * This page describes the types of non-core programs and how/where to
    install code that is specific to your site.

  * The [developer notes](dev-notes.md) page tells you how to write your own
    non-core programs.

  * The [list of non-core programs](list-non-core.md) talks about what's already
    shipped with gitolite, with a brief description of each.

----

# core versus non-core

Gitolite has five types of non-core code:

  * *Commands* can be run from the shell command line.  Among those, the ones
    in the ENABLE list in the rc file can also be run remotely.
  * *Hooks* are standard git hooks.
  * *Sugar scripts* change the conf language for your convenience.  The word
    sugar comes from "syntactic sugar".
  * *Triggers* are to gitolite what hooks are to git.  I just chose a
    different name to avoid confusion and constant disambiguation in the docs.
  * *VREFs* are extensions to the access control check part of gitolite.

# locations...

## ...for non-core programs shipped with gitolite

<pre style="float: right; font-family: 'Andale mono',monospace; margin-top: 0; font-weight: bold; padding: 4px; color: #ffffff; background-color: #000000;">
.
├── <span style="color: #00ff00">commands</span>
├── lib
│   └── Gitolite
│       ├── <span style="color: #ff0000">Conf</span>
│       ├── <span style="color: #ff0000">Hooks</span>
│       ├── <span style="color: #ff0000">Test</span>
│       └── <span style="color: #00ff00">Triggers</span>
├── <span style="color: #00ff00">syntactic-sugar</span>
├── <span style="color: #00ff00">triggers</span>
└── <span style="color: #00ff00">VREF</span>
</pre>

`gitolite query-rc GL_BINDIR` will tell you where gitolite's code has been
installed.  That directory should look like this.

Among these, the directories in green are considered "non-core", while the
ones in red are considered "core".  In addition, the two files "gitolite" and
"gitolite-shell" in src are also considered "core"

You might notice that there are two locations for [triggers](triggers.md); that is simply
because there are two types of them.  You might also notice that there is no
place for hooks -- gitolite doesn't *ship* with any hooks that are non-core.

## ...for *your* non-core programs

<pre style="float: right; font-family: 'Andale mono',monospace; margin-top: 0; font-weight: bold; padding: 4px; color: #ffffff; background-color: #000000; margin: 8px">
.
├── <span style="color: #00ff00">commands</span>
├── hooks
│   └── <span style="color: #00ff00">common</span>
│   └── <span style="color: #00ff00">repo-specific</span>
├── lib
│   └── Gitolite
│       └── <span style="color: #00ff00">Triggers</span>
├── <span style="color: #00ff00">syntactic-sugar</span>
├── <span style="color: #00ff00">triggers</span>
└── <span style="color: #00ff00">VREF</span>
</pre>

If you want to add your own non-core programs, or even *override* the shipped
ones with your own, you can.

Put your programs in some convenient directory and use the `LOCAL_CODE` rc
variable to tell gitolite where that is.  **Please supply the FULL path** to
this variable.  (You'll find the rc file already has examples lines, commented
out, so it's easy to know where to put it and what syntax to use).

Within that directory, you can use any or all of the subdirectories shown
here.

If you add a program in your local code directory with the same name as a
shipped program, gitolite uses your version.

<span class="gray">Notice that there are two directories related to hooks
here, neither of which exist in the shipped non-core code.  Also, the
`hooks/common` directory is a bit special.  If you add new hooks to this, you
must run `gitolite setup`, or at least `gitolite setup --hooks-only`, for it
to take effect.</span>

## using the gitolite-admin repo to manage non-core code

!!! danger "Important security note:"

    **In this mode, anyone who can push changes to the admin repo will
    effectively be able to run any arbitrary command on the server.**  See
    [gitolite admin and shell access][privesc] for more background.

[privesc]: rc.md#security-note-gitolite-admin-and-shell-access

The location given in `LOCAL_CODE` could be anywhere on disk, like say
`$ENV{HOME}/local`.

However, some administrators find it convenient to use the admin repo to
manage this code as well, getting the benefits of versioning them as well as
making changes to them without having to log on to the server.

To do this, simply point `LOCAL_CODE` to someplace inside `$GL_ADMIN_BASE` in
the rc file.  I **strongly** suggest:

```perl
LOCAL_CODE  =>  "$rc{GL_ADMIN_BASE}/local",
```

Then you create a directory called "local" in your gitolite clone, and create
the directory structure (shown in the previous section) within that directory.
Thus, when you push the admin repo, the files will land up, with the correct
paths, in the location pointed to by LOCAL\_CODE.

(Note: when you do this, gitolite takes care of running `gitolite setup --hooks-only` when you change any hooks and push).

# types of non-core programs

## gitolite "commands"

Gitolite comes with several commands that users can run.  Remote users run
commands by saying:

    ssh git@host command [args...]

while on the server you can run

    gitolite command [args...]

Very few commands are designed to be run both ways, but it can be done, by
checking for the presence of env var `GL_USER`.

All commands respond to a single `-h` option with a suitable message.

You can get a **list of available commands** by using the `help` command.
Naturally, a remote user will see a much smaller list than the server user.

You allow a command to be run from remote clients by adding its name to (or
uncommenting it if it's already added but commented out) the ENABLE list in
the [rc](rc.md) file.

## hooks and gitolite

You can install any hooks except these:

  * (all repos) Gitolite reserves the `update` hook.  See the "hooks" section
    in [dev-notes](dev-notes.md#hooks) if you want additional update hook
    functionality.

  * (gitolite-admin repo only) Gitolite reserves the `post-update` hook.

How/where to install them is described in detail in the "locations" section
above, especially [this][localcode] and [this][pushcode].  The summary is that
you put them in the "hooks/common" sub-directory within the directory whose
name is given in the `LOCAL_CODE` rc variable, then run `gitolite setup`.

[localcode]: non-core.md#for-your-non-core-programs
[pushcode]: non-core.md#using-the-gitolite-admin-repo-to-manage-non-core-code

### repo-specific hooks

!!! danger "Important security note:"

    **If you enable this, anyone who can push changes to the admin repo will
    effectively be able to run any arbitrary command on the server.**  See
    [gitolite admin and shell access][privesc] for more background.

If you want to add hooks only to specific repos, you can just do it manually
if you wish -- just log on to the server and add hooks (except the update hook
and, for the special gitolite-admin repo, the post-update hook -- touch these
and all bets on gitolite's functionality are off).

However, if you want to do that from within gitolite, and thus keep everything
together, you can do that also.  Here's how.

  * Create a directory called `hooks/repo-specific` in whatever location you
    decided to use for your non-core code (i.e., direct on the server, or
    within the gitolite-admin repo).

  * Add your hooks here, with descriptive names (i.e., not "post-receive",
    etc., but maybe "jenkins" or "deploy" or whatever).

    *   As of v3.6.7, you can also put them in subdirectories for convenience
        (like if you have too many repo specific hooks).  For instance, you
        could put some hook code in `foo/bar`; the symlink in the repo's hooks
        directory will be created as if you had called it `foo_bar`.

  * Uncomment the 'repo-specific-hooks' line in the rc file or add it to the
    ENABLE list if it doesn't exist.

    If your rc file does not have an ENABLE list, you need to add this to the
    POST_COMPILE and the POST_CREATE lists.  Click [here][addtrig] for more on
    all this.

  * Now add lines like this to your conf file:

    ```gitolite
    repo    foo
        option hook.post-receive    =   deploy
    ```

    The syntax should be fairly obvious, but just to be clear, in this case a
    symlink called "post-receive" will be placed in foo.git/hooks, pointing to
    the executable called "deploy" in hooks/repo-specific in the local-code
    area.

    **WARNING**: if the hook already exists, it is silently overwritten.

    **WARNING**: <span class="gray">(v3.5.x or below)</span> once the hook is placed, you can't remove it through
    gitolite.  That is, removing the option line won't do anything.  You'll
    have to go to the server and remove it manually.

  * <span class="gray">(v3.6+)</span> You can assign multiple targets for each hook.  For
    example, you could say

    ```gitolite
    repo    foo
        option hook.post-receive    =   deploy mail-admins
    ```

    where "deploy" and "mail-admins" are pieces of code that do whatever their
    names suggest, and both are, independently, candidates for being run from
    a post-receive hook.

    When you do this, gitolite does whatever is needed to run each of them as
    independent post-receive hooks (including sending them info over their
    STDIN as documented in 'man githooks').

    **For pre-receive or pre-auto-gc you should not use more than one hook.
    If you really need more than one, ask on the mailing list.**

  * <span class="gray">(v3.6+)</span> You can change these hooks by saying:

    ```gitolite
    repo    foo
        option hook.post-receive    =   deploy mail-admins
    ```

    or delete all of them by saying:

    ```gitolite
    repo    foo
        option hook.post-receive    =   ""
    ```

  * <span class="gray">(v3.6.5+)</span> You can add hooks incrementally.  For example:

    ```gitolite
    repo    @all
        option hook.post-receive.00 =   mail-admins
        option hook.post-receive.01 =   deploy
    # (and later)
    repo    foo
        option hook.post-receive.00 =   mail-users      #1
        option hook.post-receive.01 =   ""              #2
    # (and maybe still later)
    repo    @foss
        option hook.post-receive.02 =   save-push-sigs
    ```

    Assuming `foo` is a member of `@foss`, this declares 2 post-receive hooks
    for it: mail-users and save-push-sigs.  The suffix (in this example, "00",
    "01") can actually be any simple word.  Using a suffix keeps the option
    names unique, which allows you to override or delete specific options, as
    we did in the lines marked '#1' and '#2'.  The suffix also determines the
    order in which the options are used in applying hooks to the repo.  If the
    order doesn't matter to you, just make sure they're unique.

[addtrig]: triggers.md#adding-your-own-scripts-to-a-trigger

## syntactic sugar

Sugar scripts help you change the perceived syntax of the conf language.  The
base syntax of the language is very simple, so sugar scripts take something
*else* and convert it into that.

That way, the admin sees additional features (like allowing continuation
lines), while the parser in the core gitolite engine does not change.

If you want to write your own sugar scripts, please read the "your own sugar"
section in [dev-notes](dev-notes.md) first then email me.

You enable a sugar script by uncommenting the feature name in the ENABLE list
in the rc file.

## triggers

Triggers have their own [page](triggers.md).

## VREFs

VREFs also have their own [page](vref.md).

