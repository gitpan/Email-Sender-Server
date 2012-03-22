package Email::Sender::Server::Controller;
{
    $Email::Sender::Server::Controller::VERSION = '0.15';
}

use strict;
use warnings;

use Validation::Class;

our $VERSION = '0.15';    # VERSION

has arguments => sub {
    [

        # command-line arguments

    ];
};

has commands => sub {
    {

        # command-line commands

        clean => {

            abstract => 'cleanup the file system',
            routine  => \&_command_clean

        },

        config => {

            abstract => 'generate a config file',
            routine  => \&_command_config

        },

        email => {

            abstract => 'send an email real quick',
            routine  => \&_command_email

        },

        help => {

            abstract => 'display usage information',
            routine  => \&_command_help,
            hidden   => 1

        },

        start => {

            abstract => 'start processing the email queue',
            routine  => \&_command_start

        },

        start_background => {

            abstract => 'process the email queue in the background',
            routine  => \&_command_start_background,
            hidden   => 1

        },

        stop => {

            abstract => 'stop processing the email queue',
            routine  => \&_command_stop

        },

    };
};

fld command => {

    error      => "please use a valid command",
    required   => 1,
    max_length => 255,
    validation => sub {

        my ($self, $field, $params) = @_;

        unless (defined $self->commands->{$field->{value}}) {

            $self->error($field, $field->{error});

            return 0;

        }

        return 1;

      }

};

mth execute_command => {

    input => ['command'],
    using => sub {

        my ($self, @args) = @_;

        my $options = $self->parse_arguments;

        # execute the command

        my $command = $self->command;

        my $output = $self->commands->{$command}->{routine}->($self, $options);

        unless ($output) {

            my @errors =
              ("\nError while executing $0 command ($command):\n\n");

            $output = join "\n", @errors, $self->get_errors, "\n";

        }

        $output =~ s/^[ ]+//gm;
        $output =~ s/^\n +/\n/gm;
        $output =~ s/^\n{2,}/\n/gm;
        $output =~ s/\n+$/\n/;

        print $output, "\n";

      }

};

sub parse_arguments {

    my $self = shift;

    my @args = @{$self->arguments};

    my $params = {};

    # my $sequence = [];

    for (my $i = 0; $i < @args; $i++) {

        my $arg = $args[$i];

        if ($arg =~ /^:(.*)/) {

            $params->{$1} = 1;

        }

        elsif ($arg =~ /(.*):$/) {

            $params->{$1} = $args[++$i];

        }

        elsif ($arg =~ /([^:]+):(.*)$/) {

            $params->{$1} = $2;

        }

        else {

            # push @{$sequence}, $arg;

        }

    }

    return $params;

}

sub _command_clean {

    my ($self, $opts) = @_;

    system $0, "stop";

    require "Email/Sender/Server/Manager.pm";

    my $manager = Email::Sender::Server::Manager->new;

    $manager->cleanup;

    exit print "ESS Cleanup, Repair and Recovery Completed\n";

}

sub _command_config {

    my ($self, $opts) = @_;

    require "Email/Sender/Server/Manager.pm";

    my $manager = Email::Sender::Server::Manager->new;

    $manager->create_config;

    exit print "ESS Config File Generated To Override Defaults\n";

}

sub _command_email {

    my ($self, $opts) = @_;

    require "Email/Sender/Server/Client.pm";

    my $client = Email::Sender::Server::Client->new;

    # capture message body from stdin

    if ($opts->{text} xor $opts->{html}) {

        my @content = (<STDIN>);

        if (@content) {

            if ($opts->{text}) {

                $opts->{text} = join "", @content;

            }

            if ($opts->{html}) {

                $opts->{html} = join "", @content;

            }

        }

    }

    my $id = $client->send(%{$opts});

    if ($client->error_count) {

        $self->set_errors($client->get_errors);

        return;

    }

    exit print "Submitted Email for Processing (msg: $id)\n";

}

sub _command_help {

    my ($self, $opts) = @_;

    my $commands_string;

    my @commands = keys %{$self->commands};

    my @ordered = sort { $a cmp $b } @commands;

    my ($max_chars) = length(
        (

            sort   { length($b) <=> length($a) }
              grep { not defined $self->commands->{$_}->{hidden} }
              @commands

        )[0]
    );

    foreach my $name (@ordered) {

        if (defined $self->commands->{$name}->{hidden}) {

            next;

        }

        my $desc = $self->commands->{$name}->{abstract}
          || 'This Command has no Description';

        $commands_string
          .= "\t$name" . (" " x ($max_chars - length($name))) . "\t $desc\n";

    }

    return qq{
        
        usage: $0 COMMAND [ARGS]
        
        The currently registered commands are:
           
            $commands_string
        
        See '$0 help COMMAND' for more information on a specific command.
        
    }

}

sub _command_start {

    my ($self, $opts) = @_;

    my $pid = fork;

    exec $0, "start_background" unless $pid;

    exit print "Starting ESS Background Process (pid: $$)\n";

}

sub _command_start_background {

    my ($self, $opts) = @_;

    require "Email/Sender/Server/Manager.pm";

    my $manager = Email::Sender::Server::Manager->new;

    $manager->process_workload;

}

sub _command_stop {

    my ($self, $opts) = @_;

    require "Email/Sender/Server/Manager.pm";

    my $manager = Email::Sender::Server::Manager->new;

    my $flag_file = $manager->filepath('shutdown');

    open my $fh, ">", $flag_file;

    exit print "ESS Processing Shutdown Sequence Initiated\n";

}

1;
