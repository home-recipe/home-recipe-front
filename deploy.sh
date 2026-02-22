#!/bin/bash

# --- 설정 (이 부분만 확인하세요) ---
SERVER_IP="49.50.138.180"
REMOTE_USER="root"
TARGET_DIR="/var/www/html"

echo "[1/4] Flutter 빌드 시작 (web/html renderer)..."
flutter build web --web-renderer html --release

echo " [2/4] 서버 기존 파일 삭제 중..."
ssh $REMOTE_USER@$SERVER_IP "sudo rm -rf $TARGET_DIR/*"

echo "[3/4] 빌드 파일 전송 중 (web 폴더 안의 내용물만)..."
# build/web/ 뒤에 '.'을 붙여 폴더 자체가 아닌 내용물만 전송합니다.
scp -r ./build/web/. $REMOTE_USER@$SERVER_IP:$TARGET_DIR/

echo " [4/4] 서버 권한 설정 및 Nginx 재시작..."
ssh $REMOTE_USER@$SERVER_IP << 'EOF'
    # 1. assets/assets로 중복 생성된 경우 해결
    if [ -d "/var/www/html/assets/assets" ]; then
        sudo cp -r /var/www/html/assets/assets/* /var/www/html/assets/
        sudo rm -rf /var/www/html/assets/assets
    fi

    # 2. 권한 부여
    sudo chown -R www-data:www-data /var/www/html
    sudo chmod -R 755 /var/www/html
    
    # 3. Nginx 재시작
    sudo systemctl restart nginx
    echo " 모든 작업이 완료되었습니다! 브라우저에서 확인해보세요."
EOF
