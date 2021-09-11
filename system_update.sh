#!/bin/bash
: 'This bash script will update and clean your Linux System, SNAP, Flatpak packages, LinuxBrew formulas, etc...
   It will also update some DevOps tools like Google Cloud SDK, Helm charts, etc...
   In the future i hope to add more features and terminal tools.

   Created by Slavisa Milojkovic - http://github.io/slax81
'

VERSION="1.1"

# Print ASCII Header
function print_banner {
if [[ `which figlet` ]]; then
   FIGLET=1
   echo "FIGLET EXISTS"
else
   clear
   echo ""
   echo -e " ______   ______ _____ _____ __  __    _   _ ____  ____    _  _____ _____ "
   echo -e "/ ___\ \ / / ___|_   _| ____|  \/  |  | | | |  _ \|  _ \  / \|_   _| ____|"
   echo -e " \___ \\ V /\___ \ | | |  _| | |\/| |  | | | | |_) | | | |/ _ \ | | |  _|  "
   echo -e " ___) || |  ___) || | | |___| |  | |  | |_| |  __/| |_| / ___ \| | | |___ "
   echo -e "|____/ |_| |____/ |_| |_____|_|  |_|   \___/|_|   |____/_/   \_|_| |_____|"
   echo -e ""
   echo -e "USAGE: -v (version) -i (system info) -u (last updated) -a (update & clean all)"   
   echo -e ""                                                                    
fi
}

# Determine OS Package manager
function pkg_info {
   echo -e "-----------------------------Detecting System Package Managers------------------------------"
   echo ""
if [[ `which yum` ]]; then
   IS_RHEL=1
   echo "RHEL BASED DISTRO -" $(uname -a);
elif [[ `which apt` ]]; then
   IS_UBUNTU=1
   echo "DEBIAN BASED DISTRO -" $(uname -a);
elif [[ `which pacman` ]]; then
   IS_ARCH=1
   echo "ARCH BASED DISTRO -" $(uname -a);
else
   IS_UNKNOWN=1
   echo "UNKNOWN DISTRO -" $(uname -a);
fi

if [[ `which snap` ]]; then
   SNAP_PKG=1
   echo "SNAP EXISTS -" $(snap version | head -1);
   fi
if [[ `which flatpak` ]]; then
   FLATPAK_PKG=1
   echo "FLATPAK EXISTS -" $(flatpak --version);
   fi
if [[ `which pip3` ]]; then
   PIP3_PKG=1
   echo "PIP3 EXISTS -" $(pip3 --version);
   fi
if [[ `which npm` ]]; then
   NPM_PKG=1
   echo "NPM EXISTS -" $(npm --version);
   fi
if [[ `which brew` ]]; then
   BREW_PKG=1
   echo "LINUXBREW EXISTS -" $(brew -v | tail -1);
   fi
echo ""
}

# Determine Installed DevOps Tools
function devops_info {
   echo -e "-----------------------------Detecting Installed DevOps Tools-------------------------------"
   echo ""
if [[ `which gcloud` ]]; then
   GCLOUD_SDK=1
   echo "GCLOUD SDK EXISTS -" $(gcloud -v | head -1);
   fi
if [[ `which helm` ]]; then
   HELM=1
   echo "HELM EXISTS -" $(helm version | tail -1 2> /dev/null);
   fi
echo ""
}

