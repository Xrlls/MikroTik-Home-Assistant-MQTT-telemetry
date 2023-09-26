global SearchReplace do= {
    :local out ""
    :local index -1
    :local length [:len $input]
    :local findex
    :local temp
    set $findex [find $input $search $index ]
    while ([len $findex] != "0") do={
        set temp ([pick $input $index $findex ])
        set $out "$out$temp$replace"
        set $index ($findex+[len $search])
        set $findex [find $input $search $index ]
    }
    set temp [pick $input ($index) $length ]
    set $out "$out$temp"
:return $out

}

global test [/file/get "CHANGELOG" contents]

:set test [:pick $test -1 255]
#Text must be escaped before posting as JSON!
:put [$test]
#:put [:len  $test]


#:put $escchars->1
#global escchars {"\5C";"\08";"\0C";"\0A";"\0D";"\09";"\22"}
global escchars "\22"
global escReplace {"\5C"="\\\\";"\08"="\\b";"\0C"="\\f";"\0A"="\\n";"\0D"="\\r";"\09"="\\t";"\22"="\\\""}

#put "start loop"
#foreach escchar in=[$escchars] do={
    :local out ""
    :local index -1
    :local length [:len $test]
    :local findex
    :local temp
    set $findex [find $test "\"" $index ]
    while ([len $findex] != "0") do={
        set temp ([pick $test $index $findex ])
        set $out "$out$temp\\\""
        set $index ($findex+1)
        set $findex [find $test "\"" $index ]
    }
    
    set temp [pick $test ($index) $length ]
    set $out "$out$temp"



put "------------------------------------"
put $out
 #   }
put "------------------------------------"
set $out [$SearchReplace input=$test search=("\"") replace=("\\\"")]
put "--"
put "$out"
