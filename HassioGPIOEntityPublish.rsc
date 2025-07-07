:local discoverypath "homeassistant/"

#-------------------------------------------------------
#Build device string
#-------------------------------------------------------
:local dev [[:parse [system/script/get "HassioLib_DeviceString" source]]]
:local buildconfig do={
    :local SearchReplace [:parse [system/script/get "HassioLib_SearchReplace" source]]
    :local NamePostfix "_GPIO"

    #build config for Hassio
    :local entity
    :set $entity ($entity,$dev)
    :foreach eName,domainpath in=$name do={
        :local jsonname ("x".[$SearchReplace input=$eName search="-" replace="_"])
        :local dName ($eName.$NamePostfix)
        :set ($entity->"cmps"->$dName) {
            "p"=$domainpath;
            "name"=$eName;
            "~"=($discoverypath."sensor/".($entity->"dev"->"ids")."/");
            "stat_t"="~state$NamePostfix";
            "avty_t"="~state$NamePostfix";
            "avty_tpl"=\
                "{%if value_json.$jsonname is defined%}\
                    {{'online'}}\
                {%else%}\
                    {{'offline'}}\
                {%endif%}";
            "uniq_id"=(($entity->"dev"->"ids")."_$dName")
            "obj_id"=($entity->"cmps"->$dName->"uniq_id")
        }
        :if ($domainpath="sensor") do={
            :set ($entity->"cmps"->$dName) (($entity->"cmps"->$dName),{
                "sug_dsp_prc"=3;
                "unit_of_meas"="V";
                "dev_cla"="voltage";
                "stat_cla"="measurement";
                "val_tpl"=\
                    "{%if value_json.$jsonname is defined%}\
                        {{value_json.$jsonname/1000}}\
                    {%endif%}";
                "exp_aft"=70
            })
        }
        :if ($domainpath="binary_sensor") do={
            :set ($entity->"cmps"->$dName) (($entity->"cmps"->$dName),{
                "val_tpl"=\
                    "{%if value_json.$jsonname is defined%}\
                        {%if value_json.$jsonname%}\
                            {{'ON'}}\
                        {%else%}\
                            {{'OFF'}}\
                        {%endif%}\
                    {%endif%}"
            })
        }
        :if ($domainpath="switch") do={
            :set ($entity->"cmps"->$dName) (($entity->"cmps"->$dName),{
                "val_tpl"=\
                    "{%if value_json.$jsonname is defined%}\
                        {%if value_json.$jsonname%}\
                            {{'ON'}}\
                        {%else%}\
                            {{'OFF'}}\
                        {%endif%}\
                    {%endif%}";
                "cmd_t"=($discoverypath.$domainpath."/".($entity->"dev"->"ids")."/command_$jsonname$NamePostfix")
            })
        }
    }
    :return $entity;
}

:local all

/iot/gpio/analog
:foreach input in=[find] do={
    :set ($all->[get $input name]) "sensor"
}

/iot/gpio/digital
:foreach input in=[find where direction="input"] do={
    :if ([get $input input]!="(unknown)") do={; #Workaround as Knot is listing pin3 as both analog and digital, while it is only analog. 
        :set ($all->[get $input name]) "binary_sensor"
    }
}

:foreach input in=[find where direction="output"] do={
    :set ($all->[get $input name]) "switch"
}
:return [$buildconfig name=$all discoverypath=$discoverypath dev=$dev]
