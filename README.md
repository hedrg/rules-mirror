# rules-mirror

代理客户端规则集镜像。仅同步 + 缓存第三方上游，不生产数据。

## 数据源

| 文件 | 上游 |
|---|---|
| `geosite-*.mrs` / `.srs`、`geoip-*.mrs` / `.srs` | [MetaCubeX/meta-rules-dat](https://github.com/MetaCubeX/meta-rules-dat) |
| `reject-loyalsoldier.txt` | [Loyalsoldier/clash-rules](https://github.com/Loyalsoldier/clash-rules) |
| `surge-*.list` / `shadowrocket-*.list` / `clash-*.yaml` | [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) |
| `custom/*` | 个人自维护 |

## 同步

```bash
bash scripts/sync-local.sh
```

每日通过 LaunchAgent 自动拉取上游并 push。
