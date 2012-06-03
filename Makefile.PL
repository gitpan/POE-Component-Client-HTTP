
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a HTTP user-agent component",
  "AUTHOR" => "Rocco Caputo <rcaputo\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "POE-Component-Client-HTTP",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "POE::Component::Client::HTTP",
  "PREREQ_PM" => {
    "HTTP::Headers" => "5.810",
    "HTTP::Request" => "5.811",
    "HTTP::Request::Common" => "5.811",
    "HTTP::Response" => "5.813",
    "HTTP::Status" => "5.811",
    "Net::HTTP::Methods" => "5.812",
    "POE" => "1.312",
    "POE::Component::Client::Keepalive" => "0.271",
    "Socket" => "2.001",
    "Test::More" => "0.96",
    "Test::POE::Server::TCP" => "1.14",
    "URI" => "1.37"
  },
  "VERSION" => "0.947",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



