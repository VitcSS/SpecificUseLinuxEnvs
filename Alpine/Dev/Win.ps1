# =======================================================================================
# SCRIPT DE AUTOMAÇÃO: Criação de ambiente Alpine no WSL para Desenvolvimento (Python/C++)
# =======================================================================================

# Configurações de caminhos (Altere se desejar)
$DistroName = "AlpineDev"
$InstallBaseDir = "C:\WSL"
$DistroDir = "$InstallBaseDir\$DistroName"
$DownloadDir = "$env:USERPROFILE\Downloads"
$TarFileName = "alpine-minrootfs-latest-x86_64.tar.gz"
$DownloadPath = "$DownloadDir\$TarFileName"

# URL da imagem oficial estável do Alpine (Minrootfs x86_64)
$AlpineUrl = "https://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-minrootfs-3.20.0-x86_64.tar.gz"

Write-Host "========== Iniciando Configuração do Alpine no WSL ==========" -ForegroundColor Cyan

# 1. Criar diretório de instalação se não existir
if (-not (Test-Path $DistroDir)) {
    Write-Host "[*] Criando diretório de instalação em: $DistroDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $DistroDir | Out-Null
} else {
    Write-Host "[!] O diretório $DistroDir já existe. Certifique-se de que não há outra instância instalada ali." -ForegroundColor DarkYellow
}

# 2. Baixar o arquivo tar.gz do Alpine se não estiver no computador
if (-not (Test-Path $DownloadPath)) {
    Write-Host "[*] Baixando a imagem do Alpine Linux..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $AlpineUrl -OutFile $DownloadPath
    Write-Host "[+] Download concluído!" -ForegroundColor Green
} else {
    Write-Host "[+] Imagem do Alpine já encontrada em Downloads. Pulando etapa de download." -ForegroundColor Green
}

# 3. Importar a Distribuição no WSL
Write-Host "[*] Importando a distribuição '$DistroName' para o WSL..." -ForegroundColor Yellow
wsl --import $DistroName $DistroDir $DownloadPath
if ($LASTEXITCODE -eq 0) {
    Write-Host "[+] Distribuição importada com sucesso!" -ForegroundColor Green
} else {
    Write-Host "[-] Erro ao importar a distribuição no WSL." -ForegroundColor Red
    exit
}

# 4. Executar comandos internos no Alpine para instalar as ferramentas de Desenvolvimento
Write-Host "[*] Atualizando pacotes e instalando dependências de desenvolvimento (Python3, C++, Git)..." -ForegroundColor Yellow

# Script inline que roda dentro do ambiente Alpine recém-criado
$AlpineSetupScript = @"
apk update && apk upgrade
apk add --no-cache \
    bash \
    git \
    openssh-client \
    iptables \
    build-base \
    g++ \
    python3 \
    py3-pip \
    libffi-dev \
    openssl-dev
"@

# Passa o bloco de comandos para o WSL executar como root
$AlpineSetupScript | wsl -d $DistroName -e sh

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[+++] AMBIENTE CONFIGURADO COM SUCESSO! [+++]" -ForegroundColor Green
    Write-Host "Para acessar sua nova VM, use o comando: wsl -d $DistroName" -ForegroundColor Cyan
    Write-Host "Ferramentas instaladas: python3, pip, g++, gcc, make, git, openssh, iptables." -ForegroundColor Gray
} else {
    Write-Host "[-] Ocorreu um erro durante a instalação interna dos pacotes no Alpine." -ForegroundColor Red
}
