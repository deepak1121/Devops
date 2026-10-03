#!/bin/bash

set -e

SONAR_VERSION="25.12.0.117093"
SONAR_ZIP="sonarqube-${SONAR_VERSION}.zip"
SONAR_DIR="/opt/sonarqube-${SONAR_VERSION}"

echo "Updating packages..."
sudo dnf update -y

echo "Installing required packages..."
sudo dnf install -y java-21-openjdk java-21-openjdk-devel wget unzip

echo "Checking Java version..."
java -version

echo "Downloading SonarQube..."
cd /opt

sudo wget "https://binaries.sonarsource.com/Distribution/sonarqube/${SONAR_ZIP}"

echo "Extracting SonarQube..."
sudo unzip -q "${SONAR_ZIP}"

echo "Creating sonar user..."
if ! id sonar &>/dev/null; then
    sudo useradd -r -s /bin/bash sonar
fi

echo "Setting permissions..."
sudo chown -R sonar:sonar "${SONAR_DIR}"
sudo chmod -R 755 "${SONAR_DIR}"

echo "Creating systemd service..."

sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOF
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking

User=sonar
Group=sonar

ExecStart=${SONAR_DIR}/bin/linux-x86-64/sonar.sh start
ExecStop=${SONAR_DIR}/bin/linux-x86-64/sonar.sh stop

Restart=on-failure
RestartSec=10

LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Enabling SonarQube..."
sudo systemctl enable sonarqube

echo "Starting SonarQube..."
sudo systemctl start sonarqube

echo "Checking SonarQube status..."
sudo systemctl status sonarqube --no-pager

echo ""
echo "======================================"
echo "SonarQube installation completed!"
echo "======================================"
echo "Java version:"
java -version
echo ""
echo "SonarQube service:"
echo "sudo systemctl status sonarqube"
echo ""
echo "SonarQube logs:"
echo "sudo tail -f ${SONAR_DIR}/logs/sonar.log"
echo ""
echo "Access SonarQube at:"
echo "http://<EC2-PUBLIC-IP>:9000"
echo ""
echo "Default credentials:"
echo "Username: admin"
echo "Password: admin"
