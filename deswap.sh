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
    elif pgrep -x "cosmic-comp" >/dev/null; then
        echo "COSMIC (DE)"
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

# Precise Current Display Manager Resolver
if [[ "$CURRENT_ENV" == "GNOME (DE)" || "$CURRENT_ENV" == "COSMIC (DE)" ]]; then
    CURRENT_DM_SERVICE="gdm"
    [ "$PKGMGR" == "apt" ] && CURRENT_DM_SERVICE="gdm3"
    CURRENT_DM_PKGS="$CURRENT_DM_SERVICE"
elif [[ "$CURRENT_ENV" == "KDE-Plasma (DE)" || "$CURRENT_ENV" == "Hyprland (WM)" || "$CURRENT_ENV" == "Sway (WM)" ]]; then
    CURRENT_DM_SERVICE="sddm"
    [[ "$DISTRO_ID" == "cachyos" || "$DISTRO_ID" == "arch" ]] && CURRENT_DM_PKGS="sddm sddm-kcm" || CURRENT_DM_PKGS="sddm"
else
    CURRENT_DM_SERVICE="lightdm"
    if [ "$PKGMGR" == "dnf" ]; then CURRENT_DM_PKGS="lightdm lightdm-gtk"; else CURRENT_DM_PKGS="lightdm lightdm-gtk-greeter"; fi
fi

echo "================================================="
echo "   Universal Omni-Workspace Swapper v6.1      "
echo "================================================="
echo "OS Family Detected: [$DISTRO_ID / $PKGMGR]"
echo "Active Interface:   [$CURRENT_ENV]"
echo "================================================="

# Master framework array
ALL_ENVS=(
    "KDE-Plasma (DE)" "GNOME (DE)" "XFCE (DE)" 
    "Cinnamon (DE)" "MATE (DE)" "COSMIC (DE)" "Hyprland (WM)" 
    "i3wm (WM)" "Sway (WM)"
)
AVAILABLE_ENVS=()

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

# Precise Target Display Manager Resolver
if [[ "$TARGET_ENV" == "GNOME (DE)" || "$TARGET_ENV" == "COSMIC (DE)" ]]; then
    TARGET_DM_SERVICE="gdm"
    [ "$PKGMGR" == "apt" ] && TARGET_DM_SERVICE="gdm3"
    TARGET_DM_PKGS="$TARGET_DM_SERVICE"
elif [[ "$TARGET_ENV" == "KDE-Plasma (DE)" || "$TARGET_ENV" == "Hyprland (WM)" || "$TARGET_ENV" == "Sway (WM)" ]]; then
    TARGET_DM_SERVICE="sddm"
    [[ "$DISTRO_ID" == "cachyos" || "$DISTRO_ID" == "arch" ]] && TARGET_DM_PKGS="sddm sddm-kcm" || TARGET_DM_PKGS="sddm"
else
    TARGET_DM_SERVICE="lightdm"
    if [ "$PKGMGR" == "dnf" ]; then TARGET_DM_PKGS="lightdm lightdm-gtk"; else TARGET_DM_PKGS="lightdm lightdm-gtk-greeter"; fi
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
        "COSMIC (DE)")     pacman -S --needed --noconfirm cosmic-session $TARGET_DM_PKGS ;;
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
        "COSMIC (DE)")     dnf install -y @cosmic-desktop-environment $TARGET_DM_PKGS ;;
        "Hyprland (WM)")   dnf copr enable -y solopasha/hyprland; dnf install -y hyprland $TARGET_DM_PKGS ;;
        "i3wm (WM)")       dnf install -y @i3-desktop-environment $TARGET_DM_PKGS ;;
        "Sway (WM)")       dnf install -y sway $TARGET_DM_PKGS ;;
    esac

