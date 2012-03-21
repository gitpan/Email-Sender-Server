#!/usr/bin/perl

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/../lib";
}

use Email::Sender::Server::Worker;

my $worker = Email::Sender::Server::Worker->new;

print $worker->process_tasks;
