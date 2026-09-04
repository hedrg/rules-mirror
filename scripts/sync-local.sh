#!/usr/bin/env bash
# rules-mirror 同步脚本
# 目录布局：
#   mihomo/   — ClashVerge / ClashIOS / OpenClash / FIClash 用（mrs 二进制；保留 Loyalsoldier YAML 兼容副本）
#   singbox/  — sing-box NAS 用（srs 二进制）
#   surge/    — Surge / Shadowrocket 用（DOMAIN-SUFFIX 原生格式）
#                自动从 meta-rules-dat 的 mihomo classical 转换，与 mihomo/singbox 完全同源
#   clash/    — 旧 Clash classical yaml（兼容保留，新配置已切到 mihomo/*.mrs）
#   custom/   — 手维护规则（ai/uk/de），不在本脚本管辖范围

set -euo pipefail

cd "$(dirname "$0")/.."

# Loyalsoldier 上游的 reject.txt 实际为 YAML payload。大规则集先转换成
# MRS，避免客户端按文本逐行校验 YAML 标记，并降低启动解析开销。
if [[ -n "${MIHOMO_BIN:-}" && -x "$MIHOMO_BIN" ]]; then
  :
elif command -v mihomo >/dev/null 2>&1; then
  MIHOMO_BIN="$(command -v mihomo)"
elif [[ -x "/Applications/Clash Verge.app/Contents/MacOS/verge-mihomo" ]]; then
  MIHOMO_BIN="/Applications/Clash Verge.app/Contents/MacOS/verge-mihomo"
else
  echo "mihomo executable not found; set MIHOMO_BIN before syncing rules" >&2
  exit 1
fi

# Build everything below .build/, which the repository watcher ignores. No
# published file changes until every download, conversion, and load check passes.
mkdir -p .build
STAGE_DIR="$(mktemp -d .build/rules-sync.XXXXXX)"
cleanup_stage() {
  rm -rf "$STAGE_DIR"
}
trap cleanup_stage EXIT
mkdir -p "$STAGE_DIR"/{clash,mihomo,singbox,surge,check-home}

BM_BASE="${RULES_SYNC_BM_BASE:-https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule}"
META_BASE="${RULES_SYNC_META_BASE:-https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat}"
META_LIST_BASE="$META_BASE/meta/geo"
LOYAL_URL="${RULES_SYNC_LOYAL_URL:-https://raw.githubusercontent.com/Loyalsoldier/clash-rules/release/reject.txt}"
CURL_ARGS=(-L --fail --silent --show-error --retry 2 --connect-timeout 15 --max-time 120)

fetch() {
  local url="$1" destination="$2"
  curl "${CURL_ARGS[@]}" -o "$destination" "$url"
  test -s "$destination"
}

# === A. blackmatrix7 mirrors and Apple domain MRS ===
fetch "$BM_BASE/Surge/Apple/Apple.list"                 "$STAGE_DIR/surge/surge-apple.list"
fetch "$BM_BASE/Surge/China/China.list"                 "$STAGE_DIR/surge/surge-china.list"
fetch "$BM_BASE/Shadowrocket/Apple/Apple.list"          "$STAGE_DIR/surge/shadowrocket-apple.list"
fetch "$BM_BASE/Shadowrocket/China/China.list"          "$STAGE_DIR/surge/shadowrocket-china.list"
fetch "$BM_BASE/Clash/Apple/Apple.yaml"                 "$STAGE_DIR/clash/apple.yaml"
fetch "$BM_BASE/Clash/Apple/Apple_Domain.yaml"          "$STAGE_DIR/apple-domain.yaml"
"$MIHOMO_BIN" convert-ruleset domain yaml "$STAGE_DIR/apple-domain.yaml" "$STAGE_DIR/mihomo/apple-domain.mrs"

