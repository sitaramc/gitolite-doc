#!/usr/bin/perl
use strict;
use warnings;
use 5.10.0;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

@ARGV = qw(sidebar-toc);
my %done;
while (<>) {
    next unless /\[(.*?)\]\[(.*?)\]/;
    $done{ $2 || $1 } ++;
}

say "MKDs not used or used multiple times:";
my @mkds = sort map { chomp; s(.*/)(); s(\.mkd$)(); $_ } `find . -name "*.mkd"`;
for (@mkds) {
    my $d = $done{$_} || '';
    delete $done{$_};
    next if $d and $d == 1;
    # MKDs which are defined 0 times or >1 times, both being considered "not good"
    say "\t$_\t" . ($d ? $d : '');
}

say "non MKDs used multiple times:";
map { say "\t$_ => $done{$_}" } grep { $done{$_} != 1 } (sort keys %done);

__END__

type 1
    MKD is an L1 header in MTOC
    sub headers of that are part of same MKD
    one-to-one corr between subheadings in MTOC and in actual MKD
type 2
    MKD is an L2 header in MTOC
    parent is NOT a link at all but a top level collection

EVERY SINGLE MKD MUST BE IN THE MAIN TOC SOMEWHERE!!!
    Current exceptions (2014-07-13):
        g2migr-example
        glssh
        gsmigr
        progit
        rc-33
        sts
        why-v3
