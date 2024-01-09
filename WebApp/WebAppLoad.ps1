[CmdletBinding()]
Param(
    $oContext,
    [string] $SnapshotName,
    [string] $BuildingBlockName,
    $OsmoTask,
    $PlanResource,
    $PlanSrcName

)


#Calcular Ruta de persistencia

$SnapshotFolder = "$($oContext.Paths.OsmoTree)\$($oContext.Paths.Snapshot.BasePath)$($snapshotName)\"

#$PersistenciaFolder = "$SnapshotFolder$($oContext.Paths.Snapshot.BuildingBlocksPath)\$($BuildingBlockName)"
$PersistenciaFolder = "$SnapshotFolder$($oContext.Paths.Snapshot.BuildingBlocksPath)\$($OsmoTask.Type)_$($BuildingBlockName)"
$ConfigFolder = "$PersistenciaFolder\$($oContext.Paths.Snapshot.BuildingBlockConfigFolder)"
$ContentFolder = "$PersistenciaFolder\$($oContext.Paths.Snapshot.BuildingBlockContentFolder)"

$templatePathName = "$ConfigFolder\$($BuildingBlockName).json" 

# Transformamos la plantilla
$TemplateObject = (Get-Content -Raw -Path $templatePathName | ConvertFrom-Json -AsHashtable)

$BeforeEA= $ErrorActionPreference
$ErrorActionPreference="SilentlyContinue"  # Suprimimos mensajes de error

$TemplateObject.resources | ForEach-Object { $_.tags.Creador = $oContext.Target.Creator}
$TemplateObject.resources | ForEach-Object { $_.tags."Creado por" = $oContext.Target.Creator}
$TemplateObject.resources | ForEach-Object { $_.location = $oContext.Target.Location}

$ErrorActionPreference= $BeforeEA # Restauramos

$DeploymentName = $SnapshotName + "_" + $BuildingBlockName 
$ResourceName =  $BuildingBlockName + $oContext.Target.suffix

#Preparamos par�metros de plantilla
$ParamTemplSitename= "sites_" + $BuildingBlockName.Replace("-","_") + "_name"
$ParamTemplSvcFarmId= "serverfarms_" + $PlanSrcName.Replace("-","_") + "_externalid"
$ParamTemplate = @{ $ParamTemplSitename=$ResourceName; $ParamTemplSvcFarmId=$PlanResource.Resourceid}

New-AzResourceGroupDeployment `
  -Name $DeploymentName `
  -ResourceGroupName $oContext.Target.ResourceGroup `
  -TemplateObject $TemplateObject `
  -TemplateParameterObject $ParamTemplate
  #-TemplateFile $templatePathName 

# Recuperar el recurso creado para obtener su id y datos adicionales para generar la respuesta
$Resource = Get-AzResource `
  -ResourceGroupName $oContext.Target.ResourceGroup `
  -ResourceName $ResourceName `
  -ResourceType "Microsoft.Web/sites" 

  $GetTransformScriptPath = "$($oContext.Paths.OsmoTree)\$($OsmoContext.Paths.Tree.GeneralBlocks)\Transforms"


$WebAppSettingsFile = $ConfigFolder + "\" + $BuildingBlockName + "_appcfg.json"

$ConfigText = Get-Content -Raw -Path $WebAppSettingsFile                  

#Transformaciones basadas en texto#
foreach ( $transformscript in $OsmoTask.ConfigTransformScript)
{
  $trScript = $GetTransformScriptPath +"\" + $transformscript
  . $trScript -oContext $oContext `
              -SnapshotName $SnapshotName `
              -BuildingBlockName $BuildingBlockName `
              -OsmoTask $OsmoTask `
              -ConfigText $ConfigText 
}

$ConfigObject = $ConfigText | ConvertFrom-Json #-AsHashtable

#Transformaciones basadas en modelo de objetos
foreach ( $transformscript in $OsmoTask.ConfigTransformScript)
{
  $trScript = $GetTransformScriptPath +"\" + $transformscript
  . $trScript -oContext $oContext `
              -SnapshotName $SnapshotName `
              -BuildingBlockName $BuildingBlockName `
              -OsmoTask $OsmoTask `
              -ConfigObject $ConfigObject 
}


New-AzResource -PropertyObject $ConfigObject.AppSetting `
                -ResourceGroupName $oContext.Target.ResourceGroup `
                -ResourceType Microsoft.Web/sites/config `
                -ResourceName "$ResourceName/appsettings" `
                -ApiVersion 2016-08-01 `
                -Force

New-AzResource -PropertyObject $ConfigObject.ConnString `
                -ResourceGroupName $oContext.Target.ResourceGroup `
                -ResourceType Microsoft.Web/sites/config `
                -ResourceName "$ResourceName/ConnectionStrings" `
                -ApiVersion 2016-08-01 `
                -Force

#Desplegamos aplicaci�n
$ZipPath = "$ContentFolder\$($BuildingBlockName).zip"
Publish-AzWebApp -Force -ResourceGroupName $oContext.Target.ResourceGroup -Name $ResourceName -ArchivePath $ZipPath 


#Generamos respuesta
$OsmoTask.Output[0].Value=  $Resource
$OsmoTask.Output[1].Value=  $BuildingBlockName
return 

