##################################################
# Filename      : wugms_base_script.rsc
# Release       : 1.0
# Release date  : 2018-08-20
# Description   : Script to download and install
#               : any required scripts
# Author        : Neji
# Contact email : dev.duncane at gmail dot com
# Revision      : 1.0 - Initial release
##################################################

:log info "WUGMS Script Updater: Starting...";
:local WUGMSdistserver ("ERROR");
:local savefn;
:local fetchMode ("http");
:local runFileName;
:local fullURL;
:local baseURLPath ("/WUGMS/scripts/");
:local osRev [/system resource get version];
:local osShort [:pick $osRev 0 1];
#:set WUGMSdistserver "ERROR";
# Variables to be changed
:local WUGMSUpdateServers ("192.168.100.6","192.168.72.1","192.168.100.7","192.168.100.8","192.168.100.9","172.16.83.2","172.16.250.128");
:local WUGMSPullFileList ("wugms_config_uploader");
#:set fetchMode "http";
#:set baseURLPath "/WUGMS/scripts/";

:log info "WUGMS Script Updater: The routerboard is running: $osRev";    

#Check if there is connection to at least one update server else halt script\
:log info "WUGMS Script Updater: Checking links to the distribution server(s)";
:foreach uploadserver in=$WUGMSUpdateServers do={
    :if ($WUGMSdistserver="ERROR") do={
        :log info ("WUGMS Script Updater: Testing update server " . $uploadserver . " ")
        :if ([ping $uploadserver count=5]>=3) do={
            :set $WUGMSdistserver $uploadserver
            :log info ("WUGMS Script Updater: Update server ". $WUGMSdistserver ." is reachable")
        } else={
            :log warning ("WUGMS Script Updater: Update server ". $uploadserver ." is unreachable")
        }
    }
};

:if ($WUGMSdistserver!="ERROR") do={
    :log info "WUGMS Script Updater: Update server available"
    
    :log info "WUGMS Script Updater: Removing old file(s)"
    :foreach oldFileName in=$WUGMSPullFileList do={
        /file remove [/file find name~$oldFileName . "*[0-9].rsc"]
    };

    :log info "WUGMS Script Updater: Getting the new file(s)"
    :foreach filename in=$WUGMSPullFileList do={
        :log info ("WUGMS Script Updater: Getting the latest " . $filename . ".rsc ")
        :set fullURL ($fetchMode . "://" . $WUGMSdistserver . $baseURLPath . $osShort . "/" . $filename . ".rsc")
        #/tool fetch url="$fetchMode://$WUGMSdistserver$baseURLPath$filename$osShort.rsc" mode=$fetchMode;
        /tool fetch url="$fullURL" mode=$fetchMode;
        :delay delay-time=2s;
    };

    :foreach loadFileName in=$WUGMSPullFileList do={
        :set $runFileName ($loadFileName . ".rsc");
        :log info ("WUGMS Script Updater: Running " . $runFileName . "... ");
        /import $runFileName;
    };
} else={ 
    :log error "WUGMS Script Updater: Could not connect to any of the update server(s).";
}
:log info "WUGMS Script Updater: Done.";
