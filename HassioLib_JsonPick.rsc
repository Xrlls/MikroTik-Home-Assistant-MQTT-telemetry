# Use
# local JsonPick [parse [system/script/get "HassioLib_JsonPick" source]]
# $JsonPick input=$a2 len=255
#
#global JsonPick do= {
    set $input [pick $input -1 $len]
    local length [len $input]
    if (([pick $input ($length-1)] = "\\") && ([pick $input ($length-2)] != "\\")) do= {
        set $input [:pick ($input) -1 ($length-1)]
    }
    return $input
#}