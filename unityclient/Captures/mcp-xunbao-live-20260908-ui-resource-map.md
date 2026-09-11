# 法宝搜索 Unity MCP 实时截图资源映射

- 截图：`mcp-xunbao-live-20260908.png`
- 来源：Unity MCP 连接 `unityclient@412d45435dc1aa1a`，项目 `E:/neiwang_kapai/Game/unityclient`，场景 `Assets/ProjectX/Scenes/Bootstrap.unity`。
- 分辨率：`1334x750`。
- 当前状态：本地固定账号登录后的法宝搜索零次数状态；`Canvas/DynamicUi_XunbaoLayer/Xunbao` 为运行时激活节点。
- 当前截图 SHA-256：`23058E424A3266155447A60D9891B70783DD954E9F8566917C225FF3439BB885`。
- 证据边界：本图用于 Unity G3 实时展示/检查，不替代 Cocos G1 基准或 G5 双端视觉对比。

| 画面区域 | Unity 资源/来源 | Cocos 来源 | 备注 |
|---|---|---|---|
| 背景 | `res/csd/Prefabs/wanfa/XunbaoLayer.prefab` 导入层 | `res/csd/wanfa/XunbaoLayer.csb` | 内部底图文件名：`未解析` |
| 标题“寻宝” | `Panel/Title/TitleName` | `Panel/Title/TitleName` | 文字节点已映射 |
| 法宝主图 | `Xunbao/Blue/Icon`，`Configs/fabao.json` 的 `pic=1002` | `Xunbao/Blue/Icon`，`fabao` 配置 | 当前选中法宝 1001 |
| 次数 | `Panel/XunbaoBg/TimesBg/Icon/Num` | 同路径 | 权威显示值 0 |
| 次数不足提示 | `Panel/XunbaoBg/TimesBg/Tips` | 同路径 | 显示“搜索次数不足，请在背包使用…” |
| 碎片槽 | `Xunbao/Blue/Image/Add1..Add3` | 同路径 | 三个碎片数量均为 0 |
| 一键寻宝 | `Xunbao/Btn_1` | `Xunbao/Btn_1` | 运行时 Button；零次数应路由搜宝令背包边界 |
| 合成 | `Xunbao/Btn_2` | `Xunbao/Btn_2` | 运行时 Button；受碎片前置校验约束 |
| 法宝列表 | `Xunbao/Panel/List/RuntimeTreasures` | `Xunbao/Panel/List/Item` 克隆 | 当前显示 1001/1002/1003 |
| 帮助、次数加号、奖励入口 | `Panel/Title/TitleName/btn_help`、`Panel/XunbaoBg/TimesBg/AddBtn`、`Panel/XunbaoBg/Btn_1` | 同路径 | 原始图片资源名：`未解析` |
| 属性与描述 | `Panel/DescBg/Bg/*`，由 `fabao.json` 渲染 | `Panel/DescBg/Bg/*` | 当前显示散瘟鞭、攻击/命中等文本；字体材质：`未解析` |

## 未解析项

- Cocos CSB 内部背景、粒子、Timeline 的原始图片/动画资源文件名：`未解析`。
- 左侧属性文字最终字体材质：`未解析`。
- 奖励弹窗及搜宝令背包边界的动态资源：`未解析`，待有效交互状态截图补齐。
