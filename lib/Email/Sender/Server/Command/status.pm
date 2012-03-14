package Email::Sender::Server::Command::status;
{
    $Email::Sender::Server::Command::status::VERSION = '0.01_01';
}

use strict;
use warnings;

use base 'Email::Sender::Server::Command';

use Email::Sender::Server::Worker;

sub abstract {

    'Inspect the Email Delivery System'

}

sub actions {

    queued      => \&_count_queued,       # count remaining emails
      pending   => \&_count_pending,      # count in-progress emails
      delivered => \&_count_delivered,    # count processed emails
      failed    => \&_count_failed,       # count failed emails

}

sub _count_queued {

    my ($self, $options) = @_;

    my $server = Email::Sender::Server::Worker->new;

    my $db = $server->stash('database');

    my $count = $db->resultset('Message')->count({status => "queued"}) || 0;

    $self->message("$count message(s) queued.");

}

sub _count_pending {

    my ($self, $options) = @_;

    my $server = Email::Sender::Server::Worker->new;

    my $db = $server->stash('database');

    my $count = $db->resultset('Message')->count({status => "pending"}) || 0;

    $self->message("$count message(s) pending delivery.");

}

sub _count_delivered {

    my ($self, $options) = @_;

    my $server = Email::Sender::Server::Worker->new;

    my $db = $server->stash('database');

    my $count = $db->resultset('Message')->count({status => "delivered"}) || 0;

    $self->message("$count message(s) delivered.");

}

sub _count_failed {

    my ($self, $options) = @_;

    my $server = Email::Sender::Server::Worker->new;

    my $db = $server->stash('database');

    my $count = $db->resultset('Message')->count({status => "failed"}) || 0;

    $self->message("$count message(s) failed delivered.");

}

1;

__DATA__

=head1 NAME

ess-status - Inspect the Email Delivery System

=head1 USAGE

ess status ACTION [OPTIONS]

=head1 DESCRIPTION

The ess command-line command *status* is responsible for reporting email sending
metrics.

=head2 ACTIONS

=head3 pending

    ess status pending

This action reports the number of emails in-progress in the queue.

=head3 delivered

    ess status delivered

This action reports the number of delivered emails.

=head3 pending

    ess status queued

This action reports the number of undelivered emails remaining in the queue.

=head3 failed

    ess status failed

This action reports the number of emails that failed to be delivered.

=cut
