##################################################
# Filename      : wugms_config_uploader.rsc
# Release       : 1.0
# Release date  : 2018-08-20
# Description   : Script to create and send Routerboard
#               : exported configuration files to any
#               : of the listed WUGMS FTP server(s)
# Author        : Neji
# Contact email : dev.duncane at gmail dot com
# Revision      : 1.0 - Rewrite from old RBCP script
##################################################

:log info "WUGMS Config Uploader: Starting...";
:local ftpserver ("ERROR");
:local runUpdate ("NO");
:local updaterName ("wugms_base_script.rsc");
:local fetchMode ("http");
:local baseURLPath ("/WUGMS/scripts/");
:local fullURL;
:local platform [/system resource get architecture-name];
:local model [/system resource get board-name];
:local serial;
:local ftpUser;
:local ftpPass;

:set ftpserver "ERROR";
#:set urlPath "/WUGMS/scripts/WUGMS_base_script.rsc";
if ($model != "x86") do={
    :set serial [/system routerboard get serial-number];
    :log info "WUGMS Config Uploader: This is a routerboard";
    :put ("WUGMS Config Uploader: This is a routerboard");
} else={
    :log info "WUGMS Config Uploader: This is an x86 system";
    :put ("WUGMS Config Uploader: This is an x86 system");
}

:local osRev [/system resource get version];
:local osShort [:pick $osRev 0 1];
:local softwareid [/system license get software-id];
:local rscFileName ("R0" . "." . $serial . "." . $softwareid . "." . $model . "." . $platform . ".rsc");

:local WUGMSUpdateServers ("192.168.100.6","192.168.72.1","192.168.100.7","192.168.100.8","192.168.100.9","172.16.83.2","172.16.250.128");
:set ftpUser "WUGMS";
:set ftpPass "WUGMS";

:log info ("WUGMS Config Uploader: OS version is: " . $osRev);

# Use the short code and confirm that this script will work, else do not run and exit
if ($osShort=6) do={
    :if ([:len [/file find name=$rscFileName]] > 0) do={
        :log info ("WUGMS Config Uploader: Found old backup file." . $rscFileName . ", removing");
        /file remove ($rscFileName);
        :delay delay-time=1s;
    }

    # Export the current config to file
    :log info ("WUGMS Config Uploader: Backing up of current config to file: " . $rscFileName);
    /export verbose hide-sensitive file=($rscFileName);
    :log info "WUGMS Config Uploader: Completed backup of config";
    :delay delay-time=1s;
    :local rscsize [/file get ($rscFileName) value-name=size];
    :local rscUpLoadName ("R0" . "." . $serial . "." . $softwareid . "." . $model . "." . $platform . "." . $rscsize . ".rsc");

    # Determine Uploader server
    :log info "WUGMS Config Uploader: Searching for available upload server";
    :foreach uploadserver in=$WUGMSUpdateServers do={
        :if ($ftpserver="ERROR") do={
            :log info ("WUGMS Config Uploader: Testing server " . $uploadserver . " ")
            :if ([ping $uploadserver count=5]>=3) do={
                :set $ftpserver $uploadserver
                :log info ("WUGMS Config Uploader: ". $ftpserver ." is reachable")
            } else={
                :log warning ("WUGMS Config Uploader: ". $uploadserver ." is unreachable")
            }
        }
     };

    # If an upload server can be found then upload the file
    :if ($ftpserver!="ERROR") do={
        :log info "WUGMS Config Uploader: Uploading the backup file to the WUGMS FTP server...";
##        /tool fetch mode=ftp address=($ftpserver) user=$ftpUser password=$ftpPass src-path=($rscFileName) dst-path=($rscUpLoadName) upload=yes;
        :log info ("WUGMS Config Uploader: Upload to WUGMS server (" . $ftpserver . ") complete.");
        :delay delay-time=1s;

        :log info ("WUGMS Config Uploader: Retrieving latest " . $updaterName . " file.");
        :set fullURL ($fetchMode . "://" . $ftpserver . $baseURLPath . $osShort . "/" . $updaterName)
        /tool fetch url="$fullURL" mode=$fetchMode;
        :if ([:len [/file find name=$updaterName]] > 0) do={
            :set runUpdate "YES";
        } else= {
            :log warning ("WUGMS Config Uploader: There was a problem downloading " . $updaterName . ".rsc ")
        }
    } else={ 
        :log info "WUGMS Config Uploader: Could not upload the generated file as the server(s) were unreachable"; 
    }

    # Clean up for backup file
    :if (($rscFileName != "") or ([:len [/file find name=$rscFileName]] > 0)) do={
        :log info ("WUGMS Config Uploader: Removing backup file" . $rscFileName);
        /file remove ($rscFileName);
        :delay delay-time=2s;
     }

    # Clean up
    # :if ($rscFileName != "") do={
    #     :log info ("WUGMS Config Uploader: Removing backup file" . $rscFileName);
    #     /file remove ($rscFileName);
    #     :delay delay-time=2s;
    # }

    # :if ([:len [/file find name=$rscFileName]] > 0) do={
    #     :log info ("WUGMS Config Uploader: Removing backup file " . $rscFileName);
    #     /file remove ($rscFileName);
    #     :delay delay-time=2s;
    # }
} else={ 
    :log info ("WUGMS Config Uploader: This script is not meant to work on version " . $osShort . ".x");
}

:if ($runUpdate !="NO") do={
    :log info "WUGMS Config Uploader: Running updater..."
    /import $updaterName;
}

:log info "WUGMS Config Uploader: Done!";

### :log info ("WUGMS Config Uploader: Removing previous WUGMS_config_upload event(s).");
### /system scheduler remove [/system scheduler find name~"WUGMS_config_upload*[0-9]"];
### /system scheduler remove [/system scheduler find name~"WUGMS_DUL_Sch"];
### :delay delay-time=2s;
### :log info ("WUGMS Config Uploader: Adding scheduled event for wugms_config_uploader.rsc" );
### /system scheduler add comment="Scheduled event for WUGMS_config_upload" disabled=no interval=8h30m name=WUGMS_DUL_Sch on-event="WUGMS_config_upload" policy=ftp,read,write,test start-date=jan/01/1970 start-time=startup
### :log info ("WUGMS Config Uploader: Done with wugms_config_uploader.rsc" );
  