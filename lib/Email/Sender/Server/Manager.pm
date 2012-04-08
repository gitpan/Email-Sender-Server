# ABSTRACT: Email Server Manager

package Email::Sender::Server::Manager;
{
    $Email::Sender::Server::Manager::VERSION = '0.28';
}

use strict;
use warnings;

use Validation::Class;

use Carp 'confess';
use File::Copy 'move';
use File::Path 'mkpath';
use File::Spec::Functions 'splitdir', 'splitpath';
use Data::Dumper 'Dumper';
use Class::Date;
use IO::All;

use Email::Sender::Server::Message;
use Email::Sender::Server::Worker;

our $VERSION = '0.28';    # VERSION

set {

    roles => ['Email::Sender::Server::Base']

};


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

    my @workers = grep { !/^\./ } readdir $directory;

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


sub create_config {

    my ($self) = @_;

    my $cfg = $self->filepath("config");

    unless (-e $cfg) {

        open(my $file, ">:encoding(UTF-8)", $cfg)
          or confess "Couldn't find or access (write-to) the config file $cfg";

        # write config file template

        print $file Dumper {

            message => {

                from => '',

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

    while (my ($name, $value) = each(%input)) {

        $messenger->$name($value);

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

        open(my $file, ">:encoding(UTF-8)", $filepath)
          or confess
          "Couldn't find or access (write) the message file $filepath";

        $file->autoflush(1);

        print {$file} Dumper $message;

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

                        # segment storage in attempt to avoid filesystem
                        # directory size error

                        my @directory = ('passed');

                        push @directory, ($filename =~ /(\d{4})(\d{4})/);

                        push @directory, $filename;

                        move $filepath, $self->filepath(@directory);

                    }

                    else {

                        # move message to failed

                        my $filename = $self->message_filename($filepath);

                        # segment storage in attempt to avoid filesystem
                        # directory size error

                        my @directory = ('failed');

                        push @directory, ($filename =~ /(\d{4})(\d{4})/);

                        push @directory, $filename;

                        move $filepath, $self->filepath(@directory);

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

version 0.28

=head1 SYNOPSIS

    use Email::Sender::Server::Manager;
    
    my $manager = Email::Sender::Server::Manager->new;
    
    # create a list of Email::Sender::Server::Message attribute values
    
    my @message = (
        to      => '...',
        subject => '...',
        body    => '...',
    );
    
    # validate and record an email message
    
    $manager->create_work(@message);
    
    # delegate and process email messages
    
    $manager->process_workload; # blocking

=head1 DESCRIPTION

Email::Sender::Server::Manager is responsible for communicating messages between
the client, server and workers. Specifically, this class is responsible for
queuing and assigning email requests to worker processes for eventual delivery.

See L<Email::Sender::Server::Worker> for more information about that process.

=head1 ATTRIBUTES

=head2 spawn

The spawn attribute represents the number of workers to create when processing
the email queue. This attribute defaults to 3 (worker processes).

    use Email::Sender::Server::Manager;
    
    my $mgr = Email::Sender::Server::Manager->new(
        spawn => 10
    );

=head2 workers

The workers attribute contains an arrayref of worker process IDs. This value is
empty by default and is set internally by the process_workload() method.

    use Email::Sender::Server::Manager;
    
    my $mgr = Email::Sender::Server::Manager->new;
    
    $mgr->workers;

=head2 workspace

The workspace attribute contains the directory path to the queued ess_data
directory. 

    use Email::Sender::Server::Manager;
    
    my $mgr = Email::Sender::Server::Manager->new;
    
    $mgr->workspace;

=head1 METHODS

=head2 cleanup

The cleanup method restores the data directory to its initial state, re-queuing
any emails assigned to workers which haven't been processed yet.

    use Email::Sender::Server::Manager;
    
    my $mgr = Email::Sender::Server::Manager->new;
    
    $mgr->cleanup;

=head2 create_config

The create_config method writes a config file to the data directory unless one
exists. The config, if present, will be merge with L<Email::Sender::Server::Message>
attributes when messages are created (e.g. the create_work method).

    use Email::Sender::Server::Manager;
    
    my $mgr = Email::Sender::Server::Manager->new;
    
    $mgr->create_config;

... which creates a config file (e.g. in ./ess_data/config) containing:

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

... elsewhere in your codebase

    use Email::Sender::Server::Manager;
    
    my $mgr = Email::Sender::Server::Manager->new;
    
    # to, from, and transport taken from the config if not set
    
    $mgr->create_work(subject => '...', text => '...');

=head2 create_work

The create_work method writes a message file to the data directory queuing it to
be process by the next selected worker process. It returns the absolute path to
the queued email message unless message validation failed. 

    use Email::Sender::Server::Manager;
    
    my $mgr = Email::Sender::Server::Manager->new;
    
    my @message = (
        to      => '...',
        subject => '...',
        body    => '...',
    );
    
    my $filepath = $mgr->create_work(@message);
    
    unless ($filepath) {
        
        print $mgr->errors_to_string;
        
    }

=head2 process_workload

The process_workload method creates a number of worker processes based on the
spawn attribute, forks itself and blocks until shutdown.

    use Email::Sender::Server::Manager;
    
    my $mgr = Email::Sender::Server::Manager->new;
    
    $mgr->process_workload;

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

