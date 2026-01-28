#!/bin/bash

# EyeBreather 构建脚本
# 用于构建、签名和打包 macOS 应用

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="EyeBreather"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
DIST_DIR="${PROJECT_DIR}/dist"
APP_NAME="${PROJECT_NAME}.app"
SIGNING_IDENTITY="EyeBreather Self-Signed"

# 从项目中读取版本号
VERSION=$(grep 'MARKETING_VERSION' "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj/project.pbxproj" | head -1 | sed 's/.*= \(.*\);/\1/' | tr -d ' ')
if [ -z "$VERSION" ] || [[ "$VERSION" == *"."* ]] && [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+ ]]; then
    VERSION="1.0"
fi

DMG_NAME="${PROJECT_NAME}-${VERSION}.dmg"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  EyeBreather 构建脚本 v${VERSION}${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# 检查依赖
check_dependencies() {
    echo -e "${YELLOW}[1/5] 检查依赖...${NC}"
    
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}错误: 未找到 xcodebuild，请安装 Xcode${NC}"
        exit 1
    fi
    
    if ! command -v create-dmg &> /dev/null; then
        echo -e "${RED}错误: 未找到 create-dmg${NC}"
        echo -e "${YELLOW}请运行: brew install create-dmg${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 依赖检查通过${NC}"
}

# 清理旧构建
clean_build() {
    echo -e "${YELLOW}[2/5] 清理旧构建...${NC}"
    
    rm -rf "${BUILD_DIR}"
    rm -rf "${DIST_DIR}"
    mkdir -p "${DIST_DIR}"
    
    echo -e "${GREEN}✓ 清理完成${NC}"
}

# 构建应用
build_app() {
    echo -e "${YELLOW}[3/5] 构建 Release 版本...${NC}"
    
    cd "${PROJECT_DIR}"
    
    xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${PROJECT_NAME}" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        clean build | while read line; do
            # 只显示关键信息
            if [[ "$line" == *"error:"* ]] || [[ "$line" == *"warning:"* ]] || [[ "$line" == *"BUILD"* ]]; then
                echo "$line"
            fi
        done
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo -e "${RED}错误: 构建失败${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 构建完成${NC}"
}

# 签名应用
sign_app() {
    echo -e "${YELLOW}[4/5] 签名应用...${NC}"
    
    APP_PATH="${BUILD_DIR}/Build/Products/Release/${APP_NAME}"
    
    if [ ! -d "${APP_PATH}" ]; then
        echo -e "${RED}错误: 未找到构建产物 ${APP_PATH}${NC}"
        exit 1
    fi
    
    # 检查证书是否存在
    if security find-identity -v -p codesigning | grep -q "${SIGNING_IDENTITY}"; then
        echo "使用证书: ${SIGNING_IDENTITY}"
        codesign --force --deep --sign "${SIGNING_IDENTITY}" "${APP_PATH}"
        echo -e "${GREEN}✓ 签名完成${NC}"
    else
        echo -e "${YELLOW}⚠ 未找到自签名证书 '${SIGNING_IDENTITY}'${NC}"
        echo -e "${YELLOW}  应用将不进行签名，用户首次打开需手动允许${NC}"
        echo -e "${YELLOW}  创建证书: 钥匙串访问 → 证书助理 → 创建证书${NC}"
    fi
    
    # 验证签名
    echo "验证签名..."
    codesign --verify --verbose "${APP_PATH}" 2>&1 || true
}

# 创建 DMG
create_dmg_package() {
    echo -e "${YELLOW}[5/5] 创建 DMG 安装包...${NC}"
    
    APP_PATH="${BUILD_DIR}/Build/Products/Release/${APP_NAME}"
    DMG_PATH="${DIST_DIR}/${DMG_NAME}"
    
    # 删除已存在的 DMG
    rm -f "${DMG_PATH}"
    
    create-dmg \
        --volname "${PROJECT_NAME}" \
        --volicon "${PROJECT_DIR}/${PROJECT_NAME}/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" 2>/dev/null \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}" 150 185 \
        --hide-extension "${APP_NAME}" \
        --app-drop-link 450 185 \
        "${DMG_PATH}" \
        "${APP_PATH}" || {
            # 如果带图标失败，尝试不带图标
            create-dmg \
                --volname "${PROJECT_NAME}" \
                --window-pos 200 120 \
                --window-size 600 400 \
                --icon-size 100 \
                --icon "${APP_NAME}" 150 185 \
                --hide-extension "${APP_NAME}" \
                --app-drop-link 450 185 \
                "${DMG_PATH}" \
                "${APP_PATH}"
        }
    
    echo -e "${GREEN}✓ DMG 创建完成${NC}"
}

# 显示结果
show_result() {
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}  构建成功!${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "应用位置: ${BUILD_DIR}/Build/Products/Release/${APP_NAME}"
    echo -e "DMG 位置: ${DIST_DIR}/${DMG_NAME}"
    echo ""
    echo -e "DMG 大小: $(du -h "${DIST_DIR}/${DMG_NAME}" | cut -f1)"
    echo ""
    echo -e "${YELLOW}提示: 用户首次打开应用时需要：${NC}"
    echo -e "  1. 右键点击应用 → 打开"
    echo -e "  2. 在弹出的对话框中点击「打开」"
    echo ""
}

# 主流程
main() {
    check_dependencies
    clean_build
    build_app
    sign_app
    create_dmg_package
    show_result
}

main "$@"
