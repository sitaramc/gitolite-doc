# "wild" repos (user created repos)

----

The wildrepos feature allows you to specify access control rules using regular
expression patterns, so you can have many actual repos being served by a
single set of rules in the config file.  The [regex](regex) can also include the
word `CREATOR` in it, allowing you to parametrise the name of the user
creating the repo.

# quick intro/example

If you're curious about the feature but you aren't sure if you want to read
the whole page, here's a very simple example.

This is what the admin added to the conf file:

```gitolite
@users = u1 u2 u3

repo foo/CREATOR/[a-z]..*
    C   =   u1 u2 u3
    RW+ =   CREATOR
    RW  =   WRITERS
    R   =   READERS
```

User 'u1' then runs `git clone git@host:foo/u1/bar`, creating the repo.
Notice the repo name matches the regex, if you substitute the user's name
for the word CREATOR.

This is the effective rule list for 'foo/u1/bar' immediately after the user
creates it:

```gitolite
repo foo/u1/bar
    RW+ =   u1
    RW  =   WRITERS
    R   =   READERS
```

Most of this is fixed, but the creator (user 'u1') *can* use the [perms][]
command to add other users as 'READERS' or 'WRITERS'.  For example he could
add 'u2' as a writer and 'u3' and 'u5' as readers:

[perms]: user#setget-additional-permissions-for-repos-you-created

This is the effective rule list that applies to the repo if he does that:

```gitolite
repo foo/u1/bar
    RW+ =   u1
    RW  =   u2
    R   =   u3 u5
```

Note that both these "effective rule lists" were created without touching the
actual conf file or any admin intervention.

And that's it for our quick intro example.  The rest of this page will explain
all this in much more detail.

# declaring wild repos in the conf file

Here's a slightly more detailed example, starting with what the admin puts in
the conf file:

```gitolite
@prof       =   u1
@TAs        =   u2 u3
@students   =   u4 u5 u6

repo    assignments/CREATOR/a[0-9][0-9]
    C   =   @students
    RW+ =   CREATOR
    RW  =   WRITERS @TAs
    R   =   READERS @prof
```

Note the "C" permission.  This is a standalone "C", which gives the named
users the right to *create a repo*.  <span class="gray">This is not to be confused with
the "RWC" permission or its variants described [elsewhere][write-types], which
are about creating *branches*, not *repos*.</span>

[write-types]: conf-2#appendix-1-different-types-of-write-operations

# (**user**) creating a specific repo

For now, ignore the special usernames READERS and WRITERS, and just create a
new repo, as user "u4" (a student):

    $ git clone git@server:assignments/u4/a12
    Initialized empty Git repository in /home/git/repositories/assignments/u4/a12.git/
    warning: You appear to have cloned an empty repository.

# a slightly different example

Here's how the same example would look if you did not want the CREATOR's name
to be part of the actual repo name.

```gitolite
repo    assignments/a[0-9][0-9]
    C   =   @students
    RW+ =   CREATOR
    RW  =   WRITERS @TAs
    R   =   READERS @prof
```

We haven't changed anything except the repo name regex.  This means that the
first student that creates, say, `assignments/a12` becomes the owner.
Mistakes (such as claiming a12 instead of a13) need to be rectified by an
admin logging on to the back end, though it's not too difficult.

You could also replace the C line like this:

        C   =   @TAs

and have a TA create the repos in advance.

# repo regex patterns

## regex pattern versus normal repo

Due to projects like `gtk+`, the `+` character is now considered a valid
character for an *ordinary* repo.  Therefore, a regex like `foo/.+` does not
look like a [regex](regex) to gitolite.  Use `foo/..*` if you want that.

Also, `..*` by itself is not considered a valid repo regex.  Try
`[a-zA-Z0-9].*`.  `CREATOR/..*` will also work.

## line-anchored regexes

A regex like

    repo assignments/S[0-9]+/A[0-9]+

would match `assignments/S02/A37`.  It will not match `assignments/S02/ABC`,
or `assignments/S02/a37`, obviously.

But you may be surprised to find that it does not match even
`assignments/S02/A37/B99`.  This is because internally, gitolite
*line-anchors* the given regex; so that regex actually becomes
`^assignments/S[0-9]+/A[0-9]+$` -- notice the line beginning and ending
metacharacters.

