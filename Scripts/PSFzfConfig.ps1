# Fuzzy Diff
function fdi {
    $fileToDiff = fgs
    if($fileToDiff) {
        git diff $fileToDiff
    }
}

function fhi {
    $history = [System.Linq.Enumerable]::Reverse([System.Linq.Enumerable]::Distinct( [string[]]([Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems().CommandLine)))
    $command = $history | fzf --header="PSReadLine History Search"
    if ($command) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join '; '))
    }
}

Set-PSReadLineKeyHandler -Chord 'Alt+c' -ScriptBlock { Invoke-FuzzySetLocation }
Set-PSReadLineKeyHandler -Chord 'Alt+t' -ScriptBlock { Invoke-Fzf }
Set-PSReadLineKeyHandler -Chord 'Alt+o' -ScriptBlock { Invoke-FuzzyEdit }
Set-PSReadLineKeyHandler -Chord 'Alt+k' -ScriptBlock { Invoke-FuzzyKillProcess }
