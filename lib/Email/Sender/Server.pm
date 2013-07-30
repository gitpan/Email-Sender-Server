# ABSTRACT: Eventual Email Delivery System

package Email::Sender::Server;

use Email::Sender::Server::Controller;

our $VERSION = '1.000001'; # VERSION



sub run {
    my ($command, @arguments) = @_ || @ARGV;

    my $controller = Email::Sender::Server::Controller->new(
        command   => $command || 'help',
        arguments => [@arguments]
    );

    $controller->execute_command;
}

1;

__END__

=pod

=head1 NAME

Email::Sender::Server - Eventual Email Delivery System

=head1 VERSION

version 1.000001

=head1 SYNOPSIS

    $ ess help start

then ...

    $ ess start

then ...

    package main;

    # eventual emailer
    my $mailer  = Email::Sender::Server::Client->new;
    my $receipt = $mailer->email(to => '...', subject => '...', body => '...');

maybe ...

    $ ess config

    # set some defaults in ./ess_data/ess.cfg

maybe ...

    $ tree ./ess_data/

    # ... peek behind the curtain

also, send email from the command-line ...

    $ ess email to:anewkirk@ana.io from:you@yoursite.com subject:Howdy ...

    # and/or pipe to stdin

    $ cat textfile.txt | ess email :text to:anewkirk@ana.io  ...

=head1 DESCRIPTION

Email::Sender::Server is designed to provide a simple API for sending emails
from your applications in a non-blocking fashion. It accomplishes this by
separating the email creation and delivery events, thus email delivery becomes
eventual in-that email messages are not required to be delivered immediately.

This is very much a work in-progress, more documentation soon to come, see
L<Email::Sender::Server::Client> for more usage exmaples.

=head1 METHODS

=head2 run

The run method is used to execute L<Email::Sender::Server::Controller> commands.
Most commands exit abruptly and prints to STDOUT. This method is intended to be
used by a command-line interface.

    use Email::Sender::Server;

    # start the server with 1 worker
    Email::Sender::Server::run('start', 'worker:1');

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
