# ABSTRACT: Email Server Worker

package Email::Sender::Server::Worker;
{
    $Email::Sender::Server::Worker::VERSION = '0.35';
}

use strict;
use warnings;

use Validation::Class;

set {

    roles => ['Email::Sender::Server::Base']

};

use Carp 'confess';
use File::Path 'mkpath';
use File::Slurp 'write_file';
use File::Spec::Functions 'curdir', 'catdir', 'catfile', 'splitdir';

use Email::Sender::Server::Message;
use Class::Date;

our $VERSION = '0.35';    # VERSION


has id => $$;

has workspace => sub {

    my $self = shift;

    $self->directory('worker', $self->id);

};

bld sub {

    my ($self) = @_;

    my $workspace = $self->workspace;

    unless (-d $workspace && -w $workspace) {

        confess "Couldn't find or access (write-to) the worker's workspace "
          . $workspace;

    }

    return $self;

};

sub process_message {

    my ($self, $data, $args) = @_;

    my $message = Email::Sender::Server::Message->new;

    if ($message->from_hash($data)) {

        $message->send;

        if ($args->{file}) {

            # ridiculously simple stupid logging

            my @audit = ();

            push @audit, "Date: " . Class::Date::now->string;

            push @audit, "To: " . $message->to;
            push @audit, "From: " . $message->from;
            push @audit, "Subject: " . $message->subject;

            push @audit, "File: " . $args->{file};

            push @audit, "Status: " . $message->status;

            if ($message->status =~ /failure/i) {

                push @audit,
                  "Errors: "
                  . $message->status eq 'Email::Sender::Failure::Multi'
                  ? join "\n", map { $_->message } $message->response->failure
                  : $message->response->message;

            }

            push @audit, "\n\n";

            # should we segmenting audit logs?
            # my @directory = ('logs');
            # push @directory, ($args->{file} =~ /\W?(\d{4})(\d{4})/);
            # push @directory, ($args->{file} =~ /([\w\-]+)\.msg$/) . '.log';

            write_file $self->filepath('delivery.log'), {

                binmode => ':utf8',
                append  => 1

              },
              join "\n", @audit;

        }

        if ($message->error_count) {

            $self->set_errors($message->get_errors);

            return 0;

        }

        return 1;

    }

    else {

        $self->set_errors($message->get_errors);

        return 0;

    }

}

1;
__END__

=pod

=head1 NAME

Email::Sender::Server::Worker - Email Server Worker

=head1 VERSION

version 0.35

=head1 SYNOPSIS

    # poll and process queued email messages
    
    use Email::Sender::Server::Worker;
    
    my $worker = Email::Sender::Server::Worker->new;
    
    $worker->process_messages;

=head1 DESCRIPTION

Email::Sender::Server::Worker is the email processing agent which fetches messages
from the data directory and performs some action on them, e.g. processing an email
and delivering it to its recipient(s).

=head1 AUTHOR

Al Newkirk <awncorp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by awncorp.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