elif [ "$PKGMGR" == "apt" ]; then
    apt update
    if [ "$DISTRO_ID" == "ubuntu" ]; then
        case $TARGET_ENV in
            "KDE-Plasma (DE)") apt install -y kubuntu-desktop sddm-theme-breeze kde-config-sddm kubuntu-notification-helper $TARGET_DM_PKGS ;;
            "GNOME (DE)")      apt install -y ubuntu-desktop $TARGET_DM_PKGS ;;
            "XFCE (DE)")       apt install -y xubuntu-desktop $TARGET_DM_PKGS ;;
            "Cinnamon (DE)")   apt install -y cinnamon-desktop-environment $TARGET_DM_PKGS ;;
            "MATE (DE)")       apt install -y ubuntu-mate-desktop $TARGET_DM_PKGS ;;
            "COSMIC (DE)")     apt install -y software-properties-common; add-apt-repository -y ppa:hepp3n/cosmic-epoch; apt update; apt install -y cosmic-session $TARGET_DM_PKGS ;;
            "Hyprland (WM)")   apt install -y hyprland $TARGET_DM_PKGS ;;
            "i3wm (WM)")       apt install -y i3 $TARGET_DM_PKGS ;;
            "Sway (WM)")       apt install -y sway $TARGET_DM_PKGS ;;
        esac
    else
        case $TARGET_ENV in
            "KDE-Plasma (DE)") apt install -y task-kde-desktop sddm-theme-breeze kde-config-sddm $TARGET_DM_PKGS ;;
            "GNOME (DE)")      apt install -y task-gnome-desktop $TARGET_DM_PKGS ;;
            "XFCE (DE)")       apt install -y task-xfce-desktop $TARGET_DM_PKGS ;;
            "Cinnamon (DE)")   apt install -y task-cinnamon-desktop $TARGET_DM_PKGS ;;
            "MATE (DE)")       apt install -y task-mate-desktop $TARGET_DM_PKGS ;;
            "COSMIC (DE)")     apt install -y cosmic-session $TARGET_DM_PKGS ;;
            "Hyprland (WM)")   apt install -y hyprland $TARGET_DM_PKGS ;;
            "i3wm (WM)")       apt install -y i3 $TARGET_DM_PKGS ;;
            "Sway (WM)")       apt install -y sway $TARGET_DM_PKGS ;;
        esac
    fi
fi

# =========================================================
# 5. OPTIONAL DEEP PURGE PHASE (Executes SECOND)
# =========================================================
echo "================================================="
read -p "Complete the swap by permanently deleting $CURRENT_ENV and its login manager ($CURRENT_DM_SERVICE)? (y/n): " purge_choice
echo "================================================="

