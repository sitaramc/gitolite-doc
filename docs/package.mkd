# packaging gitolite

----

Gitolite has broad similarities to git in terms of packaging requirements.

  * Git has 150 executables to marshal and put somewhere.  Gitolite has the
    directories `commands`, `lib`, `syntactic-sugar`, `triggers`, and `VREF`.

    It doesn't matter what this directory is.  As an example, Fedora keeps
    git's 150 executables in /usr/libexec/git-core, so /usr/libexec/gitolite
    may be a good choice; it's upto you.

    *The rest of this section will assume you chose /usr/libexec/gitolite as
    the location, and that this location contains the 5 directories named
    above*.

  * Git has the `GIT_EXEC_PATH` env var to point to this directory.  Gitolite
    has `GL_BINDIR`.  However, in git, the "make" process embeds a suitable
    default into the binary, making the env var optional.

With that said, here's one way to package gitolite:

  * Put the executable `gitolite` somewhere in PATH.  Put the executable
    `gitolite-shell` in /usr/libexec/gitolite (along with those 5 directories).

    Change the 2 assignments to `$ENV{GL_BINDIR}`, one in 'gitolite', one in
    'gitolite-shell', to "/usr/libexec/gitolite" from `$FindBin::RealBin`.
    This is equivalent to "make" embedding the exec-path into the executable.

    **OR**

    Put both executables `gitolite` and `gitolite-shell` also into
    /usr/libexec/gitolite (i.e., as siblings to the 5 directories mentioned
    above).  Then *symlink* `/usr/libexec/gitolite/gitolite` to some directory
    in the PATH.  Do not *copy* it; it must be a symlink.

    Gitolite will find the exec-path by following the symlink.

  * The `Gitolite` subdirectory in `/usr/libexec/gitolite/lib` can stay right
    there, **OR**, if your distro policies don't allow that, can be put in any
    directory in perl's `@INC` path (such as `/usr/share/perl5/vendor_perl`).

  * Finally, a file called `/usr/libexec/gitolite/VERSION` must contain a
    suitable version string.

