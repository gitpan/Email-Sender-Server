#!/usr/bin/perl

BEGIN {
    use FindBin;
    use lib $FindBin::Bin . "/../lib";
}

use Email::Sender::Server::Client 'mail';

my @message = (
    to      => 'guy@abc.co',
    from    => 'dude@ana.io',
    subject => 'Hows it hangin?',
    html    => 'Suspendisse sit amet orci nec purus varius pharetra.'
);

my ($client, $msg_id) = mail @message;

print $msg_id, "\n";
