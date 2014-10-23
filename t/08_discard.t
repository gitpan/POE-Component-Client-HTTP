#! /usr/bin/perl
# $Id: 08_discard.t 213 2005-09-04 18:55:34Z rcaputo $
# -*- perl -*-
# vim: filetype=perl

use strict;
use warnings;

use Test::More tests => 1;

use POE;
use POE::Component::Client::HTTP;
use POE::Component::Server::TCP;
use HTTP::Request::Common qw(GET);
use Socket;

POE::Component::Client::HTTP->spawn(
 Alias => 'ua',
 Timeout => 1
);

POE::Session->create(
   inline_states => {
    _start => sub {
      my ($kernel) = $_[KERNEL];

      $kernel->alias_set('Main');

      # Spawn discard TCP server
      POE::Component::Server::TCP->new (
        Alias       => 'Discard',
        Address     => '127.0.0.1',
        Port        => 0,
        ClientInput => sub {}, # discard
        Started     => sub {
          my ($kernel, $heap) = @_[KERNEL, HEAP];
          my $port = (sockaddr_in($heap->{listener}->getsockname))[0];
          $kernel->post('Main', 'set_port', $port);
        }
      );
    },
    set_port => sub {
      my ($kernel, $port) = @_[KERNEL, ARG0];

      my $url = "http://127.0.0.1:$port/";

      $kernel->post(ua => request => response => GET $url);
      $kernel->delay(no_response => 10);
    },
    response => sub {
      my ($kernel, $rspp) = @_[KERNEL, ARG1];
      my $rsp = $rspp->[0];

      $kernel->delay('no_response'); # Clear timer
      ok($rsp->code == 408, "received error 408");
      $kernel->post(Discard => 'shutdown');
    },
    no_response => sub {
      my $kernel = $_[KERNEL];
      fail("didn't receive error 408");
      $kernel->post(Discard => 'shutdown');
    }
  }
);

POE::Kernel->run;
exit;
