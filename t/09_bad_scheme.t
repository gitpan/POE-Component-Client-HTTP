#! /usr/bin/perl
# $Id: 09_bad_scheme.t 253 2006-05-10 05:20:55Z woggle $

# Test case for POE::Component::Client::HTTP dying outright when given
# bad schemes.

use strict;
use warnings;

use Test::More tests => 4;
use POE qw(Component::Client::HTTP);
use HTTP::Request::Common qw(GET);

POE::Component::Client::HTTP->spawn( Alias => 'ua' );

POE::Session->create(
	inline_states => {
		_start => sub {
			$_[KERNEL]->post(ua => request => good_response => GET 'http://poe.perl.org/');
			$_[KERNEL]->post(ua => request => bad_response => GET 'file://test/file.txt');
		},
		good_response => sub {
                        ok(defined $_[ARG1]->[0]->request, 'good response has a corresponding request object');
			$_[HEAP]->{good_response} = $_[ARG1]->[0]->code == 200;
		},
		bad_response => sub {
                        ok(defined $_[ARG1]->[0]->request, 'bad response has a corresponding request object');
			$_[HEAP]->{bad_response} = $_[ARG1]->[0]->code == 400;
		},
		_stop => sub {
			ok($_[HEAP]->{good_response}, 'got correct response for good scheme');
			ok($_[HEAP]->{bad_response}, 'got correct response for bad scheme');
		}
	}
);

POE::Kernel->run();
exit;
