# $Id: 04_chunk_filter.t 200 2005-08-02 14:24:42Z rcaputo $
# vim: filetype=perl

use strict;
use warnings;

use Test::More tests => 9;
sub DEBUG () { 0 }

use POE qw(
  Wheel::ReadWrite
  Driver::SysRW
  Filter::Line
  Filter::Stream
  Filter::HTTPHead
  Filter::HTTPChunk
);

ok (defined $INC{"POE/Filter/HTTPChunk.pm"}, "loaded");

use IO::File;

my $chunk_count = 1;

my $session = POE::Session->create(
  inline_states => {
    _start  => \&start,
    input   => \&input,
    error   => \&error,
    flushed => \&flushed,
    _stop   => \&parser_tests,
  },
);

autoflush STDOUT 1;
POE::Kernel->run();
exit;

sub start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  my $filter = POE::Filter::HTTPHead->new;

  sysseek(DATA, tell(DATA), 0);

  my $wheel = POE::Wheel::ReadWrite->new(
    Handle      => \*DATA,
    Driver      => POE::Driver::SysRW->new(BlockSize => 100),
    InputFilter => $filter,
    InputEvent  => 'input',
    ErrorEvent  => 'error',
  );
  $heap->{'wheel'} = $wheel;
}

sub input {
  my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];
  DEBUG and warn $data;
  if ($heap->{wheel}->get_input_filter->isa('POE::Filter::HTTPHead')) {
    if (UNIVERSAL::isa ($data, 'HTTP::Response')) {
      my $te = $data->header('Transfer-Encoding');
      my @te = split(/\s*,\s*/, lc($te));
      $te = pop(@te);
      DEBUG and warn "transfer encoding $te";
      if ($te eq 'chunked') {
        $heap->{wheel}->set_input_filter(POE::Filter::HTTPChunk->new);
      }
      else {
        $heap->{wheel}->set_input_filter(POE::Filter::Line->new);
      }
    }
    elsif (DEBUG) {
      warn "not a response\n";
    }
  }
  elsif ($heap->{wheel}->get_input_filter->isa('POE::Filter::HTTPChunk')) {
    if (UNIVERSAL::isa ($data, 'HTTP::Headers')) {
      if ($chunk_count == 3) {
        is(scalar $data->header_field_names, 1, "Got trailer 'header'");
      }
      if ($chunk_count == 5) {
        is(scalar $data->header_field_names, 0, "no trailer 'headers'");
      }
      $heap->{wheel}->set_input_filter (POE::Filter::HTTPHead->new);
    }
    else {
      my $content = "chunk " . $chunk_count x $chunk_count;
      is ($data, $content, "correct chunk");
      $chunk_count++;
    }
  }
}

sub error {
  my $heap = $_[HEAP];
  my ($type, $errno, $errmsg, $id) = @_[ARG0..$#_];

  is ($errno, 0, "Got EOF");

  delete $heap->{wheel};
}

sub parser_tests {
  my $f = POE::Filter::HTTPChunk->new();

  # Yuri Karaban discovered that chunk lengths with trailing
  # whitespace were not being recognized.  The result was responses
  # with empty content.
  #
  # TODO - Make this data driven when we get more test cases.
  $f->get_one_start(
    [
      "d\n",
      "regular chunk\n",
      "25   \t   \n",
      "chunk length with trailing whitespace",
      "0\n",
    ],
  );

  my $result = $f->get_one();
  is_deeply(
    $result, [
      "regular chunk",
      "chunk length with trailing whitespace"
    ],
    "chunk length with trailing whitespace"
  );
}

__DATA__
HTTP/1.1 200 OK
Date: Thu, 11 Nov 2004 19:43:00 GMT
Transfer-Encoding: chunked
Content-Type: text/plain

7
chunk 1
CRAP
8
chunk 22
0
Server: Apache/1.3.31 (Unix) DAV/1.0.3 mod_gzip/1.3.26.1a PHP/4.3.5 mod_ssl/2.8.19 OpenSSL/0.9.6c

HTTP/1.1 200 OK
Date: Thu, 11 Nov 2004 19:43:00 GMT
Server: Apache/1.3.31 (Unix) DAV/1.0.3 mod_gzip/1.3.26.1a PHP/4.3.5 mod_ssl/2.8.19 OpenSSL/0.9.6c
Transfer-Encoding: chunked
Content-Type: text/plain

9
chunk 333
A
chunk 4444
0

