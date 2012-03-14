
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Eventual Email Delivery System",
  "AUTHOR" => "Al Newkirk <awncorp\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Email-Sender-Server",
  "EXE_FILES" => [
    "bin/ess"
  ],
  "LICENSE" => "perl",
  "NAME" => "Email::Sender::Server",
  "PREREQ_PM" => {
    "DBIx::Class" => 0,
    "Data::Validate::Email" => 0,
    "DateTime" => 0,
    "Email::MIME" => 0,
    "Email::Sender" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::ShareDir" => 0,
    "File::Spec" => 0,
    "File::Type" => 0,
    "Getopt::Long" => 0,
    "Hash::Merge" => 0,
    "IO::All" => 0,
    "Try::Tiny" => 0,
    "Validation::Class" => "5.63"
  },
  "VERSION" => "0.01_01",
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

package
MY;
use File::ShareDir::Install qw(postamble);


