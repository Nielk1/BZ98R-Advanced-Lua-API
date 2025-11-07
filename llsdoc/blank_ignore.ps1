param(
    [string]$InputFile,
    [string]$OutputFile
)

$ignoring = $false

Get-Content $InputFile | ForEach-Object {
    if ($_ -match '^ *---? \[\[START[_ ]?IGNORE\]\]$') {
        $ignoring = $true
        #$_
		""
    }
    elseif ($_ -match '^ *---? \[\[END[_ ]?IGNORE\]\]$') {
        $ignoring = $false
        #$_
		""
    }
    elseif ($ignoring) {
        ""
    }
    else {
        $_
    }
} | Set-Content $OutputFile