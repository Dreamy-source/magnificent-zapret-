#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

BOLD_RED='\033[1;31m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
NC='\033[0m'

QNUM=220
NFQWS_BIN="/usr/bin/nfqws"
DOWNLOAD_DEPS_PACKETS="nftables yay"
DOWNLOAD_DEPS_FLAGS="noconfirm"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REDIRECT_NFT="$SCRIPT_DIR/redirect.nft"

# LISTS

HOSTLIST="$SCRIPT_DIR/lists/hostlist.txt"
HOSTLISTEXCLUDE="$SCRIPT_DIR/lists/hostlist-exclude.txt"
IPSETEXCLUDE="$SCRIPT_DIR/lists/ipset-exclude.txt"
IPSETDISCORD="$SCRIPT_DIR/lists/ipset-discord.txt"
IPSETALL="$SCRIPT_DIR/lists/ipset-all.txt"


clear
echo -e "${BOLD_GREEN}=== magnificent ===${NC}"
echo -e "${BOLD_YELLOW}1. start nfqws (QID=$QNUM)${NC}"
echo -e "${BOLD_YELLOW}2. download dependencies${NC}"
echo -e "${BOLD_YELLOW}0. exit${NC}"
echo
echo -n "[magnificent!id] > "
read id

if [[ ! "$id" =~ ^[012]$ ]]; then
    echo -e "${BOLD_RED}invalid input!${NC}"
    exit 1
fi

if [ "$id" -eq 1 ]; then
    clear
    echo "[starting] depends checker..."

    if [ ! -f "$NFQWS_BIN" ]; then
        echo -e "${BOLD_RED}[fatal] nfqws not found at $NFQWS_BIN${NC}"
        exit 1
    fi

    if [ ! -f "$HOSTLIST" ]; then
        echo -e "${BOLD_RED}[fatal] hostlist not found at $HOSTLIST${NC}"
        exit 1
    fi

    if [ ! -f "$REDIRECT_NFT" ]; then
        echo -e "${BOLD_RED}[fatal] redirect.nft not found at $REDIRECT_NFT${NC}"
        exit 1
    fi

    echo -e "${BOLD_GREEN}[passed] checker passed${NC}"

    echo -e "[reset] reseting nft list ruleset, ipset${NC}"
    echo -e "[pkill] nfqws...${NC}"
    sudo pkill -9 nfqws 2>/dev/null || true
    sleep 1
    if sudo cat /proc/net/netfilter/nfnetlink_queue | grep -q "220"; then
        echo "[waiting] queue 220 still busy, waiting..."
        sleep 2
    fi
    echo -e "[flush] nft ruleset...${NC}"
    sudo nft flush ruleset
    sudo ipset destroy 2>/dev/null
    echo -e "[catch] cat=/proc/net/netfilter/nfnetlink_queue${NC}"
    sudo cat /proc/net/netfilter/nfnetlink_queue

    echo -e "[return] modprobe_target=nfnetlink_queue${NC}"
    sudo modprobe nfnetlink_queue

    echo -e "[catch] cat_target=nfnetlink_queue${NC}"
    sudo cat /proc/net/netfilter/nfnetlink_queue

    echo -e "[chmoding] files with sudo rights${NC}"
    sudo chmod 755 "$(dirname "$SCRIPT_DIR")"
    sudo chmod 755 "$SCRIPT_DIR"
    sudo chmod 755 "$(dirname "$HOSTLIST")"
    sudo chmod 644 "$HOSTLIST"
    sudo chmod 644 "$IPSETEXCLUDE"
    sudo chmod 644 "$IPSETALL"
    sudo chmod 644 "$HOSTLISTEXCLUDE"

    echo -e "[loading] nfqws module into kernel...${NC}"
    sudo nft -f "$REDIRECT_NFT"

    echo -e "${BOLD_GREEN}[final] passed all tests${NC}"
    echo "[starting] nfqws..."
    echo

    sudo $NFQWS_BIN \
        --qnum=$QNUM \
        --daemon \
        --uid=0 \
        \
        --filter-udp=443 \
        --dpi-desync=fake \
        --dpi-desync-repeats=11 \
        --dpi-desync-fake-quic="$SCRIPT_DIR/bin/quic_initial_www_google_com.bin" \
        --new \
        \
        --filter-tcp=80,443 \
        --hostlist="$HOSTLIST" \
        --hostlist-exclude="$HOSTLISTEXCLUDE" \
        --ipset-exclude="$IPSETEXCLUDE" \
        --dpi-desync=fake,multisplit \
        --dpi-desync-split-pos=1 \
        --dpi-desync-fooling=ts \
        --dpi-desync-repeats=8 \
        --new \
        \
        --filter-udp=443 \
        --ipset="$IPSETALL" \
        --hostlist-exclude="$HOSTLISTEXCLUDE" \
        --ipset-exclude="$IPSETEXCLUDE" \
        --dpi-desync=fake \
        --dpi-desync-repeats=11 \
        --new \
        \
        --filter-tcp=80,443 \
        --ipset="$IPSETALL" \
        --hostlist-exclude="$HOSTLISTEXCLUDE" \
        --ipset-exclude="$IPSETEXCLUDE" \
        --dpi-desync=fake,multisplit \
        --dpi-desync-split-pos=1 \
        --dpi-desync-fooling=ts \
        --dpi-desync-repeats=8
        # EXAMPLE (new line, do not remove original HOSTLIST):
        # --hostlit="$YOUR_HOSTLIST_NAME"
    
    sleep 0.5
    if pgrep -x nfqws > /dev/null; then
        echo -e "${BOLD_GREEN}[success] nfqws running (PID: $(pgrep -x nfqws))${NC}"
    else
        echo -e "${BOLD_RED}[error] nfqws failed to start${NC}"
        exit 1
    fi
fi

if [ "$id" -eq 2 ]; then
    clear
    echo -e "${BOLD_YELLOW}[install] checking dependencies...${NC}"
    
    if command -v nft &>/dev/null; then
        echo -e "${GREEN}[ok] nftables installed${NC}"
    else
        echo "[install] nftables..."
        sudo pacman -S --noconfirm nftables
    fi
    
    if command -v yay &>/dev/null; then
        echo -e "${GREEN}[ok] yay installed${NC}"
    else
        echo "[install] yay (AUR helper)..."
        sudo pacman -S --noconfirm --needed git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd "$SCRIPT_DIR"
    fi
    
    if command -v nfqws &>/dev/null; then
        echo -e "${GREEN}[ok] nfqws installed (dir=$(which nfqws))${NC}"
    else
        echo "[install] nfqws from AUR..."
        yay -S --noconfirm nfqws-bin
    fi
    
    echo -e "${BOLD_GREEN}[done] all dependencies installed${NC}"
fi

if [ "$id" -eq 0 ]; then
    echo -e "${BOLD_RED}[exit] exiting...${NC}"
    sleep 0.1
    clear
    exit 0
fi