global SearchReplace do= {
    :local out ""
    :local index 0
    :local length [:len $input]
    :local findex
    :local temp

    set $findex [find $input $search ($index-1) ]
    while ([len $findex] != "0") do={
        set temp ([pick $input $index $findex ])
        set $out "$out$temp$replace"
        set $index ($findex+[len $search])
        set $findex [find $input $search ($index-1) ]
    }
    set temp [pick $input ($index) $length ]
    set $out "$out$temp"
    :return $out
}

global JsonEscape do= {
    :global SearchReplace
    :local escchars {"\5C";"\08";"\0C";"\0A";"\0D";"\09";"\22"}
    :local escReplace {"\\\\";"\\b";"\\f";"\\n";"\\r";"\\t";"\\\""}
    foreach k,escchar in=$escchars do={
        set $input [$SearchReplace input=$input search=$escchar replace=($escReplace->($k))]
    }
    return $input
}

global JsonPick do= {

}

global test (([/tool/fetch "http://upgrade.mikrotik.com/routeros/7.12beta9/CHANGELOG" output=user as-value])->"data")

:set test [:pick ($test) -1 255]
#Text must be escaped before posting as JSON!
put [$test]

put "------------------------------------"

local a2 [$JsonEscape input=$test]
put $a2
put [len $a2]