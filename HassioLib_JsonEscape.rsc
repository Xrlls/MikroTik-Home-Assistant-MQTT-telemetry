# Use
# local JsonEscape [parse [system/script/get "HassioLib_JsonEscape" source]]
# $JsonEscape input=$a4
#
#global JsonEscape do= {
    #:global SearchReplace
    local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
    :local escchars   {"\\"  ; "\""  ;"/";"\08";\;"\0C";\; "\0A";\;"\0D";"\08};
    :local escReplace {"\\\\";"\\\"";"\\/";"\\b";"\\f";"\\n";"\\r";"\\t"}
    foreach k,escchar in=$escchars do={
        set $input [$SearchReplace input=$input search=$escchar replace=($escReplace->($k))]
    }
    return $input

#}