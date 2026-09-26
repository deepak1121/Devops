#!/bin/bash

# STEP 1: Install Git, Maven and wget
dnf install git maven wget -y

# STEP 2: Add Jenkins repository
wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# STEP 3: Check Java 21
java -version

# STEP 4: Install Jenkins
dnf clean all
dnf makecache
dnf install jenkins -y

# STEP 5: Start Jenkins
systemctl daemon-reload
systemctl start jenkins

# STEP 6: Enable Jenkins on boot
systemctl enable jenkins

# STEP 7: Check Jenkins status
systemctl status jenkins
