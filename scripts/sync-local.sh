#!/usr/bin/env bash
# rules-mirror 同步脚本
# 双源策略：
#   - Surge / Shadowrocket 用 blackmatrix7（.list 原生格式，meta-rules-dat 的 list 是 mihomo classical 格式不兼容）
#   - ClashVerge / OpenClash / FIClash / sing-box 用 meta-rules-dat（dnsmasq-china-list + v2fly + EasyList + AdGuard 合并源，覆盖远超 blackmatrix7）

set -euo pipefail

# === A. blackmatrix7 镜像 — Surge 系专用 ===
BM_BASE=https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule

curl -L --fail -o surge-apple.list           "$BM_BASE/Surge/Apple/Apple.list"
curl -L --fail -o surge-china.list           "$BM_BASE/Surge/China/China.list"
curl -L --fail -o shadowrocket-apple.list    "$BM_BASE/Shadowrocket/Apple/Apple.list"
curl -L --fail -o shadowrocket-china.list    "$BM_BASE/Shadowrocket/China/China.list"
# Apple 维度的 yaml 仍由 blackmatrix7 提供（meta-rules-dat 的 apple 口径偏路由侧，与「Apple 服务直连」语义不一致）
curl -L --fail -o clash-apple.yaml           "$BM_BASE/Clash/Apple/Apple.yaml"
# clash-china.yaml 保留同步：现网 ClashVerge/OpenClash/FIClash 还在引用它，未升级到 geosite-cn.mrs 之前不能删
curl -L --fail -o clash-china.yaml           "$BM_BASE/Clash/China/China.yaml"

# === B. meta-rules-dat 镜像 — mihomo (mrs) + sing-box (srs) 共用 ===
META_BASE=https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat

# B.1 mihomo mrs（ClashVerge / OpenClash / FIClash 用）
curl -L --fail -o geosite-cn.mrs                  "$META_BASE/meta/geo/geosite/cn.mrs"
curl -L --fail -o geosite-private.mrs             "$META_BASE/meta/geo/geosite/private.mrs"
curl -L --fail -o geosite-telegram.mrs            "$META_BASE/meta/geo/geosite/telegram.mrs"
curl -L --fail -o geosite-category-ads-all.mrs    "$META_BASE/meta/geo/geosite/category-ads-all.mrs"
curl -L --fail -o geoip-cn.mrs                    "$META_BASE/meta/geo/geoip/cn.mrs"
curl -L --fail -o geoip-private.mrs               "$META_BASE/meta/geo/geoip/private.mrs"
curl -L --fail -o geoip-telegram.mrs              "$META_BASE/meta/geo/geoip/telegram.mrs"

# B.2 sing-box srs（NAS sing-box 用）
curl -L --fail -o geosite-cn.srs                  "$META_BASE/sing/geo/geosite/cn.srs"
curl -L --fail -o geosite-private.srs             "$META_BASE/sing/geo/geosite/private.srs"
curl -L --fail -o geosite-telegram.srs            "$META_BASE/sing/geo/geosite/telegram.srs"
curl -L --fail -o geosite-category-ads-all.srs    "$META_BASE/sing/geo/geosite/category-ads-all.srs"
curl -L --fail -o geoip-cn.srs                    "$META_BASE/sing/geo/geoip/cn.srs"
curl -L --fail -o geoip-private.srs               "$META_BASE/sing/geo/geoip/private.srs"
curl -L --fail -o geoip-telegram.srs              "$META_BASE/sing/geo/geoip/telegram.srs"

# === C. Loyalsoldier 镜像 — 强力广告拦截（17 万条 EasyList+AdGuard+WSB 合并，仅 Clash 系用）===
# 命名为 reject-loyalsoldier.txt 与 meta-rules-dat 的 category-ads-all 区分维度
curl -L --fail -o reject-loyalsoldier.txt    "https://raw.githubusercontent.com/Loyalsoldier/clash-rules/release/reject.txt"

# === D. 清理已弃用文件（暂无）===
# 待所有客户端配置完成 mrs 切换后，再删除 clash-china.yaml
