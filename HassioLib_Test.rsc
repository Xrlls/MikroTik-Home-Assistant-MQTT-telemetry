global test (([/tool/fetch "http://upgrade.mikrotik.com/routeros/7.12beta9/CHANGELOG" output=user as-value])->"data")
#:set test [:pick ($test) -1 255]
put [$test]

put "------------------------------------"

local JsonEscape [parse [system/script/get "HassioLib_JsonEscape" source]]
local a2 [$JsonEscape input=$test]
put $a2
put [len $a2]

put "------------------------------------"

local a3 "\"Mikrotik\""
put $a3
local SearchReplace [parse [system/script/get "HassioLib_SearchReplace" source]]
set $a3 [$SearchReplace input=$a3 search=("\"") replace=("")]
put $a3

put "------------------------------------"

put "MAC Test"
local a4 "18:FD:74:B3:6C:4A"
put $a4

local LowercaseHex [parse [system/script/get "HassioLib_LowercaseHex" source]]
set a4 [$LowercaseHex input=$a4]
put $a4

put "------------------------------------"

local JsonPick [parse [system/script/get "HassioLib_JsonPick" source]]
local a5 [$JsonPick input=$a2 len=255]
put $a5
put [len $a5]

