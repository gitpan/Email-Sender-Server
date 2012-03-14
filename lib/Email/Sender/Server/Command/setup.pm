package Email::Sender::Server::Command::setup;
{
    $Email::Sender::Server::Command::setup::VERSION = '0.01_01';
}

use strict;
use warnings;

use base 'Email::Sender::Server::Command';

use Email::Sender::Server::Worker;
use Cwd;
use File::Copy;

sub abstract {

    'Setup a Local ESS Configuration'

}

sub actions {

    system => \&_setup_system,    # make local instance

}

sub _setup_system {

    my ($self, $options) = @_;

    my $worker = Email::Sender::Server::Worker->new;

    my $path = Cwd::getcwd;

    copy $worker->storage . ".tmp", "$path/ess_queue.db"
      or $self->error("Error copying ESS database: $!");

    copy $worker->script, "$path/ess_queue.db.sql"
      or $self->error("Error copying ESS database script: $!");

    copy $worker->storage . ".pl", "$path/ess_queue.db.pl"
      or $self->error("Error copying ESS database config: $!");

    return undef if $self->has_errors;

    $self->message("created new ESS system files at $path");

}

1;

__DATA__

=head1 NAME

ess-setup - Setup a Local ESS Configuration

=head1 USAGE

ess setup ACTION [OPTIONS]

=head1 DESCRIPTION

The ess command-line command *setup* is responsible for generating files and
performing various system setup and maintainence tasks.

=head2 ACTIONS

=head3 system

    ess setup system

This action creates a fresh instance of the ESS system in the current working
directory.

=cut
