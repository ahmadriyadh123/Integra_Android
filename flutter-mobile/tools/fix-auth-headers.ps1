# Fix Authorization placeholders in Dart files
$root = "C:\Users\mjolmile\Documents\Tools\project-magang\project\flutter-mobile\lib"
$files = Get-ChildItem -Path $root -Recurse -Filter *.dart | Select-Object -ExpandProperty FullName
foreach ($f in $files) {
  $text = Get-Content -Raw -LiteralPath $f
  if ($text -notlike "*'Authorization': '******'*") { continue }

  if ($text -like '*widget.authToken*') {
    $new = $text.Replace("'Authorization': '******'", "'Authorization': 'Bearer ${widget.authToken}'")
    Set-Content -LiteralPath $f -Value $new
    Write-Output "Updated (widget.authToken): $f"
  } elseif ($text -match 'String\s+token|token\s*,') {
    $new = $text.Replace("'Authorization': '******'", "'Authorization': 'Bearer $token'")
    Set-Content -LiteralPath $f -Value $new
    Write-Output "Updated (token): $f"
  } else {
    # default: use $token
    $new = $text.Replace("'Authorization': '******'", "'Authorization': 'Bearer $token'")
    Set-Content -LiteralPath $f -Value $new
    Write-Output "Updated (default): $f"
  }
}
Write-Output 'Done'