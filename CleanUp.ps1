Get-ChildItem -Recurse *.lua, *.xml, *.toc | ForEach-Object {
  $contents = [IO.File]::ReadAllText($_) -replace ';', '' -replace '`r`n', '`n' -replace '`r', '`n' -replace  '`t`n', '`n' -replace  '` `n', '`n'
  $utf8 = New-Object System.Text.UTF8Encoding $false
  [IO.File]::WriteAllText($_, $contents, $utf8)
}
