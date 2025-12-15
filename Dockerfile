FROM arm64v8/ubuntu:24.04

# 定义 AzurLaneAutoScript 目录
WORKDIR /app/AzurLaneAutoScript

# 设置环境变量，避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
# Add conda to PATH
ENV PATH="/opt/conda/bin:${PATH}"

# 复制文件
COPY --link *.sh /
COPY --link docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /*.sh /usr/local/bin/docker-entrypoint.sh
# 部署ALAS运行环境 
RUN /bin/bash -c /init_env.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash", "-c", "/start_alas.sh"]