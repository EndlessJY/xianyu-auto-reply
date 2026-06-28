# Scheduler 服务 Dockerfile
# 依赖和 Playwright 浏览器由共享基础镜像提供，业务镜像只复制源码。

ARG PYTHON_BASE_IMAGE=ghcr.io/endlessjy/xianyu-auto-reply-python-base:latest
FROM ${PYTHON_BASE_IMAGE}

WORKDIR /app

# 复制项目源码
COPY common /app/common
COPY scheduler /app/scheduler
COPY launcher /app/launcher

# 创建日志目录
RUN mkdir -p /app/scheduler/logs

# 暴露端口
EXPOSE 8091

# 启动服务
CMD ["python", "scheduler/main.py"]
