#!/bin/bash

# 1. Root privilege check
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo (e.g., sudo ./omni-swap.sh)"
  exit 1
fi

# 2. Automatically Detect Linux Distribution & Package Manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$ID
    DISTRO_LIKE=$ID_LIKE
else
    echo "Error: Cannot determine Linux distribution metadata."
    exit 1
fi

if [[ "$DISTRO_ID" == "arch" || "$DISTRO_LIKE" == "arch" || "$DISTRO_ID" == "cachyos" ]]; then
    PKGMGR="pacman"
elif [[ "$DISTRO_ID" == "fedora" || "$DISTRO_LIKE" == "fedora" ]]; then
    PKGMGR="dnf"
elif [[ "$DISTRO_ID" == "debian" || "$DISTRO_LIKE" == "debian" || "$DISTRO_ID" == "ubuntu" || "$DISTRO_ID" == "linuxmint" ]]; then
    PKGMGR="apt"
    export DEBIAN_FRONTEND=noninteractive
else
    echo "Error: Unsupported distribution ($DISTRO_ID). This script supports Arch, Fedora, and Debian families."
    exit 1
fi

# 3. Detect the currently running DE or WM
detect_current_env() {
    if pgrep -x "gnome-shell" >/dev/null; then
        echo "GNOME (DE)"
    elif pgrep -x "kwin_wayland" >/dev/null || pgrep -x "kwin_x11" >/dev/null; then
        echo "KDE-Plasma (DE)"
    elif pgrep -x "xfce4-session" >/dev/null; then
        echo "XFCE (DE)"
    elif pgrep -x "cinnamon" >/dev/null; then
        echo "Cinnamon (DE)"
    elif pgrep -x "mate-session" >/dev/null; then
        echo "MATE (DE)"
    elif pgrep -x "hyprland" >/dev/null; then
        echo "Hyprland (WM)"
    elif pgrep -x "i3" >/dev/null; then
        echo "i3wm (WM)"
    elif pgrep -x "sway" >/dev/null; then
        echo "Sway (WM)"
    else
        echo "Unknown"
    fi
}

clear 2>/dev/null || true
CURRENT_ENV=$(detect_current_env)

echo "================================================="
echo "   Universal Omni-Workspace Swapper v3.1      "
echo "================================================="
echo "OS Family Detected: [$DISTRO_ID / $PKGMGR]"
echo "Active Interface:   [$CURRENT_ENV]"
echo "================================================="

# Master framework array
ALL_ENVS=(
    "KDE-Plasma (DE)" "GNOME (DE)" "XFCE (DE)" 
    "Cinnamon (DE)" "MATE (DE)" "Hyprland (WM)" 
    "i3wm (WM)" "Sway (WM)"
)
AVAILABLE_ENVS=()

# Dynamically filter out the current desktop environment
for env in "${ALL_ENVS[@]}"; do
    if [ "$env" != "$CURRENT_ENV" ]; then
        AVAILABLE_ENVS+=("$env")
    fi
done

echo "Select the target workspace to deploy:"
for i in "${!AVAILABLE_ENVS[@]}"; do
    echo "  $((i+1))) ${AVAILABLE_ENVS[$i]}"
done
echo "  $(( ${#AVAILABLE_ENVS[@]} + 1 ))) Exit"
echo "================================================="

read -p "Select an option [1-$(( ${#AVAILABLE_ENVS[@]} + 1 ))]: " choice

if [[ "$choice" -ge 1 && "$choice" -le "${#AVAILABLE_ENVS[@]}" ]]; then
    TARGET_ENV="${AVAILABLE_ENVS[$((choice-1))]}"
elif [[ "$choice" -eq "$(( ${#AVAILABLE_ENVS[@]} + 1 ))" ]]; then
    echo "Exiting. No changes made."
    exit 0
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# =========================================================
# 4. OPTIONAL DEEP PURGE PHASE (Now Executing FIRST)
# =========================================================
echo "================================================="
read -p "Complete the swap by permanently deleting $CURRENT_ENV? (y/n): " purge_choice
echo "================================================="

if [[ "$purge_choice" =~ ^[Yy]$ ]]; then
    echo -e "\nPurging $CURRENT_ENV assets from disk..."
    
    if [ "$PKGMGR" == "pacman" ]; then
        case $CURRENT_ENV in
            "GNOME (DE)")      pacman -Rns --noconfirm gnome gnome-extra cachyos-gnome-settings gnome-shell-extension-appindicator nautilus-python nautilus-open-any-terminal 2>/dev/null || true ;;
            "KDE-Plasma (DE)") pacman -Rns --noconfirm plasma-meta kde-applications sddm-kcm 2>/dev/null || true ;;
            "XFCE (DE)")       pacman -Rns --noconfirm xfce4 xfce4-goodies 2>/dev/null || true ;;
            "Cinnamon (DE)")   pacman -Rns --noconfirm cinnamon nemo 2>/dev/null || true ;;
            "MATE (DE)")       pacman -Rns --noconfirm mate mate-extra 2>/dev/null || true ;;
            "Hyprland (WM)")   pacman -Rns --noconfirm hyprland cachyos-hyprland-settings 2>/dev/null || true ;;
            "i3wm (WM)")       pacman -Rns --noconfirm i3-wm cachyos-i3wm-settings 2>/dev/null || true ;;
            "Sway (WM)")       pacman -Rns --noconfirm sway 2>/dev/null || true ;;
        esac
        pacman -Rns --noconfirm $(pacman -Qtdq) 2>/dev/null || true

    elif [ "$PKGMGR" == "dnf" ]; then
        case $CURRENT_ENV in
            "GNOME (DE)")      dnf remove -y @gnome-desktop ;;
            "KDE-Plasma (DE)") dnf remove -y plasma-workspace @kde-desktop-environment ;;
            "XFCE (DE)")       dnf remove -y @xfce-desktop-environment ;;
            "Cinnamon (DE)")   dnf remove -y @cinnamon-desktop-environment ;;
            "MATE (DE)")       dnf remove -y @mate-desktop-environment ;;
            "Hyprland (WM)")   dnf remove -y hyprland ;;
            "i3wm (WM)")       dnf remove -y @i3-desktop-environment ;;
            "Sway (WM)")       dnf remove -y sway ;;
        esac
        dnf autoremove -y

    elif [ "$PKGMGR" == "apt" ]; then
        case $CURRENT_ENV in
            "GNOME (DE)")      apt purge -y task-gnome-desktop gdm3 ;;
            "KDE-Plasma (DE)") apt purge -y task-kde-desktop plasma-workspace ;;
            "XFCE (DE)")       apt purge -y task-xfce-desktop ;;
            "Cinnamon (DE)")   apt purge -y task-cinnamon-desktop ;;
            "MATE (DE)")       apt purge -y task-mate-desktop ;;
            "Hyprland (WM)")   apt purge -y hyprland ;;
            "i3wm (WM)")       apt purge -y i3 i3-wm ;;
            "Sway (WM)")       apt purge -y sway ;;
        esac
        apt autoremove -y
    fi
