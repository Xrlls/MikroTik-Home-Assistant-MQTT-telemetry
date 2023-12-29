# Use
# local LowercaseHex [parse [system/script/get "HassioLib_LowercaseHex" source]]
# $LowercaseHex input=$a4
#
#global LowercaseHex do= {
    #:global SearchReplace
    local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
    :local escchars {"A";"B";"C";"D";"E";"F"}
    :local escReplace {"a";"b";"c";"d";"e";"f"}
    foreach k,escchar in=$escchars do={
        set $input [$SearchReplace input=$input search=$escchar replace=($escReplace->($k))]
    }
    return $input

#}