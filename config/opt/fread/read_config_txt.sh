#!/bin/sh

# This script parses the fread.ink settings.txt file

CONF_PATH="/mnt/us/fread/config.txt"

if [ ! -f "$CONF_PATH" ]; then
    exit 0
fi

OPT_WIFI="disable"
OPT_WIFI_IP_METHOD="dhcp"
OPT_WIFI_IP_ADDRESS="192.168.1.42"
OPT_WIFI_IP_NETMASK="255.255.255.0"

# parse each line that looks like "FOO = VAR" into $SETTING and $VALUE
while read -r LINE; do

    # trim leading and trailing whitespace
    LINE="$(echo -e "${LINE}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # ignore comments
    if [ "$LINE" != "${LINE#\#}" ]; then
        continue
    fi
    
    SETTING=""
    VALUE=""
    COUNT=0
    while [ "$LINE" ]; do
        COUNT=$(( COUNT+1 ))
        if [ "$COUNT" -gt "2" ]; then
            break
        fi
        CUR=${LINE%%=*}
        
        if [ "$COUNT" -eq "1" ]; then
            # trim trailing whitespace
            SETTING=$(echo -e "${CUR}" | sed -e 's/[[:space:]]*$//')
        elif [ "$COUNT" -eq "2" ]; then
#            VALUE=$CUR
            # trim trailing double-quote
            VALUE=$(echo -e "${CUR}" | sed -e 's/\"\+.*$//')
        fi
        [ "$LINE" = "$CUR" ] && LINE='' || LINE="${LINE#*=\"}"
    done

    if [ "$COUNT" -ne "2" ]; then
        continue
    fi
    
#    echo "$SETTING = $VALUE"

    case "$SETTING" in
        WIFI)
            OPT_WIFI=$VALUE
        ;;

        WIFI_SSID)
            OPT_WIFI_SSID=$VALUE
        ;;
        WIFI_PASSWORD)
            OPT_WIFI_PASSWORD=$VALUE
        ;;

        WIFI_IP_METHOD)
            OPT_WIFI_IP_METHOD=$VALUE
        ;;

        WIFI_IP_ADDRESS)
            OPT_WIFI_IP_ADDRESS=$VALUE
        ;;

        WIFI_IP_NETMASK)
            OPT_WIFI_IP_NETMASK=$VALUE
        ;;

        WIFI_IP_GATEWAY)
            OPT_WIFI_IP_GATEWAY=$VALUE
        ;;

        WIFI_IP_DNS)
            OPT_WIFI_IP_DNS=$VALUE
        ;;
        
        SSH)
            if [ "$SSH" = "enable" ]; then
                /etc/init.d/dropbear start
            else
                /etc/init.d/dropbear stop
            fi
        ;;

        USB)
            if [ "$VALUE" = "ethernet" ]; then
                modprobe g_ether
                sleep 3
                ip addr add 192.168.1.1/24 dev usb0
                ip link set dev usb0 up
                /etc/init.d/dnsmasq start
                /etc/init.d/dropbear start
            else
                echo "USB mode $VALUE not implemented"
            fi
        ;;
 

        *)
            echo "Unknown option $SETTING"
    esac
     
done < "$CONF_PATH"

if [ "$OPT_WIFI" = "enable" ] && { [ "${#OPT_WIFI_SSID}" -gt "0" ]; }; then
    CFGPATH="/var/lib/connman/wifi.config"
    
    if [ "$OPT_WIFI_IP_METHOD" = "static" ]; then
        CFG_IPV4="${OPT_WIFI_IP_ADDRESS}/${OPT_WIFI_IP_NETMASK}"
        if [ "${#OPT_WIFI_IP_GATEWAY}" -gt "0" ]; then
            CFG_IPV4="${CFG_IPV4}/$OPT_WIFI_IP_GATEWAY"
        fi
    else
        CFG_IPV4="dhcp"
    fi

    if [ "${#OPT_WIFI_IP_DNS}" -gt "6" ]; then
        CFG_NAMESERVERS="Nameservers=$OPT_WIFI_IP_DNS"
    fi
    
    cat << EOF > $CFG_PATH
[service_wifi]
Type=wifi
Name=$OPT_WIFI_SSID
AutoConnect=True
Passphrase=$OPT_WIFI_PASSWORD
IPv4=$CFG_IPV4
$CFG_NAMESERVERS
EOF

    /etc/init.d/connman start
fi