# Determine OS platform and info
function sys_info {
   echo -e "-------------------------------System Information----------------------------"
   echo -e "Hostname:\t\t"`hostname`
   echo -e "Uptime:\t\t\t"`uptime | awk '{print $3,$4}' | sed 's/,//'`
   echo -e "Manufacturer:\t\t"`cat /sys/class/dmi/id/chassis_vendor`
   echo -e "Product Name:\t\t"`cat /sys/class/dmi/id/product_name`
   echo -e "Version:\t\t"`cat /sys/class/dmi/id/product_version`
   echo -e "Serial Number:\t\t"`cat /sys/class/dmi/id/product_serial`
   echo -e "Machine Type:\t\t"`vserver=$(lscpu | grep Hypervisor | wc -l); if [ $vserver -gt 0 ]; then echo "VM"; else echo "Physical"; fi`
   echo -e "Operating System:\t"`hostnamectl | grep "Operating System" | cut -d ' ' -f5-`
   echo -e "Kernel:\t\t\t"`uname -r`
   echo -e "Architecture:\t\t"`arch`
   echo -e "Processor Name:\t\t"`awk -F':' '/^model name/ {print $2}' /proc/cpuinfo | uniq | sed -e 's/^[ \t]*//'`
   echo -e "Active User:\t\t"`w | cut -d ' ' -f1 | grep -v USER | xargs -n1`
   echo -e "System Main IP:\t\t"`hostname -I`
   echo ""
   echo -e "-------------------------------CPU/Memory Usage------------------------------"
   echo -e "Memory Usage:\t"`free | awk '/Mem/{printf("%.2f%"), $3/$2*100}'`
   echo -e "Swap Usage:\t"`free | awk '/Swap/{printf("%.2f%"), $3/$2*100}'`
   echo -e "CPU Usage:\t"`cat /proc/stat | awk '/cpu/{printf("%.2f%\n"), ($2+$4)*100/($2+$4+$5)}' |  awk '{print $0}' | head -1`
   echo ""
   echo -e "-------------------------------Disk Usage >80%-------------------------------"
   df -Ph | sed s/%//g | awk '{ if($5 > 80) print $0;}'
   echo ""
}

# Last package update
function yum_latest {
   echo -e "-----------------------------Last System Update------------------------------"
   echo ""
   rpm -qa --last  | head
   echo ""
}





# ------------------------------ main function logic ----------------------------


if [[ $1 = "-v" ]]; then
   print_banner
   echo "Linux System Update - Version:" $VERSION
   echo ""
   exit 1
fi

if [[ $1 = "-i" ]]; then
   print_banner
   sys_info
   echo ""
   exit 1
fi

if [[ $1 = "-u" ]]; then
   print_banner
   pkg_info
   devops_info
      if [[ $IS_RHEL -eq 1 ]]; then
      yum_latest
      fi
   echo ""
   exit 1
fi

if [[ $1 = "-a" ]]; then
   print_banner
   pkg_info
   devops_info
   echo "Updating and cleaning all packages..."

      if [[ $IS_RHEL -eq 1 ]]; then
         echo "Updating and cleaning YUM/DNF packages..."
         sudo dnf update -y &
         wait $!
         dnf clean all &
         wait $!
      fi
      if [[ $IS_UBUNTU -eq 1 ]]; then
         echo "Updating and cleaning APT packages..."
         sudo apt-get update &
         wait $!
         sudo apt-get upgrade -y &
         wait $!
         apt-get autoclean &
         wait $!
         apt-get autoremove &
         wait $!
      fi
      if [[ $IS_ARCH -eq 1 ]]; then
         echo "Updating and cleaning AUR packages..."
         sudo pacman -Syu &
         wait $!
         sudo paccache -r &
         wait $!
         sudo pacman -Scc &
         wait $!
      fi
      echo "Updating SNAP Packages..."
      sudo snap refresh &
      wait $!
      #sudo rm /var/lib/snapd/cache/*

      echo "Updating and cleaning Flatpak Packages..."
      flatpak update -y &
      wait $!
      flatpak uninstall --unused -y &
      wait $! 

      echo "Updating and cleaning Pip3 packages..."
      pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U &
      wait $!
      pip3 cache purge &
      wait $!

      echo "Updating NPM packages..."
      npm update &
      wait $!

      echo "Updating and cleaning LinuxBrew packages..."
      brew update &
      wait $!
      brew upgrade &
      wait $!
      brew cleanup &
      wait $!

      echo "Updating Google Cloud SDK..."
      gcloud components update &
      wait $!

      echo "Updating Helm charts..."
      helm repo update &
      wait $!  
   echo ""
   echo "Everything completed successfully."
   exit 0;
fi

# -----------------------Main Function -------------------------

print_banner
pkg_info
devops_info

echo "Do you want to continue? (Y/n)"
read CONTINUE


if [[ $CONTINUE = "n" ]]; then
   echo "Exiting..."
   exit 1
   else
   echo "Continuing..."
fi


# ---------------------Main Menu -------------------------

print_banner

echo "-----------------------------Select option to execute-----------------------------"
echo ""
if [[ $IS_RHEL -eq 1 ]]; then
   echo "y) Update and clean YUM/DNF packages"
   fi
if [[ $IS_UBUNTU -eq 1 ]]; then
   echo "u) Update and clean APT packages"
   fi
if [[ $IS_ARCH -eq 1 ]]; then
   echo "c) Update and clean AUR packages"
   fi
