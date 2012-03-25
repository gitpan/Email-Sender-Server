package Email::Sender::Server::Controller;
{
    $Email::Sender::Server::Controller::VERSION = '0.20';
}

use strict;
use warnings;

use Validation::Class;

our $VERSION = '0.20';    # VERSION

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
            routine  => \&_command_clean,
            usage    => qq{
            
            command: clean
            
            args syntax is :x for boolean and x:y for key/value
            
        }

        },

        config => {

            abstract => 'generate a config file',
            routine  => \&_command_config,
            usage    => qq{
            
            command: config
            
            args syntax is :x for boolean and x:y for key/value
            
        }

        },

        email => {

            abstract => 'send an email real quick',
            routine  => \&_command_email,
            usage    => qq{
            
            command: email
            
            valid arguments are:
               
                ess email :text      reads text from stdin
                ess email :html      reads text from stdin
                
                ess email text:"..." set email body text
                ess email html:"..." set email body html
                
                ess email to:me\@abc.co from:you\@abc.co subject:test
                
            args syntax is :x for boolean and x:y for key/value
            
        }

        },

        help => {

            abstract => 'display usage information',
            routine  => \&_command_help,
            hidden   => 1

        },

        start => {

            abstract => 'start processing the email queue',
            routine  => \&_command_start,
            usage    => qq{
            
            command: start
            
            valid arguments are:
               
                ess start :w         starts ess with 1 worker
                ess start w:5        starts ess with 5 workers
                ess start workers:1  starts ess with 1 worker
                
            args syntax is :x for boolean and x:y for key/value
            
        }

        },

        start_background => {

            abstract => 'process the email queue in the background',
            routine  => \&_command_start_background,
            hidden   => 1

        },

        status => {

            abstract => 'display ess processing information',
            routine  => \&_command_status,
            usage    => qq{
            
            command: status
            
            args syntax is :x for boolean and x:y for key/value
            
        }

        },

        stop => {

            abstract => 'stop processing the email queue',
            routine  => \&_command_stop,
            usage    => qq{
            
            command: stop
            
            args syntax is :x for boolean and x:y for key/value
            
        }

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

        my ($options, $sequence) = $self->parse_arguments;

        # execute the command

        my $command = $self->command;

        my @params = ($self, $options, $sequence);

        my $output = $self->commands->{$command}->{routine}->(@params);

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

    my $sequence = [];

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

            push @{$sequence}, $arg;

        }

    }

    return $params, $sequence;

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

    my ($self, $opts, $args) = @_;

    my $commands_string;

    if ($args->[0]) {

        my $command = $args->[0];

        if ($self->commands->{$command}) {

            $commands_string = $self->commands->{$command}->{usage}
              if $self->commands->{$command}->{usage};

        }

    }

    unless ($commands_string) {

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
              .= "\t$name"
              . (" " x ($max_chars - length($name)))
              . "\t $desc\n";

        }

    }

    return qq{
        
        usage: $0 COMMAND [ARGS]
        
        The command(s) info is as follows:
           
            $commands_string
        
        See '$0 help COMMAND' for more information on a specific command.
        
    }

}

sub _command_start {

    my ($self, $opts) = @_;

    my $pid = fork;

    $opts->{workers} = delete $opts->{w} if $opts->{w};

    $opts->{workers} ||= 3;

    exec $0, "start_background", "w:$opts->{workers}" unless $pid;

    exit print "Starting ESS Background Process (pid: $$)\n";

}

sub _command_start_background {

    my ($self, $opts) = @_;

    require "Email/Sender/Server/Manager.pm";

    $opts->{workers} = delete $opts->{w} if $opts->{w};

    $opts->{workers} ||= 3;

    my $manager =
      Email::Sender::Server::Manager->new(spawn => $opts->{workers});

    $manager->process_workload;

}

sub _command_status {

    my ($self, $opts) = @_;

    require "Email/Sender/Server/Manager.pm";

    my $manager = Email::Sender::Server::Manager->new;

    my $queued_count = @{$manager->message_filelist} || 0;

    print "ESS Qeueue has $queued_count Message(s)\n";

    opendir my $workspace_hdl, $manager->directory('worker');

    my @workers = grep { !/^\./ } readdir $workspace_hdl;

    if (@workers) {

        print "ESS Currently Employs " . @workers . " Worker(s)\n\n";

        foreach my $worker (@workers) {

            my $count = @{$manager->message_filelist('worker', $worker)} || 0;

            print "\tESS Worker $worker is Processing $count Message(s)\n";

        }

        print "\n";

    }

    my $passed_count = @{$manager->message_filelist('passed')} || 0;
    my $failed_count = @{$manager->message_filelist('failed')} || 0;

    print "ESS has successfully processed $passed_count Message(s)\n";
    print "ESS has failed to process $failed_count Message(s)\n";

    exit;

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
