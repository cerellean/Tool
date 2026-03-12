#!/bin/sh
# ============================================
# MosDNS 业务指标查询脚本 (for Alpine Linux)
# 作者: ChatGPT
# 版本: v1.0
# ============================================

METRICS_URL="http://127.0.0.1:9099/metrics"

# 检查 curl 是否存在
if ! command -v curl >/dev/null 2>&1; then
    echo "❌ 缺少 curl，请执行：apk add curl"
    exit 1
fi

# 获取 metrics 数据
DATA=$(curl -s "$METRICS_URL")

if [ -z "$DATA" ]; then
    echo "❌ 无法访问 $METRICS_URL"
    exit 1
fi

echo "=== MosDNS Metrics 状态报告 ==="
echo "来源: $METRICS_URL"
echo

# 提取核心指标
CACHE_HIT=$(echo "$DATA" | grep '^mosdns_cache_hit_total' | awk '{print $2}')
CACHE_QUERY=$(echo "$DATA" | grep '^mosdns_cache_query_total' | awk '{print $2}')
CACHE_SIZE=$(echo "$DATA" | grep '^mosdns_cache_size_current' | awk '{print $2}')
ERR_TOTAL=$(echo "$DATA" | grep '^mosdns_metrics_collector_err_total' | awk '{print $2}')
QUERY_TOTAL=$(echo "$DATA" | grep '^mosdns_metrics_collector_query_total' | awk '{print $2}')
LAT_SUM=$(echo "$DATA" | grep '^mosdns_metrics_collector_response_latency_millisecond_sum' | awk '{print $2}')
LAT_COUNT=$(echo "$DATA" | grep '^mosdns_metrics_collector_response_latency_millisecond_count' | awk '{print $2}')

# 计算命中率
if [ "$CACHE_QUERY" != "0" ] && [ -n "$CACHE_QUERY" ]; then
    HIT_RATE=$(awk -v hit="$CACHE_HIT" -v q="$CACHE_QUERY" 'BEGIN { printf "%.2f", (hit/q)*100 }')
else
    HIT_RATE="0.00"
fi

# 计算平均延迟
if [ "$LAT_COUNT" != "0" ] && [ -n "$LAT_COUNT" ]; then
    AVG_LAT=$(awk -v s="$LAT_SUM" -v c="$LAT_COUNT" 'BEGIN { printf "%.2f", s/c }')
else
    AVG_LAT="0.00"
fi

# 计算错误率
if [ "$QUERY_TOTAL" != "0" ] && [ -n "$QUERY_TOTAL" ]; then
    ERR_RATE=$(awk -v e="$ERR_TOTAL" -v q="$QUERY_TOTAL" 'BEGIN { printf "%.2f", (e/q)*100 }')
else
    ERR_RATE="0.00"
fi

# 输出报告
echo "查询总数        : $CACHE_QUERY"
echo "缓存命中数      : $CACHE_HIT"
echo "缓存命中率      : $HIT_RATE %"
echo "当前缓存记录数  : $CACHE_SIZE"
echo "平均响应延迟    : $AVG_LAT ms"
echo "错误总数        : $ERR_TOTAL"
echo "错误率          : $ERR_RATE %"
echo
echo "更新时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
