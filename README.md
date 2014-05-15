# add-to-check_mk

    Usage: ./add_to_check_mk.sh -s SITENAME -h HOSTNAME [-f FOLDERNAME] [-t 'tag1|tag2|tag3']
    
        -s    Specifies the omd 'site' to add the host to, eg: prod
        -h    Specifies the hostname to be added
        -f    Optional. Specifies the name of the check_mk folder the
              host is to be added to.
        -t    Optional. WATO tags to add to the host.
        -?    This message.

## notes

- This script assumes check_mk has been installed as part of OMD. If you've manually installed you'll likely want to change some of the paths and remove the `-s` requirement.
- If you're copying tags from the wato web interface be warned: after every `|` character check\_mk is inserting a unicode zero-width-space, aka `\u200b`. If these are not removed before you paste the tags into your script/command line check\_mk will interpret them as part of the tag and will then fail to properly apply rules/folders/hostgroups/etc.
