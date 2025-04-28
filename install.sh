#!/bin/bash
# No-IP DDNS 终极增强版 全自动部署脚本

set -e

echo "======================================="
echo " No-IP DDNS客户端 v3.3.0 终极增强版安装"
echo " 作者: ChatGPT定制版"
echo "======================================="
sleep 1

# 检查是否已有运行
if pgrep -x "noip2" >/dev/null 2>&1; then
    echo "检测到 noip2 已运行，是否重新安装？(y/n)"
    read -r answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
        echo "退出安装。"
        exit 0
    fi
fi

# 安装必要依赖
echo "[1/6] 安装编译工具..."
if [ -x "$(command -v apt)" ]; then
    sudo apt update -y && sudo apt install -y build-essential wget cron
elif [ -x "$(command -v yum)" ]; then
    sudo yum update -y && sudo yum groupinstall "Development Tools" -y && sudo yum install -y wget cronie
else
    echo "错误：不支持的Linux发行版。"
    exit 1
fi

# 启动cron服务（防止未启用）
sudo systemctl enable --now cron || sudo systemctl enable --now crond

# 下载并安装 No-IP 客户端
echo "[2/6] 下载并安装 No-IP v3.3.0..."
cd /usr/local/src || exit 1

if [ ! -f "noip-3.3.0.tar.gz" ]; then
    sudo wget https://www.noip.com/client/linux/noip-3.3.0.tar.gz -O noip-3.3.0.tar.gz
fi

sudo rm -rf noip-3.3.0
sudo tar xf noip-3.3.0.tar.gz
cd noip-3.3.0 || exit 1
sudo make
sudo make install

echo "[3/6] 安装成功，接下来请按照提示输入No-IP账号密码..."
sleep 2

# 配置Systemd服务
echo "[4/6] 配置Systemd服务..."
sudo bash -c 'cat > /etc/systemd/system/noip2.service <<EOF
[Unit]
Description=No-IP Dynamic DNS Update Client
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/noip2
ExecStop=/usr/local/bin/noip2 -K
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable noip2
sudo systemctl restart noip2

# 配置强制刷新脚本
echo "[5/6] 配置定时刷新脚本..."
sudo bash -c 'cat > /usr/local/bin/noip-force-update.sh <<EOF
#!/bin/bash
if ! pgrep -x "noip2" >/dev/null 2>&1; then
    echo "\$(date) No-IP未运行，启动..." >> /var/log/noip-refresh.log
    /usr/local/bin/noip2
else
    echo "\$(date) No-IP运行中，发送刷新请求..." >> /var/log/noip-refresh.log
    killall -HUP noip2
fi
EOF'

sudo chmod +x /usr/local/bin/noip-force-update.sh

# 添加cron任务，每5分钟执行一次
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/noip-force-update.sh") | crontab -

# 配置开机自检脚本
echo "[6/6] 配置开机自检服务..."
sudo bash -c 'cat > /usr/local/bin/noip-check-start.sh <<EOF
#!/bin/bash
if ! pgrep -x "noip2" >/dev/null 2>&1; then
    echo "\$(date) No-IP未运行，尝试启动..." >> /var/log/noip-check.log
    /usr/local/bin/noip2
else
    echo "\$(date) No-IP运行正常。" >> /var/log/noip-check.log
fi
EOF'

sudo chmod +x /usr/local/bin/noip-check-start.sh

sudo bash -c 'cat > /etc/systemd/system/noip-check.service <<EOF
[Unit]
Description=No-IP开机自检服务
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/noip-check-start.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl daemon-reload
sudo systemctl enable noip-check.service

# 安装完毕
echo ""
echo "======================================="
echo " No-IP DDNS客户端安装完成！"
echo "======================================="
echo ""
echo " 常用指令："
echo " 查看运行状态: sudo systemctl status noip2"
echo " 重启服务:     sudo systemctl restart noip2"
echo " 手动刷新IP:   sudo /usr/local/bin/noip-force-update.sh"
echo " 查看日志:     sudo tail -f /var/log/noip-refresh.log"
echo " 检查开机脚本: sudo systemctl status noip-check"
echo ""
echo "======================================="
first commit