if [[ "$purge_choice" =~ ^[Yy]$ ]]; then
    echo -e "\nPurging $CURRENT_ENV assets from disk..."
    
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
            "COSMIC (DE)")     pacman -Rns --noconfirm cosmic-session $PURGE_DM_STRING 2>/dev/null || true ;;
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
            "COSMIC (DE)")     dnf remove -y @cosmic-desktop-environment $PURGE_DM_STRING ;;
            "Hyprland (WM)")   dnf remove -y hyprland $PURGE_DM_STRING ;;
            "i3wm (WM)")       dnf remove -y @i3-desktop-environment $PURGE_DM_STRING ;;
            "Sway (WM)")       dnf remove -y sway $PURGE_DM_STRING ;;
        esac
        dnf autoremove -y

    elif [ "$PKGMGR" == "apt" ]; then
        if [ "$DISTRO_ID" == "ubuntu" ]; then
            case $CURRENT_ENV in
                "GNOME (DE)")      apt purge -y ubuntu-desktop gnome-shell $PURGE_DM_STRING ;;
                "KDE-Plasma (DE)") apt purge -y kubuntu-desktop plasma-workspace plasma-desktop kde-standard gwenview juk kate kcalc kmail konsole korganizer sweeper okular kaddressbook ktnef kwalletmanager kwrite kio-extras pim-data-exporter sieve-editor qrca sddm-theme-breeze $PURGE_DM_STRING ;;
                "XFCE (DE)")       apt purge -y xubuntu-desktop xfce4 xfce4-goodies $PURGE_DM_STRING ;;
                "Cinnamon (DE)")   apt purge -y cinnamon-desktop-environment cinnamon nemo $PURGE_DM_STRING ;;
                "MATE (DE)")       apt purge -y ubuntu-mate-desktop ubuntu-mate-core mate-desktop-environment* mate-desktop mate-desktop-core mate-session-manager mate-panel caja pluma mate-terminal mate-utils atril engrampa marco mate-calc* mate-font-viewer $PURGE_DM_STRING ;;
                "COSMIC (DE)")     apt purge -y cosmic-session $PURGE_DM_STRING; apt install -y ppa-purge; ppa-purge -y ppa:hepp3n/cosmic-epoch || true ;;
                "Hyprland (WM)")   apt purge -y hyprland $PURGE_DM_STRING ;;
                "i3wm (WM)")       apt purge -y i3 i3-wm $PURGE_DM_STRING ;;
                "Sway (WM)")       apt purge -y sway $PURGE_DM_STRING ;;
            esac
        else
            case $CURRENT_ENV in
                "GNOME (DE)")      apt purge -y task-gnome-desktop gnome-shell $PURGE_DM_STRING ;;
                "KDE-Plasma (DE)") apt purge -y task-kde-desktop plasma-workspace plasma-desktop sddm-theme-breeze kde-config-sddm $PURGE_DM_STRING ;;
                "XFCE (DE)")       apt purge -y task-xfce-desktop $PURGE_DM_STRING ;;
                "Cinnamon (DE)")   apt purge -y task-cinnamon-desktop $TARGET_DM_PKGS ;;
                "MATE (DE)")       apt purge -y task-mate-desktop mate-desktop-environment* mate-session-manager mate-panel caja pluma mate-terminal $PURGE_DM_STRING ;;
                "COSMIC (DE)")     apt purge -y cosmic-session $PURGE_DM_STRING ;;
                "Hyprland (WM)")   apt purge -y hyprland $PURGE_DM_STRING ;;
                "i3wm (WM)")       apt purge -y i3 i3-wm $PURGE_DM_STRING ;;
                "Sway (WM)")       apt purge -y sway $PURGE_DM_STRING ;;
            esac
        fi
        apt autoremove --purge -y
    fi

    # Direct File-Level Session Purge Hook
    echo "Clearing matching workspace session definitions..."
    case $CURRENT_ENV in
        "GNOME (DE)")      rm -f /usr/share/xsessions/ubuntu* /usr/share/wayland-sessions/ubuntu* /usr/share/xsessions/gnome* /usr/share/wayland-sessions/gnome* ;;
        "KDE-Plasma (DE)") rm -f /usr/share/xsessions/plasma* /usr/share/wayland-sessions/plasma* ;;
        "XFCE (DE)")       rm -f /usr/share/xsessions/xfce* ;;
        "Cinnamon (DE)")   rm -f /usr/share/xsessions/cinnamon* ;;
        "MATE (DE)")       rm -f /usr/share/xsessions/mate* ;;
        "COSMIC (DE)")     rm -f /usr/share/wayland-sessions/cosmic* ;;
        "Hyprland (WM)")   rm -f /usr/share/wayland-sessions/hyprland* ;;
        "i3wm (WM)")       rm -f /usr/share/xsessions/i3* ;;
        "Sway (WM)")       rm -f /usr/share/wayland-sessions/sway* ;;
    esac
    update-desktop-database 2>/dev/null || true
fi

# =========================================================
# 6. UNIFIED DISPLAY MANAGER ROUTER (Executes LAST)
# =========================================================
echo -e "\nFinalizing display manager alignment..."
systemctl disable gdm gdm3 sddm lightdm 2>/dev/null || true
systemctl enable $TARGET_DM_SERVICE --force

if [ "$PKGMGR" == "apt" ]; then
    DM_BIN_PATH=$(command -v $TARGET_DM_SERVICE)
    if [ -n "$DM_BIN_PATH" ]; then
        echo "$DM_BIN_PATH" > /etc/X11/default-display-manager
    fi
fi

echo -e "\nProcess fully executed!"
read -p "Would you like to reboot the virtual machine right now? (y/n): " reboot_choice
if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
    systemctl reboot -i
fi