fi

# =========================================================
# 5. UNIFIED INSTALLATION PHASE (Now Executing SECOND)
# =========================================================
echo -e "\nDeploying and rebuilding $TARGET_ENV via $PKGMGR..."

if [ "$PKGMGR" == "pacman" ]; then
    case $TARGET_ENV in
        "KDE-Plasma (DE)") pacman -S --needed --noconfirm plasma-meta kde-applications sddm sddm-kcm ;;
        "GNOME (DE)")      pacman -S --needed --noconfirm gnome gnome-extra gdm; [ "$DISTRO_ID" == "cachyos" ] && pacman -S --needed --noconfirm cachyos-gnome-settings ;;
        "XFCE (DE)")       pacman -S --needed --noconfirm xfce4 xfce4-goodies sddm ;;
        "Cinnamon (DE)")   pacman -S --needed --noconfirm cinnamon nemo sddm ;;
        "MATE (DE)")       pacman -S --needed --noconfirm mate mate-extra sddm ;;
        "Hyprland (WM)")   pacman -S --needed --noconfirm hyprland sddm; [ "$DISTRO_ID" == "cachyos" ] && pacman -S --needed --noconfirm cachyos-hyprland-settings ;;
        "i3wm (WM)")       pacman -S --needed --noconfirm i3-wm sddm; [ "$DISTRO_ID" == "cachyos" ] && pacman -S --needed --noconfirm cachyos-i3wm-settings ;;
        "Sway (WM)")       pacman -S --needed --noconfirm sway sddm ;;
    esac

elif [ "$PKGMGR" == "dnf" ]; then
    case $TARGET_ENV in
        "KDE-Plasma (DE)") dnf install -y @kde-desktop-environment sddm ;;
        "GNOME (DE)")      dnf install -y @gnome-desktop gdm ;;
        "XFCE (DE)")       dnf install -y @xfce-desktop-environment lightdm lightdm-gtk ;;
        "Cinnamon (DE)")   dnf install -y @cinnamon-desktop-environment sddm ;;
        "MATE (DE)")       dnf install -y @mate-desktop-environment sddm ;;
        "Hyprland (WM)")   dnf copr enable -y solopasha/hyprland; dnf install -y hyprland sddm ;;
        "i3wm (WM)")       dnf install -y @i3-desktop-environment sddm ;;
        "Sway (WM)")       dnf install -y sway sddm ;;
    esac

elif [ "$PKGMGR" == "apt" ]; then
    apt update
    case $TARGET_ENV in
        "KDE-Plasma (DE)") apt install -y task-kde-desktop sddm ;;
        "GNOME (DE)")      apt install -y task-gnome-desktop gdm3 ;;
        "XFCE (DE)")       apt install -y task-xfce-desktop lightdm lightdm-gtk-greeter ;;
        "Cinnamon (DE)")   apt install -y task-cinnamon-desktop sddm ;;
        "MATE (DE)")       apt install -y task-mate-desktop sddm ;;
        "Hyprland (WM)")   apt install -y hyprland sddm ;;
        "i3wm (WM)")       apt install -y i3 sddm ;;
        "Sway (WM)")       apt install -y sway sddm ;;
    esac
fi

# =========================================================
# 6. UNIFIED DISPLAY MANAGER ROUTER
# =========================================================
echo -e "\nFinalizing display manager alignment..."
if [[ "$TARGET_ENV" == "GNOME (DE)" ]]; then
    systemctl disable sddm lightdm 2>/dev/null || true
    [ "$PKGMGR" == "apt" ] && systemctl enable gdm3 --force || systemctl enable gdm --force
elif [[ "$TARGET_ENV" == "XFCE (DE)" && ( "$PKGMGR" == "dnf" || "$PKGMGR" == "apt" ) ]]; then
    systemctl disable sddm gdm gdm3 2>/dev/null || true
    systemctl enable lightdm --force
else
    systemctl disable gdm gdm3 lightdm 2>/dev/null || true
    systemctl enable sddm --force
fi

echo -e "\nProcess fully executed!"
read -p "Would you like to reboot the virtual machine right now? (y/n): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    reboot
fi