# === B. meta-rules-dat mirrors — Mihomo MRS and sing-box SRS ===
fetch "$META_BASE/meta/geo/geosite/cn.mrs"              "$STAGE_DIR/mihomo/geosite-cn.mrs"
fetch "$META_BASE/meta/geo/geosite/private.mrs"         "$STAGE_DIR/mihomo/geosite-private.mrs"
fetch "$META_BASE/meta/geo/geosite/telegram.mrs"        "$STAGE_DIR/mihomo/geosite-telegram.mrs"
fetch "$META_BASE/meta/geo/geosite/category-ads-all.mrs" "$STAGE_DIR/mihomo/geosite-category-ads-all.mrs"
fetch "$META_BASE/meta/geo/geoip/cn.mrs"                "$STAGE_DIR/mihomo/geoip-cn.mrs"
fetch "$META_BASE/meta/geo/geoip/gb.mrs"                "$STAGE_DIR/mihomo/geoip-gb.mrs"
fetch "$META_BASE/meta/geo/geoip/de.mrs"                "$STAGE_DIR/mihomo/geoip-de.mrs"
fetch "$META_BASE/meta/geo/geoip/private.mrs"           "$STAGE_DIR/mihomo/geoip-private.mrs"
fetch "$META_BASE/meta/geo/geoip/telegram.mrs"          "$STAGE_DIR/mihomo/geoip-telegram.mrs"

fetch "$META_BASE/sing/geo/geosite/cn.srs"              "$STAGE_DIR/singbox/geosite-cn.srs"
fetch "$META_BASE/sing/geo/geosite/private.srs"         "$STAGE_DIR/singbox/geosite-private.srs"
fetch "$META_BASE/sing/geo/geosite/telegram.srs"        "$STAGE_DIR/singbox/geosite-telegram.srs"
fetch "$META_BASE/sing/geo/geosite/category-ads-all.srs" "$STAGE_DIR/singbox/geosite-category-ads-all.srs"
fetch "$META_BASE/sing/geo/geoip/cn.srs"                "$STAGE_DIR/singbox/geoip-cn.srs"
fetch "$META_BASE/sing/geo/geoip/private.srs"           "$STAGE_DIR/singbox/geoip-private.srs"
fetch "$META_BASE/sing/geo/geoip/telegram.srs"          "$STAGE_DIR/singbox/geoip-telegram.srs"

# === C. Loyalsoldier — preserve YAML source and publish validated MRS ===
fetch "$LOYAL_URL" "$STAGE_DIR/mihomo/reject-loyalsoldier.txt"
"$MIHOMO_BIN" convert-ruleset domain yaml \
  "$STAGE_DIR/mihomo/reject-loyalsoldier.txt" \
  "$STAGE_DIR/mihomo/reject-loyalsoldier.mrs"

# === D. Surge / Shadowrocket compatible text rules ===
fetch "$META_LIST_BASE/geosite/cn.list" "$STAGE_DIR/geosite-cn.list"
sed 's|^+\.|DOMAIN-SUFFIX,|' "$STAGE_DIR/geosite-cn.list" > "$STAGE_DIR/surge/cn.list"

fetch "$META_LIST_BASE/geosite/telegram.list" "$STAGE_DIR/geosite-telegram.list"
fetch "$META_LIST_BASE/geoip/telegram.list" "$STAGE_DIR/geoip-telegram.list"
{
  sed 's|^+\.|DOMAIN-SUFFIX,|' "$STAGE_DIR/geosite-telegram.list"
  printf '\n'
  awk '
    /:/ { print "IP-CIDR6," $0 ",no-resolve"; next }
    /\// { print "IP-CIDR," $0 ",no-resolve" }
  ' "$STAGE_DIR/geoip-telegram.list"
} > "$STAGE_DIR/surge/telegram.list"

fetch "$META_LIST_BASE/geosite/category-ads-all.list" "$STAGE_DIR/geosite-ads.list"
awk '
  /^\+\./ { sub(/^\+\./, ""); print "DOMAIN-SUFFIX," $0; next }
  /^[a-zA-Z0-9]/ { print "DOMAIN-SUFFIX," $0 }
' "$STAGE_DIR/geosite-ads.list" > "$STAGE_DIR/surge/ads.list"

fetch "$META_LIST_BASE/geoip/private.list" "$STAGE_DIR/geoip-private.list"
awk '
  /:/ { print "IP-CIDR6," $0 ",no-resolve"; next }
  /\// { print "IP-CIDR," $0 ",no-resolve" }
' "$STAGE_DIR/geoip-private.list" > "$STAGE_DIR/surge/private.list"

# === E. Validate staged artifacts before publication ===
grep -q '^payload:' "$STAGE_DIR/clash/apple.yaml"
grep -q '^payload:' "$STAGE_DIR/mihomo/reject-loyalsoldier.txt"
grep -q '^DOMAIN-SUFFIX,' "$STAGE_DIR/surge/cn.list"
grep -Eq '^(DOMAIN-SUFFIX|IP-CIDR6?),.*' "$STAGE_DIR/surge/telegram.list"
grep -q '^DOMAIN-SUFFIX,' "$STAGE_DIR/surge/ads.list"
grep -Eq '^IP-CIDR6?,.*' "$STAGE_DIR/surge/private.list"

