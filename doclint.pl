#!/usr/bin/perl
use strict;
use warnings;
use 5.10.0;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

@ARGV = qw(sidebar-toc);
my %bad;
my %done;
while (<>) {
    next unless /\[(.*?)\]\[(.*?)\]/;
    $done{ $2 || $1 } ++;
}

my @mkds = sort map { chomp; s(.*/)(); s(\.mkd$)(); $_ } `find . -name "*.mkd"`;
for (@mkds) {
    my $d = $done{$_} || '';
    delete $done{$_};
    next if $d and $d == 1;
    # MKDs which are defined 0 times or >1 times, both being considered "not good"
    $bad{$_} = $d || '';
}

say STDERR "MKDs not used or used multiple times:";
say STDERR Dumper \%bad;
say STDERR "non MKDs used multiple times:";
map { say STDERR "\t$_ => $done{$_}" } grep { $done{$_} != 1 } (sort keys %done);
