#!/usr/bin/perl

use warnings;
use strict;

use HTTP::Cookies;
use HTML::Form;
use HTTP::Request::Common qw(GET POST);
use POE qw(Component::Client::HTTP);

POE::Component::Client::HTTP->spawn(
  Agent             => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows 98)',
  Alias             => 'uaa',
  Timeout           => 300,
  FollowRedirects   => 3,
);

POE::Session->create(
  package_states => [
    main => ["_start", "got_response", "_stop"]
  ]
);

POE::Kernel->run();
exit;

sub got_response {
  my ($heap, $request_packet, $response_packet, $kernel) =
    @_[HEAP, ARG0, ARG1, KERNEL];
  my $http_request = $request_packet->[0];
  my $subject      = $request_packet->[1][0];

  my $http_response = $response_packet->[0];
  print $http_response->as_string;
}

sub _start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $session = $kernel->get_active_session();
  my $request = {
    "title"  => ["CHRIS",],
    "action" => POST(
      "http://www.chriselectronics.com/inventory.cfm",
      [
        "whatToSearch"   => 1,
        "searchCriteria" => 'NRC04F1212TR',
      ],
    ),
  };

  $kernel->post(
    'uaa', 'request', 'got_response', $request->{action}, $request->{title}
  );
}

sub _stop {
  print "Stop\n";
}
