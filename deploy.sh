#!/bin/bash

# 红腾电气电缆计算器 - 自动化部署脚本
# 适用于Ubuntu 20.04/22.04

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以root身份运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "请以root身份运行此脚本"
        print_info "使用命令: sudo bash deploy.sh"
        exit 1
    fi
}

# 检查系统版本
check_system() {
    print_info "检查系统版本..."
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        print_info "检测到系统: $PRETTY_NAME"
        
        if [[ "$ID" == "ubuntu" ]]; then
            if [[ "$VERSION_ID" == "20.04" || "$VERSION_ID" == "22.04" ]]; then
                print_success "系统版本支持"
                return 0
            else
                print_warning "Ubuntu版本可能不完全兼容，建议使用20.04或22.04"
            fi
        elif [[ "$ID" == "centos" ]]; then
            print_warning "检测到CentOS，部分配置可能需要调整"
        else
            print_warning "检测到其他Linux发行版，请手动检查兼容性"
        fi
    else
        print_error "无法检测系统版本"
        exit 1
    fi
}

# 更新系统
update_system() {
    print_info "更新系统软件包..."
    
    if [[ "$ID" == "ubuntu" ]]; then
        apt update -y
        apt upgrade -y
        apt install -y curl wget unzip snapd
    elif [[ "$ID" == "centos" ]]; then
        yum update -y
        yum install -y curl wget unzip epel-release
    fi
    
    print_success "系统更新完成"
}

# 安装Nginx
install_nginx() {
    print_info "安装Nginx Web服务器..."
    
    if [[ "$ID" == "ubuntu" ]]; then
        apt install -y nginx
    elif [[ "$ID" == "centos" ]]; then
        yum install -y nginx
    fi
    
    systemctl start nginx
    systemctl enable nginx
    
    print_success "Nginx安装完成"
}

# 配置防火墙
setup_firewall() {
    print_info "配置防火墙..."
    
    if [[ "$ID" == "ubuntu" ]]; then
        if command -v ufw &> /dev/null; then
            ufw --force enable
            ufw allow ssh
            ufw allow 'Nginx Full'
            print_success "Ubuntu防火墙配置完成"
        else
            print_warning "UFW未安装，跳过防火墙配置"
        fi
    elif [[ "$ID" == "centos" ]]; then
        if command -v firewall-cmd &> /dev/null; then
            systemctl start firewalld
            systemctl enable firewalld
            firewall-cmd --permanent --add-service=http
            firewall-cmd --permanent --add-service=https
            firewall-cmd --permanent --add-service=ssh
            firewall-cmd --reload
            print_success "CentOS防火墙配置完成"
        else
            print_warning "firewalld未安装，跳过防火墙配置"
        fi
    fi
}

# 获取用户输入
get_user_input() {
    echo
    print_info "请输入以下配置信息："
    
    read -p "请输入域名 (例如: example.com): " DOMAIN
    read -p "请输入您的邮箱地址: " EMAIL
    
    if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
        print_error "域名和邮箱不能为空"
        exit 1
    fi
    
    print_success "配置信息已记录"
    print_info "域名: $DOMAIN"
    print_info "邮箱: $EMAIL"
}

# 创建应用目录
setup_app_directory() {
    print_info "创建应用目录..."
    
    APP_DIR="/var/www/cable-calculator"
    
    # 检查目录是否存在
    if [[ -d "$APP_DIR" ]]; then
        print_warning "应用目录已存在，是否覆盖？(y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_info "跳过目录创建"
            return 0
        else
            rm -rf "$APP_DIR"
        fi
    fi
    
    mkdir -p "$APP_DIR"
    chown www-data:www-data "$APP_DIR" 2>/dev/null || chown nginx:nginx "$APP_DIR"
    chmod 755 "$APP_DIR"
    
    print_success "应用目录创建完成: $APP_DIR"
}

# 检查必要文件
check_app_files() {
    print_info "检查应用文件..."
    
    REQUIRED_FILES=(
        "index.html"
        "manifest.json"
        "sw.js"
        "styles/main.css"
        "scripts/app.js"
    )
    
    MISSING_FILES=()
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [[ ! -f "$file" ]]; then
            MISSING_FILES+=("$file")
        fi
    done
    
    if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
        print_error "缺少以下必要文件："
        for file in "${MISSING_FILES[@]}"; do
            echo "  - $file"
        done
        print_info "请确保在cable_calculator_app目录中运行此脚本"
        exit 1
    fi
    
    print_success "所有必要文件检查通过"
}

# 复制应用文件
copy_app_files() {
    print_info "复制应用文件..."
    
    APP_DIR="/var/www/cable-calculator"
    
    # 复制文件到应用目录
    cp -r . "$APP_DIR/"
    
    # 设置正确的权限
    chown -R www-data:www-data "$APP_DIR" 2>/dev/null || chown -R nginx:nginx "$APP_DIR"
    find "$APP_DIR" -type f -exec chmod 644 {} \;
    find "$APP_DIR" -type d -exec chmod 755 {} \;
    chmod +x "$APP_DIR/sw.js" 2>/dev/null || true
    
    print_success "应用文件复制完成"
}

