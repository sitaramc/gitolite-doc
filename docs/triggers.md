# gitolite triggers

----

Gitolite runs trigger code at several different times.  The features you
enable in the [rc](rc.md) file determine what commands to run (or functions in perl
modules to call) at each trigger point.  Example of trigger points are
`INPUT`, `PRE_GIT`, `POST_COMPILE`, etc.; the full list is examined later in
this page.

!!! note ""

    Quick tip: triggers are to gitolite what hooks are to git; we simply use a
    different name to avoid constantly having to clarify which hooks we mean!
    The other difference in gitolite is that each trigger runs multiple pieces
    of code, not just one program with the same name as the hook, like git
    does.

## types of trigger programs

There are two types of trigger programs.  Standalone scripts are placed in
triggers or its subdirectories.  Such scripts are quick and easy to write in
any language of your choice.

Triggers written as perl modules are placed in lib/Gitolite/Triggers.  Perl
modules have to follow some conventions (see some of the shipped modules for
ideas) but the advantage is that they can set environment variables and change
the argument list of the gitolite-shell program that invokes them.

If you intend to write your own triggers, it's a good idea to examine a
default install of gitolite, paying attention to:

  * the path names in various trigger lists in the rc file,
  * corresponding path names in the src/ directory in gitolite source,
  * and for perl modules, the package names and function names within.

## manually firing triggers

It's easy to manually fire triggers from the server command line.  For
example:

    gitolite trigger POST_COMPILE

However if the triggered code depends on arguments (see next section) this
won't work.  (The `POST_COMPILE` trigger programs all just happen to not
require any arguments, so it works).

## common arguments

Triggers receive the following arguments:

1.  Any arguments mentioned in the rc file (for an example, see the renice
    command).

2.  The name of the trigger as a string (example, `"POST_COMPILE"`), so you
    can call the same program from multiple triggers and it can know where it
    was called from.

3.  And finally, zero or more arguments specific to the trigger, as given in
    the next section.

## trigger-specific arguments and other details

Here are the **rest of** the arguments for each trigger, plus a brief
description of when the trigger runs.  (Note that when the repo name is passed
in as an argument, it is without the '.git' suffix).

  * `INPUT` runs before pretty much anything else.  INPUT trigger scripts
    *must* be in perl, since they manipulate the arguments and the environment
    of the 'gitolite-shell' program itself.  Most commonly they will
    read/change `@ARGV`, and/or `$ENV{SSH_ORIGINAL_COMMAND}`.

    There are certain conventions to adhere to; please see some of the shipped
    samples or ask me if you need help writing your own.

  * `ACCESS_1` runs after the first access check.  Extra arguments:
      * repo
      * user
      * 'R' or 'W'
      * 'any'
      * result (see notes below)

    'result' is the return value of the access() function.  If it contains the
    uppercase word "DENIED", the access was rejected.  Otherwise it is the
    refex that caused the access to succeed.

    !!! note ""

        Note that if access is rejected, gitolite-shell will die as soon as it
        returns from the trigger.

  * `ACCESS_2` runs after the second access check, which is invoked by the
    update hook to check the ref.  Extra arguments:
      * repo
      * user
      * any of W, +, C, D, WM, +M, CM, DM
      * the ref being updated (e.g., 'refs/heads/master')
      * result
      * old SHA
      * new SHA

    `ACCESS_2` also runs on each [VREF](vref.md) that gets checked.  In this case
    the "ref" argument will start with "VREF/", and the last two arguments
    won't be passed.

    'result' is similar to `ACCESS_1`, except that it is the *update hook*
    which dies as soon as access is rejected for the ref or any of the VREFs.
    Control then returns to git, and then to gitolite-shell, so the `POST_GIT`
    trigger *will* run.

  * `PRE_GIT` and `POST_GIT` run just before and after the git command.
    Extra arguments:
      * repo
      * user
      * 'R' or 'W'
      * 'any'
      * the git command ('git-receive-pack', 'git-upload-pack', or
        'git-upload-archive') being invoked.

    !!! note ""

        Note that the `POST_GIT` trigger has no way of knowing if the push
        succeeded, because 'git-shell' (or maybe 'git-receive-pack', I don't
        know) exits cleanly even if the update hook died.

  * `PRE_CREATE` and `POST_CREATE` run just before and after a new repo is
    created.  In addition, any command that creates a repo (like 'fork') or
    potentially changes permissions (like 'perms') may choose to run
    `POST_CREATE`.

    Extra arguments for normal repo creation (i.e., by adding a "repo foo"
    line to the conf file):

      * repo

    Extra arguments for wild repo creation:

      * repo
      * user
      * invoking operation
          * 'R' for fetch/clone/ls-remote, 'W' for push
          * can also be anything set by the command running the trigger (e.g.,
            see the perms and fork commands).  This lets the trigger code know
            how it was invoked.

  * `POST_COMPILE` runs after an admin push has successfully "compiled" the
    config file.  By default, the next thing is to update the ssh authkeys
    file, then all the 'git-config's, gitweb access, and daemon access.

    No extra arguments.

