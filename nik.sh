#!/bin/bash
# ==========================================
#  RenClouds NIK Extractor v2.1
#  Auto-process — tinggal enter NIK, sisanya otomatis
#  Data 100% DUMMY buat seru-seruan
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${GREEN}"
cat << "EOF"
  ██████╗ ███████╗███╗   ██╗ ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ███████╗
  ██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██╔════╝
  ██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ██║   ██║██║   ██║██║  ██║███████╗
  ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██║     ██║   ██║██║   ██║██║  ██║╚════██║
  ██║  ██║███████╗██║ ╚████║╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝███████║
  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝
EOF
echo -e "${NC}"
echo -e "${YELLOW}        [ RenClouds Engine v2.1 - NIK Query Terminal ]${NC}"
echo -e "${YELLOW}        ==============================================${NC}"
echo

# ---------- INPUT ----------
read -p "$(echo -e ${CYAN}"[?]${NC} Enter NIK target (16 digit): ")" NIK

if [[ ! "$NIK" =~ ^[0-9]{16}$ ]]; then
    echo -e "${RED}[!] NIK harus 16 digit angka, bro!${NC}"
    exit 1
fi

# ---------- AUTO PROCESS DIMULAI ----------
echo
echo -e "${GREEN}[+]${NC} Target NIK      : ${MAGENTA}$NIK${NC}"
echo -e "${GREEN}[+]${NC} Endpoint        : ${MAGENTA}rc-query.renclouds.io:443${NC}"
echo -e "${GREEN}[+]${NC} Mode            : ${MAGENTA}AUTO EXTRACT${NC}"
echo
sleep 0.4

# Fase 1 - koneksi
echo -e "${BLUE}[PHASE 1/5]${NC} ${YELLOW}Membangun koneksi...${NC}"
for step in "Bypassing firewall" "Spoofing MAC address" "Rotating proxy chain" "Establishing encrypted tunnel"; do
    printf "  ${CYAN}->${NC} %-28s" "$step"
    for i in {1..8}; do printf "."; sleep 0.04; done
    echo -e " ${GREEN}OK${NC}"
done
sleep 0.2

# Fase 2 - scan database
echo
echo -e "${BLUE}[PHASE 2/5]${NC} ${YELLOW}Scanning RenClouds database...${NC}"
for db in "penduduk_master" "nik_index" "kependudukan_cache" "region_map" "dukcapil_mirror"; do
    printf "  ${CYAN}->${NC} ${MAGENTA}%-20s${NC}" "$db"
    for i in {1..12}; do printf "▓"; sleep 0.02; done
    echo -e " ${GREEN}[200 OK]${NC}"
done
sleep 0.2

# Fase 3 - extract
echo
echo -e "${BLUE}[PHASE 3/5]${NC} ${YELLOW}Extracting record...${NC}"
bar_len=42
for i in $(seq 0 $bar_len); do
    filled=$(printf "%${i}s" | tr ' ' '█')
    empty=$(printf "%$((bar_len-i))s" | tr ' ' '░')
    printf "\r  [${GREEN}${filled}${NC}${empty}] %3d%%" $((i*100/bar_len))
    sleep 0.035
done
echo -e "\n"

# Fase 4 - decrypt & validasi
echo -e "${BLUE}[PHASE 4/5]${NC} ${YELLOW}Decrypting payload...${NC}"
for step in "Decrypting AES-256" "Validating checksum" "Cross-check region code" "Parsing record fields"; do
    printf "  ${CYAN}->${NC} %-28s" "$step"
    for i in {1..6}; do printf "."; sleep 0.05; done
    echo -e " ${GREEN}OK${NC}"
done
sleep 0.2

# ---------- HASIL ----------
clear
echo -e "${GREEN}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║        RenClouds - RECORD FOUND [✓]               ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${YELLOW}──────────────────────────────────────────────────────${NC}"
echo -e "  ${CYAN}NIK${NC}         : ${MAGENTA}$NIK${NC}"
echo -e "  ${CYAN}Nama${NC}        : ${MAGENTA}Budi Santoso${NC}"
echo -e "  ${CYAN}TTL${NC}         : ${MAGENTA}Jakarta, 01-01-1990${NC}"
echo -e "  ${CYAN}JK${NC}          : ${MAGENTA}Laki-laki${NC}"
echo -e "  ${CYAN}Alamat${NC}      : ${MAGENTA}Jl. Mawar No. 12, RT 03/RW 05${NC}"
echo -e "  ${CYAN}Kel/Desa${NC}    : ${MAGENTA}Menteng${NC}"
echo -e "  ${CYAN}Kecamatan${NC}   : ${MAGENTA}Menteng${NC}"
echo -e "  ${CYAN}Kab/Kota${NC}    : ${MAGENTA}Jakarta Pusat${NC}"
echo -e "  ${CYAN}Provinsi${NC}    : ${MAGENTA}DKI Jakarta${NC}"
echo -e "  ${CYAN}Agama${NC}       : ${MAGENTA}Islam${NC}"
echo -e "  ${CYAN}Status${NC}      : ${MAGENTA}Kawin${NC}"
echo -e "  ${CYAN}Pekerjaan${NC}   : ${MAGENTA}Karyawan Swasta${NC}"
echo -e "${YELLOW}──────────────────────────────────────────────────────${NC}"
echo

# Fase 5 - cleanup otomatis
echo -e "${BLUE}[PHASE 5/5]${NC} ${YELLOW}Cleanup jejak...${NC}"
for log in "access.log" "bash_history" "syslog" "rc_trace.log" "session.tmp"; do
    printf "  ${CYAN}->${NC} menghapus ${MAGENTA}%-16s${NC}" "$log"
    sleep 0.25
    echo -e " ${GREEN}OK${NC}"
done
printf "  ${CYAN}->${NC} menutup tunnel       "
sleep 0.3
echo -e "${GREEN}OK${NC}"
echo
echo -e "${GREEN}[✓] Proses selesai.${NC}"
echo -e "${YELLOW}[i] RenClouds — semua data Telah Di Simpan Di VPS gunakan /renclouds untuk membuka txt${NC}"