MRS_FILES=(
  apple-domain.mrs
  geosite-cn.mrs
  geosite-private.mrs
  geosite-telegram.mrs
  geosite-category-ads-all.mrs
  geoip-cn.mrs
  geoip-gb.mrs
  geoip-de.mrs
  geoip-private.mrs
  geoip-telegram.mrs
  reject-loyalsoldier.mrs
)
cp "${MRS_FILES[@]/#/$STAGE_DIR/mihomo/}" "$STAGE_DIR/check-home/"
cat > "$STAGE_DIR/check-home/config.yaml" <<'YAML'
mode: rule
log-level: warning
rule-providers:
  apple-domain: {type: file, behavior: domain, format: mrs, path: ./apple-domain.mrs}
  geosite-cn: {type: file, behavior: domain, format: mrs, path: ./geosite-cn.mrs}
  geosite-private: {type: file, behavior: domain, format: mrs, path: ./geosite-private.mrs}
  geosite-telegram: {type: file, behavior: domain, format: mrs, path: ./geosite-telegram.mrs}
  geosite-category-ads-all: {type: file, behavior: domain, format: mrs, path: ./geosite-category-ads-all.mrs}
  geoip-cn: {type: file, behavior: ipcidr, format: mrs, path: ./geoip-cn.mrs}
  geoip-gb: {type: file, behavior: ipcidr, format: mrs, path: ./geoip-gb.mrs}
  geoip-de: {type: file, behavior: ipcidr, format: mrs, path: ./geoip-de.mrs}
  geoip-private: {type: file, behavior: ipcidr, format: mrs, path: ./geoip-private.mrs}
  geoip-telegram: {type: file, behavior: ipcidr, format: mrs, path: ./geoip-telegram.mrs}
  reject-loyalsoldier: {type: file, behavior: domain, format: mrs, path: ./reject-loyalsoldier.mrs}
rules:
  - RULE-SET,apple-domain,DIRECT
  - RULE-SET,geosite-cn,DIRECT
  - RULE-SET,geosite-private,DIRECT
  - RULE-SET,geosite-telegram,DIRECT
  - RULE-SET,geosite-category-ads-all,REJECT
  - RULE-SET,geoip-cn,DIRECT,no-resolve
  - RULE-SET,geoip-gb,DIRECT,no-resolve
  - RULE-SET,geoip-de,DIRECT,no-resolve
  - RULE-SET,geoip-private,DIRECT,no-resolve
  - RULE-SET,geoip-telegram,DIRECT,no-resolve
  - RULE-SET,reject-loyalsoldier,REJECT
  - MATCH,DIRECT
YAML
"$MIHOMO_BIN" -t -d "$STAGE_DIR/check-home" -f "$STAGE_DIR/check-home/config.yaml" >/dev/null

# Publish only after the complete staged set has passed all checks.
PUBLISH_FILES=(
  clash/apple.yaml
  mihomo/apple-domain.mrs
  mihomo/geosite-cn.mrs
  mihomo/geosite-private.mrs
  mihomo/geosite-telegram.mrs
  mihomo/geosite-category-ads-all.mrs
  mihomo/geoip-cn.mrs
  mihomo/geoip-gb.mrs
  mihomo/geoip-de.mrs
  mihomo/geoip-private.mrs
  mihomo/geoip-telegram.mrs
  mihomo/reject-loyalsoldier.txt
  mihomo/reject-loyalsoldier.mrs
  singbox/geosite-cn.srs
  singbox/geosite-private.srs
  singbox/geosite-telegram.srs
  singbox/geosite-category-ads-all.srs
  singbox/geoip-cn.srs
  singbox/geoip-private.srs
  singbox/geoip-telegram.srs
  surge/surge-apple.list
  surge/surge-china.list
  surge/shadowrocket-apple.list
  surge/shadowrocket-china.list
  surge/cn.list
  surge/telegram.list
  surge/ads.list
  surge/private.list
)
for relative_path in "${PUBLISH_FILES[@]}"; do
  mv "$STAGE_DIR/$relative_path" "$relative_path"
done

echo "rules sync complete: ${#PUBLISH_FILES[@]} validated artifacts published"
