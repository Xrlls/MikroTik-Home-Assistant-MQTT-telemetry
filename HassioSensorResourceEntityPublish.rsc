if ([len [system/package/find name="iot"]]=0) do={ ; # If IOT packages is  not installed
    log/error message="HassioMQTT: IOT package not installed."
} else={
    if ([len [iot/mqtt/brokers/find name="Home Assistant"]]=0) do={ ;# If Home assistant broker does not exist
        log/error message="HassioMQTT: Broker does not exist."
    } else={
        while (![/iot/mqtt/brokers/get [/iot/mqtt/brokers/find name="Home Assistant"] connected ]) do={ ;# If Home assistant broker is not connected
            log/info message="HassioMQTT: Broker not connected reattempting connection..."
            delay 1m; # Wait and attempt reconnect
            iot/mqtt/connect broker="Home Assistant"
        }

        local discoverypath "homeassistant/"
        local domainpath "sensor"

        #-------------------------------------------------------
        #Build device string
        #-------------------------------------------------------
        local dev [[parse [system/script/get "HassioLib_DeviceString" source]]]
        local buildconfig do= {
            #build config for Hassio
            local entity ($entity,$dev)
            :foreach eName,unit in=$name do={
                :set ($entity->"cmps"->$eName) ($unit,{
                    "p"=$domainpath;
                    "name"=$eName;
                    "uniq_id"=(($entity->"dev"->"ids")."_$eName");
                    "sug_dsp_prc"=1;
                    "exp_aft"=70;
                    "stat_t"=("$discoverypath"."device/".($entity->"dev"->"ids")."/resource")
                })
            }
            :return $entity;#[:serialize to=json $entity]
        }
        :local arch 32
        :if ([/system/resource get architecture-name]~"64") do={;#Check if architecture is 64bit
            :set arch 64
        }
        :local all ({
            "uptime"={
                "unit_of_meas"="d";
                "dev_cla"="duration";
                "stat_cla"="total";
                "ent_cat"="diagnostic"
                "val_tpl"="{{ value_json.xuptime/(60*60*24) }}";
            };
            "free-memory"={
                "unit_of_meas"="MiB";
                "dev_cla"="data_size";
                "stat_cla"="measurement"
                "val_tpl"="{{ value_json.xfree_memory/(2**20) }}";
                "icon"="mdi:memory"
            };
            "free-hdd-space"={
                "unit_of_meas"="MiB";
                "dev_cla"="data_size";
                "stat_cla"="measurement"
                "val_tpl"="{{ value_json.xfree_hdd_space/(2**20) }}";
                "icon"="mdi:harddisk"
            };
            "cpu-load"={
                "unit_of_meas"="%";
                "stat_cla"="measurement"
                "val_tpl"="{{ value_json.xcpu_load }}";
                "icon"="mdi:cpu-$arch-bit"
            }
        })
        :return [$buildconfig name=$all discoverypath=$discoverypath domainpath=$domainpath dev=$dev]
    }
}