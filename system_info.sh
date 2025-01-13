#!/bin/bash

# 颜色变量
PURPLE='\033[1;35m'
NC='\033[0m' # 重置颜色

# 安装函数
install() {
    mkdir -p ~/.local

    # 安装依赖工具
    sudo apt install bc net-tools curl -y

    # 备份并清空 /etc/motd
    if [[ -f /etc/motd ]]; then
        sudo cp /etc/motd /etc/motd.bak
        sudo truncate -s 0 /etc/motd
    fi

    # 生成 sysinfo.sh 脚本
    cat << EOF > ~/.local/sysinfo.sh
#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
ORANGE='\033[1;33m'
NC='\033[0m'

# 进度条函数
progress_bar() {
    local progress=\$1
    local total=\$2
    local bar_width=20
    local filled=\$(echo "(\$progress/\$total)*\$bar_width" | bc -l | awk '{printf "%d", \$1}')
    local empty=\$((bar_width - filled))

    printf "["
    for ((i=0; i<filled; i++)); do printf "\${PURPLE}=\${NC}"; done
    for ((i=0; i<empty; i++)); do printf "\${GREEN}=\${NC}"; done
    printf "]"
}

# 获取系统信息
os_info=\$(cat /etc/os-release 2>/dev/null | grep '^PRETTY_NAME=' | sed 's/PRETTY_NAME="//g' | sed 's/"//g')
uptime_info=\$(uptime -p 2>/dev/null | sed 's/up //g')
cpu_info=\$(lscpu 2>/dev/null | grep -m 1 "Model name:" | sed 's/Model name:[ \t]*//g' | xargs)
cpu_cores=\$(lscpu 2>/dev/null | grep "^CPU(s):" | awk '{print \$2}')
cpu_speed=\$(lscpu 2>/dev/null | grep "CPU MHz" | awk '{print \$3/1000 "GHz"}' | xargs)
memory_total=\$(free -m 2>/dev/null | grep Mem: | awk '{print \$2}')
memory_used=\$(free -m 2>/dev/null | grep Mem: | awk '{print \$3}')
swap_total=\$(free -m 2>/dev/null | grep Swap: | awk '{print \$2}')
swap_used=\$(free -m 2>/dev/null | grep Swap: | awk '{print \$3}')
disk_total=\$(df -k / 2>/dev/null | grep / | awk '{print \$2}')
disk_used=\$(df -k / 2>/dev/null | grep / | awk '{print \$3}')

# 显示系统信息
echo -e "\${ORANGE}OS:\${NC}        \${os_info:-N/A}"
echo -e "\${ORANGE}Uptime:\${NC}    \${uptime_info:-N/A}"
echo -e "\${ORANGE}CPU:\${NC}       \${cpu_info:-N/A} @\${cpu_speed:-N/A} (\${cpu_cores:-N/A} cores)"
echo -ne "\${ORANGE}Memory:\${NC}    "
progress_bar \$memory_used \$memory_total
echo " \${memory_used:-N/A}MB / \${memory_total:-N/A}MB (\$(awk "BEGIN {printf \"%.0f%%\", (\$memory_used/\$memory_total)*100}"))"
echo -e "\${ORANGE}Swap:\${NC}      \${swap_used:-N/A}MB / \${swap_total:-N/A}MB (\$(awk "BEGIN {printf \"%.0f%%\", (\$swap_used/\$swap_total)*100}"))"
echo -ne "\${ORANGE}Disk:\${NC}      "
progress_bar \$disk_used \$disk_total
echo " \$(df -h / 2>/dev/null | grep / | awk '{print \$3 " / " \$2 " (" \$5 ")"}')"

# 获取公网 IP 信息
get_public_ip() {
    ipv4=\$(curl -s --max-time 3 ipv4.icanhazip.com 2>/dev/null)
    ipv6=\$(curl -s --max-time 3 ipv6.icanhazip.com 2>/dev/null)

    if [[ -n "\$ipv4" ]]; then
        echo -e "\${GREEN}IPv4:\${NC} \$ipv4"
    fi
    if [[ -n "\$ipv6" ]]; then
        echo -e "\${GREEN}IPv6:\${NC} \$ipv6"
    fi
    if [[ -z "\$ipv4" && -z "\$ipv6" ]]; then
        echo -e "\${RED}No Public IP\${NC}"
    fi
}

get_public_ip
sleep 0.05
echo -ne "\n"
EOF

    chmod +x ~/.local/sysinfo.sh

    # 将 sysinfo.sh 添加到 .bashrc
    if ! grep -q 'if [[ $- == *i* && -n "$SSH_CONNECTION" ]]; then' ~/.bashrc; then
        echo '# SYSINFO SSH LOGIC START' >> ~/.bashrc
        echo 'if [[ $- == *i* && -n "$SSH_CONNECTION" ]]; then' >> ~/.bashrc
        echo '    bash ~/.local/sysinfo.sh' >> ~/.bashrc
        echo 'fi' >> ~/.bashrc
        echo '# SYSINFO SSH LOGIC END' >> ~/.bashrc
    fi

    source ~/.bashrc >/dev/null 2>&1
    echo -e "\033[32m系统信息工具安装完成！\033[0m"
}

# 卸载函数
uninstall() {
    rm -f ~/.local/sysinfo.sh
    rm -f ~/.local/ip_cache.txt

    # 清理 .bashrc 中的逻辑
    sed -i '/# SYSINFO SSH LOGIC START/,/# SYSINFO SSH LOGIC END/d' ~/.bashrc

    # 恢复 /etc/motd
    if [[ -f /etc/motd.bak ]]; then
        sudo mv /etc/motd.bak /etc/motd
    else
        sudo truncate -s 0 /etc/motd
    fi

    echo -e "\033[32m系统信息工具已卸载！\033[0m"
}

# 交互式菜单
echo -e "${PURPLE}=========================${NC}"
echo -e "${PURPLE}请选择操作：${NC}"
echo -e "${PURPLE}1. 安装 SSH 欢迎系统信息${NC}"
echo -e "${PURPLE}2. 卸载脚本及系统信息${NC}"
echo -e "${PURPLE}=========================${NC}"
read -p "请输入选项 (1 或 2): " choice

case $choice in
    1)
        install
        ;;
    2)
        uninstall
        ;;
    *)
        echo -e "${PURPLE}无效选项，退出脚本。${NC}"
        exit 1
        ;;
esac
