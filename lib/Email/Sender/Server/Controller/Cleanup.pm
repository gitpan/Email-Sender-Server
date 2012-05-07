package Email::Sender::Server::Controller::Cleanup;
{
    $Email::Sender::Server::Controller::Cleanup::VERSION = '0.50';
}

use Command::Do;

has abstract => 'cleanup the file system';

=head1 NAME

ess-cleanup - cleanup the file system

=head1 SYNOPSIS

    ess cleanup
    
This command will restore the ESS data directories to a pristine operational
state in the event of an unexpected shutdown or malfunction. Calling this
command will first stop all email processing, resuming must be done manually.

=cut

sub run {

    my ($self) = @_;

    system $0, "stop";    # stop all processing

    require Email::Sender::Server::Manager;

    my $manager = Email::Sender::Server::Manager->new;

    $manager->cleanup;

    exit print "ESS Cleanup, Repair and Recovery Completed\n";

}

1;
