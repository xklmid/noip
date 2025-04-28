#!/bin/bash
# No-IP DUC v3.3.0 一键安装脚本

echo "============================="
echo " No-IP DDNS Linux安装脚本 (v3.3.0)"
echo "============================="
sleep 1

# 安装必要工具
echo "[1/5] 安装编译工具..."
if [ -x "$(command -v apt)" ]; then
    sudo apt update && sudo apt install -y build-essential wget
elif [ -x "$(command -v yum)" ]; then
    sudo yum update -y && sudo yum groupinstall "Development Tools" -y && sudo yum install -y wget
else
    echo "不支持的Linux发行版，请手动安装gcc、make、wget后重试。"
    exit 1
fi

# 下载并编译No-IP客户端
echo "[2/5] 下载并安装No-IP客户端..."
cd /usr/local/src
sudo wget https://www.noip.com/client/linux/noip-3.3.0.tar.gz -O noip-3.3.0.tar.gz
sudo tar xf noip-3.3.0.tar.gz
cd noip-3.3.0
sudo make
sudo make install

# 创建Systemd服务
echo "[3/5] 创建Systemd服务..."
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

# 启动服务
echo "[4/5] 启动并设置开机自启..."
sudo systemctl daemon-reload
sudo systemctl enable noip2
sudo systemctl start noip2

# 完成提示
echo "[5/5] 安装完成！"
sudo systemctl status noip2
echo ""
echo "============================="
echo " No-IP v3.3.0 已成功安装并启动！"
echo "============================="
first commit
