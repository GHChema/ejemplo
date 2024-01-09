[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Load","Save","None")]
    [string] $Operation="None",
    
    $oContext,
    [string] $SnapshotName,
    [string] $BuildingBlockName,
    $PlanResource,
    $PlanSrcName,
    $OsmoTask)


    $CmdPath = "$($oContext.Paths.OsmoTree)\$($oContext.Paths.Tree.BuildingBlocks)WebApp"
    $CrearArbolSnapshotPath = "$($oContext.Paths.OsmoTree)\$($oContext.Paths.Tree.GeneralBlocks)CrearArbolSnapshot"

    switch ($Operation) 
    {
        "load" {
                . $CmdPath\WebAppLoad.ps1 -oContext $oContext `
                                             -SnapshotName $SnapshotName  `
                                             -BuildingBlockName $BuildingBlockName `
                                             -PlanResource $PlanResource `
                                             -PlanSrcName $PlanSrcName `
                                             -OsmoTask $OsmoTask
               }

        
        "save" {
                

                . $CrearArbolSnapshotPath\CrearArbolSnapshot.ps1 `
                            -path "$($oContext.Paths.OsmoTree)\$($oContext.Paths.Snapshot.BasePath)" `
                            -SnapshotName $SnapshotName `
                            -BuildingBlockName $BuildingBlockName  `
                            -BuildingBlockType $OsmoTask.Type

                
                
                . $CmdPath\WebAppSave.ps1 `
                            -oContext $oContext `
                            -SnapshotName $SnapshotName `
                            -BuildingBlockName $BuildingBlockName `
                            -OsmoTask $OsmoTask
                
               }   
        default {
            throw "Operación <$Operation> no soportada"
        }
    }

    