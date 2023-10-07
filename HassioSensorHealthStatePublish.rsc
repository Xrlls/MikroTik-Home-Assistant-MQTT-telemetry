{
    global discoverypath "homeassistant/"
    global domainpath "sensor/"

    #-------------------------------------------------------
    #Get variables to build device string
    #-------------------------------------------------------
    #ID
    global ID [/system/routerboard get serial-number] 

    if ([/system/resource/get board-name] != "CHR") do={
        local string "{"
        local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
        foreach sensor in=[/system/health/find] do={
            set $string (($string).("\"").\
                ("x").([$SearchReplace input=[/system/health/get $sensor name] search="-" replace="_"]).("\":").\
                ([/system/health/get $sensor value]).(","))
        }
    set $string ([pick $string -1 ([len $string ]-1)]."}")
    
    /iot/mqtt/publish broker="Home Assistant" message=$string topic="$discoverypath$domainpath$ID/state" retain=yes   
    }
}