package Email::Sender::Server::Message;
{
    $Email::Sender::Server::Message::VERSION = '0.10';
}

use strict;
use warnings;

use Validation::Class;

use IO::All;
use Class::Date;
use Email::MIME;
use File::Type;

use Carp 'confess';
use Email::Sender::Simple 'sendmail';

set {

    roles => ['Email::Sender::Server::Directives']

};

our $VERSION = '0.10';    # VERSION

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

        # list of name/value hashrefs of attachments

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
    [

        {

            name  => 'X-Mailer',
            value => do {

                my $name    = "Email-Sender-Server";
                my $version = '0.00';

                eval { $version = ${__PACKAGE__ . "::VERSION"} };

                join " ", $name, $version || '0.00'

              }

        }

    ];
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

has status => sub {

    undef    # Email::Sender::Success or Email::Sender::Failure

};

fld subject => {

    mixin      => 'basic',
    min_length => 2

};

has tags => sub {
    [

        # list of message tags

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

has transport => sub {
    {

        # see the Email::Sender::Transport:: namespace
        # the key/value pairs should be attributes to the transport class

        Sendmail => {

            sendmail => do {

                my $path = `which sendmail`;
                $path =~ s/[\r\n]//g;

                $path || '/usr/sbin/sendmail';

              }

          }

    };
};

pro is_valid => sub {

    my ($self, @args) = @_;

    if (@{$self->attachments}) {

        my $e = 0;

        foreach my $attachment (@{$self->attachments}) {

            unless (-f $attachment->{value}) {

                $e++;

                my $error = "the attachment $attachment->{name} could not"
                  . "be located on disk";

                $self->set_errors($error);

            }

        }

        return 0 if $e;

    }

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

sub from_hash {

    my ($self, $data) = @_;

    unless ("HASH" eq ref $data) {

        $self->set_errors('invalid hash reference while converting to object');
        return 0;

    }

    $self->params(

        to      => $data->{message}->{to},
        from    => $data->{message}->{from},
        subject => $data->{message}->{subject}

    );

    $self->param('cc' => $data->{message}->{cc})
      if $data->{message}->{cc};

    $self->param('bcc' => $data->{message}->{bcc})
      if $data->{message}->{bcc};

    $self->param('reply_to' => $data->{message}->{reply_to})
      if $data->{message}->{reply_to};

    $self->param('html' => $data->{message}->{body_html})
      if $data->{message}->{body_html};

    $self->param('text' => $data->{message}->{body_text})
      if $data->{message}->{body_text};

    $self->param(
        'transport' => {

            $data->{transport}->{class} => $data->{transport}->{args}

        }
    ) if $data->{transport};

    $self->param('headers' => $data->{headers})
      if $data->{headers};

    $self->param('attachments' => $data->{attachments})
      if $data->{attachments};

    $self->param('tags' => $data->{tags})
      if $data->{tags};

    return $self->is_valid;

}

mth to_hash => {

    input => 'is_valid',
    using => sub {

        my ($self, @args) = @_;

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

        $mail->{message}->{body_html} = $self->html
          if $self->html;

        $mail->{message}->{body_text} = $self->text
          if $self->text;

        $mail->{message}->{body_html} = $self->body
          if not $self->text || not $self->html;

        while (my ($class, $args) = each(%{$self->transport})) {

            $mail->{transport} = {

                class => $class,
                args  => $args

              }

        }

        $mail->{created} = Class::Date::now->string;

        $mail->{headers} = $self->headers
          if $self->headers;

        $mail->{attachments} = $self->attachments
          if $self->attachments;

        $mail->{tags} = $self->tags
          if $self->tags;

        return $mail;

      }

};

sub send {

    my ($self, @args) = @_;

    return undef unless my $mail = $self->to_hash;

    # build the message

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

    my $status;

    eval {

        my $transporter = $mail->{transport}->{class};

        $transporter = "Email::Sender::Transport::" . $transporter
          unless $transporter =~ "^Email::Sender::Transport::";

        $transporter =~ s/::/\//g;

        require "$transporter.pm" unless $INC{"$transporter.pm"};

        $transporter =~ s/\//::/g;

        $status = sendmail $email, {

            from      => $mail->{message}->{from},
            transport => $transporter->new(%{$mail->{transport}->{args}})

        };

    };

    confess $@ if $@;

    $self->status(ref $status || $status);    # set Email::Sender:: $status

    $self->set_errors('unknown error sending email')
      if $self->status =~ /failure/i;

    return $self;

}

1;
