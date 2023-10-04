# Use
# local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
# $SearchReplace input="abc" search="a" replace="b"
#
#global SearchReplace do= {
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
#}
