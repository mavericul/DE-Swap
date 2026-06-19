A lightweight, multi-distribution shell script to safely install, switch, and purge Desktop Environments (DEs) and Window Managers (WMs) without desktop clutter or terminal crashes.

## Key Features

* **Multi-Distro Support:** Native translation for Arch Linux (`pacman`), Fedora (`dnf`), and Debian/Ubuntu (`apt`).
* **Safe Execution Flow:** Installs the new workspace interface *before* prompting to wipe the old one, avoiding session crashes mid-script.
* **Automatic Display Manager Alignment:** Identifies, installs, and cross-configures the correct login manager (`GDM3`, `SDDM`, or `LightDM`) matching your target desktop.
* **Ubuntu Login Screen Fix:** Directly overrides the legacy `/etc/X11/default-display-manager` file to eliminate the notorious blank white screen bug.
* **Deep Clean Purges:** Wipes target meta-packages, specific default tool suites, and orphaned backend libraries to prevent cross-desktop application pollution.

## Supported Ecosystems

* **Desktops:** GNOME, KDE-Plasma, XFCE, Cinnamon, MATE, COSMIC (Epoch)
* **Window Managers:** Hyprland, i3wm, Sway
