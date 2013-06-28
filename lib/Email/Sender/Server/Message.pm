# ABSTRACT: Eventual Email Message Object

package Email::Sender::Server::Message;

use Moo;
use utf8;

with 'Email::Sender::Server::Base';

use Class::Date;
use Emailesque;

our $VERSION = '1.000000'; # VERSION


my @attributes = qw(
    to
    from
    subject
    cc
    bcc
    reply_to
    headers
    attachments
    message
    type
    tags
    transport
    result
);

has \@attributes => (
    is => 'rw'
);

sub BUILDARGS {
    my ($class, @args) = @_;

    my %args = @args % 2 == 1 ?
        'HASH' eq ref $args[0] ?
            %{$args[0]} : () : @args;

    if ($args{message} && ref $args{message}) {
        if (exists $args{message}{message}) {
            for (@attributes) {
                next if $_ eq 'message';
                $args{$_} = $args{message}{$_}
                    if $args{message}{$_};
            }
            $args{message} = $args{message}{message};
            for (keys %args) {
                delete $args{$_} unless $class->can($_);
            }
        }
    }

    return \%args;
}

sub BUILD {
    my ($self) = @_;

    # set defaults from config file

    my $config = $self->filepath('config');

    if (-e $config) {
        my $data = do $config;

        return $self unless "HASH" eq ref $data ;

        $self->to($data->{message}->{to})
            if $data->{message}->{to} && ! $self->to;

        $self->from($data->{message}->{from})
            if $data->{message}->{from} && ! $self->from;

        $self->subject($data->{message}->{subject})
            if $data->{message}->{subject} && ! $self->subject;

        $self->message($data->{message}->{message})
            if $data->{message}->{message} && ! $self->message;

        $self->type($data->{message}->{type})
            if $data->{message}->{type} && ! $self->type;

        $self->cc($data->{message}->{cc})
            if $data->{message}->{cc} && ! $self->cc;

        $self->bcc($data->{message}->{bcc})
            if $data->{message}->{bcc} && ! $self->bcc;

        $self->reply_to($data->{message}->{reply_to})
            if $data->{message}->{reply_to} && ! $self->reply_to;

        $self->transport($data->{transport})
            if $data->{transport} && ! $self->transport;

        $self->headers($data->{headers})
            if $data->{headers} && ! $self->headers;

        $self->attachments($data->{attachments})
            if $data->{attachments} && ! $self->attachments;

        $self->tags($data->{tags})
            if $data->{tags} && ! $self->tags;
    }

    return $self;
}

sub to_hash {
    my ($self) = @_;

    my $mail = {
        message => {
            to      => $self->to,
            from    => $self->from,
            subject => $self->subject
        }
    };

    $mail->{message}->{cc} = $self->cc
        if $self->cc;

    $mail->{message}->{bcc} = $self->bcc
        if $self->bcc;

    $mail->{message}->{reply_to} = $self->reply_to
        if $self->reply_to;

    $mail->{message}->{message} = $self->message
        if $self->message;

    $mail->{message}->{type} = $self->type
        if $self->type;

    $mail->{transport} = $self->transport
        if $self->transport;

    $mail->{created} = Class::Date::now->string;

    $mail->{headers} = $self->headers
        if $self->headers;

    $mail->{attachments} = $self->attachments
        if $self->attachments;

    $mail->{tags} = $self->tags
        if $self->tags;

    return $mail;
};

sub send {
    my ($self) = @_;
    my $mail = $self->to_hash or return;

    my $email = Emailesque->new({
        %{$mail->{message}},
          $mail->{headers}     ? (headers     => $mail->{headers})     : (),
          $mail->{attachments} ? (attachments => $mail->{attachments}) : ()
    });

    my $result = $email->send(
        {} => $mail->{transport} ? %{$mail->{transport}} : ()
    );

    $self->result($result);

    return $result;
};

1;

__END__

=pod

=head1 NAME

Email::Sender::Server::Message - Eventual Email Message Object

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

    use Email::Sender::Server::Message;

    my $message = Email::Sender::Server::Message->new(
        to          => '...',
        from        => '...',
        subject     => '...',
        cc          => '...',
        bcc         => '...',
        reply_to    => '...',
        message     => '...'
        attachments => [],
        headers     => {},
    );

    $message->send;

=head1 DESCRIPTION

Email::Sender::Server::Message is an interface for sending email messages in
Email::Sender::Server. Please see L<Emailesque> for information on arguments
and configuration of email messages.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
