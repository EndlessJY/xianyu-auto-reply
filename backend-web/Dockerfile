# Backend-Web 服务 Dockerfile
# 依赖和 Playwright 浏览器由共享基础镜像提供，业务镜像只复制源码。

ARG PYTHON_BASE_IMAGE=ghcr.io/endlessjy/xianyu-auto-reply-python-base:latest
FROM ${PYTHON_BASE_IMAGE}

WORKDIR /app

# 复制项目源码
COPY common /app/common
COPY backend-web /app/backend-web
COPY launcher /app/launcher

# 创建日志目录
RUN mkdir -p /app/backend-web/logs /app/static/uploads

# 暴露端口
EXPOSE 8089

# 启动服务
CMD ["python", "backend-web/main.py"]
