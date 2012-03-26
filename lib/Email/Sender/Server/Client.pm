# ABSTRACT: Email Delivery Agent

package Email::Sender::Server::Client;
{
    $Email::Sender::Server::Client::VERSION = '0.22';
}

use strict;
use warnings;

use Email::Sender::Server::Manager;

use Validation::Class;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(mail);

our $VERSION = '0.22';    # VERSION


sub mail {

    my %input = @_;

    my $self = __PACKAGE__->new;

    $ENV{ESS_DATA} = delete $input{'path'} if $input{'path'};

    my $manager = Email::Sender::Server::Manager->new;

    my $result = $manager->create_work(%input);

    $self->set_errors($manager->get_errors) if $manager->error_count;

    return $self, $result;

}


sub send {

    my ($self, %input) = @_;

    $ENV{ESS_DATA} = delete $input{'path'} if $input{'path'};

    my $manager = Email::Sender::Server::Manager->new;

    my $result = $manager->create_work(%input);

    $self->set_errors($manager->get_errors) if $manager->error_count;

    return $result;

}

1;
__END__

=pod

=head1 NAME

Email::Sender::Server::Client - Email Delivery Agent

=head1 VERSION

version 0.22

=head1 SYNOPSIS

    # sending email is simple
    
    use Email::Sender::Server::Client 'mail';
    
    my @message = (
        to      => '...',
        subject => '...',
        body    => '...',
    );
    
    my ($client) = mail @message;
    
    if ($client->error_count) {
        
        die $client->errors_to_string;
        
    }
    
    my ($client, $msg_id) = mail @message;
    
    unless ($msg_id) {
        
        die $client->errors_to_string;
        
    }

or using an object-oriented approach ....

    use Email::Sender::Server::Client;
    
    my $client = Email::Sender::Server::Client->new;
    
    my @message = (to => '...', subject => '...', body => '...');
    
    my $msg_id = $client->send(@message);
    
    if ($client->error_count) {
        
        print $client->errors_to_string;
        
    }

altering or using a non-sendmail transport ...

    use Email::Sender::Server::Client;
    
    my $client = Email::Sender::Server::Client->new;
    
    my @message = (to => '...', subject => '...', body => '...');
    
    push @message, 'transport' => {
    
        # key is the Email::Sender transport driver,
        # value is the transport driver's arguments
        
        STMP => {
            
            host => '...',
            port => '...',
            
        }
    
    };
    
    my ($msg_id) = $client->send(@message);
    
    unless ($msg_id) {
        
        print $client->errors_to_string;
        
    }

Please see the L<Email::Sender::Server::Message> class for attributes that can
be used as arguments to the mail() and send() methods.

Currently all ESS classes operate out of the current-working-directory which can
be sub-optimal, especially when used in other classes that can be utilized by
various different scripts.

The ESS_DATA environment variable can be set to change the path of the ess_data
directory utilized by the current program, otherwise you may use the path
parameter. When changing the path to the ess_data directory, please specify a path
to the parent directory and not the ess_data directory itself.

    use Email::Sender::Server::Client 'mail';
    
    # if you need to change the ess data directory
    
    push @message, path => '/path/to/ess/parent/folder' ;
    
    my ($client) = mail @message;

=head1 DESCRIPTION

Email::Sender::Server::Client provides an interface to the ESS non-blocking
email delivery system which queues emails for later delivery. This class is a
simple wrapper around the L<Email::Sender::Server::Manager> class, the manager
is responsible for queuing email messages and delegating tasks to the worker
processes. Note, All messages are validated by L<Email::Sender::Server::Message>.

=head1 EXPORTS

=head2 mail

The mail method is designed to provide a simple single method for sending emails
to the server. It accepts valid attributes accepted by
L<Email::Sender::Server::Message>. It returns a list of two elements, a client
object and the filepath of the queued message if the operation was successful.

    use Email::Sender::Server::Client 'mail';
    
    my @message = (
        to      => '...',
        subject => '...',
        body    => '...',
    );
    
    my ($client, $msg_id) = mail @message;
    
    unless ($msg_id) {
        
        die $client->errors_to_string;
        
    }

=head1 METHODS

=head2 send

The send method is designed to provide an object-oriented approach for sending
emails to the server. It accepts all valid attributes accepted by
L<Email::Sender::Server::Message>. It returns a the filepath of the queued
message if the operation was successful.

    use Email::Sender::Server::Client;
    
    my $client = Email::Sender::Server::Client->new;
    
    my @message = (to => '...', subject => '...', body => '...');
    
    my $msg_id = $client->send(@message);
    
    if ($client->error_count) {
        
        print $client->errors_to_string;
        
    }

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

