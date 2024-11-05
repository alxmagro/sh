#!/bin/bash

INSTALL_SCRIPT_NAME="wonderwall"

# Verifica se o usuário passou o diretório do script
if [ -z "$1" ]; then
    echo "Erro: você precisa fornecer o diretório do script."
    echo "Uso: $0 <caminho_para_o_diretorio_do_script>"
    exit 1
fi

# Define o nome do script e o diretório de destino
INSTALL_SCRIPT_DIR="$1/$INSTALL_SCRIPT_NAME"

# Cria o diretório do script e a subpasta assets, se não existirem
mkdir -p "$INSTALL_SCRIPT_DIR/assets"

# Verifica se jq está instalado, se não, instala
if ! command -v jq &> /dev/null; then
    echo "Instalando jq..."
    sudo apt-get install jq -y
fi

# Passo 1: Criar o script run.sh no diretório de destino
RUN_SCRIPT="$INSTALL_SCRIPT_DIR/run.sh"
cat << EOF > "$RUN_SCRIPT"
#!/bin/bash

# Diretório onde o script está localizado
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="\$SCRIPT_DIR/config.txt"
WALLPAPER_DIR="\$SCRIPT_DIR/assets"
WALLPAPER_FILE="\$WALLPAPER_DIR/wallpaper-of-the-day.jpg"

# Lê o arquivo de configuração
source "\$CONFIG_FILE"

# Verifica se o script já foi executado hoje
TODAY=\$(date +%Y-%m-%d)
if [ -f "\$CONFIG_FILE" ] && grep -q "\$TODAY" "\$CONFIG_FILE"; then
    echo "O wallpaper já foi atualizado hoje."
    exit 0
fi

# Verifica se o ENGINE contém vírgula (múltiplos motores)
if [[ "\$ENGINE" == *","* ]]; then
    # Divide a string pela vírgula e escolhe um valor aleatório
    IFS=',' read -r -a ENGINES <<< "\$ENGINE"
    RANDOM_ENGINE=\${ENGINES[\$RANDOM % \${#ENGINES[@]}]}
else
    # Usa o valor único do ENGINE
    RANDOM_ENGINE=\$ENGINE
fi

# Chama o middleware correspondente
"\$SCRIPT_DIR/middleware_\$RANDOM_ENGINE.sh" "\$CONFIG_FILE"

# Define o wallpaper como plano de fundo no ElementaryOS
gsettings set org.gnome.desktop.background picture-uri "file://\$WALLPAPER_FILE"
gsettings set org.gnome.desktop.background picture-options "zoom"

# Atualiza o arquivo de controle com a data atual
sed -i "s|LAST_UPDATE=.*|LAST_UPDATE=\$TODAY|" "\$CONFIG_FILE"
EOF

# Tornar o script run.sh executável
chmod +x "$RUN_SCRIPT"

# Passo 2: Criar o script middleware_bing.sh
BING_SCRIPT="$INSTALL_SCRIPT_DIR/middleware_bing.sh"
cat << EOF > "$BING_SCRIPT"
#!/bin/bash

CONFIG_FILE=\$1
source "\$CONFIG_FILE"

# Diretórios e arquivos
WALLPAPER_FILE="\$SCRIPT_DIR/assets/wallpaper-of-the-day.jpg"

# URL da API do Bing para buscar o wallpaper do dia
BING_URL="https://www.bing.com"
BING_JSON=\$(curl -s "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=pt-BR")

# Extrai o URL da imagem
IMAGE_URL=\$(echo \$BING_JSON | grep -oP '(?<="url":")[^"]+')

# Concatena a URL completa da imagem
FULL_IMAGE_URL="\$BING_URL\$IMAGE_URL"

# Faz o download da imagem
curl -s -o "\$WALLPAPER_FILE" "\$FULL_IMAGE_URL"
EOF

# Tornar o script middleware_bing.sh executável
chmod +x "$BING_SCRIPT"

# Passo 3: Criar o script middleware_unsplash.sh
UNSPLASH_SCRIPT="$INSTALL_SCRIPT_DIR/middleware_unsplash.sh"
cat << EOF > "$UNSPLASH_SCRIPT"
#!/bin/bash

CONFIG_FILE=\$1
source "\$CONFIG_FILE"

# Verifica se a chave de acesso da API do Unsplash está configurada
if [ -z "\$UNSPLASH_CLIENT_ID" ]; then
    echo "Erro: Chave de acesso do Unsplash não configurada."
    exit 1
fi

# Diretórios e arquivos
WALLPAPER_FILE="\$SCRIPT_DIR/assets/wallpaper-of-the-day.jpg"

# Faz o download da imagem do Unsplash com base na consulta
UNSPLASH_URL=\$(curl -H "Authorization: Client-ID \$UNSPLASH_CLIENT_ID" \
"https://api.unsplash.com/photos/random?orientation=landscape&query=\$UNSPLASH_QUERY" | \
jq -r ".urls.\$UNSPLASH_IMAGE_SIZE")

# Faz o download da imagem
curl -s -o "\$WALLPAPER_FILE" "\$UNSPLASH_URL"
EOF

# Tornar o script middleware_unsplash.sh executável
chmod +x "$UNSPLASH_SCRIPT"

# Passo 4: Criar o arquivo config.txt com chave-valor
CONFIG_FILE="$INSTALL_SCRIPT_DIR/config.txt"
cat << EOF > "$CONFIG_FILE"
ENGINE=bing # bing, unsplash (require UNSPLASH_* variables) or multiples (comma-separated)
LAST_UPDATE=
UNSPLASH_CLIENT_ID=
UNSPLASH_QUERY=nature+night
UNSPLASH_IMAGE_SIZE=full # raw, full, regular
EOF

# Passo 5: Criar o arquivo wonderwall.desktop no autostart
AUTOSTART_DIR="$HOME/.config/autostart"
DESKTOP_FILE="$AUTOSTART_DIR/wonderwall.desktop"

mkdir -p "$AUTOSTART_DIR"
cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Exec=$RUN_SCRIPT
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Atualizador de Wallpaper Wonderwall
Comment=Baixa e atualiza o wallpaper do dia
Icon=io.elementary.photos
EOF

# Passo 6: Criar o script uninstall.sh no diretório de destino
UNINSTALL_SCRIPT="$INSTALL_SCRIPT_DIR/uninstall.sh"
cat << EOF > "$UNINSTALL_SCRIPT"
#!/bin/bash

# Remove o arquivo .desktop do autostart
rm -f "$DESKTOP_FILE"

echo "Arquivo .desktop removido com sucesso."
EOF

# Tornar o script uninstall.sh executável
chmod +x "$UNINSTALL_SCRIPT"

echo "Instalação completa!"
echo "Os scripts foram instalados em $INSTALL_SCRIPT_DIR."
echo "O wallpaper será salvo em $INSTALL_SCRIPT_DIR/assets."
echo "Use o script de desinstalação para remover a configuração de autostart."
echo "Para trocar o engine de wallpapers, edite o arquivo $CONFIG_FILE."
