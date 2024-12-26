:log debug ("Hassio: MQTT received on ".$msgTopic." Payload: ".$msgData)
:local SearchStringPre "command_x"
:local SearchStringPost "_GPIO"
:local SearchStringL [:len $SearchStringPre]
:local IndexB ([:find $msgTopic $SearchStringPre -1]+[:len $SearchStringPre])
:local IndexE [:find $msgTopic $SearchStringPost $IndexB]
:local pin [:pick $msgTopic $IndexB $IndexE]
:if ($msgData~"ON") do={
    /iot/gpio/digital set $pin output=1
}\
else={
    if ($msgData~"OFF") do={
        /iot/gpio/digital set $pin output=0
    }
}