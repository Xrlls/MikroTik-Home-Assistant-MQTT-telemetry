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
    put $input
    set $input [pick $input -1 $len]
    local length [len $input]
    put $length
    put $input
    put  ("Last char:        \"".[pick $input ($length-1)]."\"")
    put  ("Second last char: \"".[pick $input ($length-2)]."\"")
    put ([pick $input ($length-1)] = "\\")
    put ([pick $input ($length-2)] != "\\")
    if (([pick $input ($length-1)] = "\\") && ([pick $input ($length-2)] != "\\")) do= {
        set $input [:pick ($input) -1 ($length-1)]
    }
    return $input
}

global LowerHex do= {
    :global SearchReplace
    :local escchars {"A";"B";"C";"D";"E";"F"}
    :local escReplace {"a";"b";"c";"d";"e";"f"}
    foreach k,escchar in=$escchars do={
        set $input [$SearchReplace input=$input search=$escchar replace=($escReplace->($k))]
    }
    return $input

}

global test (([/tool/fetch "http://upgrade.mikrotik.com/routeros/7.12beta9/CHANGELOG" output=user as-value])->"data")

:set test [:pick ($test) -1 255]
#Text must be escaped before posting as JSON!
put [$test]

put "------------------------------------"

local a2 [$JsonEscape input=$test]
put $a2
put [len $a2]

local a3 "\"Mikrotik\""
put $a3
set $a3 [$SearchReplace input=$a3 search=("\"") replace=("")]
put $a3

put "------------------------------------"
put "MAC Test"
local a4 "18:FD:74:B3:6C:4A"
put $a4

set $a4 [$LowerHex input=$a4]
put $a4





put "------------------------------------"

local a5 [$JsonPick input=$a2 len=255]
put $a5

