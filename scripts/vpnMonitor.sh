#!/bin/bash
source /scripts/ENV

# Configuração básica
WG_INTERFACE="wg0"
LOG_FILE="/tmp/wireguard_iptables.log"
STATE_FILE="/tmp/wireguard_state"
ALIAS_FILE="/scripts/wg_client_aliases"  # Arquivo opcional para mapeamento

# Função para enviar mensagens para o Telegram
send_telegram_message() {
    local message=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d chat_id="$CHAT_ID" \
        -d text="$message" &> /dev/null
}

# Função para obter alias do cliente (se o arquivo existir)
get_client_alias() {
    local ip=$1
    if [ -f "$ALIAS_FILE" ]; then
        local last_octet=$(echo "$ip" | awk -F. '{print $4}')
        local alias=$(grep -i "^$last_octet" "$ALIAS_FILE" | cut -d'=' -f2 | xargs)
        if [ -n "$alias" ]; then
            echo "$alias"
            return
        fi
    fi
    echo "$ip"  # Retorna o IP se não encontrar alias
}

# Funções originais de iptables (mantidas iguais)
add_iptables_rule() {
    if ! sudo iptables -C INPUT -i "$WG_INTERFACE" -j ACCEPT 2>/dev/null; then
        sudo iptables -I INPUT -i "$WG_INTERFACE" -j ACCEPT
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Regra adicionada com sucesso." | tee -a "$LOG_FILE"
    fi
}

remove_iptables_rule() {
    if sudo iptables -C INPUT -i "$WG_INTERFACE" -j ACCEPT 2>/dev/null; then
        sudo iptables -D INPUT -i "$WG_INTERFACE" -j ACCEPT
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Regra removida com sucesso." | tee -a "$LOG_FILE"
    fi
}

# Função de ping original
is_client_reachable() {
    local client_ip=$1
    if ping -c 1 -W 1 "$client_ip" &> /dev/null; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Cliente $client_ip está acessível." | tee -a "$LOG_FILE"
        return 0
    else
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Cliente $client_ip não está acessível." | tee -a "$LOG_FILE"
        return 1
    fi
}

# Obtenção de clientes conectados (original)
get_connected_clients() {
    sudo wg show | grep -B 1 "latest handshake" | grep "allowed ips" | awk '{print $3}' | cut -d'/' -f1
}

# Lógica principal (quase igual)
previous_state=$(cat "$STATE_FILE" 2>/dev/null || echo "")
connected_clients=$(get_connected_clients)
current_state=""
aliases_list=""

for client_ip in $connected_clients; do
    if is_client_reachable "$client_ip"; then
        current_state+="$client_ip "
        aliases_list+="$(get_client_alias "$client_ip"), "
    fi
done

# Remove a vírgula e espaço final
aliases_list=${aliases_list%, }

# Ordena os IPs para consistência (como na versão original)
current_state=$(echo "$current_state" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ $//')

if [ "$current_state" != "$previous_state" ]; then
    echo "$current_state" > "$STATE_FILE"

    if [ -z "$current_state" ]; then
      message="[🔴VPN] Todos os clientes se desconectaram ou não estão acessíveis no WireGuard."
      remove_iptables_rule
    else
      message="[🟢VPN] Clientes conectados e acessíveis no WireGuard: $current_state"
      formatted_aliases=$(echo "$aliases_list" | sed 's/, /\n/g')
      message="$message - $formatted_aliases"
      add_iptables_rule
    fi
    send_telegram_message "$message"
fi
