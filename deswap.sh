#!/bin/bash

# 1. Root privilege verification
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script with sudo (e.g., sudo ./omni-swap.sh)"
  exit 1
fi

# 2. Automated Distribution & Package Manager Detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO_ID=$ID
    DISTRO_LIKE=$ID_LIKE
else
    echo "❌ Error: Unable to read system metadata files."
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
    echo "❌ Error: Unsupported OS ($DISTRO_ID). This engine maps to Arch, Fedora, and Debian families."
    exit 1
fi

# 3. Running Environment Verification Layer
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

clear
CURRENT_ENV=$(detect_current_env)

echo "================================================="
echo "   🌌 Universal Omni-Workspace Swapper v4.0      "
echo "================================================="
echo "🐧 OS Family Detected: [$DISTRO_ID / $PKGMGR]"
echo "💻 Active Interface:   [$CURRENT_ENV]"
echo "================================================="
echo "1) Install a New Desktop Environment / WM"
echo "2) Purge an Old, Inactive Desktop Environment / WM"
echo "3) Exit"
echo "================================================="
read -p "Select an action [1-3]: " main_choice

# Global Array of Target Interface Suites
ALL_ENVS=(
    "KDE-Plasma (DE)" "GNOME (DE)" "XFCE (DE)" 
    "Cinnamon (DE)" "MATE (DE)" "Hyprland (WM)" 
    "i3wm (WM)" "Sway (WM)"
)

case $main_choice in
    1)
        # =========================================================
        # INSTALLATION WORKFLOW
        # =========================================================
        AVAILABLE_ENVS=()
        for env in "${ALL_ENVS[@]}"; do
            if [ "$env" != "$CURRENT_ENV" ]; then AVAILABLE_ENVS+=("$env"); fi
        done

        echo -e "\nSelect the new workspace layout to deploy:"
        for i in "${!AVAILABLE_ENVS[@]}"; do
            echo "  $((i+1))) ${AVAILABLE_ENVS[$i]}"
        done
        read -p "Selection: " sub_choice

        if [[ "$sub_choice" -get 1 && "$sub_choice" -le "${#AVAILABLE_ENVS[@]}" ]]; then
            TARGET_ENV="${AVAILABLE_ENVS[$((sub_choice-1))]}"
        else
            echo "❌ Invalid selection." && exit 1
        fi

        echo -e "\n🚀 Fetching and configuring $TARGET_ENV..."
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

        echo -e "\n⚙️ Aligning display login managers..."
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
        
        echo -e "\n🎉 Step 1 Complete! The new interface is layered onto your storage."
        echo "⚠️ To prevent your terminal from crashing, please reboot your system, select your new desktop environment at the login screen, and run this script again to clean up the old one."
        read -p "Would you like to reboot the computer right now? (y/n): " reboot_choice
        [[ "$reboot_choice" =~ ^[Yy]$ ]] && reboot
        ;;

    2)
        # =========================================================
        # PURGE WORKFLOW (Safely targeting INACTIVE environments)
        # =========================================================
        PURGEABLE_ENVS=()
        for env in "${ALL_ENVS[@]}"; do
            if [ "$env" != "$CURRENT_ENV" ]; then PURGEABLE_ENVS+=("$env"); fi
        done

        echo -e "\n🔥 WARNING: Ensure the environment you are purging is NOT currently running or logged in."
        echo "Select an inactive workspace layout to completely erase:"
        for i in "${!PURGEABLE_ENVS[@]}"; do
            echo "  $((i+1))) ${PURGEABLE_ENVS[$i]}"
        done
        read -p "Selection: " purge_choice

        if [[ "$purge_choice" -ge 1 && "$purge_choice" -le "${#PURGEABLE_ENVS[@]}" ]]; then
            OLD_ENV="${PURGEABLE_ENVS[$((purge_choice-1))]}"
        else
            echo "❌ Invalid selection." && exit 1
        fi

        echo -e "\n🧹 Purging $OLD_ENV assets from storage..."
        if [ "$PKGMGR" == "pacman" ]; then
            case $OLD_ENV in
                "GNOME (DE)")      pacman -Rns --noconfirm gnome gnome-extra cachyos-gnome-settings gnome-shell-extension-appindicator 2>/dev/null || true ;;
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
            case $OLD_ENV in
                "GNOME (DE)")      dnf remove -y @gnome-desktop gnome-shell --setopt protected_packages= ;;
                "KDE-Plasma (DE)") dnf remove -y plasma-workspace plasma-desktop @kde-desktop-environment --setopt protected_packages= ;;
                "XFCE (DE)")       dnf remove -y @xfce-desktop-environment ;;
                "Cinnamon (DE)")   dnf remove -y @cinnamon-desktop-environment ;;
                "MATE (DE)")       dnf remove -y @mate-desktop-environment ;;
                "Hyprland (WM)")   dnf remove -y hyprland ;;
                "i3wm (WM)")       dnf remove -y @i3-desktop-environment ;;
                "Sway (WM)")       dnf remove -y sway ;;
            esac
            dnf autoremove -y

        elif [ "$PKGMGR" == "apt" ]; then
            case $OLD_ENV in
                "GNOME (DE)")      apt purge -y task-gnome-desktop gdm3 gnome-shell ;;
                "KDE-Plasma (DE)") apt purge -y task-kde-desktop plasma-workspace plasma-desktop ;;
                "XFCE (DE)")       apt purge -y task-xfce-desktop ;;
                "Cinnamon (DE)")   apt purge -y task-cinnamon-desktop ;;
                "MATE (DE)")       apt purge -y task-mate-desktop ;;
                "Hyprland (WM)")   apt purge -y hyprland ;;
                "i3wm (WM)")       apt purge -y i3 i3-wm ;;
                "Sway (WM)")       apt purge -y sway ;;
            esac
            apt autoremove -y
        fi
        echo -e "\n🎉 Complete! The system has successfully vacuumed $OLD_ENV away."
        ;;

    3)
        echo "Exiting interface."
        exit 0
        ;;
    *)
        echo "❌ Invalid choice."
        exit 1
        ;;
esac
