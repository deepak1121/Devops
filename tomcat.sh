
#!/bin/bash
set -e

# STEP 1: Install Java 21 and wget
dnf install -y java-21-openjdk-headless wget

# STEP 2: Set Tomcat version
TOMCAT_VERSION="11.0.26"
TOMCAT_DIR="/opt/apache-tomcat-${TOMCAT_VERSION}"
TOMCAT_ARCHIVE="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-11/v${TOMCAT_VERSION}/bin/${TOMCAT_ARCHIVE}"

# STEP 3: Create a dedicated Tomcat user
if ! id tomcat >/dev/null 2>&1; then
    useradd --system --home-dir /opt/tomcat \
      --shell /sbin/nologin tomcat
fi

# STEP 4: Download Tomcat
cd /tmp
wget -O "$TOMCAT_ARCHIVE" "$TOMCAT_URL"

# STEP 5: Extract Tomcat
tar -xzf "$TOMCAT_ARCHIVE" -C /opt

# Create convenient symlink
ln -sfn "$TOMCAT_DIR" /opt/tomcat

# STEP 6: Configure Tomcat Manager user
# Replace CHANGE_THIS_WITH_A_STRONG_PASSWORD
# before running this script.

sed -i '/<\/tomcat-users>/i\
  <role rolename="manager-gui"/>\
  <role rolename="manager-script"/>\
  <user username="tomcat" password="root" roles="manager-gui,manager-script"/>' \
  "$TOMCAT_DIR/conf/tomcat-users.xml"

# STEP 7: Change Tomcat port to 8081
# Jenkins is already using port 8080.
sed -i 's/port="8080"/port="8081"/' \
  "$TOMCAT_DIR/conf/server.xml"

# STEP 8: Set permissions
chown -R tomcat:tomcat "$TOMCAT_DIR"
chmod +x "$TOMCAT_DIR/bin/"*.sh

# STEP 9: Create systemd service
cat > /etc/systemd/system/tomcat.service <<'EOF'
[Unit]
Description=Apache Tomcat Server
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/jre-21"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# STEP 10: Start Tomcat
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

# STEP 11: Check status
systemctl status tomcat --no-pager
