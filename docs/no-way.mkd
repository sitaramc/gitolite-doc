# no way!

----

For the entertainment of the sensible majority, and as a way of thanking all
of you, here are some examples of requests (demands in some cases) I have
received over the last couple of years.

  * deleting environment variables copied from client session

    demand: add code to delete certain environment variables at startup
    because "the openssh servers in the linux distribution that [he] use[s],
    are configured to copy `GIT_*` variables to the remote session".

    This is wrong on so many levels it's almost plonk-able!

  * using `cp` instead of `ln`

    Guy has an NTFS file system mounted on Linux.  So... no symlinks (an NTFS
    file system on Windows works fine because msysgit/cygwin manage to
    *simulate* them.  NTFS mounted on Linux won't do that!)

    He wanted all the symlink stuff to be replaced by copies.

    No. Way.

  * non-bare repos on the server

    Some guy gave me a complicated spiel about git-svn not liking bare repos
    or whatever.  I tuned off at the first mention of those 3 letters so I
    don't really know what the actual problem was.

    But it doesn't matter.  Even if someone (Ralf H) had not chipped in with a
    workable solution, I still would not do it.  A server repo should be bare.
    Period.

  * incomplete ownership of `GL_REPO_BASE`

    This guy had a repo-base directory where not all of the files were owned
    by the git user.  As a result, some of the hooks did not get created.  He
    claimed my code should detect OS-permissions issues while it's doing its
    stuff.

    No.  I refuse to have the code constantly look over its shoulder making
    sure fundamental assumptions are being met.

  * empty template directory

    (See man git-init for what a template directory is).

    The same guy with the environment variables had an empty template
    directory because he "does not like to have sample hooks in every
    repository".  So naturally, the hooks directory does not get created when
    you run a `git init`.  He expects gitolite to compensate for it.

    Granted, it's only a 1-line change.  But again, this falls under
    "constantly looking over your shoulder to double check fundamental
    assumptions".  Where does it end?

    [update 2014-07: I believe I read somewhere that git itself may be
    removing those "sample" hooks.  If that also means the hooks directory
    will not be created when you "git init --bare", then I guess I'd have to
    do something!]

