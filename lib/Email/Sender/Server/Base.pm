package Email::Sender::Server::Base;
{
    $Email::Sender::Server::Base::VERSION = '0.11';
}

use strict;
use warnings;

use Validation::Class;

use Carp 'confess';
use File::Path 'mkpath';
use File::Spec::Functions 'curdir', 'catdir', 'catfile', 'splitdir';

bld sub {

    my ($self) = @_;

    my $dir = $self->directory;

    if (-d $dir && -w $dir) {

        $self->directory('queued');
        $self->directory('passed');
        $self->directory('failed');

    }

    else {

        confess "Couldn't find or access (write-to) the data directory $dir";

    }

    return $self;

};

sub filepath {

    my $self = shift;

    my $filename = pop;

    return catfile splitdir join '/', $self->directory(@_), $filename;

}

sub directory {

    my $self = shift;

    my $directory = $ENV{ESS_DATA} || curdir();

    $directory = catdir splitdir join '/', $directory, '.ess';
    mkpath $directory unless -d $directory;

    if (@_) {

        $directory = catdir splitdir join '/', $directory, @_;
        mkpath $directory unless -d $directory;

    }

    return $directory;

}

sub message_filelist {

    my $self = shift;

    my $directory = @_ ? $self->directory(@_) : $self->workspace;

    [glob catfile splitdir join '/', $directory, '*.msg']

}

sub message_filename {

    my ($self, $filepath) = @_;

    return undef unless $filepath;

    my ($filename) = $filepath =~ /(\d{14}-\d{1,10}-\w{4,10}\.msg)$/;

    return $filename;

}

sub stop_polling {

    my $self = shift;

    return -e $self->filepath('shutdown');

}

1;
