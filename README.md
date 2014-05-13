add-to-check_mk
===============

    Usage: ./add_to_check_mk.sh -s SITENAME -h HOSTNAME [-f FOLDERNAME] [-t 'tag1|tag2|tag3']
    
        -s    Specifies the omd 'site' to add the host to, eg: prod
        -h    Specifies the hostname to be added
        -f    Optional. Specifies the name of the check_mk folder the
              host is to be added to.
        -t    Optional. WATO tags to add to the host.
        -?    This message.
