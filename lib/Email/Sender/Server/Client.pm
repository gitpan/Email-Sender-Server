# ABSTRACT: Email Delivery Agent

package Email::Sender::Server::Client;
{
    $Email::Sender::Server::Client::VERSION = '0.11';
}

use strict;
use warnings;

use Email::Sender::Server::Manager;

use Validation::Class;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(mail);

our $VERSION = '0.11';    # VERSION


sub mail { __PACKAGE__->new->send(@_) }

has path => '';

sub send {

    my ($self, %input) = @_;

    $ENV{ESS_DATA} = $self->path if $self->path;

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

version 0.11

=head1 SYNOPSIS

    # sending email is simple
    
    use Email::Sender::Server::Client 'mail';
    
    my @message = (to => '...', subject => '...', body => '...');
    
    my $mail = mail(@message);
    
    unless ($mail->error_count) {
        
        print $mail->id;
        
    }

or using an object-oriented approach ....

    use Email::Sender::Server::Client;
    
    my $mail = Email::Sender::Server::Client->new;
    
    my @message = (to => '...', subject => '...', body => '...');
    
    $mail->send(@message);
    
    if ($mail->error_count) {
        
        print $mail->errors_to_string;
        
    }

altering or using a non-sendmail transport ...

    use Email::Sender::Server::Client;
    
    my $mail = Email::Sender::Server::Client->new;
    
    my @message = (to => '...', subject => '...', body => '...');
    
    $mail->transport({
    
        # key is the Email::Sender transport driver,
        # value is the transport driver's arguments
        
        STMP => {
            
            host => '...',
            port => '...',
            
        }
    
    });
    
    $mail->send(@message);
    
    if ($mail->error_count) {
        
        print $mail->errors_to_string;
        
    }

Currently all ESS classes operate out of the current-working-directory which can
be sub-optimal, especially when used in other classes that can be utilized by
various different scripts.

The ESS_DATA environment variable can be set to change the path of the .ess
directory utilized by the current program, otherwise you may use the path
attribute.

    use Email::Sender::Server::Client;
    
    my $mail = Email::Sender::Server::Client->new(
        path => '/path/to/.ess-folder'
    );

=head1 DESCRIPTION

Email::Sender::Server::Client provides an interface to a non-blocking email
delivery agent which queues emails for later delivery.

Email::Sender::Server::Client wraps functionality provided by
L<Email::Sender::Server::Message>.

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

