# setting up and using templates

----

This feature was added late September 2017, after 3.6.7.  In terms of
versioning, it will be part of 3.6.8, or you could just grab the latest from
github.

# overview

This feature describes a new method of specifying gitolite rules.

A "template" is a set of gitolite access rules with a name.  A gitolite
"expert" can setup a suitable set of templates, and then actual repos can use
one or more of these templates, according to their need.

A simple example will illustrate.  It's split into two parts.

First, the **template definitions**, where the rules comprising each template
are defined:

```gitolite
# (obligatory warning: the order of the following lines matters!)

repo @is_public
    R                           =   @all

repo @is_suspended
    -                           =   @all

repo @has_personal_refs
    RW+     dev/USER/           =   teamleads team
    -       dev/                =   @all
    RW+     refs/tags/dev/USER/ =   teamleads team
    -       refs/tags/dev/      =   @all

repo @has_releases
    RW      refs/tags/v[0-9]    =   release_managers
    -       refs/tags/v[0-9]    =   @all

repo @base
    RW+                         =   teamleads
    RW                          =   team
    R                           =   READERS
```

Next, you have the **template data** section (i.e., the lines between the
`begin` and `end` lines you see in the example below).  This is where you
declare actual repos (`foo` and `bar` below), giving each a set of one or more
templates it will **use**, and map users to any roles that the template may
require.

```gitolite
=begin template-data

repo foo = base is_public has_releases
    teamleads           =   sitaram
    team                =   dilbert wally
    READERS             =   ashok
    release_managers    =   alice

repo bar = base has_personal_refs
    teamleads           =   han
    team                =   luke chewie

=end
```

Notice that `foo` and `bar` use different sets of templates: `foo` is a
public-readable repo that controls who can push versioned tags (releases),
while `bar` is a basic repo which supports [personal branches][perbr].

# advantages

There are a few advantages with this approach:

1.  Maintaining access rules is much simpler.  Just choose an appropriate set
    of "template names", assign people to roles, and you're done.

    There's no need to understand the intricacies of gitolite's ruleset.  (The
    person who *wrote* the templates needs to, but not the person who is
    maintaining dozens of repos by merely *using* those templates).

    *Heck you can probably roll a nice GUI around this.  Finally!*

2.  Reduces boilerplate.  A good example is the "personal branches" one above
    -- why have each of those 4 lines in every repo if you can instead refer
    to the feature by name somehow

    A conf using this is often smaller, and definitely cleaner.

2.  Reduces possible errors.  This should follow from the previous point.  It
    is easy to make mistakes when changing something due to some new
    requirement.  Did you remember to put in the two "deny" rules in the
    personal branches example above?

    What if management decides to suspend pushes to one particular repo, and
    you best choice was to add a catch-all "deny everyone" rule.  Did you
    remember to put it at the top?  (If the templates are written as above
    (including the *order in which you see them*), all you have to do is add
    the word `is_suspended` somewhere in the list of templates that apply to
    repo `bar`.)

3.  Makes gitolite compile much faster, especially if you have thousands (or
    tens of thousands) of repos.

# how does it work?

## a repo and its users

The [wildcard](wild) repos feature already has a way to dissociate the actual
user names from the rule set in gitolite.conf.  For example, you can say

```gitolite
repo foo/..*
    C       =   @managers
    RW+     =   WRITERS
    R       =   READERS
    ...(etc.)...
```

This lets any "manager" create a repo whose name matches the pattern, then
assign arbitrary users to WRITERS and other roles using the [`perms`
command][perms].  These role assignments are stored in a simple text file
within the repository's bare directory (i.e., `~/repositories/$REPO.git`), so
they are specific to that repo, **not** common to all the repos matching that
pattern (as they would be if you listed the users in gitolite.conf directly).

In other words, we've taken the actual users (say alice, bob, etc) out of the
gitolite.conf file, and thus any changes to the users/roles no longer need to
involve gitolite.conf.

## a repo and its *rules*

In a "duh! Why didn't I think of this till now" moment, I realised I can do
the same for the *rules* that apply to a repo -- take that association out of
gitolite.conf.  That is what the `repo foo = [...list of templates...]` lines
are doing.

This list of templates is also stored in a plain text file just like the one
that contains the user/role mappings, and in the same directory.

# usage and syntax

First, you have to add all the new "roles" to the `ROLES` hash in
`~/.gitolite.rc`.  If you edit that file, you'll see two pre-created roles
`READERS` and `WRITERS`.  Using the same syntax (including the trailing
comma), add any other roles you would like to use.  In our example up at the
top, the role names are `team`, `teamleads`, and `release_managers`.

!!! danger ""
    Rolenames must start with a letter, and be made up of only alphanumeric
    characters and the underscore -- basically the same rules as a shell
    variable.

Next, you define the templates, in the right order.  This is the only order
that matters (not the order in which the templates are *used* in any
particular repo in the template-data section).

Thus, this is also the part that requires gitolite rules expertise, but it's
hopefully a one-time or once-in-a-while thing.  (Or you can ask on the mailing
list!)

Finally, you define actual repos in gitolite.conf as shown in the example
above (including the `=begin template-data` and `=end` lines).  For each repo,
you specify what templates it will use, and then you map actual users to the
role names from those templates.

A few additional points:

1.  Not all role names need to be mapped to users (for example, we did not
    assign any `READERS` to repo `bar`, even though the `base` template
    specifies that role).

2.  Within the gitolite.conf file, the placement of the template-data section
    does not matter.  (It's not even parsed by the conf compiler, which
    completely skips it.  It's processed by a new program that is run
    internally, and directly manipulates the gl-repo-groups and gl-perms
    files).

3.  You can even have multiple template-data sections, with normal
    gitolite.conf rules, group definitions, `config` and `option` lines, etc.,
    in between.  (That's why there's a begin *and* an end!)

    If you use `include` files, I strongly suggest -- in the interest of
    sanity -- that you do not let a template-data section cross over a file
    boundary (i.e., define the `begin` in one file, and the `end` in another).
    It will work, if you understand what order the files are picked up, but
    I'd still avoid such tricks if I were you!

4.  If you want to insert some rules for a repo that is defined in a
    template-data section, you need to be careful where you place it.

    Rules defined by templates are deemed to occur exactly where the template
    **definition** is.  So, speaking of repo foo, pretend that the line `repo @is_public`
    was replaced by `repo foo`, and similarly for `repo @has_releases` and
    `repo @base`.

    !!! note ""
        While we're on the subject, you can also pretend the role names on the
        right hand side of the rules are replaced by the actual user names you
        supplied in the template-data section.

    In the example above, say you wanted to insert a new rule for repo foo,
    which says that no one can rewind `master`, not even `teamleads`.

    Clearly, the rules you need are:

    ```gitolite
    repo foo
        RW  master      =   sitaram
        # notice we had to expand 'teamleads' from foo's definition in the
        # template-data section
        -   master      =   @all
    ```

    But where do you place them?  The answer is, *at least before the `base`
    template is defined*.  Otherwise, the `RW+` in the base template will kick
    in, and this restriction will fail to take effect.

    Having said that, I would rather add a new template to deal with this,
    placing it just before `repo @base`):

    ```gitolite
    repo @limits_master
        RW  master      =   teamleads
        -   master      =   @all
    ```

    and then add `limits_master` to the list of templates that `foo` uses.

    This has the advantages of being able to reuse that logic for other repos,
    but even more important, you're avoiding repeating the actual teamleads
    name(s) in more than one place!  (Potentially a huge future inconsistency
    if someone forgot to update both places when the teamleads change!)

5.  You can also do multiple repos in one shot, as well as repo groups:

    ```gitolite
    # before the '=begin' line
    @repogroup1 = r1 r2 r3
    ...
    ...
    ...

    =begin template-data
    repo foo bar @repogroup1 = base is_public has_releases
        ...
        ...
        ...
    =end
    ```

# bypassing gitolite.conf for *huge* sites

Some sites have all their access control information in a web-based system,
and generate gitolite.conf as needed.  If they have tens of thousands of
repos, this "generated" gitolite.conf becomes humongous, and slows down
compiles.  Worse, the more repos you have, the more churn you have in terms of
changes to users accesses, so you do more compiles per hour than a smaller
site, which only makes things worse!

With this feature, you can bypass gitolite.conf and directly create/update
those text files to change the users and rule-sets for a given repo.  It
doesn't even have to touch gitolite or gitolite.conf (assuming the templates
and roles are already defined in gitolite.conf and `~/.gitolite.rc` of
course!)

## generating the text files externally

The actual text files involved are very simple.  Remember these files go into
`~/repositories/$REPO.git` (or more accurately, `$(gitolite query-rc GL_REPO_BASE)/$REPO.git`).

For the example above, here's the file `gl-repo-groups` in repo foo:

    $ cat ~/repositories/foo.git/gl-repo-groups
    base is_public has_releases

As you can see, this text is just what is after the `=` sign in the `repo`
line in the template data section of gitolite.conf.

and the file `gl-perms` is:

    $ cat ~/repositories/foo.git/gl-perms
    teamleads           =   sitaram
    team                =   dilbert wally
    READERS             =   ashok
    release_managers    =   alice

Again, this text is exactly the same as in the gitolite.conf!

## creating new repos

Gitolite has no mechanism to create repos out of thin air, so if you don't
want to go via gitolite.conf, one way to do this is to add the following lines
to the conf file (one-time):

```gitolite
repo [a-zA-Z0-9].*
    C   =   gitolite-admin
```

and then, at the server, run this:

    GL_USER=gitolite-admin gitolite create foo/bar

That creates the repo, and you can now populate its `gl-perms` and
`gl-repo-groups` files.

# thanks to...

...pingou on irc, and the Fedora project, for having 42,000 repos in a conf
file over 560,000 lines long.  Which made me think about this real hard for
days, including two false starts (one of which I published and have just now
reverted, and one which was so kludgey I refuse to acknowledge it exists --
thank God I did not publish that!)

# miscellanea

This feature is not the same as [wild]() repos; repos here are created by the
gitolite admin or a server-side backend, *not* by a gitolite user.  (However,
this feature piggy-backs on a lot of the code for wild repos, adding just a
wee bit -- the "duh" comment earlier in this document -- to complete it).

[perms]: user#setget-additional-permissions-for-repos-you-created
[perbr]: user#personal-branches
[group]: conf#group-definitions
[accum]: conf#rule-accumulation