!!! warning "Side-note: contrast with refexes"

    Just for interest, note that this is in contrast to the [refexes][refex]
    for the normal "branch" permissions. Refexes are only anchored at the
    start; a regex like `refs/heads/master` actually can match
    `refs/heads/master01/bar` as well, even if no one will actually push such
    a branch!  You can anchor both sides if you really care, by using
    `master$` instead of `master`, but that is *not* the default for refexes.

[refex]: conf#the-refex-field

# roles

The words READERS and WRITERS are called "role" names.  The access rules in
the conf file decide what permissions these roles have, but they don't say
what users are in each of these roles.

That needs to be done by the creator of the repo, using the `perms` command.
You can run `ssh git@host perms -h` for detailed help, but in brief, that
command lets you give and take away roles to users.  [This][perms] has some
more detail.

## adding other roles

If you want to have more than just the 2 default roles, say something like:

You can add the new names to the ROLES hash in the [rc file](rc); see comments
in that file for how to do that.  Be sure to run the 2 commands mentioned
there after you have added the roles.

```gitolite
repo foo/..*
  C                 =   u1
  RW    refs/tags/  =   TESTERS
  -     refs/tags/  =   @all
  RW+               =   WRITERS
  RW                =   INTERNS
  R                 =   READERS
  RW+D              =   MANAGERS
```

### <font color="red">**IMPORTANT WARNING ABOUT THIS FEATURE**</font>

!!! danger ""

    Please make sure that none of the role names conflict with any of the user
    names or group names in the system.  For example, if you have a user
    called "foo" or a group called "@foo", make sure you do not include "foo"
    as a valid role in the ROLES hash.

You can keep things sane by using UPPERCASE names for roles, while keeping all
your user and group names lowercase; then you don't have to worry about this
problem.

## setting default roles

You can setup some default role assignments as soon as a new wild repo is
created.

Here's how:

  * Enable the 'set-default-roles' feature in the rc file by uncommenting it
    if it is already present or adding it to the ENABLE list if it is not.

  * Supply a set of default role assignments for a wild repo regex by adding
    lines like this to the repo config para:

        option default.roles-1  =   READERS @all
        option default.roles-2  =   WRITERS @senior-devs

This will then behave as if the [perms][] command was used immediately after
the repo was created to add those two role assignments.

If you want to simulate the old (pre v3.5) `DEFAULT_ROLE_PERMS` rc file
variable, just add them under a `repo @all` line.  (Remember that this only
affects newly created wild repos, despite the '@all' name).

## specifying owners

See the section on `OWNER_ROLENAME` in the [rc file page](rc).

# listing wild repos

In order to see what repositories were created from a wildcard, use the 'info'
command.  Try `ssh git@host info -h` to get help on the info command.

# deleting a wild repo

Run the whimsically named "D" command -- try `ssh git@host D -h` for more info
on how to delete a wild repo.  (Yes the command is "D"; it's meant to be a
counterpart to the "C" permission that allowed you to create the repo in the
first place).  Of course this only works if your admin has enabled the command
(gitolite ships with the command disabled for remote use).

# appendix 1: owner and creator

A wild repo is created by one specific user.  This user is usually called the
**creator** of the repo: his username is placed in a file called gl-creator in
the (bare) repo directory, any permissions given in the gitolite.conf file to
"CREATOR" will be applicable to this user, he is the only person who can give
permissions to other users (by running the 'perms' command), etc.

But, as I said in [this mail](https://groups.google.com/d/msg/gitolite/nFbnQuO0ztM/tXiVs5ah2bcJ):

```text
    Until about a year ago, Gitolite only knew the concept of a "creator", and
    there was only one.

    But then people started seeing the need for more than one "owner", because
    wild repos may be *created* by one person, but they often needed to be
    *administered* by one of several people.

    So now, even though large parts of the documentation probably conflate
    "creator" and "owner", you can see wild.html ([wild]) and rc.html ([rc])
    to actually understand how this larger group become the "owner".
```

<!--

# appendix 2: handing off the repo to someone else #TODO

-->
