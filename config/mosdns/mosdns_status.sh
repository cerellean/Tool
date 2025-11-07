#!/bin/sh
# MosDNS Metrics 分类统计脚本
# 支持: 缓存分类命中率 + 上游 Top5 + 平均响应延迟 + Top10 域名
# 兼容科学计数法 + 彩色输出
# 依赖: curl, awk, grep, bc

METRICS_URL="http://127.0.0.1:9099/metrics"

# 终端颜色
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

printf "${CYAN}=== MosDNS Metrics 分类统计 ===${RESET}\n"
printf "来源: %s\n\n" "$METRICS_URL"

metrics=$(curl -s "$METRICS_URL")
if [ -z "$metrics" ]; then
  printf "${RED}❌ 无法获取 metrics，请确认 MosDNS 正在运行并开启 API${RESET}\n"
  exit 1
fi

# ---------------------
# 缓存类指标
# ---------------------
hit=$(echo "$metrics" | grep '^mosdns_cache_hit_total' | awk '{print $2}' | head -1)
lazy_hit=$(echo "$metrics" | grep '^mosdns_cache_lazy_hit_total' | awk '{print $2}' | head -1)
total_query=$(echo "$metrics" | grep '^mosdns_metrics_collector_query_total' | awk '{print $2}' | head -1)

hit=${hit:-0}
lazy_hit=${lazy_hit:-0}
total_query=${total_query:-0}

# 分类命中率
if [ "$total_query" -gt 0 ]; then
  hit_rate=$(echo "scale=2; $hit/$total_query*100" | bc)
  lazy_hit_rate=$(echo "scale=2; $lazy_hit/$total_query*100" | bc)
  total_hit_rate=$(echo "scale=2; ($hit + $lazy_hit)/$total_query*100" | bc)
else
  hit_rate=0
  lazy_hit_rate=0
  total_hit_rate=0
fi

printf "${YELLOW}缓存类指标:${RESET}\n"
printf "  总查询次数           : %s\n" "$total_query"
printf "  普通缓存命中         : %s (%.2f%%)\n" "$hit" "$hit_rate"
printf "  过期缓存命中         : %s (%.2f%%)\n" "$lazy_hit" "$lazy_hit_rate"
printf "  总缓存命中率         : %s (%.2f%%)\n\n" "$(expr $hit + $lazy_hit)" "$total_hit_rate"

# ---------------------
# 上游类指标 Top5
# ---------------------
printf "${BLUE}上游使用情况 Top5:${RESET}\n"
echo "$metrics" | grep '^mosdns_upstream_total{name=' \
  | sed 's/.*name="\([^"]*\)".*} \(.*\)/\2 \1/' \
  | sort -nr | head -5 \
  | while read count name; do
      printf "  %-40s %s 次\n" "$name" "$count"
    done
printf "\n"

# ---------------------
# 响应延迟类指标 (平均响应时间)
# ---------------------
latency_sum=$(echo "$metrics" | grep 'mosdns_metrics_collector_response_latency_millisecond_sum' | awk '{print $2}' | head -1)
latency_count=$(echo "$metrics" | grep 'mosdns_metrics_collector_response_latency_millisecond_count' | awk '{print $2}' | head -1)

# 转换科学计数法为普通数字
latency_sum=$(awk "BEGIN{printf \"%.6f\", $latency_sum}")
latency_count=$(awk "BEGIN{printf \"%.6f\", $latency_count}")

if [ -n "$latency_sum" ] && [ -n "$latency_count" ] && [ "$(echo "$latency_count > 0" | bc)" -eq 1 ]; then
  avg_latency=$(awk "BEGIN{printf \"%.2f\", $latency_sum / $latency_count}")
else
  avg_latency="N/A"
fi

printf "${YELLOW}响应延迟类指标:${RESET}\n"
printf "  平均响应延迟 (ms)    : ${CYAN}%s${RESET}\n\n" "$avg_latency"

# ---------------------
# 查询域名类指标 Top10
# ---------------------
printf "${BLUE}Top10 查询域名:${RESET}\n"
echo "$metrics" | grep '^mosdns_metrics_collector_query_total{name=' \
  | grep 'name="' \
  | sed 's/.*name="\([^"]*\)".*} \(.*\)/\2 \1/' \
  | sort -nr | head -10 \
  | while read count name; do
      printf "  %-40s %s 次\n" "$name" "$count"
    done
printf "\n"

printf "${CYAN}=== 统计完成 ===${RESET}\n"
