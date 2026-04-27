#!/usr/bin/env bash
# rules-mirror 同步脚本
# 目录布局：
#   mihomo/   — ClashVerge / OpenClash / FIClash 用（mrs 二进制 + Loyalsoldier classical txt）
#   singbox/  — sing-box NAS 用（srs 二进制）
#   surge/    — Surge / Shadowrocket 用（DOMAIN-SUFFIX 原生格式）
#                自动从 meta-rules-dat 的 mihomo classical 转换，与 mihomo/singbox 完全同源
#   clash/    — 旧 Clash classical yaml（兼容保留，新配置已切到 mihomo/*.mrs）
#   custom/   — 手维护规则（ai/uk/de），不在本脚本管辖范围

set -euo pipefail

cd "$(dirname "$0")/.."

# === A. blackmatrix7 镜像 — Surge / Shadowrocket / 旧 Clash 用 ===
BM_BASE=https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule

curl -L --fail -o surge/surge-apple.list           "$BM_BASE/Surge/Apple/Apple.list"
curl -L --fail -o surge/surge-china.list           "$BM_BASE/Surge/China/China.list"
curl -L --fail -o surge/shadowrocket-apple.list    "$BM_BASE/Shadowrocket/Apple/Apple.list"
curl -L --fail -o surge/shadowrocket-china.list    "$BM_BASE/Shadowrocket/China/China.list"
curl -L --fail -o clash/apple.yaml                 "$BM_BASE/Clash/Apple/Apple.yaml"
curl -L --fail -o clash/china.yaml                 "$BM_BASE/Clash/China/China.yaml"

# === B. meta-rules-dat 镜像 — mihomo (mrs) + sing-box (srs) ===
META_BASE=https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat
META_LIST_BASE="$META_BASE/meta/geo"

# B.1 mihomo mrs
curl -L --fail -o mihomo/geosite-cn.mrs                  "$META_BASE/meta/geo/geosite/cn.mrs"
curl -L --fail -o mihomo/geosite-private.mrs             "$META_BASE/meta/geo/geosite/private.mrs"
curl -L --fail -o mihomo/geosite-telegram.mrs            "$META_BASE/meta/geo/geosite/telegram.mrs"
curl -L --fail -o mihomo/geosite-category-ads-all.mrs    "$META_BASE/meta/geo/geosite/category-ads-all.mrs"
curl -L --fail -o mihomo/geoip-cn.mrs                    "$META_BASE/meta/geo/geoip/cn.mrs"
curl -L --fail -o mihomo/geoip-private.mrs               "$META_BASE/meta/geo/geoip/private.mrs"
curl -L --fail -o mihomo/geoip-telegram.mrs              "$META_BASE/meta/geo/geoip/telegram.mrs"

# B.2 sing-box srs
curl -L --fail -o singbox/geosite-cn.srs                 "$META_BASE/sing/geo/geosite/cn.srs"
curl -L --fail -o singbox/geosite-private.srs            "$META_BASE/sing/geo/geosite/private.srs"
curl -L --fail -o singbox/geosite-telegram.srs           "$META_BASE/sing/geo/geosite/telegram.srs"
curl -L --fail -o singbox/geosite-category-ads-all.srs   "$META_BASE/sing/geo/geosite/category-ads-all.srs"
curl -L --fail -o singbox/geoip-cn.srs                   "$META_BASE/sing/geo/geoip/cn.srs"
curl -L --fail -o singbox/geoip-private.srs              "$META_BASE/sing/geo/geoip/private.srs"
curl -L --fail -o singbox/geoip-telegram.srs             "$META_BASE/sing/geo/geoip/telegram.srs"

# === C. Loyalsoldier — Clash 系强力广告（17 万条 EasyList+AdGuard+WSB 合并）===
curl -L --fail -o mihomo/reject-loyalsoldier.txt   "https://raw.githubusercontent.com/Loyalsoldier/clash-rules/release/reject.txt"

# === D. Surge / Shadowrocket 兼容格式（自动从 meta-rules-dat 转换）===
# Surge 系不支持 mrs/srs，但通过 sed 转换可获得与 mihomo/singbox 同源的覆盖度
# → 6 端命中域名集合一致 → Telegram 等服务出口 IP 不会跳变

# D.1 cn 直连（11.8 万条 dnsmasq-china-list 派生，覆盖 17track 等海外注册中国公司）
curl -sL --fail "$META_LIST_BASE/geosite/cn.list" \
  | sed 's|^+\.|DOMAIN-SUFFIX,|' > surge/cn.list

# D.2 Telegram 域名 + IP 合并
{
  curl -sL --fail "$META_LIST_BASE/geosite/telegram.list" | sed 's|^+\.|DOMAIN-SUFFIX,|'
  curl -sL --fail "$META_LIST_BASE/geoip/telegram.list" | awk '
    /:/ { print "IP-CIDR6," $0 ",no-resolve"; next }
    /\// { print "IP-CIDR," $0 ",no-resolve" }
  '
} > surge/telegram.list

# D.3 广告拦截（meta-rules-dat 870 条；Loyalsoldier 17 万不接，性能优先）
curl -sL --fail "$META_LIST_BASE/geosite/category-ads-all.list" | awk '
  /^\+\./ { sub(/^\+\./, ""); print "DOMAIN-SUFFIX," $0; next }
  /^[a-zA-Z0-9]/ { print "DOMAIN-SUFFIX," $0 }
' > surge/ads.list

# D.4 私有 IP
curl -sL --fail "$META_LIST_BASE/geoip/private.list" | awk '
  /:/ { print "IP-CIDR6," $0 ",no-resolve"; next }
  /\// { print "IP-CIDR," $0 ",no-resolve" }
' > surge/private.list
