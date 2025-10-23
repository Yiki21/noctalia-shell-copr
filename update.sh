#!/usr/bin/env bash
set -euo pipefail

REPO="noctalia-dev/noctalia-shell"
SPEC=".copr/noctalia-shell.spec"
WORKDIR="$(dirname "$(realpath "$0")")"

cd "$WORKDIR"

# 获取最新 tag (去掉 v 前缀)
VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r .tag_name | sed 's/^v//')

if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
    echo "❌ 无法获取版本号"
    exit 1
fi

echo "📦 最新版本: $VERSION"

# 如果 spec 文件已经是最新，就退出
if grep -q "Version:[[:space:]]*${VERSION}" "$SPEC"; then
    echo "✅ 已是最新版本 $VERSION"
    exit 0
fi

# 下载源码 tarball
TARBALL="${WORKDIR}/noctalia-shell-${VERSION}.tar.gz"
wget -q "https://github.com/${REPO}/archive/refs/tags/v${VERSION}.tar.gz" -O "$TARBALL"

# 更新 spec 文件中的 Version 和 Source
sed -i "s/^Version:.*/Version:        ${VERSION}/" "$SPEC"
sed -i "s|^Source0:.*|Source0:        noctalia-shell-${VERSION}.tar.gz|" "$SPEC"

# 提交更改
git add "$SPEC" "$TARBALL"
git commit -m "Update to version ${VERSION}" || true
git push

# 如果定义了 COPR_WEBHOOK，就调用
if [[ -n "${COPR_WEBHOOK:-}" ]]; then
    echo "🚀 触发 Copr webhook..."
    curl -fsSL -X POST "$COPR_WEBHOOK" || echo "⚠️ Copr webhook 触发失败"
fi

echo "✅ 更新完成"
