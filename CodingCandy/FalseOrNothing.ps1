#Sometimes when we use bool parameters and need to know if the value is false or if no value was given (not mandatory parameter).
#We do this with $PSBoundParameters, see example below

Function HelloBool{
  param([bool]$someboolvalue)
  
  if($PSBoundParameters.ContainsKey('someboolvalue')){
    if($someboolvalue){
      Write-Host "someboolValue was given the value $true"
    }
    else{
      Write-Host "someboolValue was given the value $false"
    }
  }
  else{
    Write-Host "No value was supplied"
  }
}
