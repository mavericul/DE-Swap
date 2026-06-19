#!/bin/bash

# 1. Root privilege check
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo (e.g., sudo ./deswap.sh)"
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

# Map current login manager configurations
if [[ "$CURRENT_ENV" == "GNOME (DE)" ]]; then
    CURRENT_DM_SERVICE="gdm"
    if [ "$PKGMGR" == "apt" ]; then CURRENT_DM_SERVICE="gdm3"; fi
    CURRENT_DM_PKGS="$CURRENT_DM_SERVICE"
elif [[ "$CURRENT_ENV" == "XFCE (DE)" && ( "$PKGMGR" == "dnf" || "$PKGMGR" == "apt" ) ]]; then
    CURRENT_DM_SERVICE="lightdm"
    if [ "$PKGMGR" == "dnf" ]; then CURRENT_DM_PKGS="lightdm lightdm-gtk"; else CURRENT_DM_PKGS="lightdm lightdm-gtk-greeter"; fi
else
    CURRENT_DM_SERVICE="sddm"
    if [[ "$DISTRO_ID" == "cachyos" || "$DISTRO_ID" == "arch" ]]; then CURRENT_DM_PKGS="sddm sddm-kcm"; else CURRENT_DM_PKGS="sddm"; fi
fi

echo "================================================="
echo "   Universal Omni-Workspace Swapper v5.1      "
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

# Map target login manager configurations
if [[ "$TARGET_ENV" == "GNOME (DE)" ]]; then
    TARGET_DM_SERVICE="gdm"
    if [ "$PKGMGR" == "apt" ]; then TARGET_DM_SERVICE="gdm3"; fi
    TARGET_DM_PKGS="$TARGET_DM_SERVICE"
elif [[ "$TARGET_ENV" == "XFCE (DE)" && ( "$PKGMGR" == "dnf" || "$PKGMGR" == "apt" ) ]]; then
    TARGET_DM_SERVICE="lightdm"
    if [ "$PKGMGR" == "dnf" ]; then TARGET_DM_PKGS="lightdm lightdm-gtk"; else TARGET_DM_PKGS="lightdm lightdm-gtk-greeter"; fi
else
    TARGET_DM_SERVICE="sddm"
    if [[ "$DISTRO_ID" == "cachyos" || "$DISTRO_ID" == "arch" ]]; then TARGET_DM_PKGS="sddm sddm-kcm"; else TARGET_DM_PKGS="sddm"; fi
fi

# =========================================================
# 4. UNIFIED INSTALLATION PHASE (Executes FIRST)
# =========================================================
echo -e "\nDeploying and rebuilding $TARGET_ENV via $PKGMGR..."

if [ "$PKGMGR" == "pacman" ]; then
    case $TARGET_ENV in
        "KDE-Plasma (DE)") pacman -S --needed --noconfirm plasma-meta kde-applications $TARGET_DM_PKGS ;;
        "GNOME (DE)")      pacman -S --needed --noconfirm gnome gnome-extra $TARGET_DM_PKGS; [ "$DISTRO_ID" == "cachyos" ] && pacman -S --needed --noconfirm cachyos-gnome-settings ;;
        "XFCE (DE)")       pacman -S --needed --noconfirm xfce4 xfce4-goodies $TARGET_DM_PKGS ;;
        "Cinnamon (DE)")   pacman -S --needed --noconfirm cinnamon nemo $TARGET_DM_PKGS ;;
        "MATE (DE)")       pacman -S --needed --noconfirm mate mate-extra $TARGET_DM_PKGS ;;
        "Hyprland (WM)")   pacman -S --needed --noconfirm hyprland $TARGET_DM_PKGS; [ "$DISTRO_ID" == "cachyos" ] && pacman -S --needed --noconfirm cachyos-hyprland-settings ;;
        "i3wm (WM)")       pacman -S --needed --noconfirm i3-wm $TARGET_DM_PKGS; [ "$DISTRO_ID" == "cachyos" ] && pacman -S --needed --noconfirm cachyos-i3wm-settings ;;
        "Sway (WM)")       pacman -S --needed --noconfirm sway $TARGET_DM_PKGS ;;
    esac

elif [ "$PKGMGR" == "dnf" ]; then
    case $TARGET_ENV in
        "KDE-Plasma (DE)") dnf install -y @kde-desktop-environment $TARGET_DM_PKGS ;;
        "GNOME (DE)")      dnf install -y @gnome-desktop $TARGET_DM_PKGS ;;
        "XFCE (DE)")       dnf install -y @xfce-desktop-environment $TARGET_DM_PKGS ;;
        "Cinnamon (DE)")   dnf install -y @cinnamon-desktop-environment $TARGET_DM_PKGS ;;
        "MATE (DE)")       dnf install -y @mate-desktop-environment $TARGET_DM_PKGS ;;
        "Hyprland (WM)")   dnf copr enable -y solopasha/hyprland; dnf install -y hyprland $TARGET_DM_PKGS ;;
        "i3wm (WM)")       dnf install -y @i3-desktop-environment $TARGET_DM_PKGS ;;
        "Sway (WM)")       dnf install -y sway $TARGET_DM_PKGS ;;
    esac

