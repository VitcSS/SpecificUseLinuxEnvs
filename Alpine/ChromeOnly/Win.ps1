# 1. Cria a pasta onde o Alpine vai morar
$wslPath = "C:\WSL\Alpine-Secure"
if (!(Test-Path $wslPath)) {
    New-Item -ItemType Directory -Force -Path $wslPath | Out-Null
}

# 2. Baixa a imagem minimalista oficial do Alpine Linux
Write-Output "📥 Baixando imagem minimalista do Alpine..."
$url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-minirootfs-3.19.1-x86_64.tar.gz"
$tarPath = "$wslPath\alpine.tar.gz"
Invoke-WebRequest -Uri $url -OutFile $tarPath

# 3. Importa a distribuicao para o WSL (Garante uma instalacao limpa)
Write-Output "📦 Importando para o WSL (Alpine-Chrome)..."
if (wsl --list | Select-String "Alpine-Chrome") {
    wsl --unregister Alpine-Chrome | Out-Null
}
wsl --import Alpine-Chrome $wslPath $tarPath

# 4. Remove o arquivo tar.gz para limpar espaco
Remove-Item $tarPath

# 5. Executa a configuracao interna com todas as dependencias corretas
Write-Output "⚙️ Instalando componentes e ferramentas de rede (isso pode levar um minuto)..."
wsl -d Alpine-Chrome -u root -- sh -c "sed -i 's/#http/http/g' /etc/apk/repositories && apk update && apk add chromium font-noto wireguard-tools iptables openresolv mesa-gl bash"

# 6. Cria o arquivo iniciar.sh dentro do Alpine de forma blindada contra erros de string
Write-Output "📝 Gerando script de inicializacao..."
$LinuxScript = @"
#!/bin/bash
echo '=========================================='
echo ' 🛡️  LIGANDO A VPN (WIREGUARD)...'
echo '=========================================='
wg-quick up wg0

echo ''
echo '=========================================='
echo ' 🌐  ABRINDO O CHROMIUM EM MODO JANELA...'
echo '=========================================='
chromium --no-sandbox --window-size=1280,720 --start-windowed --disable-gpu --disable-software-rasterizer --disable-dbus-attachments --disable-dev-shm-usage https://www.google.com

echo ''
echo '=========================================='
echo ' 🛑  FECHANDO A VPN...'
echo '=========================================='
wg-quick down wg0
"@

# Transfere o script de inicializacao para dentro do container Alpine
$LinuxScript | wsl -d Alpine-Chrome -u root -- sh -c "cat > /root/iniciar.sh && chmod +x /root/iniciar.sh"

Write-Output ""
Write-Output "========================================================"
Write-Output " 🎉 AMBIENTE CONSTRUIDO COM SUCESSO!"
Write-Output "========================================================"
Write-Output "Proximos passos:"
Write-Output "1. Abra o Windows Explorer (Win + E) e acesse esta pasta:"
Write-Output "   \\wsl.localhost\Alpine-Chrome\etc\wireguard"
Write-Output ""
Write-Output "2. Jogue o seu arquivo 'wg0.conf' dentro dela."
Write-Output ""
Write-Output "3. Para abrir o seu Chrome seguro, rode no PowerShell:"
Write-Output "   wsl -d Alpine-Chrome /root/iniciar.sh"
Write-Output "========================================================"
