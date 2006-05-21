#!/usr/bin/perl
# $Id: Makefile.PL 254 2006-05-10 20:48:45Z woggle $

use strict;
use lib qw(./mylib);
use ExtUtils::MakeMaker;

# Touch CHANGES so it exists.
open(CHANGES, ">>CHANGES") and close CHANGES;

my %prereq = (
  'POE'             => 0.31,
  'HTTP::Request'   => 1.30,
  'HTTP::Response'  => 1.37,
  'URI'             => 1.24,
  'POE::Component::Client::Keepalive' => 0.0704,
);

# Write that makefile.
WriteMakefile(
  NAME         => 'POE::Component::Client::HTTP',
  AUTHOR       => 'Rocco Caputo <rcaputo@cpan.org>',
  ABSTRACT     => 'Non-blocking/concurrent HTTP queries with POE',
  VERSION_FROM => 'lib/POE/Component/Client/HTTP.pm',
  PREREQ_PM    => \%prereq,
  dist         => {
    COMPRESS   => 'gzip -9f',
    SUFFIX     => 'gz',
    PREOP      => (
      'svn-log.perl | tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES'
    ),
  },
);
