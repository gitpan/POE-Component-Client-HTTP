#!/usr/bin/perl -w
# $Id: 01_request.t,v 1.9 2002/07/10 02:30:19 rcaputo Exp $

use strict;

use HTTP::Request::Common qw(GET POST);

use lib '/home/troc/perl/poe';
sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE qw(Component::Client::HTTP);

sub DEBUG          () { 0 }
sub TEST_BIG_STUFF () { 0 }  # requires localhost:19

$| = 1;
print "1..5\n";

my @test_results = ( 'not ok 1', 'not ok 2', 'not ok 3', 'not ok 4',
                     'ok 5',
                   );

BEGIN {
  eval { require Net::SSLeay::Handle; };
  if ($@) {
    eval "sub HAS_SSL () { 0 }";
  }
  else {
    eval "sub HAS_SSL () { 1 }";
  }
}

#------------------------------------------------------------------------------

sub client_start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  DEBUG and warn "client starting...\n";

  $kernel->post( weeble => request => got_response =>
                 GET 'http://poe.perl.org/misc/test.html'
               );

  $kernel->post( weeble => request => got_response =>
                 ( POST 'http://poe.perl.org/misc/test.cgi',
                   [ cgi_field_one => '111',
                     cgi_field_two => '222',
                     cgi_field_six => '666',
                     cgi_field_ten => 'AAA',
                   ]
                 )
               );

  $kernel->post( weeble => request => got_response =>
                 GET 'http://poe.perl.org/misc/test.cgi?cgi_field_fiv=555',
               );

  if (HAS_SSL) {
    my $secure_request = GET 'https://sourceforge.net/projects/poe/';
    $kernel->post( weeble => request => got_response =>
                   $secure_request,
                 );
  }
  else {
    $test_results[3] = 'ok 4 # skipped: need Net::SSLeay::Handle to test SSL';
  }

  $kernel->post( weeble => request => got_response =>
                 GET 'http://poe.perl.org',
               );

  if (TEST_BIG_STUFF) {
    $kernel->post( weeble => request => got_response =>
                   GET 'http://127.0.0.1:19/'
                 );
  }
}

sub client_stop {
  DEBUG and warn "client stopped...\n";
  foreach (@test_results) {
    print "$_\n";
  }
}

sub client_got_response {
  my ($heap, $request_packet, $response_packet) = @_[HEAP, ARG0, ARG1];
  my $http_request  = $request_packet->[0];
  my $http_response = $response_packet->[0];

  DEBUG and do {
    warn "client got request...\n";

    my $response_string = $http_response->as_string();
    $response_string =~ s/^/| /mg;

    warn ",", '-' x 78, "\n";
    warn $response_string;
    warn "`", '-' x 78, "\n";
  };

  my $request_path = $http_request->uri->path . ''; # stringify

  if (defined $http_response->code) {
    if ($http_response->code == 200) {
      my $response_string = $http_response->as_string();
      $test_results[0] = 'ok 1' if $request_path =~ m/\/test\.html$/;
      $test_results[1] = 'ok 2' if $response_string =~ /cgi_field_six/;
      $test_results[2] = 'ok 3' if $response_string =~ /cgi_field_fiv/;
    }
    elsif ($http_response->code == 302) {
      my $response_string = $http_response->as_string();
      $test_results[3] = 'ok 4' if $response_string =~ /projects\/poe/;
    }
  }
  else {
    $test_results[4] = 'not ok 5';
  }
}

#------------------------------------------------------------------------------

# Create a weeble component.
POE::Component::Client::HTTP->spawn
  ( MaxSize => 4096,
    Timeout => 180,
  );

# Create a session that will make some requests.
POE::Session->create
  ( inline_states =>
    { _start       => \&client_start,
      _stop        => \&client_stop,
      got_response => \&client_got_response,
      _signal      => sub { 0 },
    }
  );

# Run it all until done.
$poe_kernel->run();

exit;
