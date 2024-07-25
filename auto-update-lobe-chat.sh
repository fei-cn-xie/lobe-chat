#!/bin/bash
# auto-update-lobe-chat.sh

# 设置代理（可选）
export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890

# 拉取最新的镜像并将输出存储在变量中
output=$(docker pull lobehub/lobe-chat:latest 2>&1)

# 检查拉取命令是否成功执行
if [ $? -ne 0 ]; then
  exit 1
fi

# 检查输出中是否包含特定的字符串
echo "$output" | grep -q "Image is up to date for lobehub/lobe-chat:latest"

# 如果镜像已经是最新的，则不执行任何操作
if [ $? -eq 0 ]; then
  exit 0
fi

echo "Detected Lobe-Chat update"

# 删除旧的容器
echo "Removed: $(docker rm -f Lobe-Chat)"

# 运行新的容器
echo "Started: $(docker run -d --network=host --env-file ./lobe.env --name=Lobe-Chat --restart=always lobehub/lobe-chat)"

# 打印更新的时间和版本
echo "Update time: $(date)"
echo "Version: $(docker inspect lobehub/lobe-chat:latest | grep 'org.opencontainers.image.version' | awk -F'"' '{print $4}')"

# 清理不再使用的镜像
docker images | grep 'lobehub/lobe-chat' | grep -v 'latest' | awk '{print $3}' | xargs -r docker rmi > /dev/null 2>&1
echo "Removed old images."
