#!/bin/bash

# EyeBreather 性能监控脚本
# 监控 CPU、内存、空闲唤醒等指标

DURATION=${1:-60}  # 默认监控 60 秒
INTERVAL=${2:-5}   # 默认每 5 秒采样一次
LOG_FILE="/tmp/eyebreather_perf_$(date +%Y%m%d_%H%M%S).log"

echo "=========================================="
echo "  EyeBreather 性能监控"
echo "=========================================="
echo "监控时长: ${DURATION} 秒"
echo "采样间隔: ${INTERVAL} 秒"
echo "日志文件: ${LOG_FILE}"
echo "=========================================="
echo ""

# 检查进程是否存在
PID=$(pgrep -f "EyeBreather.app/Contents/MacOS/EyeBreather" | head -1)

if [ -z "$PID" ]; then
    echo "❌ 错误: EyeBreather 进程未找到"
    exit 1
fi

echo "✅ 找到 EyeBreather 进程 (PID: $PID)"
echo ""

# 获取进程路径
PROCESS_PATH=$(ps -p $PID -o command= | head -1)
if [[ "$PROCESS_PATH" == *"DerivedData"* ]]; then
    echo "📦 版本: 开发版本 (DerivedData)"
elif [[ "$PROCESS_PATH" == *"/Applications/"* ]]; then
    echo "📦 版本: 已安装版本 (/Applications/)"
else
    echo "📦 版本: 未知路径"
fi
echo "   路径: $PROCESS_PATH"
echo ""

# 初始化统计
declare -a CPU_SAMPLES
declare -a MEM_SAMPLES
SAMPLE_COUNT=0
START_TIME=$(date +%s)

echo "开始监控..."
echo "时间戳, CPU%, 内存MB, 线程数" | tee -a "$LOG_FILE"
echo "-------------------------------------------"

while [ $(($(date +%s) - START_TIME)) -lt $DURATION ]; do
    # 获取进程信息（分别获取避免解析问题）
    CPU=$(ps -p $PID -o %cpu= 2>/dev/null | tr -d ' ')
    MEM_KB=$(ps -p $PID -o rss= 2>/dev/null | tr -d ' ')
    THREADS=$(ps -M $PID 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
    
    if [ -z "$CPU" ]; then
        echo "⚠️  进程已退出"
        break
    fi
    
    # 转换内存为 MB
    MEM_MB=$(echo "scale=1; $MEM_KB / 1024" | bc)
    
    # 记录样本
    CPU_SAMPLES+=($CPU)
    MEM_SAMPLES+=($MEM_MB)
    SAMPLE_COUNT=$((SAMPLE_COUNT + 1))
    
    # 时间戳
    TIMESTAMP=$(date +"%H:%M:%S")
    
    # 输出
    echo "$TIMESTAMP, $CPU%, ${MEM_MB}MB, $THREADS 线程" | tee -a "$LOG_FILE"
    
    sleep $INTERVAL
done

echo ""
echo "=========================================="
echo "  监控报告"
echo "=========================================="

# 计算 CPU 统计
if [ $SAMPLE_COUNT -gt 0 ]; then
    CPU_SUM=0
    CPU_MAX=0
    for cpu in "${CPU_SAMPLES[@]}"; do
        CPU_SUM=$(echo "$CPU_SUM + $cpu" | bc)
        if (( $(echo "$cpu > $CPU_MAX" | bc -l) )); then
            CPU_MAX=$cpu
        fi
    done
    CPU_AVG=$(echo "scale=2; $CPU_SUM / $SAMPLE_COUNT" | bc)
    
    # 计算内存统计
    MEM_SUM=0
    MEM_MAX=0
    for mem in "${MEM_SAMPLES[@]}"; do
        MEM_SUM=$(echo "$MEM_SUM + $mem" | bc)
        if (( $(echo "$mem > $MEM_MAX" | bc -l) )); then
            MEM_MAX=$mem
        fi
    done
    MEM_AVG=$(echo "scale=1; $MEM_SUM / $SAMPLE_COUNT" | bc)
    
    echo ""
    echo "📊 CPU 使用率:"
    echo "   平均: ${CPU_AVG}%"
    echo "   最大: ${CPU_MAX}%"
    echo ""
    echo "📊 内存使用:"
    echo "   平均: ${MEM_AVG} MB"
    echo "   最大: ${MEM_MAX} MB"
    echo ""
    echo "📊 采样次数: $SAMPLE_COUNT"
    echo ""
    
    # 性能评估
    echo "=========================================="
    echo "  性能评估"
    echo "=========================================="
    
    if (( $(echo "$CPU_AVG < 1.0" | bc -l) )); then
        echo "✅ CPU: 优秀 (平均 < 1%)"
    elif (( $(echo "$CPU_AVG < 2.0" | bc -l) )); then
        echo "✅ CPU: 良好 (平均 < 2%)"
    elif (( $(echo "$CPU_AVG < 5.0" | bc -l) )); then
        echo "⚠️  CPU: 一般 (平均 < 5%)"
    else
        echo "❌ CPU: 需要优化 (平均 >= 5%)"
    fi
    
    if (( $(echo "$MEM_AVG < 100" | bc -l) )); then
        echo "✅ 内存: 优秀 (平均 < 100MB)"
    elif (( $(echo "$MEM_AVG < 200" | bc -l) )); then
        echo "✅ 内存: 良好 (平均 < 200MB)"
    else
        echo "⚠️  内存: 偏高 (平均 >= 200MB)"
    fi
    
    echo ""
    echo "优化前基准: CPU 5.4%, 空闲唤醒 25 次"
    echo "当前性能相比优化前提升: $(echo "scale=0; (5.4 - $CPU_AVG) / 5.4 * 100" | bc)%"
fi

echo ""
echo "详细日志已保存到: $LOG_FILE"
echo "=========================================="
