package Email::Sender::Server::Controller::Config;
{
    $Email::Sender::Server::Controller::Config::VERSION = '0.50';
}

use Command::Do;

has abstract => 'generate a config file';

=head1 NAME

ess-config - generate a config file

=head1 SYNOPSIS

    ess config
    
This command creates a perlish config file under the ESS data directory whose
configuration values will be used as default unless otherwise overridden.

=cut

sub run {

    my ($self) = @_;

    require Email::Sender::Server::Manager;

    my $manager = Email::Sender::Server::Manager->new;

    $manager->create_config;

    exit print "ESS Config File Generated To Override Defaults\n";

}

1;