# 配置Nginx
configure_nginx() {
    print_info "配置Nginx站点..."
    
    DOMAIN=$1
    APP_DIR="/var/www/cable-calculator"
    
    # 创建Nginx配置
    cat > /etc/nginx/sites-available/cable-calculator << EOF
server {
    listen 80;
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    root $APP_DIR;
    index index.html;

    # SSL配置将由certbot自动添加
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # 安全头
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";
    
    # Service Worker配置
    location /sw.js {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Service-Worker-Allowed "/";
        expires off;
    }
    
    # Manifest文件
    location /manifest.json {
        add_header Content-Type "application/manifest+json";
        add_header Cache-Control "public, max-age=31536000";
    }
    
    # 图标文件缓存
    location /icons/ {
        add_header Cache-Control "public, max-age=31536000";
    }
    
    # CSS/JS文件缓存
    location ~* \.(css|js)$ {
        add_header Cache-Control "public, max-age=31536000";
    }
    
    # 主页面配置
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Gzip压缩
    gzip on;
    gzip_types text/plain text/css application/javascript application/json;
    
    # 隐藏Nginx版本
    server_tokens off;
}
EOF

    # 启用站点
    if [[ -f /etc/nginx/sites-enabled/default ]]; then
        rm /etc/nginx/sites-enabled/default
    fi
    
    ln -sf /etc/nginx/sites-available/cable-calculator /etc/nginx/sites-enabled/
    
    # 测试配置
    if nginx -t; then
        systemctl reload nginx
        print_success "Nginx配置完成"
    else
        print_error "Nginx配置有误"
        exit 1
    fi
}

# 安装SSL证书
install_ssl() {
    print_info "安装SSL证书..."
    
    DOMAIN=$1
    EMAIL=$2
    
    # 检查域名是否解析到服务器IP
    SERVER_IP=$(curl -s ifconfig.me)
    DOMAIN_IP=$(dig +short $DOMAIN)
    
    if [[ "$SERVER_IP" != "$DOMAIN_IP" ]]; then
        print_warning "域名解析可能未指向当前服务器"
        print_info "当前服务器IP: $SERVER_IP"
        print_info "域名解析IP: $DOMAIN_IP"
        read -p "是否继续？(y/N): " continue_ssl
        if [[ ! "$continue_ssl" =~ ^[Yy]$ ]]; then
            print_info "SSL安装已跳过"
            return 1
        fi
    fi
    
    # 安装certbot
    if [[ "$ID" == "ubuntu" ]]; then
        if ! command -v certbot &> /dev/null; then
            snap install core; snap refresh core
            snap install --classic certbot
            ln -sf /snap/bin/certbot /usr/bin/certbot
        fi
    elif [[ "$ID" == "centos" ]]; then
        if ! command -v certbot &> /dev/null; then
            yum install -y certbot python3-certbot-nginx
        fi
    fi
    
    # 获取SSL证书
    print_info "正在获取SSL证书..."
    if certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive; then
        print_success "SSL证书安装完成"
        
        # 设置自动续期
        (crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/certbot renew --quiet") | crontab -
        print_success "自动续期任务已设置"
    else
        print_error "SSL证书安装失败"
        return 1
    fi
}

# 测试部署
test_deployment() {
    print_info "测试部署结果..."
    
    DOMAIN=$1
    
    # 测试HTTP连接
    if curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN | grep -q "200"; then
        print_success "HTTP连接测试通过"
    else
        print_warning "HTTP连接测试失败"
    fi
    
    # 测试HTTPS连接
    if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN | grep -q "200"; then
        print_success "HTTPS连接测试通过"
    else
        print_warning "HTTPS连接测试失败"
    fi
    
    # 检查关键文件
    if curl -s https://$DOMAIN/manifest.json | grep -q "name"; then
        print_success "PWA Manifest文件可访问"
    else
        print_warning "PWA Manifest文件可能有问题"
    fi
}

# 显示部署结果
show_result() {
    DOMAIN=$1
    
    echo
    print_success "========== 部署完成！=========="
    echo
    print_info "应用访问地址:"
    echo "  http://$DOMAIN"
    echo "  https://$DOMAIN"
    echo
    print_info "鸿蒙设备安装步骤:"
    echo "  1. 在鸿蒙浏览器中访问: https://$DOMAIN"
    echo "  2. 点击地址栏的'添加'按钮"
    echo "  3. 选择'添加到主屏幕'"
    echo "  4. 确认安装到桌面"
    echo
    print_info "测试命令:"
    echo "  # 检查SSL证书状态"
    echo "  sudo certbot certificates"
    echo
    echo "  # 查看Nginx状态"
    echo "  sudo systemctl status nginx"
    echo
    echo "  # 查看错误日志"
    echo "  sudo tail -f /var/log/nginx/error.log"
    echo
    print_warning "请确保域名DNS已正确解析到服务器IP"
    print_warning "SSL证书将在90天后自动续期"
}

# 主函数
main() {
    clear
    echo "============================================"
    echo "  红腾电气电缆计算器 - 自动部署脚本"
    echo "============================================"
    echo
    
    # 检查权限
    check_root
    
    # 检查系统
    check_system
    
    # 更新系统
    update_system
    
    # 安装Nginx
    install_nginx
    
    # 配置防火墙
    setup_firewall
    
    # 获取用户输入
    get_user_input
    
    # 创建应用目录
    setup_app_directory
    
    # 检查必要文件
    check_app_files
    
    # 复制应用文件
    copy_app_files
    
    # 配置Nginx
    configure_nginx $DOMAIN
    
    # 安装SSL证书
    print_info "是否现在安装SSL证书？(推荐)"
    print_info "注意: 域名必须已解析到服务器IP"
    read -p "是否继续安装SSL证书？(Y/n): " install_ssl_choice
    if [[ ! "$install_ssl_choice" =~ ^[Nn]$ ]]; then
        install_ssl $DOMAIN $EMAIL
    else
        print_info "SSL证书安装已跳过"
        print_info "如需安装SSL证书，请运行:"
        print_info "sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive"
    fi
    
    # 测试部署
    test_deployment $DOMAIN
    
    # 显示结果
    show_result $DOMAIN
    
    echo
    print_success "部署脚本执行完成！"
}

# 错误处理
trap 'print_error "脚本执行中断"; exit 1' ERR

# 运行主函数
main "$@"