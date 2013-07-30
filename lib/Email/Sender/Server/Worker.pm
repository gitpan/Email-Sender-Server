# ABSTRACT: Email Server Worker

package Email::Sender::Server::Worker;

use Moo;
use utf8;

with 'Email::Sender::Server::Base';

use Carp 'confess';
use File::Path 'mkpath';
use File::Slurp 'write_file';
use File::Spec::Functions 'curdir', 'catdir', 'catfile', 'splitdir';

use Email::Sender::Server::Message;
use Class::Date;

our $VERSION = '1.000001'; # VERSION


has id => (
    is      => 'ro',
    default => $$
);

has workspace => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->directory('worker', $self->id);
    }
);

sub BUILD {
    my ($self) = @_;

    my $workspace = $self->workspace;

    unless (-d $workspace && -w $workspace) {
        confess "Couldn't find or access (write-to) the worker's workspace ".
            $workspace;
    }

    return $self;
}

sub process_message {
    my ($self, $data) = @_;

    my $message = Email::Sender::Server::Message->new($data);
       $message->send;

    return $message;
}

1;

__END__

=pod

=head1 NAME

Email::Sender::Server::Worker - Email Server Worker

=head1 VERSION

version 1.000001

=head1 SYNOPSIS

    use Email::Sender::Server::Worker;

    my $worker = Email::Sender::Server::Worker->new;

    my $message = $worker->process_message;

=head1 DESCRIPTION

Email::Sender::Server::Worker is the email processing agent which poll and
process queued email messages, fetches messages from the data directory and
performs some action on them, e.g. processing an email and delivering it to its
recipient(s).

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
