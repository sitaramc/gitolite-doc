# Building the Documentation

## Summary

As of 2025-10, it is my intention to eventually move away from depending on
the specifics of any particular service (specifically, github pages or
anything else like it).  The gitolite documentation is now:

-   easy to build if you have mkdocs with the material theme, and pandoc
    -   pandoc is needed for [one specific file](how.html)).
    -   in addition, you'll also need vim and xterm.  I know this sounds weird
        but I wasn't able to easily enable gitolite.conf's syntax highlighting
        within mkdocs, so I kludged it.  See below for more on this
-   easy to view just by pointing a browser at the site that is built, or copy
    that entire directory as is to any web server you want to.

For convenience, with no promises of long term availability, it will also be
available at https://gitolite.com.

### Side note: why "move away from github"

First, I'm not deleting anything in github -- I'm only making my stuff **not**
dependent on github's features, beyond what the command line git client needs.
In fact, at the moment, gitolite.com is still being served by github pages.

The point is, it was always the intent that the documentation, once "built"
(by `mkdocs build`) would stand on its own.

But a few days ago I suddenly realised that this was not the case.  Many of
the links were broken, when I tried to access the "site" directly with a
browser, or put it behind some other web server.

It seems that github silently allows "URL/ending/in/foo" to resolve to
"URL/ending/in/foo.html" if "foo" does not exist but foo.html does.

Sure it's partly my fault for saying e.g., `[install](install)` instead of
`[install](install.md)`, but if I weren't using github I'd have realised this
long ago.

## Building the Docs

*   Make sure the tree is not dirty.  `cd` to the project root.
*   Run `bin/build`; takes a few seconds and **grabs the screen**, sorry!
    *   See the [Code highlight](#code-highlight) section below for more on this
*   Deploy `site/`

## Appendix A: Some mkdocs quirks

### Bad language guesses

It seems to be too hard to make it turn off its "guess the language"
pseudo-smartness when you use a plain indented code block.  And looking at the
mailing list archives does not give me much hope this will be fixed.  So
you're left with strange colors on some random words in many code blocks!

(I could fence each of them with an explicit language but I'm reluctant to do
that; plain markdown's plain indented code **should** be left plain, ideally!)

### `foo bar` split across lines

If a `foo bar` is split across lines due to vim formatting, the bloody output
also shows it split there.  My constant OCD to reformat all paras has taken a
hit, due to all these manually UN-formatted paragraphs.

### Code highlight

1.  the "codehilite" extension seems too complicated looking at the steps
    described in
    <https://pythonhosted.org/Markdown/extensions/code_hilite.html>

2.  in any case they don't recognise gitolite syntax.

So we just use the

    ```LANG
    ...code...
    ```

syntax and let our preprocessor fix things up using vim.  Kludgy, slow,
annoying (all those xterms -- I need to implement caching for this), but it
gets the job done with a minimum of fuss.  If you don't like it, just look
away from the screen for about 20 seconds ;-)

### Short anchors

can only be created like:

    <h1 id="dl">download</h1>

Using

    # <a id="dl" />download

causes some weird artefacts in the generated page.

At present I'm not using them at all; just using the long forms.

<!--

## notes

from <https://pythonhosted.org/Markdown/extensions/admonition.html>

    rST suggests the following types, but you’re free to use whatever you
    want: attention, caution, danger, error, hint, important, note, tip,
    warning.


## vim: set ft=markdown:
-->
