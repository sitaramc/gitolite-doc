#!/usr/bin/perl

# a rather simple script to produce a single mkd file out of all the docs.
#
# the major effort is in coming up with the best sequence of MKD files for
# reading.  It's kinda subjective...

# typically run as `./1-page.pl`; produces "gitolite.mkd" (hardcoded)

open(STDOUT, ">", "gitolite.mkd");

my $out = '';
my $base;
my %map;

while (<DATA>) {
    if (/^include (\S+)$/) {
        $out .= one($1)
    } else {
        $out .= $_;
    }
}

sub one {
    my $mkd = shift;

    my $base = $mkd;
    $base =~ s(.*/)();
    $base =~ s(.mkd$)();

    my $out = '';

    # for each mkd
    for (`cat $mkd`) {

        # ignore internal HRs and TOCs
        next if /^----$/ or /^TOC$/;
        # add anchor to h1 lines that don't already have one
        s/^# (?!#)/# #$base /;
        # increase the outline level all through by 1
        s/^#/##/;
        # prefix all anchor texts with basename and remember the mapping
        $map{$2} = "$base-$2" if s/^(#+) #(\S+) /$1 #$base-$2 /;

        $out .= $_;
    }
    $out .= "\n\n----\n\n";

    return $out;
}

# apply the mapping to references [like][this] etc., although you have to fix
# [this][] to look like [this][this] for convenience.
$out =~ s/\[(\S+?)\]\[\]/[$1][$1]/g;
$out =~ s/\]\[(\S+?)\]/"][" . ( $map{$1} || $1 ) . "]"/ge;

print $out;

# note: ips, locking, progit, sskm, plus any mkds that belong to specific
# branches (cache, namespaces) are left out.

__DATA__

#title Gitolite docs in one big page

This contains **all** of gitolite's documentation in one page.  Useful for
people who'd rather Ctrl-F around than click around :-)

The page is loosely divided into the following sections:

1.  [introduction, quick links, basics, and emergency help][s1]
2.  [detailed install/setup and access rules][s2]
3.  [git-config, gitolite options, gitweb/daemon, and the rc file][s3]
4.  [wildcard repos, mirroring, and some other special features][s4]
5.  [smart http mode][s5]
6.  [customising gitolite with your own code][s6]
7.  [all things ssh][s7]
8.  [various odds and ends like how/why/who, regexes, and performance][s8]
9.  [everything to do with migration from v2][s9]

Please note that this is only the latest entry point to the documentation.
Others are:

  * the main page -- see link at the top
  * the "master table of contents" -- see link at the top
  * the graphical overviews: [basic][] and [advanced][]
  * a truly humungous index of all the section headings in *this* document
    appears at the end, cleverly moved there from its traditional place to
    avoid scaring people away!

Enjoy!

----

# #s1 basics, quick links, and help

include index.mkd
include testing.mkd
include qi.mkd
include user.mkd
include users.mkd
include repos.mkd
include groups.mkd
include emergencies.mkd
include WARNINGS.mkd

# #s2 detailed installation and access rules

include install.mkd
include setup.mkd
include clone.mkd
include syntax.mkd
include admin.mkd
include rules.mkd
include refex.mkd
include write-types.mkd

# #s3 the rc file, git-config, and options

include rc.mkd
include git-config.mkd
include options.mkd
include external.mkd

# #s4 wild repos, mirroring, and other features

include wild.mkd
include mirroring.mkd
include deleg.mkd
include special.mkd
include rare.mkd

# #s5 smart http

include http.mkd
include contrib/ssh-and-http.mkd

# #s6 customising gitolite

include cust.mkd
include non-core.mkd
include dev-notes.mkd
include vref.mkd
include triggers.mkd

# #s7 ssh

include extras/ssh.mkd
include extras/auth.mkd
include extras/glssh.mkd
include extras/sts.mkd
include contrib/putty.mkd

# #s8 odds and ends

include how.mkd
include why.mkd
include who.mkd
include g3why.mkd
include dev-status.mkd
include files.mkd
include extras/regex.mkd
include perf.mkd

# #s9 migration

include g2incompat.mkd
include g2migr-example.mkd
include g2migr.mkd
include gsmigr.mkd

**THE END**

----

TOC

[s1]: gitolite.html#s1
[s2]: gitolite.html#s2
[s3]: gitolite.html#s3
[s4]: gitolite.html#s4
[s5]: gitolite.html#s5
[s6]: gitolite.html#s6
[s7]: gitolite.html#s7
[s8]: gitolite.html#s8
[s9]: gitolite.html#s9
