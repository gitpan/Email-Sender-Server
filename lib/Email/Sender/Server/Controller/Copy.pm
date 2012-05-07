package Email::Sender::Server::Controller::Copy;
{
    $Email::Sender::Server::Controller::Copy::VERSION = '0.50';
}

use Command::Do;

has abstract => 'copy the ess executable';

=head1 NAME

ess-copy - copy the ess executable

=head1 SYNOPSIS

    ess copy [<executable_name>]
    
This command allows you to copy the ess executable from its default location to
the current working directory. Doing so allows you to tailor ESS on a
project-specific basis.

=cut

fld exe => {
    error      => "please specify a valid executable name",
    required   => 1,
    max_length => 255,
    filters    => ['trim', 'strip', sub { $_[0] =~ s/\W/\_/g; lc $_[0] }],
    default    => 'new_ess'
};

bld sub {
    shift->exe(shift @ARGV);
};

sub run {

    my ($self, $opts) = @_;

    my $exe = $self->exe;

    require File::Copy;
    require Email::Sender::Server::Manager;

    my $manager = Email::Sender::Server::Manager->new;

    File::Copy::copy($0, $manager->filepath('..', $exe));

    File::Copy::move($manager->directory,
        $manager->directory('..', "$exe\_data"));

    chmod 0755, $manager->filepath('..', $exe);

    rmdir $manager->directory;

    exit print "ESS Executable Copied Successfully\n";

}

1;
