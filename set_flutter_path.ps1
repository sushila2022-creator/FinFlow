$userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
$flutterPath = "C:\Users\ratan\Documents\SUSHILA\flutter_windows_3.35.1-stable\flutter\bin"
if (($userPath -split ';') -notcontains $flutterPath) {
    $newPath = "$userPath;$flutterPath"
    [System.Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Output "Flutter path added to user PATH."
} else {
    Write-Output "Flutter path already exists in user PATH."
}
