# ABSTRACT: Email Server Manager

package Email::Sender::Server::Manager;
{
    $Email::Sender::Server::Manager::VERSION = '0.11';
}

use strict;
use warnings;

use Validation::Class;

set {

    roles => ['Email::Sender::Server::Base']

};

use Carp 'confess';
use File::Copy 'move';
use File::Path 'mkpath';
use File::Spec::Functions 'curdir', 'catdir', 'catfile', 'splitdir';
use Data::Dumper 'Dumper';
use Class::Date;

use Email::Sender::Server::Message;
use Email::Sender::Server::Worker;

our $VERSION = '0.11';    # VERSION


has spawn => 3;

has workers => sub {
    [

        # list of workers process IDs

    ];
};

has workspace => sub {

    my $self = shift;

    $self->directory('queued');

};

bld sub {

    my ($self) = @_;

    my $queue = $self->directory('queued');

    unless (-d $queue && -w $queue) {

        confess "Couldn't find or access (write-to) the server's queue "
          . $queue;

    }

    return $self;

};

sub cleanup {

    my $self = shift;

    # re-queue imcompleted work orders

    opendir my $directory, $self->directory('worker');

    my @workers = readdir $directory;

    foreach my $worker (@workers) {

        my @filelist = @{$self->message_filelist('worker', $worker)};

        foreach my $filepath (@filelist) {

            my $filename = $self->message_filename($filepath);

            move $filepath, $self->filepath('queued', $filename);

            unlink $filepath;

        }

        rmdir $self->directory('worker', $worker);

    }

    closedir $directory;

    # remove shutdown flag

    my $killer = $self->filepath('shutdown');

    unlink $killer if -e $killer;

    return $self;

}

sub create_work {

    my ($self, %input) = @_;

    my $messenger = Email::Sender::Server::Message->new;

    while (my ($name, $value) = each(%input)) {

        $messenger->param($name, $value);

    }

    my $message = $messenger->to_hash;

    if ($message) {

        my $filename = do {

            my $n = $message->{created};
            $n =~ s/\W//g;

            my $x = join "-", $n, $$;

            my $i = do {

                my @chars = ('a' .. 'z', '0' .. '9');

                join '',
                  $chars[rand @chars],
                  $chars[rand @chars],
                  $chars[rand @chars],
                  $chars[rand @chars]

            };

            "$x" . "-" . $i . ".msg"

        };

        my $filepath = $self->filepath('queued', $filename);

        open(my $file, '>', $filepath)
          or confess
          "Couldn't find or access (write) the message file $filepath";

        print $file Dumper $message;

        return $filepath;

    }

    else {

        $self->set_errors($messenger->get_errors);

        return 0;

    }

}

sub process_workload {

    my $self = shift;

    # delegate to workers (minions)

    my $i = $self->spawn || 1;

    for (1 .. $i) {

        my $pid = fork;

        if ($pid == 0) {

            my $worker = Email::Sender::Server::Worker->new(id => $$);

            while (1) {

                foreach my $filepath (@{$worker->message_filelist}) {

                    # print $worker->id, " is processing ", $filepath, "\n";

                    my $data = do $filepath;

                    if ($worker->process_message($data)) {

                        # move message to passed

                        my $filename = $self->message_filename($filepath);

                        move $filepath, $self->filepath('passed', $filename);

                    }

                    else {

                        # move message to failed

                        my $filename = $self->message_filename($filepath);

                        move $filepath, $self->filepath('failed', $filename);

                    }

                }

                last if $worker->stop_polling;

            }

            exit(0);

        }

        elsif ($pid) {

            push @{$self->workers}, $pid;

        }

        else {

            # to die or not to die ?
            die

        }

    }

    my $pid = fork;

    if ($pid == 0) {

        # delegate and process queued messages

        while (1) {

            foreach my $filepath (@{$self->message_filelist}) {

                # find suitable worker bee (currently at-random)

                my $random_worker = $self->workers->[rand(@{$self->workers})];

                my $filename = $self->message_filename($filepath);

                if ($filename) {

                    move $filepath,
                      $self->filepath('worker', $random_worker, $filename);

                }

              # print "manager handed-off work to worker $random_worker", "\n";

            }

            last if $self->stop_polling;

        }

        exit(0);

    }

    elsif (!$pid) {

        confess "Couldn't fork the manager's delegator, $!";

    }

    $SIG{INT} =
      sub { $self->cleanup; exit };    # always cleanup behind yourself !!!

    waitpid $_, 0 for (@{$self->workers}, $pid);    # blocking

    $self->cleanup;    # cleanup server environment

    exit               # return $self;

}

1;
__END__

=pod

=head1 NAME

Email::Sender::Server::Manager - Email Server Manager

=head1 VERSION

version 0.11

=head1 SYNOPSIS

    # record and delegate email message processing
    
    use Email::Sender::Server::Manager;
    
    my $manager = Email::Sender::Server::Manager->new;
    
    $worker->queue_message($message);
    
    $worker->process_queue;

=head1 DESCRIPTION

Email::Sender::Server::Manager is the liason between the client, server and
workers. This class is responsible for storing and processing messages through
workers, see L<Email::Sender::Server::Worker>.

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

