# rules-mirror

代理客户端规则集镜像。**仅同步 + 缓存**第三方上游，不自己生产数据，不需要 issue/PR。

由 `~/projects/proxy-configs/` 中 6 个客户端引用：ClashVerge / OpenClash / FIClash / sing-box / Surge / Shadowrocket。

## 目录结构

```
rules-mirror/
├── scripts/
│   └── sync-local.sh                      # 同步脚本（每日由 LaunchAgent 触发）
│
├── geosite-*.mrs / .srs                   # mihomo / sing-box 二进制规则集
├── geoip-*.mrs / .srs
│   ├── cn                                 # 中国大陆（dnsmasq-china-list 派生）
│   ├── private                            # 内网 / 保留地址
│   ├── telegram                           # Telegram 域名 / IP
│   └── category-ads-all                   # 广告域名（v2fly + AdGuard 等）
│
├── reject-loyalsoldier.txt                # 17 万条强力广告（Loyalsoldier 合并 EasyList+AdGuard+WSB）
│
├── surge-{apple,china}.list               # Surge 原生格式（不支持 mrs，必须保留 list）
├── shadowrocket-{apple,china}.list        # Shadowrocket 原生格式
├── clash-apple.yaml                       # Apple 服务直连（meta-rules-dat 的 apple 口径偏路由侧，不替代）
├── clash-china.yaml                       # 兼容保留（旧版本客户端），新配置已切到 geosite-cn.mrs
│
└── custom/                                # 自维护规则（个人定制，不来自上游镜像）
    ├── ai.list                            # AI 服务（Anthropic / OpenAI / Gemini / Grok / Cursor 等）
    ├── uk.list                            # 英国本地业务（银行、Fintech、媒体）
    └── de.list                            # 德国本地业务（N26 / Vivid / Sparkasse）
```

## 数据源链路

| 输出文件 | 上游 |
|---|---|
| `geosite-*.mrs/srs`、`geoip-*.mrs/srs` | [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat)（融合 v2fly/domain-list-community + felixonmars/dnsmasq-china-list + EasyList + AdGuard + WindowsSpyBlocker，每日 06:30 自动构建）|
| `reject-loyalsoldier.txt` | [Loyalsoldier/clash-rules](https://github.com/Loyalsoldier/clash-rules) |
| `surge-*.list` / `shadowrocket-*.list` / `clash-apple.yaml` / `clash-china.yaml` | [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)（Surge / Shadowrocket 原生格式，与 mrs 无替代关系）|
| `custom/*` | 手维护，不来自镜像 |

## 同步与发布

- **本地同步**：`bash scripts/sync-local.sh` 拉所有上游到本地
- **远端发布**：`~/.hermes/scripts/config-sync-MacMini.sh` 是 LaunchAgent 守护进程，监听本目录变更，自动 `git add/commit/push` 到 `hedrg/rules-mirror`
- 因此本地修改 = 几秒内推到 GitHub，无审核窗口；改动 `custom/` 时务必谨慎

## 引用方式速查

```yaml
# mihomo (ClashVerge / OpenClash / FIClash)
rule-providers:
  geosite-cn:
    type: http
    behavior: domain
    format: mrs
    url: https://raw.githubusercontent.com/hedrg/rules-mirror/main/geosite-cn.mrs

  ai:
    type: http
    behavior: classical
    format: text
    url: https://raw.githubusercontent.com/hedrg/rules-mirror/main/custom/ai.list
```

```jsonc
// sing-box: 通过 /etc/sing-box/update-singbox-rules.sh 拉到本地
{ "tag": "geosite-cn", "type": "local", "format": "binary", "path": "/etc/sing-box/geosite-cn.srs" }
```

```ini
# Surge / Shadowrocket（不支持 mrs）
RULE-SET,https://raw.githubusercontent.com/hedrg/rules-mirror/main/surge-china.list,DIRECT
RULE-SET,https://raw.githubusercontent.com/hedrg/rules-mirror/main/custom/ai.list,🤖 AI-Services
```
