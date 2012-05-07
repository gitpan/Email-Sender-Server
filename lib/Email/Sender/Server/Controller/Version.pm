package Email::Sender::Server::Controller::Version;

use Command::Do;

has abstract => 'display version information';

=head1 NAME

ess-version - display version information

=head1 SYNOPSIS

    ess version

=cut

sub run {

    my $VERSION = '0.00';

    eval { $VERSION = $__PACKAGE__::VERSION if $__PACKAGE__::VERSION };

    exit print "Email-Sender-Server (ESS) $VERSION\n";

}

1;
