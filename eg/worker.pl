#!/usr/bin/perl

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/../lib";
}

use Email::Sender::Server::Worker;

my $worker = Email::Sender::Server::Worker->new;

my $data = do $FindBin::Bin . "/../ess_data/queued/20120408162614-18571-e8v0.msg";

print $worker->process_message($data);
