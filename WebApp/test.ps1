function Get-OsmoParametersAndConfig( $oRoot="." )
{
    $ParmPath = "$oRoot\Parametros\OsmoeuropaParam.json"
    $ConfigPath = "$oRoot\Configuracion\OsmoeuropaConfig.json"
    $Param = Get-Content -Path $ParmPath | ConvertFrom-Json
    $Config = Get-Content -Path $ConfigPath | ConvertFrom-Json

    $Result = @{ "Param" = $Param;
                 "Config" = $Config
                 }

    return $Result
}

function New-OsmoContext
{   
    [CmdletBinding()] 
    param(
            [Parameter(Mandatory=$true)]
            $oparams )

    return $oparams
    

}




Import-module Az
$OsmoTree = "C:\Users\josem\Documents\Gadesoft\OSMOEUROPA\Migración\script\OsmoEuropaScript"
$OsmoParamAndConfig = (Get-OsmoParametersAndConfig -oroot $OsmoTree )
$OsmoParamAndConfig.Param.Paths.OsmoTree = $OsmoTree
$OsmoContext = (New-OsmoContext  -oparams $OsmoParamAndConfig["param"])

#$cred = Get-Credential -UserName $OsmoContext.Source.Identity -Message "Conexión a Azure"

<#
$OsmoContext.Source.AzureContext = (Connect-AzAccount -Tenant $OsmoContext.Source.TenantId `
                                                      -Subscription $OsmoContext.Source.SubscriptionId `
                                                      -AccountId  $OsmoContext.Source.Identity)
                                                      #-Credential $cred)
#>
                                                      

Get-AzResourceGroup 

#Creamos la estructura de archivos del snapshot
. $OsmoTree\$($OsmoContext.Paths.Tree.GeneralBlocks)\CrearArbolSnapshot\CrearArbolSnapshot -path "$OsmoTree\$($osmoContext.Paths.Snapshot.BasePath)" `
                                                                                           -SnapshotName Test 
#. $OsmoTree\$($OsmoContext.Paths.Tree.GeneralBlocks)\CrearArbolSnapshot\CrearArbolSnapshot -path "$OsmoTree\$($osmoContext.Paths.Snapshot.BasePath)" `
#                                                                                           -SnapshotName Test `
#                                                                                           -BuildingBlockName "OsmoIotShedMainGatewayFree"

#. .\SvcPlanSave.ps1 -oContext $OsmoContext -SnapshotName "test" -BuildingBlockName "OsmoIotShedMainGatewayFree" 

. $OsmoTree\$($OsmoContext.Paths.Tree.BuildingBlocks)\WebApp\WebApp.ps1 -Operation Save -oContext $OsmoContext -SnapshotName "test" -BuildingBlockName "OsmoIotShedMainGateway"