## adding your own scripts to a trigger

<span class="box-r">Note: for gitolite v3.3 or less, adding your own scripts
to a trigger list was simply a matter of finding the trigger name in the rc
file and adding an entry to it.  Even for gitolite v3.4 or higher, if your rc
file was created before v3.4, *it will continue to work, and you can continue
to add triggers to it the same way as before*.</span>

The rc file (from v3.4 on) does not have trigger lists; it has a simple list
of "features" within a list called "ENABLE" in the rc file.  Simply comment
out or uncomment appropriate entries, and gitolite will *internally* create
the trigger lists correctly.

This is fine for triggers that are shipped with gitolite, but does present a
problem when you want to add your own.

Here's how to do that: Let's say you wrote yourself a trigger script called
'foo', to be invoked from the `POST_CREATE` trigger list.  To do that, just
add the following to the [rc](rc.md) file, just before the ENABLE section:

    POST_CREATE                 =>
        [
            'foo'
        ],

Since the ENABLE list pulls in the rest of the trigger entries, this will be
*effectively* as if you had done this in a v3.3 rc file:

    POST_CREATE                 =>
        [
            'foo',
            'post-compile/update-git-configs',
            'post-compile/update-gitweb-access-list',
            'post-compile/update-git-daemon-access-list',
        ],

As you can see, the 'foo' gets added to the top of the list.

### adding a perl module as a trigger

If your trigger is a perl module, as opposed to a standalone script or
executable, the process is almost the same as above, except what you add to
the rc file it looks like this:

    POST_CREATE                 =>
        [
            'Foo::post_create'
        ],

Gitolite will add the `Gitolite::Triggers::` prefix to the name given there.

The subroutine to be run (in this example, `post_create`) is looked for in the
`Gitolite::Triggers::Foo` package, so this requires that the perl module
start with a package header like this:

    package Gitolite::Triggers::Foo;

### displaying the resulting trigger list

You can use the 'gitolite query-rc' command to see what the trigger list
actually looks like.  For example:

    gitolite query-rc POST_CREATE

<!--
(ref: https://groups.google.com/forum/#!searchin/gitolite/NON_CORE/gitolite/2kZaqLohSz0/LsIo_W8B2I8J )
-->
<!--

### running your script AFTER the defaults

By default, your custom scripts will run *before* the shipped ones (e.g., look
at where `foo` landed in the example above).

There is a way to make `foo` land *after* the shipped scripts, but it is not
documented because it never came up till now, and I don't want to commit to it
in case I want to change the implementation.

Let's say your post-compile script is called "my-custom-config". Here's what
you do:

-   add something like 'my-cust' (could be anything you like, as long as it
    matches the next step) to the ENABLE list in the rc file. Dont forget the
    trailing comma if it's not the last element (and in perl you can add a
    trailing comma even if it *is* the last element)

-   after the ENABLE list, but still within the RC hash, add this:

        NON_CORE => "
        my-cust POST_COMPILE post-compile/my-custom-config
        ",

    The words in caps are fixed. The others you know, and as you can see the
    "my-cust" here matches the "my-cust" in the ENABLE list.

-   After you do this, you can test whether it worked or not:

        gitolite query-rc POST_COMPILE

    and it should show you what it thinks are the items in that list, in the
    order it has them.

-->

## tips and examples

1.  If you have code that latches onto more than one trigger, collecting data
    (such as for logging), then the outputs may be intermixed.  You can record
    the value of the environment variable `GL_TID` to tie together related
    entries.

    The documentation on the [log file format][lff] has more on this.

2.  If you look at CpuTime.pm, you'll see that it's `input()` function doesn't
    set or change anything, but does set a package variable to record the
    start time.  Later, when the same module's `post_git()` function is
    invoked, it uses this variable to determine elapsed time.

    *(This is a very nice and simple example of how you can implement features
    by latching onto multiple events and sharing data to do something)*.

3.  You can even change the reponame the user sees, behind his back.  Alias.pm
    handles that.

4.  Finally, as an exercise for the reader, consider how you would create a
    brand new env var that contains the *comment* field of the ssh pubkey that
    was used to gain access, using the information [here][kfn].

[lff]: dev-notes.md#appendix-2-log-file-format
[kfn]: sts.md#distinguishing-one-key-from-another

<!--

  - PRE_GIT, ACCESS_1, and ACCESS_2 must only write to STDERR

  - perl triggers should not chdir() away

-->

