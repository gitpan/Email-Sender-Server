package Email::Sender::Server::Controller::Start;
{
    $Email::Sender::Server::Controller::Start::VERSION = '0.50';
}

use Command::Do;

has abstract => 'start processing the email queue';

=head1 NAME

ess-start - start processing the email queue

=head1 SYNOPSIS

    ess start [--workers | -w]
    
This command spawns worker processes (defaults to 3) to validate and deliver
email messages stored in the queue.

=head1 OPTIONS

=head2 -w, --workers

The number of worker processes to spawn in order to efficiently process the email
queue. Please do not overload your system by spawning more processes than your
system can handle.

=cut

fld workers => {
    required => 1,
    filters  => ['trim', 'number'],
    alias    => ['w'],
    optspec  => 'n',
    default  => 3
};

mth run => {

    input => ['workers'],
    using => sub {

        my ($self) = @_;

        my $pid = fork;

        unless ($pid) {

            require Email::Sender::Server::Manager;

            my $manager =
              Email::Sender::Server::Manager->new(spawn => $self->workers);

            $manager->delegate_workload;

        }

        exit print "Starting ESS Background Process (pid: $$)\n";

      }

};

1;
