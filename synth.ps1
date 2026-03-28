Set-PSDebug -Trace 1
Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

Write-Host "Running nextpnr-ecp5..."
nextpnr-ecp5 --12k --json synth_out.json --lpf constraints.lpf --textcfg pnr_out.config

Write-Host "Running ecppack..."
ecppack --compress pnr_out.config bitstream.bit

Write-Host "Running fujprog..."
fujprog bitstream.bit

Write-Host "Done!"