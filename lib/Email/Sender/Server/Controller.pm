package Email::Sender::Server::Controller;
{
    $Email::Sender::Server::Controller::VERSION = '0.50';
}

use strict;
use warnings;

use Command::Do;
set {classes => [__PACKAGE__]};

Getopt::Long::Configure(qw(pass_through));    # pass args to children

use utf8;

our $VERSION = '0.50';                        # VERSION

fld command => {

    error      => "please specify a valid command",
    required   => 1,
    max_length => 255,
    min_length => 2,
    filters    => ['trim', 'strip', sub { $_[0] =~ s/\W/\_/g; $_[0] }]

};

bld sub {

    my ($self) = @_;

    $self->command(shift @ARGV);

    return $self;

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

mth execute_command => {

    input => ['command'],
    using => sub {

        my ($self, @args) = @_;

        # execute the command

        my $command = $self->command;
        my $class   = $self->class($command) unless $command eq 'help';
        my $output  = '';

        if ($class) {

            $output = $class->run;

            unless ($output || not $class->error_count) {

                $output = "Error: " . $class->errors_to_string(", ");

            }

        }

        else {

            my $command = $self->command(shift @ARGV);

            if ($self->validate('command') && $command ne 'help') {

                # output help information

                my $class = $self->class($command);

                return unless $class;

                my $FILE = ref $class;

                $FILE =~ s/::/\//g;

                print "\n";

                system "pod2usage", "-verbose", 1, $INC{"$FILE.pm"};

                print "\n";

                exit;

            }

            else {

                my $commands_string = "";

                my ($ruler) = sort { length($b) <=> length($a) }
                  keys %{
                    ;
                      $self->proto->relatives
                  };

                $ruler = length $ruler;

                foreach my $class (
                    sort keys %{
                        ;
                          $self->proto->relatives
                    }
                  )
                {

                    my $command = $self->class($class);

                    $commands_string
                      .= "\t$class"
                      . (" " x (($ruler - length($class)) + 5))
                      . $command->abstract . "\n";

                }

                $output = qq{
                    
                    Usage: ess [command] [args]
                    
                    The command(s) info is as follows:
                       
                        $commands_string
                    
                    See 'ess help COMMAND' for more information on a specific command.
                    
                };

            }
        }

        if ($output) {

            $output =~ s/^[ ]+//gm;
            $output =~ s/^\n +/\n/gm;
            $output =~ s/^\n{2,}/\n/gm;
            $output =~ s/\n+$/\n/;

            print $output, "\n";

        }

      }

};

1;
