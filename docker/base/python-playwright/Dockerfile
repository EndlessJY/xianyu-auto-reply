# Shared Python + Playwright base for backend-web, websocket, and scheduler.
# Rebuild this image only when Python dependencies or browser/system deps change.

FROM python:3.11-slim

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

WORKDIR /app

RUN apt-get update && apt-get install -y curl ca-certificates gcc \
    fonts-dejavu-core fonts-liberation \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY backend-web/pyproject.toml /tmp/pyprojects/backend-web.toml
COPY websocket/pyproject.toml /tmp/pyprojects/websocket.toml
COPY scheduler/pyproject.toml /tmp/pyprojects/scheduler.toml

RUN python - <<'PY' && pip install --no-cache-dir -r /tmp/requirements.txt
import pathlib
import tomllib

deps = []
seen = set()
for pyproject in sorted(pathlib.Path("/tmp/pyprojects").glob("*.toml")):
    data = tomllib.load(pyproject.open("rb"))
    for dep in data.get("project", {}).get("dependencies", []):
        if dep not in seen:
            deps.append(dep)
            seen.add(dep)

pathlib.Path("/tmp/requirements.txt").write_text("\n".join(deps), encoding="utf-8")
PY

RUN python -m playwright install --with-deps chromium

ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV TZ=Asia/Shanghai
