#!/bin/bash

output(){
    echo -e '\e[36m'$1'\e[0m';
}

warn(){
    echo -e '\e[31m'$1'\e[0m';
}

copyright(){
    echo "翼龍面板安裝 & 升級程序 v3"
    echo "想要免費的1G服務器嗎? BlueHosting! https://discord.blueserv.ga/"
}

get_distribution(){
    echo "感謝您的支持. 請注意這個程序只能在全新的運作系統運行. 如果在較舊的運作系統運行可能會無法運行."
    echo "自动操作系统检测已初始化."
	if [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
		dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
    else
        exit 1
	fi
	echo "OS: $lsb_dist $dist_version 已偵測."
    echo ""

    if [ "$lsb_dist" =  "ubuntu" ]; then
        if [ "$dist_version" != "18.10" ] && [ "$dist_version" != "18.04" ] && [ "$dist_version" != "16.04" ] && [ "$dist_version" != "14.04" ]; then
            echo "不支持的Ubuntu版本。 仅支持Ubuntu 18.04,16.04和14.04."
            exit 2
        fi
	elif [ "$lsb_dist" = "debian" ]; then
        if [ "$dist_version" != "9" ] && [ "$dist_version" != "8" ]; then
            echo "不支持的Debian版本。 仅支持Debian 9和8."
            exit 2
		fi
    elif [ "$lsb_dist" = "fedora" ]; then
        if [ "$dist_version" != "29" ] && [ "$dist_version" != "28" ]; then
            echo "不支持的Fedora版本。 仅支持Fedora 29和28."
            exit 2
        fi
    elif [ "$lsb_dist" = "centos" ]; then
        if [ "$dist_version" != "7" ]; then
            echo "不支持的CentOS版本。 仅支持CentOS 7."
            exit 2
        fi
    elif [ "$lsb_dist" = "rhel" ]; then
        if [ "$dist_version" != "7" ]&&[ "$dist_version" != "7.1" ]&&[ "$dist_version" != "7.2" ]&&[ "$dist_version" != "7.3" ]&&[ "$dist_version" != "7.4" ]&&[ "$dist_version" != "7.5" ]&&[ "$dist_version" != "7.6" ]; then
            echo "不支持的RHEL版本。 仅支持RHEL 7."
            exit 2
        fi
    elif [ "$lsb_dist" != "ubuntu" ] && [ "$lsb_dist" != "debian" ] && [ "$lsb_dist" != "centos" ] && [ "$lsb_dist" != "rhel" ]; then
        echo "不接受的運行系統."
        echo ""
        echo "接受的運行系統:"
        echo "Ubuntu: 18.10, 18.04, 16.04 14.04"
        echo "Debian: 9, 8"
        echo "Fedora: 29, 28"
        echo "CentOS: 7"
        echo "RHEL: 7"
        exit 2
    fi
}

check_root(){
    if [ "$EUID" -ne 0 ]; then
        echo "請使用ROOT賬號登入才能繼續"
        exit 3
    fi
}

get_architecture(){
    echo "自动架构检测已初始化."
    MACHINE_TYPE=`uname -m`
    if [ ${MACHINE_TYPE} == 'x86_64' ]; then
        echo "64-bit server 已偵測! 祝你好運."
        echo ""
    else
        echo "检测到不支持的架构! 请切换到64位(x86_64)."
        exit 4
    fi
}

get_virtualization(){
    echo "自动虚拟化检测已初始化."
    if [ "$lsb_dist" =  "ubuntu" ]; then
        apt-get update --fix-missing
        apt-get -y install software-properties-common
        add-apt-repository -y universe
        apt-get -y install virt-what
    elif [ "$lsb_dist" =  "debian" ]; then
        apt update --fix-missing
        apt-get -y install software-properties-common
        apt-get -y install virt-what
    elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "rhel" ]; then
        yum -y install virt-what
    fi
    virt_serv=$(echo $(virt-what))
    if [ "$virt_serv" = "" ]; then
        echo "Virtualization: Bare Metal 已偵測."
    elif [ "$virt_serv" = "openvz lxc" ]; then
        echo "Virtualization: OpenVZ 7 已偵測."
    else
        echo "Virtualization: $virt_serv 已偵測."
    fi
    echo ""
    if [ "$virt_serv" != "" ] && [ "$virt_serv" != "kvm" ] && [ "$virt_serv" != "vmware" ] && [ "$virt_serv" != "hyperv" ] && [ "$virt_serv" != "openvz lxc" ]; then
        echo "不支持的虚拟化方法. 有关您的服务器是否可以运行Docker，请咨询您的提供商. 继续需要您承擔担风险."
        echo "如果您的服务器在将来的任何时候中断，将不会给予支持."
        echo "接受?\n[1] Yes.\n[2] No."
        read choice
        case $choice in 
            1)  echo "正在運作...喝杯咖啡先吧"
                ;;
            2)  echo "正在取消運作..."
                exit 5
                ;;
        esac
        echo ""
    fi

    echo "Kernel 检测初始化."
    if echo $(uname -r) | grep -q xxxx; then
        echo "OVH Kernel 已偵測. The script will not work. Please install your server with a generic/distribution kernel."
        exit 6
    elif echo $(uname -r) | grep -q pve; then
        echo "Proxmox LXE Kernel 已偵測. 您已选择继续执行最后一步，因此您將自行承担风险."
        echo "继续进行危险的安裝 請放心我會努力的..."
    elif echo $(uname -r) | grep -q stab; then
        if echo $(uname -r) | grep -q 2.6; then 
            echo "OpenVZ 6 已偵測. 該服務器都無法使用Docker. 這個程序將退出以避免進一步的損害."
            exit 6
        fi
    elif echo $(uname -r) | grep -q lve; then
        echo "CloudLinux Kernel 已偵測. 該服務器都無法使用Docker. 這個程序將退出以避免進一步的損害."
        exit 6
    elif echo $(uname -r) | grep -q gcp; then
        echo "Google Cloud Platform 已偵測. 祝您好運."
    else
        echo "沒有檢測到任何壞內核. 繼續前進."
    fi
}

