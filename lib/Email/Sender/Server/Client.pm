# ABSTRACT: Email Delivery Agent

package Email::Sender::Server::Client;
{
    $Email::Sender::Server::Client::VERSION = '0.01_01';
}

use strict;
use warnings;

use Validation::Class;

set {base =>
      ['Email::Sender::Server::Base', 'Email::Sender::Server::Directives']
};

use DateTime;
use Try::Tiny;

our $VERSION = '0.01_01';    # VERSION


mxn basic => {

    required   => 1,
    max_length => 255,
    filters    => ['trim', 'strip']

};

mxn body => {

    required   => 1,
    min_length => 2,
    max_length => 255,
    filters    => ['trim', 'strip']

};

has attachments => sub {
    [


    ];
};

fld bcc => {

    mixin      => 'basic',
    min_length => 2,
    is_email   => '1+'

};

fld body => {

    mixin => 'body'

};

fld cc => {

    mixin      => 'basic',
    min_length => 2,
    is_email   => '1+'

};

has headers => sub {
    {

        'X-Mailer' => __PACKAGE__

    };
};

fld html => {

    mixin => 'body'

};

fld from => {

    mixin      => 'basic',
    min_length => 2,
    is_email   => 1

};

fld reply_to => {

    mixin      => 'basic',
    min_length => 2,
    is_email   => 1

};

fld subject => {

    mixin      => 'basic',
    min_length => 2

};

has tags => sub {
    [


    ];
};

fld text => {

    mixin => 'body'

};

fld to => {

    mixin      => 'basic',
    min_length => 2,
    is_email   => '1+'

};

pro sendable => sub {

    my ($self, @args) = @_;

    if ($self->html) {

        return 0 unless $self->validate('html');

    }

    if ($self->text) {

        return 0 unless $self->validate('text');

    }

    unless ($self->text || $self->html) {

        return 0 unless $self->validate('body');

    }

    return 0 unless $self->validate('+to', '+from', '+subject', '-cc', '-bcc');

    return 1;    # email looks sendable

};

mth send => {

    input => 'sendable',
    using => sub {

        my ($self, @args) = @_;

        # queue the email to be delivered
        my $db = $self->stash('database');

        try {

            $db->txn_do(
                sub {

                    my $msg = {

                        to      => $self->to,
                        from    => $self->from,
                        subject => $self->subject

                    };

                    $msg->{cc}  = $self->cc  if $self->cc;
                    $msg->{bcc} = $self->bcc if $self->bcc;

                    $msg->{reply_to} = $self->reply_to if $self->reply_to;

                    $msg->{body_html} = $self->html if $self->html;
                    $msg->{body_text} = $self->text if $self->text;
                    $msg->{body_html} = $self->body
                      if not $self->text || $self->html;

                    $msg->{created} = DateTime->now;

                    # create message
                    my $message = $db->resultset('Message')->create($msg);

                    # create headers
                    while (my ($name, $value) = each %{$self->headers}) {
                        $message->headers->create(
                            {name => $name, value => $value});
                    }

                    # create attachments
                    if (my @attachments = @{$self->attachments}) {

                        unless (2 % scalar(@attachments)) {

                            for (my $i = 0; $i < @attachments; $i++) {

                                my $file = {};

                                $file->{name}  = $attachments[$i];
                                $file->{value} = $attachments[++$i];

                                $message->attachments->create($file);

                            }

                        }

                    }

                    # create tags
                    $message->tags->create({name => $_}) for @{$self->tags};

                    return $message->id;

                }
            );

        }

        catch {

            $self->set_errors($_);

            return undef;

        };

      }

};

sub message {

    my ($self, %input) = @_;

    while (my ($name, $value) = each(%input)) {
        $self->param($name, $value);
    }

    $self->send;

}

1;
__END__

=pod

=head1 NAME

Email::Sender::Server::Client - Email Delivery Agent

=head1 VERSION

version 0.01_01

=head1 SYNOPSIS

    # sending email is simple
    
    my $mailer  = Email::Sender::Server::Client->new;
    
    my @message = (to => '...', subject => '...', body => '...');
    
    my $msg_id  = $mailer->message(@message); # non-blocking
    
    if ($mailer->error_count) {
        
        print $mailer->errors_to_string;
        
    }

=head1 DESCRIPTION

Email::Sender::Server::Client is the email delivery agent which passes messages
to the L<Email::Sender::Server> to be queued for delivery.

This class uses the L<Validation::Class> object system, please see that library
for more information on any foreign methods mentioned herewith.

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

