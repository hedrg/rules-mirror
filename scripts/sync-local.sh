#!/usr/bin/env bash
set -euo pipefail
curl -L --fail -o clash-apple.yaml https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/Apple/Apple.yaml
curl -L --fail -o clash-china.yaml https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Clash/China/China.yaml
curl -L --fail -o surge-apple.list https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/Apple/Apple.list
curl -L --fail -o surge-china.list https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Surge/China/China.list
curl -L --fail -o shadowrocket-apple.list https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Shadowrocket/Apple/Apple.list
curl -L --fail -o shadowrocket-china.list https://raw.githubusercontent.com/blackmatrix7/ios_rule_script/master/rule/Shadowrocket/China/China.list
curl -L --fail -o geosite-cn.srs https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geosite/cn.srs
curl -L --fail -o geoip-cn.srs https://raw.githubusercontent.com/MetaCubeX/meta-rules-dat/sing/geo/geoip/cn.srs
