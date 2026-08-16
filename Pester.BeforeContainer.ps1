# Setup that every test container in this repository needs.
#
# Pester dot-sources this file into the run session state before each container is
# discovered and run, so a single .Tests.ps1 opened on its own (from an editor's
# Test Explorer, or with Invoke-Pester on one path) gets the same helpers that
# ./test.ps1 sets up for a full run.
#
# Without it, a file that calls one of these while it is being discovered fails
# with "The term 'InPesterModuleScope' is not recognized", because test.ps1
# defines them in the parent session and nothing carries that into an isolated
# run.
#
# Keep this idempotent. It runs before every container, and ./test.ps1 has
# usually set the same things up already.

# Axiom, the Verify-* assertions nearly every test in this repository calls.
$axiomModule = "$PSScriptRoot/tst/axiom/Axiom.psm1"
if ((Test-Path -LiteralPath $axiomModule) -and -not (Get-Module -Name Axiom)) {
    Import-Module $axiomModule -DisableNameChecking
}

# Mirrors the New-Module block in test.ps1. In module scope on purpose, the
# implementation Pester relies on needs to be in a different session state than
# the module scope it targets.
if (-not (Get-Module -Name TestHelpers)) {
    New-Module -Name TestHelpers -ScriptBlock {
        function InPesterModuleScope {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [scriptblock]
                $ScriptBlock
            )

            $module = Get-Module -Name Pester -ErrorAction Stop
            . $module $ScriptBlock
        }

        function New-Dictionary ([hashtable]$Hashtable) {
            $d = [System.Collections.Generic.Dictionary[string, object]]::new()
            $Hashtable.GetEnumerator() | ForEach-Object { $d.Add($_.Key, $_.Value) }

            $d
        }

        function Clear-WhiteSpace ($Text) {
            "$($Text -replace "(`t|`n|`r)"," " -replace "\s+"," ")".Trim()
        }
    } | Out-Null
}