server_options() {
    echo "選擇一項你想安裝的東西吧:"
    echo "[1] 只安裝面板."
    echo "[2] 只安裝主機."
    echo "[3] 安裝面板和主機."
    echo "[4] 安裝 SFTP 服務器 (必須安裝主機后才能使用. Ubuntu 14.04 不支持使用此安裝.)"
    echo "[5] 升級 0.7.x 面板到 0.7.13."
    echo "[6] 升級 0.6.x 主機到 0.6.12."
    echo "[7] 升級SFTP至 1.0.4."
    echo "[8] 安裝或者升級 phpMyAdmin 4.8.5 (必須安裝面板后才能使用.)"
    echo "[9] 切換一個翼龍面板主題."
    echo "[10] 緊急切換 MariaDB root 密碼."
    echo "[11] 緊急重置數據庫架設咨詢."
    echo "[12] 启用外部Mariadb root登录.（警告：这是非常不鼓励的，因为它存在安全风险）"
    echo "[13] 禁止外部Mariadb root登录. (Reversing [12].)"
    read choice
    case $choice in
        1 ) installoption=1
            echo "您選擇了只安裝面板."
            ;;
        2 ) installoption=2
            echo "您選擇了只安裝主機."
            ;;
        3 ) installoption=3
            echo "您選擇了安裝面板與主機."
            ;;
        4 ) installoption=4
            echo "您選擇了安裝SFTP服務器."
            ;;
        5 ) installoption=5
            echo "您選擇了升級面板."
            ;;
        6 ) installoption=6
            echo "您選擇了升級主機."
            ;;
        7 ) installoption=7
            echo "您選擇了升級SFTP服務器."
            ;;
        8 ) installoption=8
            echo "您選擇了安裝/升級 phpMyAdmin."
            ;;
        9 ) installoption=9
            echo "您選擇了切換翼龍面板主題."
            ;;
        10 ) installoption=10
            echo "您選擇了 MariaDB root 密碼切換."
            ;;
        11 ) installoption=11
            echo "您選擇了 Database 架設咨詢重置."
            ;;
        12 ) installoption=12
            echo "您選擇了接受外部MariaDB root登入."
            ;;
        13 ) installoption=12
            echo "您選擇了拒絕MariaDB root登入."
            ;;
        * ) echo "您沒有選擇正確的選項."
            server_options
    esac
}   

webserver_options() {
    echo "選擇一個你想用的網絡服務器:\n[1] Nginx (推薦).\n[2] Apache2/Httpd."
    read choice
    case $choice in
        1 ) webserver=1
            echo "您選擇了 Nginx."
            ;;
        2 ) webserver=2
            echo "您選擇了 Apache2 / Httpd."
            ;;
        * ) echo "您沒有選擇正確的選項."
            webserver_options
    esac
}

theme_options() {
    echo "您想要安裝一個翼龍面板主題嗎? :\n[1] No.\n[2] Graphite theme.\n[3] Midnight theme."
    echo "查看更多面板主題訊息: https://github.com/TheFonix/Pterodactyl-Themes"
    read choice
    case $choice in
        1 ) themeoption=1
            echo "您選擇了普通的翼龍面板主題."
            ;;
        2 ) themeoption=2
            echo "您選擇了 Fonix's Graphite 主題."
            ;;
        3 ) themeoption=3
            echo "您選擇了 Fonix's Midnight 主題."
            ;;
        * ) echo "您沒有選擇正確的選項."
            theme_options
    esac
}   

required_infos() {
    echo "請輸入您的電子郵件:"
    read email
    dns_check
}

