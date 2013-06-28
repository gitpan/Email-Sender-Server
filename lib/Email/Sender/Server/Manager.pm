# ABSTRACT: Email Server Manager

package Email::Sender::Server::Manager;

use Moo;
use utf8;

with 'Email::Sender::Server::Base';

use Carp 'confess';
use Data::Dumper 'Dumper';
use File::Copy 'move';
use File::Path 'mkpath';
use File::Spec::Functions 'splitdir', 'splitpath';
use File::Slurp 'write_file', 'read_file';
use Class::Date;

use Email::Sender::Server::Message;
use Email::Sender::Server::Worker;

$Data::Dumper::Useperl = 1;

our $VERSION = '1.000000'; # VERSION



has spawn => (
    is      => 'rw',
    default => 3
);


has workers => (
    is      => 'rw',
    default => sub {[
        # list of workers process IDs
    ]}
);


has workspace => (
    is      => 'rw',
    default => sub {
        shift->directory('queued');
    }
);


sub BUILD {
    my ($self) = @_;

    my $queue = $self->directory('queued');

    confess "Couldn't find or access (write-to) the server's queue $queue"
        unless -d $queue && -w $queue;

    return $self;
}


sub cleanup {
    my ($self) = @_;

    # re-queue imcompleted work orders

    opendir my $directory, $self->directory('worker');

    my @workers = grep { !/^\./ } readdir $directory;

    foreach my $worker (@workers) {
        my @filelist = @{ $self->message_filelist('worker', $worker) };

        foreach my $filepath (@filelist) {
            my $filename = $self->message_filename($filepath);

            move $filepath, $self->filepath('queued', $filename);

            unlink $filepath;
        }

        rmdir $self->directory('worker', $worker);
    }

    closedir $directory;

    # remove shutdown flag

    my $killer = $self->filepath('shutdown') ;

    unlink $killer if -e $killer;

    return $self;
}


sub create_config {
    my ($self) = @_;
    my $cfg = $self->filepath("config");

    unless (-e $cfg) {
        # write config file template
        write_file $cfg, {binmode => ':utf8'}, join "\n\n",
        '# see the Emailesque module for configuration options',
        'use utf8;',
        Dumper {
            message => {
                to          => undef,
                from        => undef,
                subject     => undef,
                cc          => undef,
                bcc         => undef,
                reply_to    => undef,
                message     => undef,
                type        => 'text'
            },
            transport => {
                Sendmail => {
                    sendmail => do {
                        my $path = `which sendmail`;
                           $path =~ s/[\r\n]//g;
                           $path || '/usr/sbin/sendmail';
                      }
                  }
              }
        };
    }

    return $self;
}


sub create_work {
    my ($self, %input) = @_;
    my $messenger = Email::Sender::Server::Message->new;

    while (my($name, $value) = each(%input)) {
        $messenger->$name($value);
    }

    my $message = $messenger->to_hash;

    if ($message) {
        my $filename = do {
            my $n = $message->{created}; $n =~ s/\W//g;
            my $x = join "-", $n, $$;
            my $i = do {
                my @chars = ('a'..'z','0'..'9');
                join '',
                    $chars[rand @chars],
                    $chars[rand @chars],
                    $chars[rand @chars],
                    $chars[rand @chars]
            };
            "$x" . "-" . $i . ".msg"
        };

        my $filepath = $self->filepath('queued', $filename);

        my $pid = fork();

        if ($pid == 0) {
            write_file $filepath, {binmode => ':utf8'}, join "\n\n",
            '# see the Emailesque module for configuration options',
            'use utf8;', Dumper $message;

            exit; # zombies will self-destruct
        }

        return $filepath if $pid;
    }

    return;
}


