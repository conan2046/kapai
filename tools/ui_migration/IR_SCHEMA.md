# UI Migration IR v1

`schemaVersion: 1` 是 Unity 导入器和当前迁移工具之间的冻结契约。v1 只允许增加可选字段；删除字段、重命名字段或改变字段含义必须提升主版本。

## 顶层字段

| 字段 | 说明 |
|---|---|
| `schemaVersion` | 固定为 `1` |
| `kind` | `CocosStudioUI` 或 `CocosStudioBinaryUI` |
| `source` | 原始文件、格式、Cocos Studio版本与保真度 |
| `coordinateSystem` | 原始Cocos坐标约定 |
| `root` | UI节点树 |
| `animation` | 原始Timeline；CSB兜底当前提供动画摘要 |
| `resources` | 扁平化资源引用，保留节点路径 |
| `statistics` | 节点、资源和不支持类型统计 |

## 节点字段

| 字段 | 说明 |
|---|---|
| `nodePath` | 从根节点开始的稳定层级路径 |
| `name` | Cocos节点名 |
| `sourceType` | Cocos Studio控件类型 |
| `attributes` | 原始节点属性，不做破坏性重命名 |
| `properties` | `Size/Position/AnchorPoint/Scale/CColor`等原始子元素 |
| `resources` | 当前节点直接引用的资源 |
| `unityComponentHints` | 后续Unity组件建议，不代表已生成组件 |
| `unityRect` | 按 `cocos-bottom-left-v1` 规则得到的RectTransform建议值 |
| `children` | 子节点数组 |

## 坐标规则 `cocos-bottom-left-v1`

- Unity锚点基准先统一为左下角，避免静态布局发生二次换算误差。
- Cocos `AnchorPoint` 映射为 Unity `pivot`。
- 非百分比位置直接映射到 `anchoredPosition`。
- 启用百分比位置的轴使用 `PrePosition` 作为锚点，该轴 `anchoredPosition` 归零。
- `Size` 映射到 `sizeDelta`，`Scale` 映射到 `localScale`。
- Cocos旋转方向映射为 Unity Z轴反号；最终由基准界面视觉验收确认。
- Stretch、百分比尺寸和Widget边缘约束仍完整保留在原始属性中，Unity导入器必须优先读取原始约束，不得只依赖建议值。

## 资源选源

`asset-manifest.json` 是资源唯一来源契约：

1. 图集优先选择覆盖最多CSD请求帧的版本。
2. 普通资源优先级为运行客户端、Cocos Studio源资源、编辑器导出资源。
3. 内容相同的副本通过SHA-256折叠。
4. 不删除原始资源，只在迁移清单中指定唯一选中版本。

JSON Schema见 `ui-ir.schema.json`。
