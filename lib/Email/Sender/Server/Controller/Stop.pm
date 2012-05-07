package Email::Sender::Server::Controller::Stop;
{
    $Email::Sender::Server::Controller::Stop::VERSION = '0.50';
}

use Command::Do;

has abstract => 'stop processing the email queue';

=head1 NAME

ess-stop - stop processing the email queue

=head1 SYNOPSIS

    ess stop
    
This command instructs all workers to cease and desist from processing their
remaining messages, any messages remaining in a worker's individual queue will
be reaped and placed back in the management queue (pool).

=cut

sub run {

    my ($self) = @_;

    require Email::Sender::Server::Manager;

    my $manager = Email::Sender::Server::Manager->new;

    my $flag_file = $manager->filepath('shutdown');

    open my $fh, ">", $flag_file;

    exit print "ESS Processing Shutdown Sequence Initiated\n";

}

1;
