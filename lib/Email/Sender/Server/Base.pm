package Email::Sender::Server::Base;
{
    $Email::Sender::Server::Base::VERSION = '0.39';
}

use strict;
use warnings;

use Validation::Class;

use Carp 'confess';

use File::Path 'mkpath';
use File::Spec::Functions 'rel2abs', 'catdir', 'catfile', 'curdir', 'splitdir',
  'splitpath';

our $VERSION = '0.39';    # VERSION

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

    my ($self, @dir) = @_;

    my @root = ();

    @root = (rel2abs($ENV{ESS_DATA})) if $ENV{ESS_DATA};

    @root = (rel2abs(curdir() || (splitpath($0))[1]), 'ess_data') unless @root;

    my $path = catdir splitdir join '/', @root;

    mkpath $path unless -d $path;

    if (@dir) {

        my $dir = $path;

        for my $sub (@dir) {

            $path = catdir splitdir join '/', $path, $sub;
            mkpath $path unless -d $path;

        }

    }

    return catdir splitdir join '/', @root, @dir;

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
