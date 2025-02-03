#!/bin/bash

# Перевірка прав root
if [ "$EUID" -ne 0 ]; then 
    echo "Будь ласка, запустіть скрипт з правами root (sudo)"
    exit 1
fi

# Оновлюємо кольори та додаємо нові
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Додаємо лого
show_logo() {
    clear
    echo -e "${YELLOW} ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
    echo -e "${YELLOW} ★   ${CYAN}⚡ S P A R K M I N T L I N U X ⚡${YELLOW}   ★${NC}"

    echo -e "${YELLOW} ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
    echo ""
}

# Додаємо анімацію завантаження
show_loading() {
    local pid=$1
    local delay=0.1
    local spinstr='⋆ ★ ⋆ ✦ ⋆ ★ ⋆'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${YELLOW}[%c]${NC}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Функція для відображення прогресу
progress_bar() {
    local duration=$1
    local steps=20
    local sleep_time=$(bc <<< "scale=4; $duration/$steps")
    
    echo -ne "${YELLOW}[★"
    for ((i=0; i<steps; i++)); do
        echo -ne "⋆"
        sleep $sleep_time
    done
    echo -e "★]${NC}"
}

# Функції для різних операцій
update_system() {
    echo -e "${CYAN}Оновлення системи...${NC}"
    (apt update && apt upgrade -y) &
    show_loading $!
    progress_bar 2
}

clean_system() {
    echo -e "${CYAN}Очищення системи...${NC}"
    apt autoremove -y
    apt clean
    journalctl --vacuum-time=7d
    # Очищення тимчасових файлів
    rm -rf /tmp/*
    rm -rf ~/.cache/thumbnails/*
    progress_bar 1
}

optimize_swap() {
    echo -e "${CYAN}Оптимізація SWAP...${NC}"
    # Перевірка наявності SWAP
    if [ "$(swapon -s | wc -l)" -eq 0 ]; then
        echo -e "${YELLOW}SWAP не знайдено. Створити новий SWAP файл? (y/n)${NC}"
        read answer
        if [ "$answer" = "y" ]; then
            fallocate -l 2G /swapfile
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            echo '/swapfile none swap sw 0 0' >> /etc/fstab
        fi
    fi
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    sysctl -p
    progress_bar 1
}

optimize_io() {
    echo "Налаштування планувальника I/O..."
    echo "deadline" > /sys/block/sda/queue/scheduler
}

install_performance_tools() {
    echo "Встановлення інструментів оптимізації..."
    apt install -y preload
    apt install -y tlp tlp-rdw
    systemctl enable tlp
    systemctl start tlp
}

setup_auto_clean() {
    echo "Налаштування автоматичного очищення..."
    cat > /etc/cron.weekly/clean_cache << EOF
#!/bin/bash
sync
echo 3 > /proc/sys/vm/drop_caches
EOF
    chmod +x /etc/cron.weekly/clean_cache
}

optimize_memory() {
    echo "Оптимізація використання пам'яті..."
    echo "vm.dirty_background_ratio = 5" >> /etc/sysctl.conf
    echo "vm.dirty_ratio = 10" >> /etc/sysctl.conf
}

install_multimedia() {
    clear
    echo -e "${YELLOW}=== Встановлення мультимедіа програм ===${NC}"
    echo "1. VLC Media Player"
    echo "2. GIMP (редактор зображень)"
    echo "3. Audacity (редактор аудіо)"
    echo "4. OBS Studio (запис екрану)"
    echo "5. Kdenlive (відеоредактор)"
    echo "6. Spotify"
    echo "0. Повернутися назад"
    
    read -p "Виберіть програму для встановлення (0-6): " choice
    case $choice in
        1) apt install -y vlc ;;
        2) apt install -y gimp ;;
        3) apt install -y audacity ;;
        4) apt install -y obs-studio ;;
        5) apt install -y kdenlive ;;
        6) 
            curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | apt-key add -
            echo "deb http://repository.spotify.com stable non-free" | tee /etc/apt/sources.list.d/spotify.list
            apt update && apt install -y spotify-client
            ;;
        0) return ;;
    esac
}

install_internet() {
    clear
    echo -e "${YELLOW}=== Встановлення інтернет програм ===${NC}"
    echo "1. Firefox"
    echo "2. Google Chrome"
    echo "3. Thunderbird"
    echo "4. Telegram"
    echo "5. Discord"
    echo "6. Skype"
    echo "0. Повернутися назад"
    
    read -p "Виберіть програму для встановлення (0-6): " choice
    case $choice in
        1) apt install -y firefox ;;
        2) 
            wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            apt install -y ./google-chrome-stable_current_amd64.deb
            rm google-chrome-stable_current_amd64.deb
            ;;
        3) apt install -y thunderbird ;;
        4) 
            apt install -y telegram-desktop
            ;;
        5)
            wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
            apt install -y ./discord.deb
            rm discord.deb
            ;;
        6)
            wget https://go.skype.com/skypeforlinux-64.deb
            apt install -y ./skypeforlinux-64.deb
            rm skypeforlinux-64.deb
            ;;
        0) return ;;
    esac
}

install_development() {
    clear
    echo -e "${YELLOW}=== Встановлення інструментів розробки ===${NC}"
    echo "1. Git"
    echo "2. Visual Studio Code"
    echo "3. Python3 + PIP"
    echo "4. Node.js + NPM"
    echo "5. Docker"
    echo "6. Sublime Text"
    echo "7. PostgreSQL"
    echo "8. MySQL"
    echo "0. Повернутися назад"
    
    read -p "Виберіть інструмент для встановлення (0-8): " choice
    case $choice in
        1) apt install -y git ;;
        2) 
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list
            apt update && apt install -y code
            ;;
        3) apt install -y python3 python3-pip ;;
        4) apt install -y nodejs npm ;;
        5)
            apt install -y docker.io
            systemctl enable docker
            systemctl start docker
            ;;
        6)
            wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
            echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
            apt update && apt install -y sublime-text
            ;;
        7) apt install -y postgresql postgresql-contrib ;;
        8) apt install -y mysql-server ;;
        0) return ;;
    esac
}

install_gaming() {
    clear
    echo -e "${YELLOW}=== Встановлення ігрових платформ та утиліт ===${NC}"
    echo "1. Steam"
    echo "2. Lutris"
    echo "3. Wine"
    echo "4. PlayOnLinux"
    echo "5. GameMode"
    echo "6. Discord"
    echo "0. Повернутися назад"
    
    read -p "Виберіть опцію (0-6): " choice
    case $choice in
        1) 
            apt install -y steam-installer
            ;;
        2)
            add-apt-repository ppa:lutris-team/lutris
            apt update
            apt install -y lutris
            ;;
        3)
            apt install -y wine-stable
            ;;
        4)
            apt install -y playonlinux
            ;;
        5)
            apt install -y gamemode
            ;;
        6)
            apt install -y discord
            ;;
        0) return ;;
    esac
}

install_office() {
    clear
    echo -e "${YELLOW}=== Встановлення офісних програм ===${NC}"
    echo "1. LibreOffice"
    echo "2. OnlyOffice"
    echo "3. WPS Office"
    echo "4. Evince (переглядач PDF)"
    echo "5. Calibre (менеджер електронних книг)"
    echo "0. Повернутися назад"
    
    read -p "Виберіть опцію (0-5): " choice
    case $choice in
        1) apt install -y libreoffice libreoffice-l10n-uk ;;
        2)
            wget -O onlyoffice.deb "https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb"
            apt install -y ./onlyoffice.deb
            rm onlyoffice.deb
            ;;
        3)
            wget -O wps.deb "https://wdl1.pcfg.cache.wpscdn.com/wpsdl/wpsoffice/download/linux/10976/wps-office_11.1.0.10976.XA_amd64.deb"
            apt install -y ./wps.deb
            rm wps.deb
            ;;
        4) apt install -y evince ;;
        5) apt install -y calibre ;;
        0) return ;;
    esac
}

system_maintenance() {
    clear
    echo -e "${YELLOW}=== Обслуговування системи ===${NC}"
    echo "1. Перевірка диску на помилки"
    echo "2. Оптимізація SSD (якщо встановлений)"
    echo "3. Очистка журналів системи"
    echo "4. Перевірка температури системи"
    echo "5. Налаштування автоматичного оновлення"
    echo "0. Повернутися назад"
    
    read -p "Виберіть опцію (0-5): " choice
    case $choice in
        1)
            echo -e "${CYAN}Перевірка диску...${NC}"
            fsck -f /dev/sda1
            ;;
        2)
            echo -e "${CYAN}Налаштування SSD...${NC}"
            apt install -y hdparm
            systemctl enable fstrim.timer
            systemctl start fstrim.timer
            ;;
        3)
            echo -e "${CYAN}Очищення журналів...${NC}"
            journalctl --vacuum-time=7d
            rm -rf /var/log/*.old
            rm -rf /var/log/*.gz
            ;;
        4)
            echo -e "${CYAN}Встановлення та запуск sensors...${NC}"
            apt install -y lm-sensors
            sensors-detect --auto
            sensors
            ;;
        5)
            echo -e "${CYAN}Налаштування автоматичного оновлення...${NC}"
            apt install -y unattended-upgrades
            dpkg-reconfigure -plow unattended-upgrades
            ;;
        0) return ;;
    esac
}

show_system_info() {
    clear
    echo -e "${BLUE}=== Системна інформація ===${NC}"
    echo -e "${GREEN}Операційна система:${NC} $(lsb_release -ds)"
    echo -e "${GREEN}Ядро:${NC} $(uname -r)"
    echo -e "${GREEN}Процесор:${NC} $(grep "model name" /proc/cpuinfo | head -1 | cut -d ":" -f2)"
    echo -e "${GREEN}Оперативна пам'ять:${NC} $(free -h | grep Mem | awk '{print $2}')"
    echo -e "${GREEN}Використання диску:${NC}"
    df -h /
    
    read -p "Натисніть Enter для продовження..."
}

# Функція для підтвердження дій
confirm_action() {
    local message=$1
    echo -e "${YELLOW}$message${NC}"
    echo -e "${RED}Увага: Ця дія може вплинути на роботу системи.${NC}"
    read -p "Бажаєте продовжити? (y/n): " confirm
    if [[ $confirm != "y" ]]; then
        echo -e "${RED}Операцію скасовано${NC}"
        return 1
    fi
    return 0
}

# Оновлена функція для показу опису
show_description() {
    local title=$1
    local description=$2
    echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
    echo -e "${YELLOW}★${NC} ${BOLD}$title${NC}"
    echo -e "${YELLOW}★${NC} ${CYAN}$description${NC}"
    echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
}

# Оновлена функція backup_system
backup_system() {
    clear
    show_description "Резервне копіювання системи" "Створення резервних копій важливих файлів та налаштувань системи. Це дозволить відновити систему у разі збоїв."
    
    echo "1. Створити резервну копію домашньої директорії"
    echo "2. Створити резервну копію системних налаштувань"
    echo "3. Створити повний образ системи"
    echo "4. Відновити з резервної копії"
    echo "5. Налаштувати автоматичне резервне копіювання"
    echo "0. Повернутися назад"
    
    read -p "Виберіть опцію (0-5): " choice
    case $choice in
        1)
            if confirm_action "Буде створено резервну копію домашньої директорії. Це може зайняти деякий час."; then
                echo -e "${CYAN}Створення резервної копії домашньої директорії...${NC}"
                mkdir -p /backup
                backup_date=$(date +%Y-%m-%d)
                tar -czf "/backup/home_backup_$backup_date.tar.gz" /home/ && \
                echo -e "${GREEN}Резервну копію створено успішно!${NC}" || \
                echo -e "${RED}Помилка при створенні резервної копії!${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}Створення резервної копії налаштувань...${NC}"
            tar -czf "/backup/etc_backup_$(date +%Y-%m-%d).tar.gz" /etc/
            ;;
        3)
            echo -e "${CYAN}Створення повного образу системи...${NC}"
            apt install -y clonezilla
            clonezilla
            ;;
        4)
            echo -e "${CYAN}Доступні резервні копії:${NC}"
            ls -l /backup/
            read -p "Введіть ім'я файлу для відновлення: " backup_file
            if [ -f "/backup/$backup_file" ]; then
                tar -xzf "/backup/$backup_file" -C /
            else
                echo -e "${RED}Файл не знайдено!${NC}"
            fi
            ;;
        5)
            if confirm_action "Буде налаштовано автоматичне резервне копіювання."; then
                echo -e "${CYAN}Налаштування автоматичного резервного копіювання...${NC}"
                apt install -y duplicity
                echo -e "${GREEN}Налаштування автоматичного резервного копіювання завершено успішно!${NC}"
            fi
            ;;
        0) return ;;
    esac
}

# Оновлена функція advanced_optimization
advanced_optimization() {
    clear
    show_description "Розширена оптимізація" "Додаткові налаштування для покращення продуктивності системи. Включає оптимізацію CPU, пам'яті та мережі."
    
    echo "1. Оптимізація завантаження"
    echo "2. Оптимізація використання CPU"
    echo "3. Оптимізація мережі"
    echo "4. Оптимізація графічної підсистеми"
    echo "5. Оптимізація використання RAM"
    echo "6. Налаштування планувальника процесів"
    echo "0. Повернутися назад"
    
    read -p "Виберіть опцію (0-6): " choice
    case $choice in
        1)
            if confirm_action "Буде виконано оптимізацію завантаження системи."; then
                echo -e "${CYAN}Оптимізація завантаження...${NC}"
                {
                    systemctl disable plymouth
                    apt install -y preload
                    systemctl enable preload
                    # Видалення непотрібних сервісів з автозапуску
                    systemctl disable bluetooth.service
                    systemctl disable cups.service
                    # Оптимізація параметрів GRUB
                    sed -i 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=3/' /etc/default/grub
                    update-grub
                } && echo -e "${GREEN}Оптимізацію завантаження завершено успішно!${NC}" || \
                echo -e "${RED}Виникла помилка при оптимізації завантаження!${NC}"
            fi
            ;;
        2)
            echo -e "${CYAN}Оптимізація CPU...${NC}"
            apt install -y cpufrequtils
            cpufreq-set -g performance
            ;;
        3)
            echo -e "${CYAN}Оптимізація мережі...${NC}"
            echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
            sysctl -p
            ;;
        4)
            echo -e "${CYAN}Оптимізація графіки...${NC}"
            apt install -y mesa-utils
            ;;
        5)
            echo -e "${CYAN}Оптимізація використання RAM...${NC}"
            echo "vm.swappiness=10" >> /etc/sysctl.conf
            echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
            sysctl -p
            ;;
        6)
            echo -e "${CYAN}Налаштування планувальника процесів...${NC}"
            echo "kernel.sched_migration_cost_ns = 5000000" >> /etc/sysctl.conf
            sysctl -p
            ;;
        0) return ;;
    esac
}

# Функція для налаштування безпеки
security_settings() {
    clear
    echo -e "${YELLOW}=== Налаштування безпеки ===${NC}"
    echo "1. Встановити файрвол"
    echo "2. Налаштувати автоматичні оновлення безпеки"
    echo "3. Встановити антивірус ClamAV"
    echo "4. Налаштувати SSH"
    echo "5. Перевірити відкриті порти"
    echo "0. Повернутися назад"
    
    read -p "Виберіть опцію (0-5): " choice
    case $choice in
        1)
            apt install -y ufw
            ufw enable
            ufw default deny incoming
            ufw default allow outgoing
            ;;
        2)
            apt install -y unattended-upgrades
            dpkg-reconfigure -plow unattended-upgrades
            ;;
        3)
            apt install -y clamav clamav-daemon
            freshclam
            ;;
        4)
            apt install -y openssh-server
            cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
            echo "PermitRootLogin no" >> /etc/ssh/sshd_config
            echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
            systemctl restart ssh
            ;;
        5)
            apt install -y nmap
            nmap localhost
            ;;
        0) return ;;
    esac
}

# Нова функція для налаштування системи
system_tweaks() {
    clear
    show_description "Налаштування системи" "Додаткові налаштування для покращення зручності використання системи."
    
    echo "1. Налаштувати автоматичне очищення системи"
    echo "2. Налаштувати швидкі клавіші"
    echo "3. Налаштувати автозапуск програм"
    echo "4. Налаштувати енергозбереження"
    echo "5. Налаштувати робочий стіл"
    echo "0. Повернутися назад"
    
    read -p "Виберіть опцію (0-5): " choice
    case $choice in
        1)
            if confirm_action "Буде налаштовано автоматичне очищення системи."; then
                setup_auto_clean
                echo -e "${GREEN}Налаштування автоочищення завершено!${NC}"
            fi
            ;;
        # ... інші опції ...
    esac
}

# Оновлене головне меню
while true; do
    show_logo
    echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
    echo -e "${YELLOW}★${NC}        ${BOLD}Оберіть опцію для оптимізації${NC}  ${YELLOW}★${NC}"
    echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
    echo -e "${YELLOW}★${NC} 1. ⚡ Системна інформація             ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 2. ⭐ Базова оптимізація              ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 3. 🚀 Розширена оптимізація           ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 4. 📦 Встановлення програм            ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 5. 🔒 Налаштування безпеки            ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 6. 💾 Резервне копіювання             ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 7. 🔧 Обслуговування системи          ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 8. 🎮 Встановлення драйверів          ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 9. ⚡ Повна оптимізація               ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 10. ⚙️  Налаштування системи           ${YELLOW}★${NC}"
    echo -e "${YELLOW}★${NC} 0. 🚪 Вийти                           ${YELLOW}★${NC}"
    echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
    echo ""

    read -p "$(echo -e $YELLOW"★ Виберіть опцію (0-10): "$NC)" choice

    case $choice in
        1) 
            show_description "Системна інформація" "Відображення детальної інформації про вашу систему"
            show_system_info 
            ;;
        2) 
            if confirm_action "Буде виконано базову оптимізацію системи."; then
                clear
                show_description "Базова оптимізація" "Виконання основних налаштувань для покращення продуктивності"
                update_system
                clean_system
                optimize_swap
                optimize_io
            fi
            ;;
        3) advanced_optimization ;;
        4)
            clear
            echo -e "${YELLOW}=== Встановлення програм ===${NC}"
            echo "1. Мультимедіа програми"
            echo "2. Інтернет програми"
            echo "3. Інструменти розробки"
            echo "4. Ігрові платформи"
            echo "5. Офісні програми"
            echo "0. Назад"
            read -p "Виберіть категорію: " subchoice
            case $subchoice in
                1) install_multimedia ;;
                2) install_internet ;;
                3) install_development ;;
                4) install_gaming ;;
                5) install_office ;;
                0) continue ;;
            esac
            ;;
        5) security_settings ;;
        6) backup_system ;;
        7) system_maintenance ;;
        8)
            clear
            echo -e "${YELLOW}=== Встановлення драйверів ===${NC}"
            ubuntu-drivers autoinstall
            apt install -y firmware-linux-nonfree
            ;;
        9)
            clear
            echo -e "${YELLOW}=== Повна оптимізація системи ===${NC}"
            update_system
            clean_system
            optimize_swap
            optimize_io
            install_performance_tools
            setup_auto_clean
            optimize_memory
            advanced_optimization
            security_settings
            ;;
        10) system_tweaks ;;
        0) 
            clear
            echo -e "${GREEN}Дякуємо за використання скрипта!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Невірний вибір. Натисніть Enter для продовження...${NC}"
            read
            ;;
    esac

    if [ $choice != 1 ]; then
        echo -e "${GREEN}Операцію завершено. Натисніть Enter для продовження...${NC}"
        read
    fi
done 