dns_check(){
    echo "請輸入您的 FQDN (panel.yourdomain.com):"
    read FQDN

    echo "成功檢查 DNS."
    SERVER_IP=$(curl -s http://checkip.amazonaws.com)
    DOMAIN_RECORD=$(dig +short ${FQDN})
    if [ "${SERVER_IP}" != "${DOMAIN_RECORD}" ]; then
        echo "您輸入的網域并沒有連接此主機的IP地址."
        echo "請使用 A 記錄 連接您的IP地址到網域. 例子, 如果您成功添加了一個Ａ記錄　他的名字是 "Panel", 那麽您的 FQDN 就是 panel.yourdomain.tld"
        echo "如果您使用的是CloudFlare, 請點擊那個橙色的雲朵 確定他變成灰色"
        echo "如果您沒有一個網域, 您可以到這裏獲取一個 https://www.freenom.com/en/index.html?lang=en."
        dns_check
    else 
        echo "網域成功添加. 讓我們繼續吧."
    fi
}

theme() {
    echo "主題安裝已初始化."
    cd /var/www/pterodactyl
    if [ "$themeoption" = "1" ]; then
        echo "保持翼手龍的普通主題."
    elif [ "$themeoption" = "2" ]; then
        curl https://raw.githubusercontent.com/TheFonix/Pterodactyl-Themes/master/Pterodactyl-7/Graphite/build.sh | sh    
    elif [ "$themeoption" = "3" ]; then
        curl https://raw.githubusercontent.com/TheFonix/Pterodactyl-Themes/master/Pterodactyl-7/Midnight/build.sh | sh
    fi
    php artisan view:clear
    php artisan cache:clear
}

repositories_setup(){
    echo "正在配置存儲庫."
    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        apt-get -y install sudo
        echo 'Acquire::ForceIPv4 "true";' | sudo tee /etc/apt/apt.conf.d/99force-ipv4
        apt-get -y update 
        if [ "$lsb_dist" =  "ubuntu" ]; then
            LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
            add-apt-repository -y ppa:chris-lea/redis-server
            add-apt-repository -y ppa:certbot/certbot
            if [ "$dist_version" = "18.10" ]; then
                apt-get install software-properties-common
                apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
                add-apt-repository 'deb [arch=amd64] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu cosmic main'
            elif [ "$dist_version" = "18.04" ]; then
                add-apt-repository -y ppa:nginx/stable
                apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
                add-apt-repository -y 'deb [arch=amd64,arm64,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu bionic main'
            elif [ "$dist_version" = "16.04" ]; then
                add-apt-repository -y ppa:nginx/stable
                apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
                add-apt-repository 'deb [arch=amd64,arm64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu xenial main'
            elif [ "$dist_version" = "14.04" ]; then
                add-apt-repository -y ppa:ondrej/nginx
                apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
                add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://sfo1.mirrors.digitalocean.com/mariadb/repo/10.3/ubuntu trusty main'            
            fi
        elif [ "$lsb_dist" =  "debian" ]; then
            apt-get -y install ca-certificates apt-transport-https
            if [ "$dist_version" = "9" ]; then
                apt-get -y install software-properties-common dirmngr
                wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
                sudo echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list
                sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
                sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/debian stretch main'
            elif [ "$dist_version" = "8" ]; then
                apt-get -y install software-properties-common
                wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
                echo "deb https://packages.sury.org/php/ jessie main" | sudo tee /etc/apt/sources.list.d/php.list
                apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
                add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://nyc2.mirrors.digitalocean.com/mariadb/repo/10.3/debian jessie main'
            fi
        fi
        apt-get -y update 
        apt-get -y upgrade
        apt-get -y autoremove
        apt-get -y autoclean   
        apt-get -y install dnsutils curl
    elif  [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "rhel" ]; then
        if  [ "$lsb_dist" =  "fedora" ] && [ "$dist_version" = "29" ]; then

            bash -c 'cat > /etc/yum.repos.d/mariadb.repo' <<-'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/fedora29-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

bash -c 'cat > /etc/yum.repos.d/nginx.repo' <<-'EOF'
[heffer-nginx-mainline]
name=Copr repo for nginx-mainline owned by heffer
baseurl=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/fedora-$releasever-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF
        elif  [ "$lsb_dist" =  "fedora" ] && [ "$dist_version" = "28" ]; then

            bash -c 'cat > /etc/yum.repos.d/mariadb.repo' <<-'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/fedora28-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

bash -c 'cat > /etc/yum.repos.d/nginx.repo' <<-'EOF'
[heffer-nginx-mainline]
name=Copr repo for nginx-mainline owned by heffer
baseurl=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/fedora-$releasever-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

        elif  [ "$lsb_dist" =  "centos" ] && [ "$dist_version" = "7" ]; then

            bash -c 'cat > /etc/yum.repos.d/mariadb.repo' <<-'EOF'
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

            bash -c 'cat > /etc/yum.repos.d/nginx.repo' <<-'EOF'
[heffer-nginx-mainline]
name=Copr repo for nginx-mainline owned by heffer
baseurl=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/epel-7-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF

            yum -y install epel-release
            yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
        elif  [ "$lsb_dist" =  "rhel" ]; then
            
            bash -c 'cat > /etc/yum.repos.d/mariadb.repo' <<-'EOF'        
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/rhel7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

            bash -c 'cat > /etc/yum.repos.d/nginx.repo' <<-'EOF'
[heffer-nginx-mainline]
name=Copr repo for nginx-mainline owned by heffer
baseurl=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/epel-7-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/heffer/nginx-mainline/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
EOF
            yum -y install epel-release
            yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
        fi
        yum -y install yum-utils
        yum-config-manager --enable remi-php72
        yum -y upgrade
        yum -y autoremove
        yum -y clean packages
        yum -y install curl bind-utils
    fi
}

install_dependencies(){
    echo "正在安裝配件."
    if  [ "$lsb_dist" =  "ubuntu" ] ||  [ "$lsb_dist" =  "debian" ]; then
        if [ "$webserver" = "1" ]; then
            apt-get -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip curl tar unzip git redis-server nginx git wget expect
        elif [ "$webserver" = "2" ]; then
            apt-get -y install php7.2 php7.2-cli php7.2-gd php7.2-mysql php7.2-pdo php7.2-mbstring php7.2-tokenizer php7.2-bcmath php7.2-xml php7.2-fpm php7.2-curl php7.2-zip curl tar unzip git redis-server apache2 libapache2-mod-php7.2 redis-server git wget expect
        fi
        sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server"
    elif [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        if [ "$webserver" = "1" ]; then
            yum -y install php php-common php-fpm php-cli php-json php-mysqlnd php-mcrypt php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache mariadb-server redis cronie nginx git policycoreutils-python-utils libsemanage-devel unzip wget expect
        elif [ "$webserver" = "2" ]; then
            yum -y install php php-common php-fpm php-cli php-json php-mysqlnd php-mcrypt php-gd php-mbstring php-pdo php-zip php-bcmath php-dom php-opcache mariadb-server redis cronie httpd git policycoreutils-python-utils libsemanage-devel mod_ssl unzip wget expect
        fi
    fi

    echo "正在開啓服務."
    systemctl enable php-fpm
    systemctl enable php7.2-fpm
    if [ "$webserver" = "1" ]; then
        systemctl enable nginx
    elif [ "$webserver" = "2" ]; then
        systemctl enable apache2
        systemctl enable httpd
    fi

    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        systemctl enable redis-server
        service redis-server start
    elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "rhel" ]; then
        systemctl enable redis
        service redis start
    fi
    
    systemctl enable cron
    systemctl enable mariadb
    service php-fpm start
    service php7.2-fpm start
    if [ "$webserver" = "1" ]; then
        service nginx start
    elif [ "$webserver" = "2" ]; then
        if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
            service apache2 start
        elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "rhel" ]; then
            service httpd start
        fi
    fi
    service cron start
    service mariadb start
}

