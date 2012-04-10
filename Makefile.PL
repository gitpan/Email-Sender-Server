
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Eventual Email Delivery System",
  "AUTHOR" => "Al Newkirk <awncorp\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Email-Sender-Server",
  "EXE_FILES" => [
    "bin/ess"
  ],
  "LICENSE" => "perl",
  "NAME" => "Email::Sender::Server",
  "PREREQ_PM" => {
    "Class::Date" => 0,
    "Data::Dumper" => 0,
    "Data::Validate::Email" => "0.04",
    "Email::MIME" => 0,
    "Email::Sender" => 0,
    "File::Basename" => 0,
    "File::Copy" => 0,
    "File::Path" => 0,
    "File::Slurp" => 0,
    "File::Spec" => 0,
    "File::Type" => 0,
    "IO::All" => 0,
    "Validation::Class" => "5.82",
    "utf8" => 0
  },
  "VERSION" => "0.36",
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



