$env:JAVA_HOME="C:\Program Files\Java\jdk1.8.0"
$env:PYTHON="C:\Python27-x64"
$env:PATH="$($env:PYTHON);$($env:PYTHON)\Scripts;$($env:JAVA_HOME)\bin;$($env:PATH)"
$env:PATHEXT="$($env:PATHEXT);.PY"

Write-Host "Smoke tests for Apache Cassandra $env:CCM_VERSION using $env:DRIVER_REPO on Windows"
Write-Host "Using $env:SERVER_PACKAGE_URL"

# Install Ant
$ant_base = "$($env:USERPROFILE)\ant"
$ant_path = "$($ant_base)\apache-ant-1.9.7"
If (!(Test-Path $ant_path)) {
  Write-Host "Installing Ant"
  $ant_url = "https://www.dropbox.com/s/lgx95x1jr6s787l/apache-ant-1.9.7-bin.zip?dl=1"
  $ant_zip = "C:\Users\appveyor\apache-ant-1.9.7-bin.zip"
  Invoke-WebRequest -Uri $ant_url -OutFile $ant_zip
  expand-archive -Path $ant_zip -destinationpath $ant_base
}
$env:PATH="$($ant_path)\bin;$($env:PATH)"

Write-Host "Installing java Cryptographic Extensions, needed for SSL..."
# Install Java Cryptographic Extensions, needed for SSL.
$target = "$($env:JAVA_HOME)\jre\lib\security"
# If this file doesn't exist we know JCE hasn't been installed.
$jce_indicator = "$target\README.txt"
$zip = "C:\Users\appveyor\jce_policy-8.zip"

If (!(Test-Path $jce_indicator)) {
  if(!(Test-Path $zip)) {
    $url = "https://www.dropbox.com/s/al1e6e92cjdv7m7/jce_policy-8.zip?dl=1"
    Write-Host "Downloading file..."
    Invoke-WebRequest -Uri $url -OutFile $zip
    Write-Host "Download completed."
  }

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  Write-Host "Extracting zip file..."
  expand-archive -Path $zip -destinationpath $target
  Write-Host "Extraction completed."

  $jcePolicyDir = "$target\UnlimitedJCEPolicyJDK8"
  Move-Item $jcePolicyDir\* $target\ -force
  Remove-Item $jcePolicyDir
}

# Install Python Dependencies for CCM.
Write-Host "Installing CCM and its dependencies"
Start-Process python -ArgumentList "-m pip install psutil pyYaml six" -Wait -NoNewWindow

$env:CCM_PATH="C:$($env:USERPROFILE)\ccm"

If (!(Test-Path $env:CCM_PATH)) {
  Write-Host "Cloning git ccm... $($env:CCM_PATH)"
  Start-Process git -ArgumentList "clone https://github.com/pcmanus/ccm.git $($env:CCM_PATH)" -Wait -NoNewWindow
  Write-Host "git ccm cloned"
  pushd $env:CCM_PATH
  Start-Process python -ArgumentList "setup.py install" -Wait -NoNewWindow
  popd
}

$sslPath="C:$($env:USERPROFILE)\ssl"
If (!(Test-Path $sslPath)) {
  Copy-Item "$($env:CCM_PATH)\ssl" -Destination $sslPath -Recurse
}

Write-Host "Set execution Policy"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

$INSTALL_PATH = "$env:USERPROFILE\.ccm\repository\$env:CCM_VERSION"

New-Item -ItemType Directory -Path $INSTALL_PATH
Invoke-WebRequest -Uri $SERVER_PACKAGE_URL -OutFile server-bin.tar.gz
tar xzf server-bin.tar.gz -C $INSTALL_PATH --strip-components=1

$MyPath = "$INSTALL_PATH\0.version.txt"
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllText($MyPath, $env:CCM_VERSION, $Utf8NoBomEncoding)

# Verify that ccm cluster creation succeeds
ccm create test -v $env:CCM_VERSION
ccm remove test

# Clone the driver repository
git clone https://github.com/datastax/$env:DRIVER_REPO
cd $env:DRIVER_REPO