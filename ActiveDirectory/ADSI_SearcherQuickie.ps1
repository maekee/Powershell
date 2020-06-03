#Super simple ADSISearcher

([ADSISearcher]@{
    Filter = '(samAccountName=maekee)'
    SearchRoot = [ADSI]''
    PageSize = 1
} | % *All).Properties
