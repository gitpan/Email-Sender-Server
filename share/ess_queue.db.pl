
sub sendmail_path {
    
    my $path = `which sendmail`; $path =~ s/[\r\n]//g;
    
    return $path;
    
}

my $config = {
    
    # specify default variables (optional)
    # plese view the specification at Email::Sender::Server::Client
    # to ensure the proper values are set
    message => {
        
        #from => 'The Dude <dude@company.com>',
        #bcc => 'The Dude <dude@company.com>',
        
    },
    
    # how we intend to send the emails
    # see the Email::Sender::Transport:: namespace
    # the key/value pairs should be attributes to the transport class
    transport => {
        
        Sendmail => {
            
            sendmail => sendmail_path()
            
        }
        
    }
    
};