pterodactyl_queue(){
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        apt -y install supervisor
        service supervisor start
        sudo bash -c 'cat > /etc/supervisor/conf.d/pterodactyl-worker.conf' <<-'EOF'
[program:pterodactyl-worker]
process_name=%(program_name)s_%(process_num)02d
command=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/pterodactyl/storage/logs/queue-worker.log
EOF
        echo "正在更新supervisor."
        supervisorctl reread
        supervisorctl update
        supervisorctl start pterodactyl-worker:*
        sed -i -e '$i \service supervisor start\n' /etc/rc.local    
    elif  [ "$lsb_dist" =  "ubuntu" ] ||  [ "$lsb_dist" =  "debian" ]; then
        cat > /etc/systemd/system/pteroq.service <<- 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF
    elif  [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        if [ "$webserver" = "1" ]; then
            cat > /etc/systemd/system/pteroq.service <<- 'EOF'
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=nginx
Group=nginx
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF
        elif [ "$webserver" = "2" ]; then
            cat > /etc/systemd/system/pteroq.service <<- 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=apache
Group=apache
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3

[Install]
WantedBy=multi-user.target
EOF
        fi
    fi
    sudo systemctl daemon-reload
    systemctl enable pteroq.service
    systemctl start pteroq
}

install_pterodactyl() {
    echo "正在創建數據庫並設置root密碼."
    password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    adminpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    rootpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q0="DROP DATABASE IF EXISTS test;"
    Q1="CREATE DATABASE IF NOT EXISTS panel;"
    Q2="GRANT ALL ON panel.* TO 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$password';"
    Q3="GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP, EXECUTE, PROCESS, RELOAD, CREATE USER ON *.* TO 'admin'@'$SERVER_IP' IDENTIFIED BY '$adminpassword' WITH GRANT OPTION;"
    Q4="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$rootpassword');"
    Q5="SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('$rootpassword');"
    Q6="SET PASSWORD FOR 'root'@'::1' = PASSWORD('$rootpassword');"
    Q7="DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
    Q8="DELETE FROM mysql.user WHERE User='';"
    Q9="DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
    Q10="FLUSH PRIVILEGES;"
    SQL="${Q0}${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}${Q8}${Q9}${Q10}"
    mysql -u root -e "$SQL"

    echo "Binding MariaDB to 0.0.0.0."
	if [ -f /etc/mysql/my.cnf ] ; then
        sed -i -- 's/bind-address/# bind-address/g' /etc/mysql/my.cnf
		sed -i '/\[mysqld\]/a bind-address = 0.0.0.0' /etc/mysql/my.cnf
		echo '正在重啓MYSQL...'
		service mariadb restart
	elif [ -f /etc/my.cnf ] ; then
        sed -i -- 's/bind-address/# bind-address/g' /etc/my.cnf
		sed -i '/\[mysqld\]/a bind-address = 0.0.0.0' /etc/my.cnf
		echo '正在重啓MYSQL...'
		service mariadb restart
	else 
		echo '文件 my.cnf 不存在! 請通知藍藍.'
	fi
    
    echo "正在下載翼龍面板."
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl
    curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/download/v0.7.13/panel.tar.gz
    tar --strip-components=1 -xzvf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/

    echo "翼龍面板安裝中."
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    cp .env.example .env
    if [ "$lsb_dist" =  "rhel" ]; then
        yum -y install composer
        composer update
    else
        composer install --no-dev --optimize-autoloader
    fi
    php artisan key:generate --force
    php artisan p:environment:setup -n --author=$email --url=https://$FQDN --timezone=America/New_York --cache=redis --session=database --queue=redis --redis-host=127.0.0.1 --redis-pass= --redis-port=6379
    php artisan p:environment:database --host=127.0.0.1 --port=3306 --database=panel --username=pterodactyl --password=$password
    echo "To use PHP's internal mail sending, select [mail]. To use a custom SMTP server, select [smtp]. TLS Encryption is recommended."
    php artisan p:environment:mail
    php artisan migrate --seed --force
    php artisan p:user:make --email=$email --admin=1
    if  [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        chown -R www-data:www-data *
    elif  [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "rhel" ]; then
        if [ "$webserver" = "1" ]; then
            chown -R nginx:nginx *
        elif [ "$webserver" = "2" ]; then
            chown -R apache:apache *
        fi
	    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/pterodactyl/storage(/.*)?"
        restorecon -R /var/www/pterodactyl
    fi
    echo "正在創建面板隊列偵聽器."
    (crontab -l ; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1")| crontab -
    service cron restart
}

upgrade_pterodactyl(){
    cd /var/www/pterodactyl
    php artisan down
    curl -L https://github.com/pterodactyl/panel/releases/download/v0.7.13/panel.tar.gz | tar --strip-components=1 -xzv
    unzip panel
    chmod -R 755 storage/* bootstrap/cache
    composer install --no-dev --optimize-autoloader
    php artisan view:clear
    php artisan migrate --force
    php artisan db:seed --force
    chown -R www-data:www-data *
    if [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "rhel" ]; then
        if [ "$webserver" = "1" ]; then
            chown -R nginx:nginx $(pwd)
        elif [ "$webserver" = "2" ]; then
            chown -R apache:apache $(pwd)
        fi
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/pterodactyl/storage(/.*)?"
        restorecon -R /var/www/pterodactyl
    fi
    echo "您的面板已被升級至 0.7.13."
    php artisan up
    php artisan queue:restart
}

webserver_config(){
    if  [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        if [ "$webserver" = "1" ]; then
            nginx_config
        elif [ "$webserver" = "2" ]; then
            apache_config
        fi
    elif  [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        if [ "$webserver" = "1" ]; then
            php_config
            nginx_config_redhat
        elif [ "$webserver" = "2" ]; then
            apache_config_redhat
        fi
    fi
}

nginx_config() {
    echo "正在禁止default config"
    rm -rf /etc/nginx/sites-enabled/default
    echo "正在設置Nginx."
    
echo '
server_tokens off;

server {
    listen 80;
    server_name '"$FQDN"';
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name '"$FQDN"';

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/'"$FQDN"'/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/'"$FQDN"'/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
' | sudo -E tee /etc/nginx/sites-available/pterodactyl.conf >/dev/null 2>&1

    ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
    service nginx restart
}

apache_config() {
    echo "Disabling default configuration"
    rm -rf /etc/nginx/sites-enabled/default
    echo "Configuring Apache2"
echo '
<VirtualHost *:80>
  ServerName '"$FQDN"'
  RewriteEngine On
  RewriteCond %{HTTPS} !=on
  RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L] 
</VirtualHost>

<VirtualHost *:443>
  ServerName '"$FQDN"'
  DocumentRoot "/var/www/pterodactyl/public"
  AllowEncodedSlashes On
  php_value upload_max_filesize 100M
  php_value post_max_size 100M
  <Directory "/var/www/pterodactyl/public">
    AllowOverride all
  </Directory>
  SSLEngine on
  SSLCertificateFile /etc/letsencrypt/live/'"$FQDN"'/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/'"$FQDN"'/privkey.pem
</VirtualHost> 


' | sudo -E tee /etc/apache2/sites-available/pterodactyl.conf >/dev/null 2>&1
    
    ln -s /etc/apache2/sites-available/pterodactyl.conf /etc/apache2/sites-enabled/pterodactyl.conf
    a2enmod ssl
    a2enmod rewrite
    service apache2 restart
}

nginx_config_redhat(){
    echo "Configuring Nginx Webserver"
    
echo '
server {
    listen 80;
    server_name '"$FQDN"';
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name '"$FQDN"';

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;
    
    sendfile off;

    # strengthen ssl security
    ssl_certificate /etc/letsencrypt/live/'"$FQDN"'/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/'"$FQDN"'/privkey.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
    
    # See the link below for more SSL information:
    #     https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html
    #
    # ssl_dhparam /etc/ssl/certs/dhparam.pem;

    # Add headers to serve security related headers
    add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php-fpm/pterodactyl.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
' | sudo -E tee /etc/nginx/conf.d/pterodactyl.conf >/dev/null 2>&1

    service nginx restart
    chown -R nginx:nginx $(pwd)
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/pterodactyl/storage(/.*)?"
    restorecon -R /var/www/pterodactyl
}

apache_config_redhat() {
    echo "Configuring Apache2"
echo '
<VirtualHost *:80>
  ServerName '"$FQDN"'
  RewriteEngine On
  RewriteCond %{HTTPS} !=on
  RewriteRule ^/?(.*) https://%{SERVER_NAME}/$1 [R,L] 
</VirtualHost>
<VirtualHost *:443>
  ServerName '"$FQDN"'
  DocumentRoot "/var/www/pterodactyl/public"
  AllowEncodedSlashes On
  <Directory "/var/www/pterodactyl/public">
    AllowOverride all
  </Directory>
  SSLEngine on
  SSLCertificateFile /etc/letsencrypt/live/'"$FQDN"'/fullchain.pem
  SSLCertificateKeyFile /etc/letsencrypt/live/'"$FQDN"'/privkey.pem
</VirtualHost> 

' | sudo -E tee /etc/httpd/conf.d/pterodactyl.conf >/dev/null 2>&1
    service httpd restart
}

php_config(){
    echo "Configuring PHP socket."
    bash -c 'cat > /etc/php-fpm.d/www-pterodactyl.conf' <<-'EOF'
[pterodactyl]

user = nginx
group = nginx

listen = /var/run/php-fpm/pterodactyl.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0750

pm = ondemand
pm.max_children = 9
pm.process_idle_timeout = 10s
pm.max_requests = 200
EOF
    systemctl restart php-fpm
}

install_daemon() {
    cd /root
    echo "Installing Pterodactyl Daemon dependencies."
    if  [ "$lsb_dist" =  "ubuntu" ] ||  [ "$lsb_dist" =  "debian" ]; then
        apt-get -y install curl tar unzip
    elif  [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        yum -y install curl tar unzip
    fi
    echo "Installing Docker"
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash
    systemctl enable docker
    systemctl start docker
    echo "Enabling Swap support for Docker & Installing NodeJS."
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& swapaccount=1/' /etc/default/grub
    if  [ "$lsb_dist" =  "ubuntu" ] ||  [ "$lsb_dist" =  "debian" ]; then
        sudo update-grub
        curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
        apt -y install nodejs make gcc g++ node-gyp
        apt-get -y update 
        apt-get -y upgrade
        apt-get -y autoremove
        apt-get -y autoclean
    elif  [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        grub2-mkconfig -o "$(readlink /etc/grub2.conf)"
        curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
        yum -y install nodejs gcc-c++ make
        yum -y upgrade
        yum -y autoremove
        yum -y clean packages
    fi
    echo "Installing the Pterodactyl Daemon."
    mkdir -p /srv/daemon /srv/daemon-data
    cd /srv/daemon
    curl -L https://github.com/pterodactyl/daemon/releases/download/v0.6.12/daemon.tar.gz | tar --strip-components=1 -xzv
    npm install --only=production
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        npm install -g forever
    else
        bash -c 'cat > /etc/systemd/system/wings.service' <<-'EOF'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service

[Service]
User=root
#Group=some_group
WorkingDirectory=/srv/daemon
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/bin/node /srv/daemon/src/index.js
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload
        systemctl enable wings
    fi
    if [ "$lsb_dist" =  "debian" ] && [ "$dist_version" = "8" ]; then
        kernel_modifications_d8
    fi
}

upgrade_daemon(){
    cd /srv/daemon
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        forever stop src/index.js
    else
    service wings stop
    fi
    curl -L https://github.com/pterodactyl/daemon/releases/download/v0.6.12/daemon.tar.gz | tar --strip-components=1 -xzv
    npm install --only=production
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        forever start src/index.js
    else
    service wings restart
    fi
    echo "Your daemon has been updated to version 0.6.12."
}

install_standalone_sftp(){
    cd /srv/daemon
    echo "Disabling default SFTP server."
	$text="\ \ \"enabled\": false,"
    sed -i '/"port": 2022,/a\\        "enabled": false,' /srv/daemon/config/core.json
    service wings restart
    echo "Installing standalone SFTP server."
    curl -Lo sftp-server https://github.com/pterodactyl/sftp-server/releases/download/v1.0.4/sftp-server
    chmod +x sftp-server
    bash -c 'cat > /etc/systemd/system/pterosftp.service' <<-'EOF'
[Unit]
Description=Pterodactyl Standalone SFTP Server
After=wings.service

[Service]
User=root
WorkingDirectory=/srv/daemon
LimitNOFILE=4096
PIDFile=/var/run/wings/sftp.pid
ExecStart=/srv/daemon/sftp-server
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF
    systemctl enable --now pterosftp
    service pterosftp restart
}

upgrade_standalone_sftp(){
    echo "Turning off the standalone SFTP server."
    service pterosftp stop
    curl -Lo sftp-server https://github.com/pterodactyl/sftp-server/releases/download/v1.0.4/sftp-server
    chmod +x sftp-server
    service pterosftp start
    echo "Your standalone SFTP server has been updated to v1.0.4"
}

install_phpmyadmin(){
    echo "Installing phpMyAdmin."
    cd /var/www/pterodactyl/public
    rm -rf phpmyadmin
    wget https://files.phpmyadmin.net/phpMyAdmin/4.8.5/phpMyAdmin-4.8.5-all-languages.zip
    unzip phpMyAdmin-4.8.5-all-languages
    mv phpMyAdmin-4.8.5-all-languages phpmyadmin
    rm -rf phpMyAdmin-4.8.5-all-languages.zip
    cd /var/www/pterodactyl/public/phpmyadmin

    SERVER_IP=$(curl -s http://checkip.amazonaws.com)
    BOWFISH=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 34 | head -n 1`
    bash -c 'cat > /var/www/pterodactyl/public/phpmyadmin/config.inc.php' <<EOF
<?php
/* Servers configuration */
\$i = 0;

/* Server: MariaDB [1] */
\$i++;
\$cfg['Servers'][\$i]['verbose'] = 'MariaDB';
\$cfg['Servers'][\$i]['host'] = '${SERVER_IP}';
\$cfg['Servers'][\$i]['port'] = '';
\$cfg['Servers'][\$i]['socket'] = '';
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['user'] = 'root';
\$cfg['Servers'][\$i]['password'] = '';

/* End of servers configuration */

\$cfg['blowfish_secret'] = '${BOWFISH}';
\$cfg['DefaultLang'] = 'en';
\$cfg['ServerDefault'] = 1;
\$cfg['UploadDir'] = '';
\$cfg['SaveDir'] = '';
\$cfg['CaptchaLoginPublicKey'] = '6LcJcjwUAAAAAO_Xqjrtj9wWufUpYRnK6BW8lnfn';
\$cfg['CaptchaLoginPrivateKey'] = '6LcJcjwUAAAAALOcDJqAEYKTDhwELCkzUkNDQ0J5'
?>    
EOF
    echo "Installation completed."
    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        chown -R www-data:www-data * /var/www/pterodactyl
    elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        chown -R apache:apache * /var/www/pterodactyl
        chown -R nginx:nginx * /var/www/pterodactyl
        semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/pterodactyl/storage(/.*)?"
        restorecon -R /var/www/pterodactyl
    fi
}

kernel_modifications_d8(){
    echo "Modifying Grub."
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& cgroup_enable=memory/' /etc/default/grub  
    echo "Adding backport repositories." 
    echo deb http://http.debian.net/debian jessie-backports main > /etc/apt/sources.list.d/jessie-backports.list
    echo deb http://http.debian.net/debian jessie-backports main contrib non-free > /etc/apt/sources.list.d/jessie-backports.list
    echo "Updating Server Packages."
    apt-get -y update
    apt-get -y upgrade
    apt-get -y autoremove
    apt-get -y autoclean
    echo"Installing new kernel"
    apt install -t jessie-backports linux-image-4.9.0-0.bpo.7-amd64
    echo "Modifying Docker."
    sed -i 's,/usr/bin/dockerd,/usr/bin/dockerd --storage-driver=overlay2,g' /lib/systemd/system/docker.service
    systemctl daemon-reload
    service docker start
}

ssl_certs(){
    echo "Installing LetsEncrypt and creating an SSL certificate."
    cd /root
    if  [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        if [ "$lsb_dist" =  "debian" ] && [ "$dist_version" = "8" ]; then
            wget https://dl.eff.org/certbot-auto
            chmod a+x certbot-auto
        else
            apt-get -y install certbot
        fi
    elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        yum -y install certbot
    fi
    if [ "$webserver" = "1" ]; then
        service nginx stop
    elif [ "$webserver" = "2" ]; then
        if  [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
            service apache2 stop
        elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
            service httpd stop
        fi
    fi

    if [ "$lsb_dist" =  "debian" ] && [ "$dist_version" = "8" ]; then
        ./certbot-auto certonly --standalone --email "$email" --agree-tos -d "$FQDN" --non-interactive
    else
        certbot certonly --standalone --email "$email" --agree-tos -d "$FQDN" --non-interactive
    fi
    if [ installoption = "2"]; then
        if  [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
            ufw disable 80
        elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
            firewall-cmd --permanent --remove-port=80/tcp
            firewall-cmd --reload
        fi
    else
        if [ "$webserver" = "1" ]; then
            service nginx restart
        elif [ "$webserver" = "2" ]; then
            if  [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
                service apache2 restart
            elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
                service httpd restart
            fi
        fi
    fi
}

firewall(){
    rm -rf /etc/rc.local
    printf '%s\n' '#!/bin/bash' 'exit 0' | sudo tee -a /etc/rc.local
    chmod +x /etc/rc.local

    iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
    iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP 
    iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    iptables -t mangle -A PREROUTING -p icmp -j DROP
    iptables -A INPUT -p tcp -m connlimit --connlimit-above 80 --connlimit-mask 32 --connlimit-saddr -j REJECT --reject-with tcp-reset
    iptables -t mangle -A PREROUTING -f -j DROP
    /sbin/iptables -N port-scanning 
    /sbin/iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN 
    /sbin/iptables -A port-scanning -j DROP  
    sh -c "iptables-save > /etc/iptables.conf"
    sed -i -e '$i \iptables-restore < /etc/iptables.conf\n' /etc/rc.local

    echo "Setting up Fail2Ban"
    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        apt -y install fail2ban
    elif [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        yum -y install fail2ban
    fi 
    systemctl enable fail2ban
    bash -c 'cat > /etc/fail2ban/jail.local' <<-'EOF'
[DEFAULT]
# Ban hosts for ten hours:
bantime = 36000

# Override /etc/fail2ban/jail.d/00-firewalld.conf:
banaction = iptables-multiport

[sshd]
enabled = true
EOF
    service fail2ban restart

    echo "Configuring your firewall."
    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        apt-get -y install ufw
        ufw allow 22
        if [ "$installoption" = "1" ]; then
            ufw allow 80
            ufw allow 443
            ufw allow 3306
        elif [ "$installoption" = "2" ]; then
            ufw allow 80
            ufw allow 8080
            ufw allow 2022
        elif [ "$installoption" = "3" ]; then
            ufw allow 80
            ufw allow 443
            ufw allow 8080
            ufw allow 2022
            ufw allow 3306
        fi
        yes |ufw enable 
    elif [ "$lsb_dist" =  "centos" ] || [ "$lsb_dist" =  "fedora" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        yum -y install firewalld
        systemctl enable firewalld
        systemctl start firewalld
        if [ "$installoption" = "1" ]; then
            firewall-cmd --add-service=http --permanent
            firewall-cmd --add-service=https --permanent 
            firewall-cmd --add-service=mysql --permanent 
        elif [ "$installoption" = "2" ]; then
            firewall-cmd --permanent --add-port=80/tcp
            firewall-cmd --permanent --add-port=2022/tcp
            firewall-cmd --permanent --add-port=8080/tcp
        elif [ "$installoption" = "3" ]; then
            firewall-cmd --add-service=http --permanent
            firewall-cmd --add-service=https --permanent 
            firewall-cmd --permanent --add-port=2022/tcp
            firewall-cmd --permanent --add-port=8080/tcp
            firewall-cmd --add-service=mysql --permanent 
        fi
        firewall-cmd --reload
    fi
}

mariadb_root_reset(){
    service mariadb stop
    mysqld_safe --skip-grant-tables >res 2>&1 &
    sleep 5
    rootpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q1="UPDATE user SET plugin='';"
    Q2="UPDATE user SET password=PASSWORD('$rootpassword') WHERE user='root';"
    Q3="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}"
    mysql mysql -e "$SQL"
    pkill mysqld
    service mariadb restart
    echo "Your MariaDB root password is $rootpassword"
}

database_host_reset(){
    SERVER_IP=$(curl -s http://checkip.amazonaws.com)
    service mariadb stop
    mysqld_safe --skip-grant-tables >res 2>&1 &
    sleep 5
    adminpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q1="UPDATE user SET plugin='';"
    Q2="UPDATE user SET password=PASSWORD('$adminpassword') WHERE user='admin';"
    Q3="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}"
    mysql mysql -e "$SQL"
    pkill mysqld
    service mariadb restart
    echo "New database host information:"
    echo "Host: $SERVER_IP"
    echo "Port: 3306"
    echo "User: admin"
    echo "Password: $adminpassword"
}

mariadb_external_enable(){
    service mariadb stop
    mysqld_safe --skip-grant-tables >res 2>&1 &
    sleep 5    
    Q1="update user set Host='%' where User='root'"
    SQL="$Q1"
    mysql mysql -e "$SQL"
    pkill mysqld
    service mariadb restart
    echo "External MariaDB root login enabled."
}

mariadb_external_disable(){
    service mariadb stop
    mysqld_safe --skip-grant-tables >res 2>&1 &
    sleep 5    
    Q1="update user set Host='127.0.0.1' where User='root'"
    SQL="$Q1"
    mysql mysql -e "$SQL"
    pkill mysqld
    service mariadb restart
    echo "External MariaDB root login disabled."
}

broadcast(){
    if [ "$installoption" = "1" ] || [ "$installoption" = "3" ]; then
        echo "###############################################################"
        echo "MARIADB 登入資訊"
        echo ""
        echo "您的MARIADB密碼是 $rootpassword"
        echo ""
        echo "使用以下信息創建MariaDB主机:"
        echo "Host: $SERVER_IP"
        echo "Port: 3306"
        echo "User: admin"
        echo "Password: $adminpassword"
        echo "###############################################################"
        echo ""
    fi
    echo "###############################################################"
    echo "FIREWALL INFORMATION"
    echo ""
    echo "All unnecessary ports are blocked by default."
    if [ "$lsb_dist" =  "ubuntu" ] || [ "$lsb_dist" =  "debian" ]; then
        echo "Use 'ufw allow <port>' to enable your desired ports"
    elif [ "$lsb_dist" =  "fedora" ] || [ "$lsb_dist" =  "centos" ] ||  [ "$lsb_dist" =  "rhel" ]; then
        echo "Use 'firewall-cmd --permanent --add-port=<port>/tcp' to enable your desired ports."
        semanage permissive -a httpd_t
        semanage permissive -a redis_t
    fi
    echo "###############################################################"
    echo ""
}

broadcast_daemon(){
    echo "###############################################################"
    echo "DAEMON CONFIGURATION"
    echo ""
    echo "Installation completed. Please configure the daemon. "
    echo "The guide for daemon configuration can be founded here: https://pterodactyl.io/daemon/installing.html#configure-daemon"   
    if [ "$lsb_dist" =  "ubuntu" ] && [ "$dist_version" = "14.04" ]; then
        echo "Please run 'forever start src/index.js' after the configuration process is finished."
    else
        echo "Please run 'service wings restart' after the configuration."  
        if [ "$lsb_dist" =  "debian" ] && [ "$dist_version" = "8" ]; then
            echo "Please restart the server after you have configured the daemon to apply the necessary kernel changes on Debian 8."
        fi
    fi
    echo "###############################################################"
                         
}

#Execution
copyright
get_distribution
check_root
get_architecture
server_options
case $installoption in 
    1)  webserver_options
        theme_options
        repositories_setup
        required_infos
        firewall
        install_dependencies
        install_pterodactyl
        pterodactyl_queue
        ssl_certs
        webserver_config
        theme
        broadcast
        ;;
    2)  get_virtualization
        repositories_setup
        required_infos
        firewall
        ssl_certs
        install_daemon
        broadcast
        broadcast_daemon
        ;;
    3)  get_virtualization
        webserver_options
        theme_options
        repositories_setup
        required_infos
        firewall
        install_dependencies
        install_pterodactyl
        pterodactyl_queue
        ssl_certs
        webserver_config
        theme
        install_daemon
        broadcast
        broadcast_daemon
        ;;
    4)  install_standalone_sftp
        ;;
    5)  theme_options
        upgrade_pterodactyl
        theme
        ;;
    6)  upgrade_daemon
        ;;
    7)  upgrade_standalone_sftp
        ;;
    8)  install_phpmyadmin
        ;;
    9)  theme_options
        if [ "$themeoption" = "1" ]; then
            upgrade_pterodactyl
        fi
        theme
        ;;
    10) mariadb_root_reset
        ;;
    11) database_host_reset
        ;;
    12) mariadb_external_enable
        ;;
    13) mariadb_external_disable
        ;;
esac