sub delegate_workload {
    my ($self) = @_;

    # delegate to workers (minions)

    my $i = $self->spawn || 1;

    for(1..$i) {
        my $pid = fork;

        if ($pid == 0) {
            my $worker = Email::Sender::Server::Worker->new(id => $$);

            while (1) {
                foreach my $filepath (@{ $worker->message_filelist }) {
                    my $data = do $filepath;

                    my $next_filepath;

                    my $message = $worker->process_message($data);

                    if ($message && ref($message->result) =~ /success/i) {
                        # move message to passed

                        my $filename = $self->message_filename($filepath);

                        # segment storage in attempt to avoid filesystem
                        # directory size error

                        my @directory = ('passed');

                        push @directory, ($filename =~ /\W?(\d{4})(\d{4})/);
                        push @directory, $filename;

                        move $filepath,
                            $next_filepath = $self->filepath(@directory);
                    }
                    else {
                        # move message to failed

                        my $filename = $self->message_filename($filepath);

                        # segment storage in attempt to avoid filesystem
                        # directory size error

                        my @directory = ('failed');

                        push @directory, ($filename =~ /\W?(\d{4})(\d{4})/);
                        push @directory, $filename;

                        move $filepath,
                            $next_filepath = $self->filepath(@directory);
                    }

                    # log outcome (real quick)

                    if ($next_filepath) {
                        # ridiculously simple stupid logging

                        my @audit = ();

                        push @audit, "Date: "    . Class::Date::now->string;
                        push @audit, "To: "      . $message->to;
                        push @audit, "From: "    . $message->from;
                        push @audit, "Subject: " . $message->subject;
                        push @audit, "File: "    . $next_filepath;
                        push @audit, "Status: "  . ref $message->result;

                        if (ref($message->result) =~ /failure/i) {
                            if (ref($message->result) =~ /multi/i) {
                                push @audit, "Errors: " . join ", ",
                                    map { $_->message }
                                    $message->result->failure;
                            }
                            else {
                                push @audit, "Errors: " .
                                    $message->result->message;
                            }
                        }

                        write_file $self->filepath('delivery.log'),
                            {binmode => ':utf8', append  => 1},
                            join "\n", "", @audit;
                    }
                }

                last if $worker->stop_polling;
            }

            exit(0);
        }
        elsif ($pid) {
            push @{ $self->workers }, $pid;
        }
        else {
            die # die you!
        }
    }

    my $pid = fork;

    if ($pid == 0) {
        # delegate and process queued messages

        while (1) {
            foreach my $filepath (@{ $self->message_filelist }) {
                # find suitable worker bee (currently at-random)

                my $random_worker =
                    $self->workers->[rand(@{ $self->workers })];

                my $filename = $self->message_filename($filepath);

                if ($filename) {
                    move $filepath,
                        $self->filepath('worker', $random_worker, $filename);
                }
            }

            last if $self->stop_polling;
        }

        exit(0);
    }

    elsif (! $pid) {
        confess "Couldn't fork the manager's delegator, $!" ;
    }

    # always cleanup behind yourself !!!
    $SIG{INT} = sub { $self->cleanup; exit };

    waitpid $_, 0 for (@{$self->workers}, $pid); # blocking

    $self->cleanup; # cleanup server environment

    exit # return $self;
}

1;

__END__

=pod

=head1 NAME

Email::Sender::Server::Manager - Email Server Manager

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

    use Email::Sender::Server::Manager;

    my $manager = Email::Sender::Server::Manager->new;

    # set some email message attributes
    my @message = (to => '...', subject => '...', body => '...');

    # record an email message
    $manager->create_work(@message);

    # delegate and process all recorded email messages
    $manager->process_workload; # blocking

=head1 DESCRIPTION

Email::Sender::Server::Manager is responsible for communicating messages between
the client, server and workers. Specifically, this class is responsible for
queuing and assigning email requests to worker processes for eventual delivery.
See L<Email::Sender::Server::Worker> for more information about email
processing.

=head1 ATTRIBUTES

=head2 spawn

The spawn attribute represents the number of workers to create when processing
the email queue. This attribute defaults to 3 (worker processes).

=head2 workers

The workers attribute contains an arrayref of worker process IDs. This value is
empty by default and is set internally by the process_workload() method.

=head2 workspace

The workspace attribute contains the directory path to the queued ess_data
directory.

=head1 METHODS

=head2 cleanup

The cleanup method restores the data directory to its initial state, re-queuing
any emails assigned to workers which haven't been processed yet.

=head2 create_config

The create_config method writes a config file to the data directory unless one
exists. The config, if present, will be merge with any existing email message
attributes, see L<Email::Sender::Server::Message> for more details, when the
messages are created.

    my $mgr = Email::Sender::Server::Manager->new;

    $mgr->create_config;

    # ... creates a config file (e.g. in ./ess_data/config) containing:

    use utf8;
    $VAR1 = {
        message {
            to   => '...',
            from => '...',
        },
        transport => {
            SMTP => {
                host => '...',
                port => '...'
            }
        }
    };

=head2 create_work

The create_work method writes a message file to the data directory queuing it to
be process by the next selected worker process. It returns the absolute path to
the queued email message.

    my $mgr = Email::Sender::Server::Manager->new;

    my @message  = (to => '...', subject => '...', body => '...');

    my $filepath = $mgr->create_work(@message);

    print "file has been queued" if -f $filepath;
    print "file has been processed" if -f $filepath;

=head2 delegate_workload

The delegate_workload method creates a number of worker processes based on the
spawn attribute, forks itself and blocks until shutdown.

    my $mgr = Email::Sender::Server::Manager->new;

    $mgr->delegate_workload; # blocking

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
