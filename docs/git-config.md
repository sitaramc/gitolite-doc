# specifying "git-config" keys and values

----

<span class="gray">(Original version thanks to teemu dot matilainen at iki dot fi.)</span>

!!! danger ""

    **Important**: This won't work unless the rc file has the right settings;
    please see `$GIT_CONFIG_KEYS` in the [rc file doc](rc.md#specific-variables).

## basic syntax

The syntax is simple:

    config sectionname.keyname = value

For example:

```gitolite
repo gitolite
    config hooks.mailinglist = gitolite-commits@example.tld
    config hooks.emailprefix = "[gitolite] "
    config foo.bar = ""
```

This does either a plain "git config section.key value" (for the first 2
examples above) or "git config --unset-all section.key" (for the last
example).  Other forms of the `git config` command (`--add`, the
`value_regex`, etc) are not supported.

### <span class="red">an important warning about **deleting** a config line</span>

!!! danger ""

    Simply deleting the config line from the `conf/gitolite.conf` file will
    *not* delete the variable from `repo.git/config`.  You have to use the
    syntax in the last example to make gitolite execute a `--unset-all`
    operation on the given key.

## substituting the repo name and the creator name

You can also use the special values `%GL_REPO` and `%GL_CREATOR` in the
string.  The former is available to all repos, while the latter is only
available to [wild](wild.md) repos.

```gitolite
repo foo bar baz
    config hooks.mailinglist = %GL_REPO-commits@example.tld
    config hooks.emailprefix = "[%GL_REPO] "
```

## <span class="gray">(v3.6.7+)</span> expanding a group name

If you add

    EXPAND_GROUPS_IN_CONFIG     =>  1,

to the rc file (suggested location: just after the `GIT_CONFIG_KEYS` line),
then the *value* of a config line will have groupnames expanded.  For example:

```gitolite
@admins = sitaramc@gmail.com jdoe@example.com
...
repo foo
    ...
    config hooks.mailinglist = @admins
```

will behave as if the two email addresses were explicitly listed in the config
line.  However, if there is no such group, the text will be left as-is.  Also,
for safety, only word characters (alphanumerics and underscore) are expected
as part of the group name.

## overriding config values

You can repeat the 'config' line as many times as you like, and the *last*
occurrence will be the one in effect.  This allows you to override settings
just for one project, as in this example:

```gitolite
repo @all
    config hooks.mailinglist = %GL_REPO-commits@example.tld
    config hooks.emailprefix = "[%GL_REPO] "

... later ...

repo customer-project
    # different mailing list
    config hooks.mailinglist = announce@customer.tld
```

The "delete config variable" syntax can also be used, if you wish:

```gitolite
repo secret     # no emails for this one please
    config hooks.mailinglist = ""
    config hooks.emailprefix = ""
```

As you can see, the general idea is to place the most generic ones (`repo @all`,
or repo regex like `repo foo.*`) first, and place more specific ones
later to override the generic settings.

## compensating for UNSAFE\_PATT (and other patterns)

An important feature in gitolite is that you can share the admin load with
more people, **without** having to give all of them shell access on the
server.  Thus there are some restrictions designed to prevent someone who can
push the gitolite-admin repo, from somehow managing to run arbitrary commands
on the server.

This section is about one of these restrictions.

Gitolite, by default, does not allow the following characters in the value of
a config variable: `` ` ~ # $ & ( ) | ; < > ``.  This is due to unspecified
paranoia; see [this discussion][ud] for some context.  This restriction is
enforced by a regex called `UNSAFE_PATT`, whose default value is
``[`~#\$\&()|;<>]``.

[ud]: https://groups.google.com/d/topic/gitolite/9WNsA-Axmg4/discussion

But let's say you need to do this, which fails due to the semicolon.

```gitolite
    config hooks.showrev = "git show -C %s; echo"
```

There are two ways to fix this.

**If all your admins already have shell access**, you can override this by
placing a modified version in the rc file.  For our example, you'd just put
the following line at the **very end** of your rc file, just before the `1;`
line (notice there is no semicolon in the regex here):

    $UNSAFE_PATT          = qr([`~#\$\&()|<>]);

Similarly, you can remove other characters from that regex (to allow those
characters in your config values).

**If all your admins do not have shell access**, you need a more fine-grained
method:

  * In the rc file, add the following within the '%RC' hash (for example, just
    after the UMASK line would do fine):

        SAFE_CONFIG => {
            SHOWREV         =>  "git show -C %s; echo"
        },

  * In your gitolite.conf file, add this instead of the line we saw earlier:

```gitolite
    config hooks.showrev = %SHOWREV
```

This mechanism allows you to add any number of **specific** violations to the
`UNSAFE_PATT` rule instead of denaturing the regex itself and potentially
allowing something that could be (ab)used by a repo admin to obtain shell
access at some later point in time.

A similar problem arises with email addresses, which contain the `<` and `>`
characters.  Here's how to deal with that easily:

  * In the rc file:

        SAFE_CONFIG => {
            LT              =>  '<',
            GT              =>  '>',
        },

  * In the gitolite.conf file:

```gitolite
    config hooks.mailinglist = "Sitaram Chamarty %LTsitaramc@gmail.com%GT"
```

Admittedly, that looks a wee bit ugly, but it gets the job done without having
to remove angle brackets from UNSAFE\_PATT.

