# ABSTRACT: Eventual Email Delivery System

package Email::Sender::Server;
{
    $Email::Sender::Server::VERSION = '0.10';
}

use strict;
use warnings;

use Validation::Class;

use Email::Sender::Server::Controller;

our $VERSION = '0.10';    # VERSION


sub run {

    my $self      = shift;
    my @arguments = @ARGV;

    @arguments = @_ unless @arguments;

    my $command = shift @arguments;

    $command ||= 'help';

    my $controller = Email::Sender::Server::Controller->new(
        command   => $command,
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

version 0.10

=head1 SYNOPSIS

    $ ess help

then ...

    $ ess start

then ...

    package main;
    
    # eventual emailer
    
    my $mailer  = Email::Sender::Server::Client->new;
    
    unless ($mailer->send(to => '...', subject => '...', body => '...')) {
        
        print $mailer->errors_to_string;
        
    }

=head1 DESCRIPTION

Email::Sender::Server is designed to provide a simple client API for sending
emails from your applications. It accomplishes this by separating the email
creation and delivery events, thus email delivery becomes eventual in-that email
messages are not required to be delivered immediately.

This is very much a work in-progress, more documentation soon to come, see
L<Email::Sender::Server> for common usage exmaples.

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