if [[ $SNAP_PKG -eq 1 ]]; then
   echo "s) Update and clean SNAP packages"
   fi
if [[ $FLATPAK_PKG -eq 1 ]]; then
   echo "f) Update and clean Flatpak packages"
   fi
if [[ $PIP3_PKG -eq 1 ]]; then
   echo "p) Update and clean Pip3 packages"
   fi
if [[ $NPM_PKG -eq 1 ]]; then
   echo "n) Update and clean NPM packages"
   fi
if [[ $BREW_PKG -eq 1 ]]; then
   echo "b) Update and clean LinuxBrew packages"
   fi
if [[ $GCLOUD_SDK -eq 1 ]]; then
   echo "g) Update and clean Google Cloud SDK"
   fi
if [[ $HELM -eq 1 ]]; then
   echo "h) Update Helm charts"
   fi
echo -e "a) Update and clean all packages"
echo -e "e) Exit script"

echo ""
echo "Input option you wish to run (default e):"
read OPTION

case $OPTION in

  e)
    echo "Exiting..."
    exit 1;
    ;;

  h)
    echo "Updating Helm charts..."
    helm repo update &
    wait $!
    ;;
  y)
    echo "Updating and cleaning YUM/DNF packages..."
    sudo dnf update -y &
    wait $!
    dnf clean all &
    wait $!
    ;;
  c)
    echo "Updating and cleaning AUR packages..."
    sudo pacman -Syu &
    wait $!
    sudo paccache -r &
    wait $!
    sudo pacman -Scc &
    wait $!
    ;;
  u)
    echo "Updating and cleaning APT packages..."
    sudo apt-get update &
    wait $!
    sudo apt-get upgrade -y &
    wait $!
    apt-get autoclean &
    wait $!
    apt-get autoremove &
    wait $!
    ;;
  s)
    echo "Updating SNAP Packages..."
    sudo snap refresh &
    wait $!
    #sudo rm /var/lib/snapd/cache/*
    ;;
  f)
    echo "Updating and cleaning Flatpak Packages..."
    flatpak update -y &
    wait $!
    flatpak uninstall --unused -y &
    wait $!
    ;;
 p)
    echo "Updating and cleaning Pip3 packages..."
    pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U &
    wait $!
    pip3 cache purge &
    wait $!
    ;;
 n)
    echo "Updating NPM packages..."
    npm update &
    wait $!
    ;;
 b)
    echo "Updating and cleaning LinuxBrew packages..."
    brew update &
    wait $!
    brew upgrade &
    wait $!
    brew cleanup &
    wait $!
    ;;
  g)
    echo "Updating Google Cloud SDK..."
    gcloud components update &
    wait $!
    ;;
  a)
    echo "Updating and cleaning all packages..."

      if [[ $IS_RHEL -eq 1 ]]; then
         echo "Updating and cleaning YUM/DNF packages..."
         sudo dnf update -y &
         wait $!
         dnf clean all &
         wait $!
      fi
      if [[ $IS_UBUNTU -eq 1 ]]; then
         echo "Updating and cleaning APT packages..."
         sudo apt-get update &
         wait $!
         sudo apt-get upgrade -y &
         wait $!
         apt-get autoclean &
         wait $!
         apt-get autoremove &
         wait $!
      fi
      if [[ $IS_ARCH -eq 1 ]]; then
         echo "Updating and cleaning AUR packages..."
         sudo pacman -Syu &
         wait $!
         sudo paccache -r &
         wait $!
         sudo pacman -Scc &
         wait $!
      fi
      echo "Updating SNAP Packages..."
      sudo snap refresh &
      wait $!
      #sudo rm /var/lib/snapd/cache/*

      echo "Updating and cleaning Flatpak Packages..."
      flatpak update &
      wait $!
      flatpak uninstall --unused &
      wait $! 

      echo "Updating and cleaning Pip3 packages..."
      pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U &
      wait $!
      pip3 cache purge &
      wait $!

      echo "Updating NPM packages..."
      npm update &
      wait $!

      echo "Updating and cleaning LinuxBrew packages..."
      brew update &
      wait $!
      brew upgrade &
      wait $!
      brew cleanup &
      wait $!

      echo "Updating Google Cloud SDK..."
      gcloud components update &
      wait $!

      echo "Updating Helm charts..."
      helm repo update &
      wait $!       
    ;;
  *)
    echo "Exiting..."
    exit 1;
    ;;
esac