elif [ "$PKGMGR" == "apt" ]; then
    apt update
    case $TARGET_ENV in
        "KDE-Plasma (DE)") apt install -y task-kde-desktop $TARGET_DM_PKGS ;;
        "GNOME (DE)")      apt install -y task-gnome-desktop $TARGET_DM_PKGS ;;
        "XFCE (DE)")       apt install -y task-xfce-desktop $TARGET_DM_PKGS ;;
        "Cinnamon (DE)")   apt install -y task-cinnamon-desktop $TARGET_DM_PKGS ;;
        "MATE (DE)")       apt install -y task-mate-desktop $TARGET_DM_PKGS ;;
        "Hyprland (WM)")   apt install -y hyprland $TARGET_DM_PKGS ;;
        "i3wm (WM)")       apt install -y i3 $TARGET_DM_PKGS ;;
        "Sway (WM)")       apt install -y sway $TARGET_DM_PKGS ;;
    esac
fi

# =========================================================
# 5. UNIFIED DISPLAY MANAGER ROUTER
# =========================================================
echo -e "\nFinalizing display manager alignment..."
systemctl disable gdm gdm3 sddm lightdm 2>/dev/null || true
systemctl enable $TARGET_DM_SERVICE --force

# =========================================================
# 6. OPTIONAL DEEP PURGE PHASE (Executes SECOND)
# =========================================================
echo "================================================="
read -p "Complete the swap by permanently deleting $CURRENT_ENV and its login manager ($CURRENT_DM_SERVICE)? (y/n): " purge_choice
echo "================================================="

if [[ "$purge_choice" =~ ^[Yy]$ ]]; then
    echo -e "\nPurging $CURRENT_ENV assets from disk..."
    
    # Append the old login manager to the removal sequence if it changes
    PURGE_DM_STRING=""
    if [ "$CURRENT_DM_SERVICE" != "$TARGET_DM_SERVICE" ]; then
        PURGE_DM_STRING=" $CURRENT_DM_PKGS"
    fi

    if [ "$PKGMGR" == "pacman" ]; then
        case $CURRENT_ENV in
            "GNOME (DE)")      pacman -Rns --noconfirm gnome gnome-extra cachyos-gnome-settings gnome-shell-extension-appindicator nautilus-python nautilus-open-any-terminal $PURGE_DM_STRING 2>/dev/null || true ;;
            "KDE-Plasma (DE)") pacman -Rns --noconfirm plasma-meta kde-applications sddm-kcm $PURGE_DM_STRING 2>/dev/null || true ;;
            "XFCE (DE)")       pacman -Rns --noconfirm xfce4 xfce4-goodies $PURGE_DM_STRING 2>/dev/null || true ;;
            "Cinnamon (DE)")   pacman -Rns --noconfirm cinnamon nemo $PURGE_DM_STRING 2>/dev/null || true ;;
            "MATE (DE)")       pacman -Rns --noconfirm mate mate-extra $PURGE_DM_STRING 2>/dev/null || true ;;
            "Hyprland (WM)")   pacman -Rns --noconfirm hyprland cachyos-hyprland-settings $PURGE_DM_STRING 2>/dev/null || true ;;
            "i3wm (WM)")       pacman -Rns --noconfirm i3-wm cachyos-i3wm-settings $PURGE_DM_STRING 2>/dev/null || true ;;
            "Sway (WM)")       pacman -Rns --noconfirm sway $PURGE_DM_STRING 2>/dev/null || true ;;
        esac
        pacman -Rns --noconfirm $(pacman -Qtdq) 2>/dev/null || true

    elif [ "$PKGMGR" == "dnf" ]; then
        case $CURRENT_ENV in
            "GNOME (DE)")      dnf remove -y @gnome-desktop gnome-shell $PURGE_DM_STRING --setopt protected_packages= ;;
            "KDE-Plasma (DE)") dnf remove -y plasma-workspace plasma-desktop @kde-desktop-environment $PURGE_DM_STRING --setopt protected_packages= ;;
            "XFCE (DE)")       dnf remove -y @xfce-desktop-environment $PURGE_DM_STRING ;;
            "Cinnamon (DE)")   dnf remove -y @cinnamon-desktop-environment $PURGE_DM_STRING ;;
            "MATE (DE)")       dnf remove -y @mate-desktop-environment $PURGE_DM_STRING ;;
            "Hyprland (WM)")   dnf remove -y hyprland $PURGE_DM_STRING ;;
            "i3wm (WM)")       dnf remove -y @i3-desktop-environment $PURGE_DM_STRING ;;
            "Sway (WM)")       dnf remove -y sway $PURGE_DM_STRING ;;
        esac
        dnf autoremove -y

    elif [ "$PKGMGR" == "apt" ]; then
        case $CURRENT_ENV in
            "GNOME (DE)")      apt purge -y task-gnome-desktop gnome-shell $PURGE_DM_STRING ;;
            "KDE-Plasma (DE)") apt purge -y task-kde-desktop plasma-workspace plasma-desktop $PURGE_DM_STRING ;;
            "XFCE (DE)")       apt purge -y task-xfce-desktop $PURGE_DM_STRING ;;
            "Cinnamon (DE)")   apt purge -y task-cinnamon-desktop $PURGE_DM_STRING ;;
            "MATE (DE)")       apt purge -y task-mate-desktop $PURGE_DM_STRING ;;
            "Hyprland (WM)")   apt purge -y hyprland $PURGE_DM_STRING ;;
            "i3wm (WM)")       apt purge -y i3 i3-wm $PURGE_DM_STRING ;;
            "Sway (WM)")       apt purge -y sway $PURGE_DM_STRING ;;
        esac
        apt autoremove -y
    fi
fi

echo -e "\nProcess fully executed!"
read -p "Would you like to reboot your computer right now? (y/n): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    reboot
fi
