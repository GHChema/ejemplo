[CmdletBinding()]
Param(
    $oContext,
    [string] $SnapshotName,
    [string] $BuildingBlockName,
    $OsmoTask

)


#Calcular Ruta de persistencia

$SnapshotFolder = "$($oContext.Paths.OsmoTree)\$($oContext.Paths.Snapshot.BasePath)$($snapshotName)\"

#$PersistenciaFolder = "$SnapshotFolder$($oContext.Paths.Snapshot.BuildingBlocksPath)\$($BuildingBlockName)"
$PersistenciaFolder = "$SnapshotFolder$($oContext.Paths.Snapshot.BuildingBlocksPath)\$($OsmoTask.Type)_$($BuildingBlockName)"
$ConfigFolder = "$PersistenciaFolder\$($oContext.Paths.Snapshot.BuildingBlockConfigFolder)"
$ContentFolder = "$PersistenciaFolder\$($oContext.Paths.Snapshot.BuildingBlockContentFolder)"

$GetTokenPath = "$($oContext.Paths.OsmoTree)\$($OsmoContext.Paths.Tree.GeneralBlocks)\Tokens"
$GetAppSvcContentPath = "$($oContext.Paths.OsmoTree)\$($OsmoContext.Paths.Tree.GeneralBlocks)\AppServiceContent"



Write-Verbose( "Creando Plantilla del recurso $buidingBlockName ...")

$resource = Get-AzResource `
  -ResourceGroupName $oContext.Source.ResourceGroup `
  -ResourceName $buildingBlockName `
  -ResourceType "Microsoft.Web/sites"

 Export-AzResourceGroup `
  -ResourceGroupName $oContext.Source.ResourceGroup `
  -Resource $resource.ResourceId `
  -Path "$ConfigFolder\$($BuildingBlockName).json" `
  -Force
  
  
Write-Verbose( "Creando Contenido del recurso $buidingBlockName ...")

$Token = (. $GetTokenPath\Get-OsmoToken.ps1)

. $GetAppSvcContentPath\Get-OsmoAppContent.ps1 -AppServiceName $buildingBlockName `
                                             -bToken $Token.BearerToken `
                                             -Path "$ContentFolder\$($BuildingBlockName).zip"
  
  $WebAppSettings = Invoke-AzResourceAction `
                     -ResourceGroupName $oContext.Source.ResourceGroup `
                     -ResourceType Microsoft.Web/sites/config `
                     -ResourceName "$buildingBlockName/appsettings" `
                     -Action list `
                     -ApiVersion 2016-08-01 `
                     -Force

  $WebAppConString = Invoke-AzResourceAction `
                     -ResourceGroupName $oContext.Source.ResourceGroup `
                     -ResourceType Microsoft.Web/sites/config `
                     -ResourceName "$buildingBlockName/ConnectionStrings" `
                     -Action list `
                     -ApiVersion 2016-08-01 `
                     -Force
                      
  $WebAppSettings_ConString=@{"AppSetting"=$WebAppSettings.properties;
                              "ConnString"=$WebAppConString.properties}

  $WebAppSettingsFile = $ConfigFolder + "\" + $BuildingBlockName + "_appcfg.json"
                      
  $WebAppSettings_ConString  | ConvertTo-Json -Depth 10 | Out-File -FilePath $WebAppSettingsFile                                               