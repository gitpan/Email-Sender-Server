# ABSTRACT: Eventual Email Delivery System

package Email::Sender::Server;
{
    $Email::Sender::Server::VERSION = '0.01_01';
}

use strict;
use warnings;

our $VERSION = '0.01_01';    # VERSION


#use Email::Sender::Server;
#
#my ($cmd, $rtn) = Email::Sender::Server->run('worker', 'run');
#
#if (ref $cmd) {
#
#    # ...
#
#}

sub run {

    my $class = shift;

    my @args = @ARGV;

    @args = @_ unless @args;

    my $args = [];
    my $opts = {};
    my $cmds = $class->commands;

    my $goto = shift @args;

    if ($goto) {

        if (defined $cmds->{$goto}) {

            my $class = $cmds->{$goto};

            require $class->{path} unless $INC{$class->{used}};

            my $package = $class->{name};

            my $command = $package->new(commands => $cmds);

            my $results = $command->run(@args) || '';

            return ($command, $results);

        }

        if ($goto eq 'help') {

            my $cmd = shift @args;

            if ($cmd) {

                if (defined $cmds->{$cmd}) {

                    my $class = $cmds->{$cmd};

                    require $class->{path} unless $INC{$class->{used}};

                    my $package = $class->{name};

                    my $command = $package->new(commands => $cmds);

                    return ($command, $command->usage())
                      if $command->can("usage");

                }

            }

        }

    }

    print <<"DEFAULT";
usage: $0 COMMAND [ARGS]

The currently installed commands are:
   
DEFAULT

    my @cmd_names = keys %{$cmds};

    my @ordered_cmds = sort { $a cmp $b } @cmd_names;

    my ($max_chars) =
      length((sort { length($b) <=> length($a) } @cmd_names)[0]);

    foreach my $name (@ordered_cmds) {

        my $class = $cmds->{$name};

        require $class->{path} unless $INC{$class->{used}};

        my $package = $class->{name};

        my $desc =
          (defined &{"$package\::abstract"})
          ? $package->abstract()
          : 'This command has no description';

        print "\t$name" . (" " x ($max_chars - length($name))) . "\t $desc\n";

    }

    print <<"DEFAULT";

See '$0 help COMMAND' for more information on a specific command.
DEFAULT

}

sub commands {

    my $class = ref $_[0] || $_[0];

    my $cmds = {};

    my $cmds_dir = $class;
    $cmds_dir =~ s/::/\//g;
    $cmds_dir .= "/Command";

    foreach my $location (@INC) {

        my $path = "$location/$cmds_dir";

        foreach my $module (glob "$path/*.pm") {

            my ($command) = $module =~ /$path\/([a-zA-Z0-9]+)\.pm$/;

            unless (defined $cmds->{$command}) {

                $cmds->{$command} = {
                    path => $module,
                    name => "$class\::Command\::$command",
                    used => "$cmds_dir/$command.pm"
                };

            }

        }

    }

    return $cmds;

}

1;
__END__

=pod

=head1 NAME

Email::Sender::Server - Eventual Email Delivery System

=head1 VERSION

version 0.01_01

=head1 SYNOPSIS

    $ ess setup system

then ...

    $ nohup ess queue process &

then ...

    package main;
    
    my $ess_dbpath = "...";
    
    my $mailer  = Email::Sender::Server::Client->new(storage => $ess_dbpath);
    
    my @message = (to => '...', subject => '...', body => '...');
    
    # non-blocking email sending
    
    unless ($mailer->message(@message)) {
        
        print $mailer->errors_to_string;
        
    }

=head1 DESCRIPTION

Email::Sender::Server is designed to provide a simple client API for sending
emails from your applications. It accomplishes this by separating the email
creation and delivery events, thus email delivery becomes eventual in-that email
messages are not required to be delivered immediately.

ESS is an acronym for the Email::Sender::Server system and refers to the entire
system and not a specific component within the system. ESS is an EDS (eventual
email delivery system) which means email messages are not usually delivered
immediately.

More documentation to come ...

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

