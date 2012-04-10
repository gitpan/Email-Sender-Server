
package Email::Sender::Server::Controller;
{
    $Email::Sender::Server::Controller::VERSION = '0.40';
}

use strict;
use warnings;

use Validation::Class;

use utf8;

our $VERSION = '0.40';    # VERSION

has arguments => sub {
    [

        # command-line arguments

    ];
};

has commands => sub {
    {

        # command-line commands

        copy => {

            abstract => 'copy the ess executable',
            routine  => \&_command_copy,
            usage    => qq{
            
            command: copy
            
            valid arguments are:
               
                ess copy to:"..."    copies and renames the executable
            
            args syntax is :x for boolean and x:y for key/value
            
        }

        },

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

        testmail => {

            abstract => 'send emails as a test',
            routine  => \&_command_testmail,
            usage    => qq{
            
            command: test
            
            valid arguments are:
               
                ess testmail i:15       send 15 test messages
                
                ess testmail :text      reads text from stdin
                ess testmail :html      reads text from stdin
                
                ess testmail text:"..." set email body text
                ess testmail html:"..." set email body html
                
                ess testmail to:me\@abc.co from:you\@abc.co subject:test
            
            args syntax is :x for boolean and x:y for key/value
            
        }

        },

        version => {

            abstract => 'display version information',
            routine  => \&_command_version,
            usage    => qq{
            
            command: version
            
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

sub _command_copy {

    my ($self, $opts) = @_;

    my $to = $opts->{to} ||= 'new_ess';

    require "File/Copy.pm";
    require "Email/Sender/Server/Manager.pm";

    my $manager = Email::Sender::Server::Manager->new;

    File::Copy::copy($0, $manager->filepath('..', $to));
    File::Copy::move($manager->directory,
        $manager->directory('..', "$to\_data"));

    chmod 0755, $manager->filepath('..', $to);

    rmdir $manager->directory;

    exit print "ESS Executable Copied Successfully\n";

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

    $opts->{text} ||= '';
    $opts->{html} ||= '';

    if ($opts->{text} eq '1' xor $opts->{html} eq '1') {

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

    $manager->delegate_workload;

}

sub _command_status {

    my ($self, $opts) = @_;

    require "Email/Sender/Server/Manager.pm";

    my $manager = Email::Sender::Server::Manager->new;

    my $queued_count = @{$manager->message_filelist} || 0;

    print "ESS Qeueue has $queued_count Message(s)\n";

    sub count_files_in_directory {

        my ($directory) = @_;

        my @files = (glob "$directory/*.msg");

        my $count = scalar @files;

        my @sub_directories = grep {

            -d $_ && $_ !~ /\.+$/

        } glob "$directory/*";

        for my $directory (@sub_directories) {

            $count += count_files_in_directory($directory);

        }

        return $count;

    }

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

    my $passed_count = count_files_in_directory($manager->directory('passed'));

    my $failed_count = count_files_in_directory($manager->directory('failed'));

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

sub _command_testmail {

    my ($self, $opts) = @_;

    require "Email/Sender/Server/Client.pm";

    $opts->{text} ||= '';
    $opts->{html} ||= '';

    if ($opts->{text} eq '1' xor $opts->{html} eq '1') {

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

    $opts->{text} = <<'TEST' unless $opts->{text} || $opts->{html};

# text
The quick brown fox jumps over the ......

# random lorem
Lorem ipsum dolor sit amet, esse modus mundi id usu, dicit ....

# random l33t
1T y0ur kl1k c4n, be r35u|7z n0n-3N9l1sh c@N, t3H 1T 1n70 250m p1cz!

# random chinese
富士は日本一の山

TEST

    my $i = $opts->{i} || 1;
    my $x = 1;

    for (1 .. $i) {

        # pause per 10 submissions in an attempt to not overwhelm the system
        $x = 0 && sleep 5 if $i > $_ && $x == 10;

        my $client = Email::Sender::Server::Client->new;

        my @message = (
            to      => $opts->{to},
            from    => $opts->{from},
            subject => $opts->{subject} || "ESS Test Msg: #" . $_,
        );

        push @message, (text => $opts->{text}) if $opts->{text};

        push @message, (html => $opts->{html}) if $opts->{html};

        my $msg_id = $client->send(@message);

        $msg_id
          ? print "Processed email to: $message[1] - $msg_id\n"
          : print "Failed processing email: "
          . $client->errors_to_string . "\n";

    }

    exit print "ESS has processed $i test messages (hope everything is OK)\n";

}

sub _command_version {

    my ($self, $opts) = @_;

    require "Email/Sender/Server/Manager.pm";

    my $version = do {

        my $name    = "Email-Sender-Server (ESS)";
        my $version = '0.00';

        eval { $version = $Email::Sender::Server::Manager::VERSION };

        join " ", $name, $version || '0.00'

    };

    exit print "$version\n";

}

1;
