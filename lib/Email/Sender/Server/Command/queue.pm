package Email::Sender::Server::Command::queue;
{
    $Email::Sender::Server::Command::queue::VERSION = '0.01_01';
}

use strict;
use warnings;

use base 'Email::Sender::Server::Command';

use Email::Sender::Server::Worker;

sub abstract {

    'Process the Email Sender Server Queue'

}

sub actions {

    process => \&_process_queue,    # send emails

}

sub _process_queue {

    my ($self, $options) = @_;

    # poll and process queued email messages

    my $worker = Email::Sender::Server::Worker->new;

  CHECK:
    while (my $message = $worker->next_message) {

        my $status = $worker->deliver_message($message);

        # .. status is a Email::Sender::Success or Failure object

        if ("Email::Sender::Success" eq ref $status) {

            my $mail = $message->{message};

            $self->message("email #{mail->{id}} was delivered successfully "
                  . "to #{mail->{to}} from #{mail->{from}}");

        }

        else {

            my $mail = $message->{message};

            $self->message(
                    "email #{mail->{id}} failed delivery and was NOT sent "
                  . "to #{mail->{to}} from #{mail->{from}}");

        }

        sleep 5;

    }

    sleep 5;
    goto CHECK;

}

1;

__DATA__

=head1 NAME

ess-queue - Process the Email Sender Server Queue

=head1 USAGE

ess queue ACTION [OPTIONS]

=head1 DESCRIPTION

The ess command-line command *queue* is responsible for manipulating the stored
emails within the queue.

=head2 ACTIONS

=head3 process

    ess queue process

This action starts polling the queue for new messages and attemps to deliver
them based on the transport information in the config file.

=cut
