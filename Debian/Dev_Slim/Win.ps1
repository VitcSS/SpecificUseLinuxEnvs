# --- Configuration ---
$DistroName = "Debian-ML"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host " 1/3: Installing Official Baseline Debian via WSL..." -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# Check if standard Debian is already registered; if not, download the official app store layer
if ((wsl --list) -notmatch "Debian") {
    Write-Host "Fetching official stable Debian layer from Microsoft..." -ForegroundColor Yellow
    wsl --install Debian --no-launch
}

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host " 2/3: Creating the Slim ML Instance Custom Copy..." -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# We use the official engine to create an isolated, slim production clone called 'Debian-ML'
$InstallDir = "C:\wslDistros\$DistroName"
$DownloadDir = "$env:USERPROFILE\wslDistros"
if (Test-Path $InstallDir) { Remove-Item $InstallDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
New-Item -ItemType Directory -Force -Path $DownloadDir | Out-Null

Write-Host "Exporting minimal blueprint..." -ForegroundColor Yellow
wsl --export Debian "$DownloadDir\base.tar"
Write-Host "Importing pristine '$DistroName' workspace..." -ForegroundColor Yellow
wsl --import $DistroName $InstallDir "$DownloadDir\base.tar"
Remove-Item "$DownloadDir\base.tar" -Force

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host " 3/3: Slimming System & Injecting ML Stack (CUDA/PyTorch)..." -ForegroundColor Cyan
Write-Host "      *This will take a few minutes. Please wait...*" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Cyan

$BashCommands = @'
set -e

# Purge any default background bloat or unwanted interactive applications
apt-get update
apt-get install -y --no-install-recommends \
    python3-minimal python3-pip python3-venv git curl ca-certificates gnupg sudo

# Register NVIDIA CUDA repository keys for Debian 12
curl -fSsL https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/3bf863cc.pub | gpg --dearmor -o /usr/share/keyrings/nvidia-drivers.gpg
echo "deb [signed-by=/usr/share/keyrings/nvidia-drivers.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /" > /etc/apt/sources.list.d/nvidia-cuda.list

# Install minimal backend CUDA runtime elements (no system/display driver bloat)
apt-get update
apt-get install -y --no-install-recommends \
    cuda-nvcc-12-4 libcublas-12-4 libcufft-12-4 libcurand-12-4 libcusolver-12-4 libcusparse-12-4 libcudnn9

# Configure developer user
if ! id -u mluser >/dev/null 2>&1; then
    useradd -m -s /bin/bash mluser
    echo "mluser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
fi

# Set up clean python isolation structure
sudo -u mluser python3 -m venv /home/mluser/ml_env
sudo -u mluser /home/mluser/ml_env/bin/pip install --no-cache-dir --upgrade pip
sudo -u mluser /home/mluser/ml_env/bin/pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
sudo -u mluser /home/mluser/ml_env/bin/pip install --no-cache-dir jupyterlab pandas scikit-learn numpy

# Auto-activate on startup
if ! grep -q "ml_env/bin/activate" /home/mluser/.bashrc; then
    echo "source ~/ml_env/bin/activate" >> /home/mluser/.bashrc
fi

# Set default user login mapping
cat <<EOF > /etc/wsl.conf
[user]
default=mluser
[boot]
systemd=false
EOF

# Clear apt data structures to minimize disk print
apt-get clean
rm -rf /var/lib/apt/lists/*
'@

# Pipe directly into our newly deployed distro
$BashCommands | wsl -d $DistroName -u root /bin/bash

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host " COMPLETE! Slim Debian ML Environment is Active." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green

wsl -d $DistroName
