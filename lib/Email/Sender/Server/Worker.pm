# ABSTRACT: Email Processing Agent

package Email::Sender::Server::Worker;
{
    $Email::Sender::Server::Worker::VERSION = '0.01_01';
}

use strict;
use warnings;

use Validation::Class;

set {base =>
      ['Email::Sender::Server::Base', 'Email::Sender::Server::Directives']
};

use DateTime;
use Try::Tiny;
use Email::MIME;
use File::Type;
use IO::All;
use Hash::Merge 'merge';
use Email::Sender::Simple 'sendmail';

our $VERSION = '0.01_01';    # VERSION


sub next_message {

    my ($self) = @_;

    # get the message next in line

    my $db = $self->stash('database');

    try {

        $db->txn_do(
            sub {

                my $message = $db->resultset('Message')->find(
                    {

                        attempt => 0,
                        status  => "queued",
                        worker  => undef

                    },
                    {

                        rows => 1

                    }
                );

                return undef unless $message;

                $message->worker($$);
                $message->status('pending');
                $message->attempt($message->attempt + 1);
                $message->updated(DateTime->now);

                $message->update;

                return $self->format_message($message);

            }
        );

    }

    catch {

        my $error = $_;

        $self->set_errors($_);

        return undef;

    };

}

sub format_message {

    my ($self, $message) = @_;

    return undef unless ref $message;

    my $outcome = {};
    my @fields  = ();


    @fields = qw/id to reply_to from cc bcc subject body_text body_html/;

    foreach my $field (@fields) {

        $outcome->{message}->{$field} = $message->$field();

    }

    if (my @headers = $message->headers->all) {

        foreach my $header (@headers) {

            push @{$outcome->{headers}}, {

                name  => $header->name,
                value => $header->value

            };

        }

    }

    if (my @attachments = $message->attachments->all) {

        foreach my $attachment (@attachments) {

            push @{$outcome->{attachments}}, {

                name  => $attachment->name,
                value => $attachment->value

            };

        }

    }

    if (my @tags = $message->tags->all) {

        push @{$outcome->{tags}}, $_->value for @tags;

    }

    return $outcome;

}

sub deliver_message {

    my ($self, $mail) = @_;

    return undef unless ref $mail;

    # merge config with hash_message

    $mail = merge $mail, $self->settings;

    # build the message

    my $id = $mail->{message}->{id};

    my @parts = ();

    if (defined $mail->{attachments}) {

        foreach my $attachment (@{$mail->{attachments}}) {

            my $filename = $attachment->{name};
            my $filepath = $attachment->{value};

            my $content_type = File::Type->new->mime_type($filepath);

            next unless $content_type;

            push @parts,
              Email::MIME->create(
                attributes => {
                    filename     => $filepath,
                    content_type => $content_type,
                    encoding     => "base64",
                    name         => $filename,
                },
                body => io($filepath)->all,
              );

        }

    }

    push @parts,
      Email::MIME->create(
        attributes => {
            content_type => 'text/plain',
            charset      => 'utf-8',
            encoding     => 'quoted-printable',
            format       => 'flowed'
        },
        body_str => $mail->{message}->{text_body}
      ) if $mail->{message}->{text_body};

    push @parts,
      Email::MIME->create(
        attributes => {
            content_type => 'text/html',
            charset      => 'utf-8',
            encoding     => 'quoted-printable',
        },
        body_str => $mail->{message}->{html_body}
      ) if $mail->{message}->{html_body};

    my $email = Email::MIME->create(
        header_str => [
            To      => $mail->{message}->{to},
            From    => $mail->{message}->{from},
            Subject => $mail->{message}->{subject}
        ],
        parts => [@parts],
    );

    if (defined $mail->{headers}) {

        foreach my $header (@{$mail->{headers}}) {

            $email->header_str_set($header->{name} => $header->{value});

        }

    }

    # fweeew, now for the delivery

    try {

        my $transport = (keys(%{$mail->{transport}}))[0];

        my $transporter = "Email::Sender::Transport::$transport";

        my $transporter_class = $transporter;

        $transporter_class =~ s/::/\//g;

        $transporter_class .= ".pm";

        require $transporter_class unless $INC{$transporter_class};

        my %transporter_args = %{$mail->{transport}->{$transport}};

        my $transporter_obj = $transporter->new(%transporter_args);

        my $status = sendmail $email, {

            from      => $mail->{message}->{from},
            transport => $transporter_obj

        };

        my $db = $self->stash('database');

        try {

            $db->txn_do(
                sub {

                    my $message =
                      $db->resultset('Message')->single({id => $id});

                    $message->worker(undef);
                    $message->status('delivered');
                    $message->updated(DateTime->now);

                    $message->update;

                    $message->logs->create(
                        {

                            report  => 'Email has been delivered successfully',
                            created => DateTime->now

                        }
                    );

                }
            );

        }

        catch {

            my $error = $_;

            $self->set_errors($_);

            return undef;

        };

        return $status;

    }

    catch {

        my $error = $_;

        $self->set_errors($_);

        my $db = $self->stash('database');

        try {

            $db->txn_do(
                sub {

                    my $message =
                      $db->resultset('Message')->single({id => $id});

                    $message->worker(undef);
                    $message->status('failed');
                    $message->updated(DateTime->now);

                    $message->update;

                    $message->logs->create(
                        {

                            report  => "Error sending email, " . $error,
                            created => DateTime->now

                        }
                    );

                }
            );

        }

        catch {

            my $error = $_;

            $self->set_errors($_);

            return undef;

        };

        return $error;

    };

}

1;
__END__

=pod

=head1 NAME

Email::Sender::Server::Worker - Email Processing Agent

=head1 VERSION

version 0.01_01

=head1 SYNOPSIS

    # poll and process queued email messages
    
    use Email::Sender::Server::Worker;
    
    my $worker = Email::Sender::Server::Worker->new;
    
    CHECK:
    while (my $message = $worker->next_message) {
        
        my $status = $worker->deliver_message($message);
        
        # .. status is a Email::Sender::Success or Failure object
        
        sleep 5;
        
    }
    
    sleep 5;
    goto CHECK;

=head1 DESCRIPTION

Email::Sender::Server::Worker is the email processing agent which fetches messages
from the Email::Sender::Server database and delivers them to their recipient(s).

This class uses the L<Validation::Class> object system, please see that library
for more information on any foreign methods mentioned herewith.

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

