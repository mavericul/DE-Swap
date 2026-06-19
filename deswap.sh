#!/bin/bash

# 1. Root privilege verification
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script with sudo (e.g., sudo ./omni-swap.sh)"
  exit 1
fi

# 2. Automated Distribution & Package Manager Detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$ID
    DISTRO_LIKE=$ID_LIKE
else
    echo "Error: Unable to read system metadata files."
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
    echo "Error: Unsupported OS ($DISTRO_ID). This engine maps to Arch, Fedora, and Debian families."
    exit 1
fi

# 3. Running Environment & Display Manager Identity Mapping
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

# Map current display manager packages and systemd services
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
echo "   Universal Omni-Workspace Swapper v5.0         "
echo "================================================="
echo "OS Family Detected: [$DISTRO_ID / $PKGMGR]"
echo "Active Interface:   [$CURRENT_ENV]"
echo "================================================="

# Global Array of Target Interface Suites
ALL_ENVS=(
    "KDE-Plasma (DE)" "GNOME (DE)" "XFCE (DE)" 
    "Cinnamon (DE)" "MATE (DE)" "Hyprland (WM)" 
    "i3wm (WM)" "Sway (WM)"
)
AVAILABLE_ENVS=()

for env in "${ALL_ENVS[@]}"; do
    if [ "$env" != "$CURRENT_ENV" ]; then AVAILABLE_ENVS+=("$env"); fi
done

echo "Select the target workspace to deploy:"
for i in "${!AVAILABLE_ENVS[@]}"; do
    echo "  $((i+1))) ${AVAILABLE_ENVS[$i]}"
done
echo "  $(( ${#AVAILABLE_ENVS[@]} + 1 ))) Exit"
echo "================================================="
read -p "Selection: " sub_choice

if [[ "$sub_choice" -ge 1 && "$sub_choice" -le "${#AVAILABLE_ENVS[@]}" ]]; then
    TARGET_ENV="${AVAILABLE_ENVS[$((sub_choice-1))]}"
elif [[ "$sub_choice" -eq "$(( ${#AVAILABLE_ENVS[@]} + 1 ))" ]]; then
    echo "Exiting interface." && exit 0
else
    echo "Invalid selection. Script terminating." && exit 1
fi

# Map target display manager packages and systemd services
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
# INSTALLATION PHASE
# =========================================================
echo -e "\nFetching and configuring $TARGET_ENV and its login manager ($TARGET_DM_SERVICE)..."

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

echo -e "\nAligning display login managers..."
systemctl disable gdm gdm3 sddm lightdm 2>/dev/null || true
systemctl enable $TARGET_DM_SERVICE --force

# =========================================================
# PURGE SELECTION PHASE (Offered at the End)
# =========================================================
echo "================================================="
read -p "Do you want to completely uninstall $CURRENT_ENV and its login manager ($CURRENT_DM_SERVICE) now? (y/n): " purge_choice
echo "================================================="

if [[ "$purge_choice" =~ ^[Yy]$ ]]; then
    # Formulate the targeted deletion package group string
    PURGE_TARGETS=""
    if [ "$PKGMGR" == "pacman" ]; then
        case $CURRENT_ENV in
            "GNOME (DE)")      PURGE_TARGETS="gnome gnome-extra cachyos-gnome-settings gnome-shell-extension-appindicator" ;;
            "KDE-Plasma (DE)") PURGE_TARGETS="plasma-meta kde-applications" ;;
            "XFCE (DE)")       PURGE_TARGETS="xfce4 xfce4-goodies" ;;
            "Cinnamon (DE)")   PURGE_TARGETS="cinnamon nemo" ;;
            "MATE (DE)")       PURGE_TARGETS="mate mate-extra" ;;
            "Hyprland (WM)")   PURGE_TARGETS="hyprland cachyos-hyprland-settings" ;;
            "i3wm (WM)")       PURGE_TARGETS="i3-wm cachyos-i3wm-settings" ;;
            "Sway (WM)")       PURGE_TARGETS="sway" ;;
        esac
        [ "$CURRENT_DM_SERVICE" != "$TARGET_DM_SERVICE" ] && PURGE_TARGETS="$PURGE_TARGETS $CURRENT_DM_PKGS"
        
        echo "Handing over purge execution to systemd background subshell to prevent session crash truncation..."
        systemd-run --description="Omni-Swap-Purge" bash -c "pacman -Rns --noconfirm $PURGE_TARGETS 2>/dev/null; pacman -Rns --noconfirm \$(pacman -Qtdq) 2>/dev/null; reboot"

    elif [ "$PKGMGR" == "dnf" ]; then
        case $CURRENT_ENV in
            "GNOME (DE)")      PURGE_TARGETS="@gnome-desktop gnome-shell" ;;
            "KDE-Plasma (DE)") PURGE_TARGETS="plasma-workspace plasma-desktop @kde-desktop-environment" ;;
            "XFCE (DE)")       PURGE_TARGETS="@xfce-desktop-environment" ;;
            "Cinnamon (DE)")   PURGE_TARGETS="@cinnamon-desktop-environment" ;;
            "MATE (DE)")       PURGE_TARGETS="@mate-desktop-environment" ;;
            "Hyprland (WM)")   PURGE_TARGETS="hyprland" ;;
            "i3wm (WM)")       PURGE_TARGETS="@i3-desktop-environment" ;;
            "Sway (WM)")       PURGE_TARGETS="sway" ;;
        esac
        [ "$CURRENT_DM_SERVICE" != "$TARGET_DM_SERVICE" ] && PURGE_TARGETS="$PURGE_TARGETS $CURRENT_DM_PKGS"
        
        echo "Handing over purge execution to systemd background subshell to prevent session crash truncation..."
        systemd-run --description="Omni-Swap-Purge" bash -c "dnf remove -y $PURGE_TARGETS --setopt protected_packages=; dnf autoremove -y; reboot"

    elif [ "$PKGMGR" == "apt" ]; then
        case $CURRENT_ENV in
            "GNOME (DE)")      PURGE_TARGETS="task-gnome-desktop gdm3 gnome-shell" ;;
            "KDE-Plasma (DE)") PURGE_TARGETS="task-kde-desktop plasma-workspace plasma-desktop" ;;
            "XFCE (DE)")       PURGE_TARGETS="task-xfce-desktop" ;;
            "Cinnamon (DE)")   PURGE_TARGETS="task-cinnamon-desktop" ;;
            "MATE (DE)")       PURGE_TARGETS="task-mate-desktop" ;;
            "Hyprland (WM)")   PURGE_TARGETS="hyprland" ;;
            "i3wm (WM)")       PURGE_TARGETS="i3 i3-wm" ;;
            "Sway (WM)")       PURGE_TARGETS="sway" ;;
        esac
        [ "$CURRENT_DM_SERVICE" != "$TARGET_DM_SERVICE" ] && PURGE_TARGETS="$PURGE_TARGETS $CURRENT_DM_PKGS"
        
        echo "Handing over purge execution to systemd background subshell to prevent session crash truncation..."
        systemd-run --description="Omni-Swap-Purge" bash -c "apt purge -y $PURGE_TARGETS; apt autoremove -y; reboot"
    fi
    echo "Purge initialized. The system will now safely close down, perform the package wipe, and reboot automatically."
else
    echo -e "\nInstallation completed successfully."
    read -p "Would you like to reboot the computer right now? (y/n): " reboot_choice
    [[ "$reboot_choice" =~ ^[Yy]$ ]] && reboot
fi
