#!/bin/bash

# 更新软件并安装基础工具
echo -e "\n ========== Installing Foundational Software ========== \n"
apt-get update
apt-get install -y --no-install-recommends \
	software-properties-common build-essential \
	curl git adb libgomp1 \
	openssh-client

# 添加 deadsnakes PPA 来安装 Python 3.7
echo -e "\n ========== Installing Python 3.7 ========== \n"
add-apt-repository -y ppa:deadsnakes/ppa

# 安装 Python 3.7
apt-get install -y --no-install-recommends python3.7 python3.7-dev python3.7-distutils
# 安装pip
curl -fL -sS https://bootstrap.pypa.io/pip/3.7/get-pip.py -o /tmp/get-pip.py
python3.7 /tmp/get-pip.py
rm /tmp/get-pip.py

# 创建 Python 3.7 的符号链接
update-alternatives --install /usr/local/bin/python3 python3 /usr/bin/python3.7 1
update-alternatives --install /usr/local/bin/python python /usr/bin/python3.7 1

# 安装 PyAV 依赖参考 https://github.com/LmeSzinc/AzurLaneAutoScript/issues/5322
# Install Miniconda (Miniconda3-py313_25.9.1-3)
echo -e "\n ========== Downloading Miniconda3 ========== \n"
curl -fL --retry 5 --retry-delay 1 \
	-sS -o /tmp/miniconda.sh \
	https://repo.anaconda.com/miniconda/Miniconda3-py313_25.9.1-3-Linux-aarch64.sh 
echo -e "\n ========== Installing Miniconda3 ========== \n"
bash /tmp/miniconda.sh -b -p /opt/conda
rm /tmp/miniconda.sh

# Remove only defaults channel
# Add the conda-forge channel
# Set the priority as strict (make sure it only pull from conda-forge channel)
echo -e "\n ========== Installing mamba ========== \n"
conda config --system --remove channels defaults
conda config --system --add channels conda-forge
conda config --system --set channel_priority strict

conda install -y mamba

# 下载 AzurLaneAutoScript 依赖
curl -fL --retry 5 --retry-delay 1 \
  -sS -o /tmp/requirements.txt \
  "https://github.com/LmeSzinc/AzurLaneAutoScript/raw/refs/heads/master/deploy/docker/requirements.txt"

sed -i 's/^numpy.*$/numpy==1.19.5/' /tmp/requirements.txt
sed -i 's/^scipy.*$/scipy==1.7.3/' /tmp/requirements.txt

# 安装 AzurLaneAutoScript 依赖
# Install PyAV according to requirements.txt
AV_VERSION=$(grep -E '^av==' /tmp/requirements.txt | cut -d '=' -f 3)
echo -e "\n ========== Installing av == $AV_VERSION ========== \n"
mamba install -y "python=3.7" "av==$AV_VERSION"
conda clean --all --yes

# Install other pip dependencies (skip av)
echo -e "\n ========== Installing other pip dependencies (skip av) ========== \n"
grep -v '^av==' /tmp/requirements.txt > /tmp/requirements_no_av.txt
pip install --no-cache-dir -r /tmp/requirements_no_av.txt 
rm /tmp/requirements.txt /tmp/requirements_no_av.txt

# Apt-Get 清理
echo -e "\n ========== Clean up ========== \n"
apt-get -y remove python3.7-dev python3.7-distutils build-essential software-properties-common
apt-get autoremove -y
apt-get clean
pip cache purge
rm -rf /var/lib/apt/lists/
rm -rf ~/.cache/pip
rm -rf ~/.cache/meson/