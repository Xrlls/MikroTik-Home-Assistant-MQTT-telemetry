:local discoverypath "homeassistant/"

#-------------------------------------------------------
#Build device string
#-------------------------------------------------------
:local dev [[:parse [system/script/get "HassioLib_DeviceString" source]]]
:local buildconfig do={
    :local SearchReplace [:parse [system/script/get "HassioLib_SearchReplace" source]]
    :local jsonname ("x".[$SearchReplace input=$name search="-" replace="_"])
    :local NamePostfix "_GPIO"

    #build config for Hassio
    :local entity
    :set $entity ($entity,$dev)
    :set ($entity->"name") $name
    :set ($entity->"~") ($discoverypath."sensor/".($entity->"dev"->"ids")."/")
    :set ($entity->"stat_t") "~state$NamePostfix"
    :set ($entity->"avty_t") "~state$NamePostfix"
    :set ($entity->"avty_tpl") "{%if value_json.$jsonname is defined%}{{'online'}}{%else%}{{'offline'}}{%endif%}"
    :set ($entity->"uniq_id") (($entity->"dev"->"ids")."_$name$NamePostfix")
    :set ($entity->"obj_id") ($entity->"uniq_id")

    :if ($domainpath="sensor") do={
        :set ($entity->"sug_dsp_prc") 3
        :set ($entity->"unit_of_meas") "V"
        :set ($entity->"dev_cla") "voltage"
        :set ($entity->"stat_cla") "measurement"
        :set ($entity->"val_tpl") "{%if value_json.$jsonname is defined%}{{value_json.$jsonname/1000}}{%endif%}"
        :set ($entity->"exp_aft") 70
    }
    :if ($domainpath="binary_sensor") do={
        :set ($entity->"val_tpl") "{%if value_json.$jsonname is defined%}{%if value_json.$jsonname%}{{'ON'}}{%else%}{{'OFF'}}{%endif%}{%endif%}"
    }
    :if ($domainpath="switch") do={
        :set ($entity->"val_tpl") "{%if value_json.$jsonname is defined%}{%if value_json.$jsonname%}{{'ON'}}{%else%}{{'OFF'}}{%endif%}{%endif%}"
        :set ($entity->"cmd_t") ($discoverypath.$domainpath."/".($entity->"dev"->"ids")."/command_$jsonname$NamePostfix")
    }
    /iot/mqtt/publish broker="Home Assistant" message=[:serialize $entity to=json]\
        topic=("$discoverypath$domainpath/".($entity->"dev"->"ids")."/$name$NamePostfix/config") retain=yes        
}

/iot/gpio/analog
:foreach input in=[find] do={
    $buildconfig dev=$dev name=[get $input name] domainpath="sensor" discoverypath=$discoverypath
}

/iot/gpio/digital
:foreach input in=[find where direction="input"] do={
    $buildconfig dev=$dev name=[get $input name] domainpath="binary_sensor" discoverypath=$discoverypath
}

:foreach input in=[find where direction="output"] do={
    $buildconfig dev=$dev name=[get $input name] domainpath="switch" discoverypath=$discoverypath
}
