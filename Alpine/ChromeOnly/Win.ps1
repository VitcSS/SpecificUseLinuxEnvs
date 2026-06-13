# 1. Cria a pasta onde o Alpine vai morar
$wslPath = "C:\WSL\Alpine-Secure"
if (!(Test-Path $wslPath)) {
    New-Item -ItemType Directory -Force -Path $wslPath | Out-Null
}

# 2. Baixa a imagem minimalista oficial do Alpine Linux
echo "📥 Baixando imagem minimalista do Alpine..."
$url = "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-minirootfs-3.19.1-x86_64.tar.gz"
$tarPath = "$wslPath\alpine.tar.gz"
Invoke-WebRequest -Uri $url -OutFile $tarPath

# 3. Importa a distribuição para o WSL
echo "📦 Importando para o WSL (Alpine-Chrome)..."
wsl --import Alpine-Chrome $wslPath $tarPath

# 4. Remove o arquivo tar.gz para limpar espaço
Remove-Item $tarPath

# 5. Executa a configuração interna com todas as dependências e correções
echo "⚙️ Instalando componentes e corrigindo rede (isso pode levar um minuto)..."
wsl -d Alpine-Chrome -u root -- sh -c '
    # Ativa o repositório community
    sed -i "s/#http/http/g" /etc/apk/repositories
    
    # Atualiza os índices
    apk update
    
    # INSTALAÇÃO DOS COMPONENTES FALTANTES:
    # - chromium e font-noto: O navegador e as fontes de texto
    # - wireguard-tools: Comando wg e wg-quick
    # - iptables: ESSENCIAL para o roteamento do WireGuard no Alpine
    # - resolvconf: ESSENCIAL para o WireGuard conseguir alterar o DNS
    # - mesa-gl: Driver para renderização estável via WSLg
    # - bash: Garante compatibilidade caso o WireGuard precise rodar scripts internos
    apk add chromium font-noto wireguard-tools iptables resolvconf mesa-gl bash
    
    # Garante a criação da pasta de configurações da VPN
    mkdir -p /etc/wireguard
    
    # Cria o script de inicialização perfeitamente configurado em modo janela
    cat << "EOF" > /root/iniciar.sh
#!/bin/bash
echo "=========================================="
echo "🛡️  LIGANDO A VPN (WIREGUARD)..."
echo "=========================================="
wg-quick up wg0

echo ""
echo "=========================================="
echo "🌐  ABRINDO O CHROMIUM EM MODO JANELA..."
echo "=========================================="
chromium --no-sandbox --window-size=1280,720 --start-windowed --disable-gpu --disable-software-rasterizer --disable-dbus-attachments --disable-dev-shm-usage https://www.google.com

echo ""
echo "=========================================="
echo "🛑  FECHANDO A VPN..."
echo "=========================================="
wg-quick down wg0
EOF

    # Dá permissão de execução ao script
    chmod +x /root/root/iniciar.sh 2>/dev/null || chmod +x /root/iniciar.sh
'

echo ""
echo "========================================================"
echo "🎉 AMBIENTE CONSTRUÍDO COM SUCESSO!"
echo "========================================================"
echo "Próximos passos:"
echo "1. Abra o Windows Explorer (Win + E) e cole isto na barra de endereços:"
echo "   \\wsl.localhost\Alpine-Chrome\etc\wireguard"
echo ""
echo "2. Jogue o seu arquivo 'wg0.conf' dentro dessa pasta."
echo ""
echo "3. Para abrir o seu Chrome seguro, rode no PowerShell:"
echo "   wsl -d Alpine-Chrome /root/iniciar.sh"
echo "========================================================"
