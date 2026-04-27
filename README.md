# rules-mirror

代理客户端规则集镜像。仅同步 + 缓存第三方上游，不生产数据。

## 目录结构

```
mihomo/    # ClashVerge / OpenClash / FIClash 用（mrs 二进制 + Loyalsoldier classical txt）
singbox/   # sing-box 用（srs 二进制）
surge/     # Surge / Shadowrocket 用（DOMAIN-SUFFIX 原生 .list 格式）
clash/     # 旧版 Clash classical yaml（兼容保留）
custom/    # 个人自维护规则
scripts/   # 同步脚本
```

## 数据源

| 目录 | 上游 |
|---|---|
| `mihomo/geosite-*.mrs`、`mihomo/geoip-*.mrs`、`singbox/*.srs` | [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) |
| `mihomo/reject-loyalsoldier.txt` | [Loyalsoldier/clash-rules](https://github.com/Loyalsoldier/clash-rules) |
| `surge/{cn,telegram,ads,private}.list` | 由 [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) 的 mihomo classical 自动转换 |
| `surge/{surge,shadowrocket}-{apple,china}.list`、`clash/*.yaml` | [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) |
| `custom/*` | 个人自维护 |

## 同步

```bash
bash scripts/sync-local.sh
```

每日通过 LaunchAgent 自动拉取上游并 push。
