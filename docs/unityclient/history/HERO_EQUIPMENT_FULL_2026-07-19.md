# 神将、阵容、装备与法宝

> 2026-07-19 完成口径纠正：阵容旧 `visual-1to1-complete` 已撤销。Cocos 可达控件清单不完整、Unity 多个按钮无 Listener、自动化绕过真实点击；本文件旧 G4-G6 结果只保留为协议/截图历史证据，不再代表迁移完成。

## 范围

神将列表/详情、阵容位置、装备/法宝列表与增量、穿脱和装备强化。

## 装备/法宝 G0-G2 冻结与证据（2026-07-19）

### G0 范围冻结

| 项 | 冻结内容 |
|---|---|
| 模块 | `HeroEquip`，仅装备/法宝；神将/阵容只作为入口上下文 |
| 入口 | 神将详情 `EquipIcon1..6`：`1..4` 装备、`5..6` 法宝；独立背包入口 `tankuang2/btn_zhuangbei`、`tankuang2/btn_fabao` |
| 页面 | 神将详情装备槽、装备背包、法宝背包、装备/法宝更换列表、共享详情、装备强化页 |
| 弹窗 | `zhuangbeigenghuan`、`zhuangbeiInfo`；服务端失败使用旧 `Utils:ShowScrollTips` |
| 本批状态 | 空槽、空背包、列表、详情、未穿戴/已穿戴/替换/卸下、强化前后、材料不足、非法/重复操作、重拉、重连、切号清理 |
| 包含 | 装备穿戴/替换/卸下；装备单次强化及属性刷新；法宝列表/详情/穿戴/卸下 |
| 排除 | 装备精炼、觉醒、神铸、合成、分解、回收；法宝强化、炼化和完整培养；批量操作、复杂属性模型 |
| 允许数据变更 | 用户已授权隔离角色加入测试夹具：5 件装备、3 件法宝、6 组法宝碎片；装备强化请求 1 次，穿脱/替换后恢复未穿戴；禁止触碰默认 `userId=1` |
| 测试账号 | `userId=7200057`、`roleId=1000078`、`U00057`、神将 57 苏全忠；当前权威装备 5、法宝 3、碎片 6 组 |
| 视觉环境 | Windows DPI `96/100%`；Cocos/Unity 客户区原生 `1334×750`；禁止二次缩放 |
| 成功判定 | G1 所有冻结状态均有同账号有效 Cocos 图；G2 Lua 权威、协议字段、Transform/资源映射无猜测后才可进入 G3 |

当前状态：`g6-logic-complete-visual-fixing`。G0-G4 与 G6 逻辑/回归门禁已完成；G5 已恢复装备、法宝两张关键列表的双端对照，但原 18 张冻结 Cocos 图被旧 Runner 误删，详情、弹窗、失败态仍需重新取证和生成差异图，禁止标记 `visual-1to1-complete`。

### G1 当前 Cocos 调用链

```text
主界面装备背包
UImainLayer_new/tankuang2/btn_zhuangbei
  → MainUI:OnPetEquipButtonClick
  → Utils:OpenFunction(EMID_KAPAI_EQUIP_BAG=1110)
  → AppDef.moduleUI[1110] = PetEquip.PetEquipMainUI
  → PetEquipBagSubUI
  → csd/zhuangbeiyangcheng/zhuangbeibeibao.csb

主界面法宝背包
UImainLayer_new/tankuang2/btn_fabao
  → MainUI click callback
  → Utils:OpenFunction(EMID_KAPAI_FABAO_SYS=1180)
  → AppDef.moduleUI[1180] = FaBao.FaBaoMainUI
  → FaBaoSubBagUI
  → csd/zhuangbeiyangcheng/zhuangbeibeibao.csb

神将详情槽位
UImainLayer_new/ButtonGroup1/btn_zhenrong
  → MainUI:PetTouchCallback
  → Utils:OpenFunction(EMID_KAPAI_SHENJIANG=1030)
  → KaPaiPet.PetZhenRongUI
  → yingxiongListLayer.csb + yingxiongInfoLayer.csb
  → EquipIcon1..6/PosCallBack
  ├─ 空装备槽 + 有未穿戴同部位装备 → PetEquip.PetEquipChangeUI → zhuangbeigenghuan.csb
  ├─ 已穿装备 → PetEquip.EquipInfoUI → zhuangbeiInfo.csb
  ├─ 空法宝槽 + 有未穿戴法宝 → FaBao.PetFaBaoChangeUI → zhuangbeigenghuan.csb
  └─ 已穿法宝 → FaBao.FaBaoInfo → zhuangbeiInfo.csb

装备强化
EquipInfoUI/Info/qianghuashuxing/Btn_qianghua
  → Utils:OpenFunction(EMID_KAPAI_EQUIPSRENGTH=1120, {1, uid})
  → EquipCultivate.EquipCultivateMainUI → zhuangbeiyangcheng.csb
  → EquipCultivate.EquipStrongUpUI → zhuangbeiqianghua.csb
  → LuaNetSendMsg:SendEquipQiangHua(uid, type=0) → /319 op=4
```

网络链：`LuaNetCmd.MGS_PETEQUIP_BAG=319` → `LuaNetSendMsg` → `LuaNetRecvdMsg.DealMsgPetEquip` → `LRoleDataMgr.Pet` → UI 事件；服务端为 `protocol.h: PET_EQUIP_OPERATE=319` → `pack_deal.cpp: DealPetEquipOperate` → `CEquipManeger`。

关键资源语义：装备/法宝列表共用 `zhuangbeibeibao.csb`，更换共用 `zhuangbeigenghuan.csb`，详情共用 `zhuangbeiInfo.csb`；动态列表由 `cc.TableView` 和 `ItemList/Item1..2` 克隆；图标由 `ItemCellUI` 按配置 `pic` 加载 `item/<pic>.png`，并叠加品质框、强化/精炼等级、已穿戴标识。本批页面未发现必须播放的 Imod；培养深页 Imod/特效不在本批。

### G1 有效截图与缺口

| 状态 | Cocos 原生图 | SHA-256 | 结论 |
|---|---|---|---|
| 神将详情空装备/法宝槽 | `.local/ui-fidelity/HeroEquip/cocos/01-hero-detail.png` | `6CDABE151C16502E94F7274C2C600351046F9BC21597F6165538EF1DA64BD3B7` | 有效；账号、页面、尺寸一致 |
| 装备空背包 | `.local/ui-fidelity/HeroEquip/cocos/03-equipment-bag.png` | `F272C45EE4458A3227A264E3B5B66DDD05D195354E8308F0DC7AD86CCF63DA8A` | 有效；权威数量 `0/1000` |
| 法宝空背包 | `.local/ui-fidelity/HeroEquip/cocos/04-fabao-bag.png` | `8CDFE192DE4313BF69101B983465AF3B02437F3E8CDD4678716A6ADF325F8C46` | 有效；权威数量 `0/999` |
| 装备非空背包 | `.local/ui-fidelity/HeroEquip/cocos/05-equipment-bag-seeded.png` | `9FB57D97CD9728CB69269029395A3BF0C4AFE6D1AE0B0D90D0FADDE32EDAA633` | 2026-07-19 重采；5 件，含同部位青罗刃/素心刀 |
| 法宝非空背包 | `.local/ui-fidelity/HeroEquip/cocos/06-fabao-bag-seeded.png` | `E2041676AC29E9A3369CE7A6EE9421EBD695F7409745F65548B52FB5DA814661` | 有效；3 件 |
| 法宝碎片 | `.local/ui-fidelity/HeroEquip/cocos/07-fabao-fragments-seeded.png` | `0E2567341577EE17C89F14D58CE5EC233224EEE8DB089E728BCC3D8FCB3301E7` | 有效；`4701..4706` 各 10 |
| 穿戴后神将详情 | `.local/ui-fidelity/HeroEquip/cocos/08-hero-detail-equipped.png` | `5F24B030A66FB464B598D6EEAD1A77F83A34D0CDD73D8F4F9AA2A2AD9073E2E3` | 有效；素心刀 + 散瘟鞭 |
| 装备详情 | `.local/ui-fidelity/HeroEquip/cocos/09-equipment-detail.png` | `ABA86FE5AD2E8E84DBC6E9C18FDB9A6EA8CEEB7A555D9EF8D9FD7DF6C2DB182C` | 有效；共享详情、卸下/更换/培养入口 |
| 法宝详情 | `.local/ui-fidelity/HeroEquip/cocos/10-fabao-detail.png` | `C3253763E9CF0382E4B0B94169E0022320B53AD079DAF9AC9BF77B3D9EC9F649` | 有效；共享详情、卸下/更换入口 |
| 强化前 | `.local/ui-fidelity/HeroEquip/cocos/11-equipment-strength-before.png` | `693B74B7330577A10040DF656F959A89AD0A1FF3FEECF3A45FAAF2AB93144DAD` | 有效；等级 0、攻击 0、消耗 100 |
| 强化后 | `.local/ui-fidelity/HeroEquip/cocos/12-equipment-strength-after.png` | `AE38D10BDA521E5FFAEA2209708235CE70414A214320EB38B323F9CF0CCBC0FE` | 有效；一次请求暴击至 5 级、攻击 100，先收 `op16` 后收 `op4` |
| 同槽替换后 | `.local/ui-fidelity/HeroEquip/cocos/13-hero-detail-replaced.png` | `86F087174BA10491810D2C2D59055D46A588EEACDD9B06656FB329CB69DB6B5A` | 有效；青罗刃 + 捆龙索，战力/属性刷新 |
| 装备更换弹窗 | `.local/ui-fidelity/HeroEquip/cocos/14-equipment-change-popup.png` | `E31A8A4943BD45E3AAC230D5007EB475DB87B43472CB1224E2ED9E5B9B37816E` | 有效；同部位两件装备、强化角标、穿戴按钮 |
| 法宝更换弹窗 | `.local/ui-fidelity/HeroEquip/cocos/15-fabao-change-popup.png` | `82C7351B00E4F016D9771A868287D051E51DDA9CB5F6E965705802B1BA116271` | 有效；3 件法宝、穿戴按钮 |
| 材料不足 | `.local/ui-fidelity/HeroEquip/cocos/17-equipment-material-insufficient.png` | `43AB0CFA8ABF0560DD1C2790E94B9644F067E3AD477AF171DD6C730991AE6B96` | 有效；金币 0，真实强化按钮回调显示“您的金币不足！” |
| 非法 UID | `.local/ui-fidelity/HeroEquip/cocos/18-illegal-uid.png` | `78715B5953A29A0294492284DCAE9E518448F4E7FE4BF64A607C1DE5533B6339` | 有效；`op2 uid=0xffffffff` 显示“参数错误” |
| 重复操作 | `.local/ui-fidelity/HeroEquip/cocos/19-repeat-operation.png` | `B8D01AD589CB8848DFCE30941C942345CF2E098A6103D7683C8406A3D40AC150` | 有效；重复法宝卸下显示“已经装备” |
| 全部卸下并重连 | `.local/ui-fidelity/HeroEquip/cocos/20-hero-detail-after-takeoff.png` | `03405648A388DF5F0A790BEEFC9AE02C4081F373ABAC7332D78669E09ACC7361` | 有效；角色仍持有夹具但 6 个槽全部为空 |

以上图片均为 `1334×750`、Windows `100%`。槽位/页签后台消息点击首次未进入目标页，已按 SOP 停止坐标尝试；无效重复帧已删除。碎片页使用既有 `sub=2` 初始化参数，详情/强化使用旧 Lua 原调用参数直达，临时取证配置已恢复且源码无残留差异。

夹具与动态协议证据：`PRO_INTERACT/13 op53` 走正常管理器新增装备/法宝并产生 `/319 op6/op22`；`op50` 新增碎片。首次为装备/法宝 `0/0`，注入后为 `5/3`；独立重连仍为 `5/3`，碎片 `4701..4706` 各 10。装备/法宝 UID 分别为 `2120843265..3269`、`2120843265..3267`。`op2/op18` 穿戴与同槽替换成功；装备重复穿戴/重复卸下为幂等成功，法宝重复穿戴/重复卸下返回“已经装备”；非法 UID 返回“参数错误”。`op3/op19` 卸下后再次重连确认全部 `fpos/wpos=0`。装备 `1001` 单次 `op4 type=0` 因暴击从强化 0 到 5，且 `op16` 完整记录先于 `op4` 成功回包；最终夹具保持 5 件装备、3 件法宝、6 组碎片，全部未穿戴。

G1 结论：通过。失败态取证期间临时关闭本地登录补币并使用数据库操作前镜像回滚；取证结束后源码、服务端 EXE、角色金币、装备强化、任务/材料状态全部恢复。最终独立重连确认装备 5、法宝 3、碎片 6 组，装备 `1001` 强化 5，全部 `fpos/wpos=0`。临时备份表已删除。

### G2 Lua 权威与 Bridge 边界

| 旧 Lua | 权威职责 | G3 保留方式/所需兼容 API |
|---|---|---|
| `Data/LPetData.lua` | `LPetEquipInfo/Bag`、`LPetFaBaoInfo/Bag` 数据结构 | 原样保留；Bridge 只读字段并转成渲染 DTO |
| `Data/LRoleDataMgr.lua` | `equipList/faBaoList` 生命周期、筛选、未穿戴判断、切号 `Reset` | 修正/验证 Reset 后继续作为角色态唯一权威；C# 镜像必须随切号清空 |
| `NetWork/LuaNetSendMsg.lua` | `/319` 写包字段顺序 | 原样复用 `QueryPetEquip/SendPetEquipWearReq/SendEquipQiangHua/SendFaBaoList/TakeOn/TakeOff` |
| `NetWork/LuaNetRecvdMsg.lua` | 分包列表、增量、穿脱/替换、强化更新、失败提示 | 原样复用 `DealMsgPetEquip/ReadPetEquipData/ReadPetFaBaoData`；先更新 Lua，再通知 Bridge 渲染 |
| `KaPaiPet/PetZhenRongUI.lua` | 槽位 1..6、当前阵位、入口与刷新事件 | 保留业务判断；Unity 兼容 `InitUI/OpenFunction/SendMsg` 和节点绑定 |
| `PetEquip/*.lua`、`FaBao/*.lua` | 列表排序、详情、穿脱/替换操作 | 保留；直接 `cc/ccui/TableView` 调用由通用渲染 Bridge 适配 |
| `EquipCultivate/EquipStrongUpUI.lua` | 单次强化请求、成本/前后属性展示 | 仅保留强化 Tab；精炼/觉醒/神铸入口禁用但不删除旧逻辑 |
| `ConfigData`/`JsonConfig` | `equip/fabao/equip_qianghua` 配置解释与资源名 | 继续由 Lua/统一 ConfigService 读取；C# 不重算属性和成本 |

权威源：服务端持久化数据 → `/319` → `LRoleDataMgr.Pet.equipList/faBaoList`。Unity C# 只能保存当前帧渲染镜像；不得以现有 `HeroEquipmentStore/FaBaoStore` 判断替换、槽位、材料、强化结果。现有 `HeroEquipmentPresenter` 把装备/法宝混成单列表、写 `UID` 占位文案并隐藏全部培养按钮，和冻结页面不一致，G3 必须改为 Lua 驱动真实页面，但本轮不编码。

### G2 `/319` 本批 op/字段映射

| op | 方向 | 字段/语义 | Lua 权威更新 |
|---:|---|---|---|
| 1 | C→S/S→C | 请求仅 `op`；回包 `total:u16`，非空再带 `packetCount:u8, packetIndex:u8, itemCount:u8, records` | 重建 `m_petEquips` 与 `m_formationEquips[fpos][part]` |
| 2 | C→S/S→C | 请求 `fpos:u8, uid:u32`；回包回显后 `success:u8, msg:string?`；同槽自动替换 | 成功后迁移原装备、被替换装备和目标槽 |
| 3 | C→S/S→C | 请求 `fpos:u8, uid:u32`；响应同 op2 | 清槽、`m_fpos=0` |
| 4 | C→S/S→C | 请求 `uid:u32, type:u8`，本批固定 `type=0`；成功返回 `success, crit:u8, addLevel:u16, attrs` | 服务端先推 op16 完整记录，再回 op4；Lua 以 op16 为最终等级/属性权威 |
| 6 | S→C | 新增装备完整记录 | `m_petEquips[uid]` 增量、背包数 +1 |
| 16 | S→C | 装备完整记录更新 | 覆盖同 uid；强化属性刷新关键推送 |
| 17 | C→S/S→C | 法宝列表，分包头同 op1；记录多 `wpos:u8`，培养等级为 `u8` | 重建 `m_petFaBaos` 与 `m_formationFaBaos[fpos][5/6]` |
| 18 | C→S/S→C | 请求 `uid:u32, fpos:u8, wpos:u8`；响应 `uid,fpos,wpos,success,replaceUid,msg?` | 设置新法宝，`replaceUid` 回包法宝归零 |
| 19 | C→S/S→C | 请求 `uid:u32`；响应 `uid,success,msg?` | 清 `m_fpos/m_wpos` 与阵位槽 |
| 22 | S→C | 法宝完整记录更新/新增 | Upsert 法宝并重建已穿戴映射 |

装备记录：`uid:u32, templateId:u16, fpos:u8, jlExp:u32, cultivateCount:u8, (type:u8,level:u16)*, baseAttrType:u16,baseAttrValue:u32, 4组培养属性`。法宝记录：`uid:u32,templateId:u16,fpos:u8,wpos:u8,qhExp:u32,cultivateCount:u8,(type:u8,level:u8)*`。

### G2 Cocos 节点 ↔ Unity Transform 映射

| 语义 | Cocos 路径 | Unity Transform/Prefab | 关键布局/交互 |
|---|---|---|---|
| 神将详情槽 | `yingxiongInfoLayer/EquipUI/Bg/bg/EquipIcon1..6` | `yingxiongInfoLayer/Layer/EquipUI/Bg/bg/EquipIcon1..6` | 1..4 装备、5..6 法宝；点击委托 Lua `PosCallBack` |
| 背包根 | `zhuangbeibeibao/zhuangbeibeibaoUI` | `zhuangbeibeibao/Layer/zhuangbeibeibaoUI` | 共享装备/法宝 Prefab；父级标题/Tab 由 FirstClassLayer 提供 |
| 背包列表 | `.../TableView` | `.../TableView` | `1005×508`；动态 `VirtualList/cc.TableView` |
| 行模板 | `.../ItemList/Item1..2` | `.../ItemList/Item1..2` | 行高 `142`，每行 2 件；不得合并装备与法宝数据源 |
| 列表字段 | `Item/Icon,Name_1,Name_2,Atrribute_1,Atrribute_2,yichuandai,Btn_yangcheng` | 同名 Transform | 真实图标、名称、穿戴神将、属性、已穿戴条、养成入口 |
| 空态/数量 | `.../Point/txt`, `.../Number` | 同名 Transform | 装备和法宝各自旧文案与容量，禁止改成合并计数 |
| 更换弹窗 | `zhuangbeigenghuan/Popup` | `zhuangbeigenghuan/Layer/Popup` | `1080×500`；遮罩 `2000×1500`；标题、关闭、隐藏已穿戴、列表 |
| 更换列表 | `Popup/TableView` + 根 `ItemList` | 同名 Transform | 仅展示兼容部位/未穿戴项；选择即发穿戴，服务端决定替换 |
| 详情根 | `zhuangbeiInfo/zhuangbeiInfoUI` | `zhuangbeiInfo/Layer/zhuangbeiInfoUI` | 共享装备/法宝详情；Mask、Popup、关闭 |
| 详情左栏 | `.../zhuangbei/Node,Namebg/Name,Btn_genghuan,Btn_xiexia` | `.../zhuangbei/Bg/Image,Namebg/Name,Btn_genghuan,Btn_xiexia` | 图标/品质、名称；按穿戴态二选一显示按钮 |
| 详情属性 | `.../Info/ListView/{jichushuxing,qianghuashuxing,jinglianshuxing,juexingshuxing,shenzhushuxing,zhuangbeimiaoshu}` | 同名 Transform | 本批装备显示基础+强化；法宝只读基础/已有等级；排除项隐藏但不重排错位 |
| 强化主页面 | `zhuangbeiyangcheng/zhuangbeiyangchengUI` | `zhuangbeiyangcheng/Layer/zhuangbeiyangchengUI` | 保留真实左侧装备选择与强化 Tab；其他培养 Tab 禁用 |
| 单次强化面板 | `zhuangbeiqianghua/zhuangbeiqianghuaUI/qianghua` | 对应 Prefab/Transform | `ListView/Panel_1` 前后属性、`qianghuaxiaohao/ConsumeBg/Value`、`qianghuaBtn`；五次按钮不在本批 |

字体、颜色、锚点、裁剪以导入 Prefab 原值为准；运行时只改文本、图片、显隐和列表实例。当前映射是静态路径确认，尚需 G1 非空状态截图校正实际字体、动态节点、按钮态和稳定帧。

## 装备/法宝 G3-G6 实施与验收（2026-07-19）

### G3 实现

- `LegacyEquipmentModel.lua.txt + EquipmentController.lua.txt` 成为 `/319` 装备/法宝角色态权威；所有列表、增量、穿脱、强化先更新 Lua，再发布 `HeroEquipmentStore/FaBaoStore` 渲染镜像。
- `Bootstrap.OnPacket` 对共享 `/319` 仅读取一次 `op`，再路由装备/法宝或寻宝 Controller；断线、返回登录、切号同步清 Lua 与 C# 角色态。
- 接入旧 `equip_dat.lua`、`fabao_dat.lua`、`equip_qianghua_dat.lua` 的机械转换配置；C# 不解释协议业务结果，只做配置查询、资源加载、Transform 显隐和列表渲染。
- 挂接 `zhuangbeibeibao/zhuangbeigenghuan/zhuangbeiInfo/zhuangbeiyangcheng/zhuangbeiqianghua`；列表每行两件，装备/法宝独立数据源，详情、更换、穿脱和单次强化可操作；精炼、觉醒、神铸、法宝培养、批量按钮保持隐藏/禁用。
- 新增 `FaBaoIcons/<pic>` 独立资源域，直接导入旧 `res/item/<pic>.png`，避免与普通道具同名覆盖；共 53 张配置法宝图全部存在。

### G4 结果

| 场景 | 结果 |
|---|---|
| 装备/法宝列表与增量 | 固定角色重拉为装备 5、法宝 3；真实配置名、属性、图标缺失数 0 |
| 装备穿戴→强化→卸下 | `/319 op2 → op4/op16 → op3` 通过；本轮强化 `5→7`，最终恢复未穿戴 |
| 法宝穿戴→卸下 | `/319 op18 → op19` 通过，阵位 1/槽 5，最终恢复未穿戴 |
| 非法/重复操作 | `uid=0xffffffff` 返回“参数错误”；重复法宝操作返回“已经装备” |
| 材料不足 | 旧 Lua 同语义客户端预检将金币镜像置 0，强化等级保持 7，提示“您的金币不足！” |
| 重拉/重连/切号 | 同角色新进程重拉保持 5/3；设置切号后网络断开，Lua/C# 装备、法宝、pending 状态均清空并回登录页 |

### G5 当前证据

| 状态 | Cocos | Unity | RGB MAE | 变化像素比（阈值 8） |
|---|---|---|---:|---:|
| 装备背包 5 件 | `.local/ui-fidelity/HeroEquip/cocos/05-equipment-bag-seeded.png` | `.local/ui-fidelity/HeroEquip/unity/05-equipment-bag-seeded.png` | 9.0451 | 0.168533 |
| 法宝背包 3 件 | `.local/ui-fidelity/HeroEquip/cocos/06-fabao-bag-seeded.png` | `.local/ui-fidelity/HeroEquip/unity/06-fabao-bag-seeded.png` | 7.4068 | 0.134950 |

并排、50% 叠加、增强差异图与 JSON 指标位于 `.local/ui-fidelity/HeroEquip/compare/`。已修复标题、右侧“装备/法宝/碎片”页签、默认勾选、真实名称/属性、法宝错误钱袋图和图标越界。

旧 `Run-UnityModuleValidation.ps1` 把 Manifest 的 `screenshots` 当运行产物先删除；此前误将冻结 Cocos 基准放入该字段，导致 18 张图被清空。Manifest 已改为只登记 Runner 产物 `build/ui-migration/bootstrap-hero.png`，冻结基准只放 `visualFidelity.cocosScreenshots`。当前仅重新采集两张列表图；其余原 SHA-256 只保留历史校验信息，不作为现存文件证据。

### G6 结果

- 主 Runner：`COMPLETE`，装备穿戴/强化/卸下、法宝穿脱、非法 UID、重复操作、最终列表重拉通过。
- 独立材料不足 Runner：`COMPLETE: /319 op=4 material insufficient rejected; ... strength unchanged=7; reason=您的金币不足！`。
- Python UI migration：`16/16`。
- Bootstrap 连续两次生成 SHA-256 一致：`9AC1A77AEC1F9ED405C6DE7E0C9B90F56799C59CBE60404599F1CA33234393AC`。
- Unity 严重异常扫描为 0；Runner 截图为 `1334×750`；Bootstrap、登录入口、返回栈和切号清理均可重复执行。
- G6 逻辑门禁完成，但依据 SOP，G5 冻结状态证据未全部恢复前，模块总状态保持 `g6-logic-complete-visual-fixing`。

## 三方证据

- 神将：`/24 op=1`。
- 阵容：`/48 op=1/op=4`。
- 装备/法宝：`/319 op=1/17` 列表、`op=16/22` 增量。

## 实现

- 阵容试点已改为 `Hero/LegacyFormationModel.lua.txt` 保存神将、阵法、展示阵位、战斗阵位和当前选择的权威状态；方法名沿用旧 `LCPet/LCFormation`。
- `HeroController.lua.txt` 复用旧 `LuaNetSendMsg/LuaNetRecvdMsg` 的 `/24、/48` 请求与解析语义，先更新 Lua 模型，再同步 C# 渲染镜像。
- `HeroStore + FormationStore` 暂时只作为现有 `HeroPresenter` 的渲染镜像，不再作为阵容业务权威源；后续通用 Lua UI Bridge 成熟后再移除模块专属镜像。
- `HeroEquipmentStore + FaBaoStore` 处理分包列表与增量。
- `EquipmentCatalog` 读取 `equip.json/fabao.json`。
- Presenter 复用真实神将、装备背包和详情 Prefab。
- 同步 44 张 `petequip_*.png`，资源走 ResourceService。

## 已验证

- 主界面 `btn_zhenrong` 与 `btn_shenjiangbeibao` 分别绑定阵容、神将背包，不再共用错误入口。
- 阵容复用 `yingxiongListLayer + yingxiongInfoLayer`，神将复用 `yingxiongbeibao` 五列卡牌列表；两者挂载 `OneLevelLayer` 公共背景、标题和返回按钮。
- `HeroCatalog` 从 Cocos `hero_dat.lua` 对齐神将 ID、模型/半身像编号和品质；列表与背包加载 `Resources/MonsterBust` 的真实头像/半身像，并显示等级、星级和上阵标识。
- 阵容中央严格复用 Cocos `Utils:CreateAnimModel(AWRD_ITEM_PET, petId, nil, true) → PlayStand(1)`：Unity 从 `Monster/btm{pic}_zd` 加载 Imod，挂到原 `BaseImage/Node`、继承节点 `0.8` 缩放并循环动作 1；资源缺失时才退回静态半身像。
- `local_test` 的 `/88` 零正文公告响应按“无公告”处理，不再在进入主界面后触发 `Packet body underflow` 并把应用切到 Failed。
- 单神将列表、详情和阵位 `1→2→1` 恢复。
- 阵容 `/48 op=4` 只支持上阵/替换，不伪造空卸下。
- 隔离角色装备穿戴、强化 `0→2`、卸下。
- 法宝穿戴到阵位/槽位后卸下。
- 装备、法宝各 1 件，缺图 `0`。
- 2026-07-18：阵容与神将背包分别以 `-projectXHeroValidation`、`-projectXHeroBagValidation` 重验，Unity 均 `exit=0`；阵容中央 Imod 站立动作、背包真实单卡、`/24 → /48`、入口与截图通过，严重异常 0。证据：`build/ui-migration/bootstrap-hero.png`、`bootstrap-hero-bag.png`。
- 2026-07-18 Lua 回归试点：`btn_zhenrong → HeroController → LegacyFormationModel → /24 → /48`，隔离 `userId=7200056`；神将 `57` 完成阵位 `1→2→1` 并由服务端快照确认，Lua 权威状态与 C# 渲染镜像一致。`Run-UnityModuleValidation.ps1 -Module Hero -NoStartServices -KeepServices`、16/16 Python UI 测试、编译和严重异常扫描通过；截图无错误弹窗。
- 阵位变更会伴随旧任务代际的 `/37` 未请求推送；旧 Cocos `DealMsgTaskInfo` 对未知代际 op 静默忽略，Unity 已仅在没有待处理任务请求时保持同一兼容边界，避免错误弹窗覆盖阵容。

## 视觉门禁

- 旧 `.local/cocos-formation-compare.png` 实际为“游戏公告”空框，不是阵容基准，已排除，不得作为视觉通过证据。
- 最终基准固定 Windows `100%` 显示缩放、原生 `1334×750`；旧 `150%` 下实际 `889×500` 再放大的截图全部降级为历史参考。
- 固定账号 `userId=7200057`、角色 `1000078/U00057`、神将 57 苏全忠。有效 Cocos 基准覆盖阵容首页、神将背包、布阵弹窗、换阵后和恢复后五个状态。
- 对应 Unity 图、并排图、50% 叠加图、差异图、SHA-256 和全帧指标位于 `.local/ui-fidelity/Hero/unity/`、`.local/ui-fidelity/Hero/compare/`。五组 RGB MAE 分别为 `5.153 / 4.259 / 13.190 / 13.015 / 12.983`；指标包含同一 Imod 的不同动画帧、字体采样和 Cocos 实时跑马灯，不单独作为通过判定。
- 已修复：三货币公共层、5 个阵容槽、真实头像/品质框/技能图和技能文本、中央与弹窗 Imod、神将/碎片页签、阵法图标/属性/消耗/材料、弹窗标题/遮罩、截断重叠、红点和占位文图。
- 逻辑门禁：`/24 → /48`、阵位 `1→2→1`、回包后重拉权威快照、独立 Unity 进程重连持久化、非法 `hero=65535` 拒绝且阵位不变均通过；日志为 `unity-hero-validation.log`、`unity-hero-bag-validation.log`、`unity-formation-popup-validation.log`、`unity-formation-invalid-validation.log`。
- 换阵后与恢复后均已取得 Cocos/Unity 同路径原生对照。此前所谓登录循环是把追加日志跨进程记录和启动早期截图误判为单进程循环；正确做法是等待 `40-45` 秒稳定帧并以客户区 `PrintWindow flags=2` 捕获。
- 换阵补证修复：`HeroPresenter.ItemCount` 恢复为神将实际数量；`FormationPopupPresenter` 按首个非零战斗阵位和阵法网格映射挂载 Imod，换到位置 2 后模型不再消失。
- G6：`Run-UnityModuleValidation.ps1 -Module Hero -UserId 7200057 -NoStartServices -KeepServices -SkipPythonTests` 通过并恢复 `1→2→1`；16/16 Python UI 通过；Bootstrap 两次 SHA-256 一致为 `2041B981D9A85C45A8080447E8D92CAB282C2D8C3E8C6BD8E51752C038A1031C`；严重异常 0。状态升级为 `visual-1to1-complete`。

## 遗留

- 当前完成“Lua 权威业务状态 + C# 渲染镜像”试点；`HeroPresenter` 的节点绑定、VirtualList 和 Imod 保持为 Unity 平台渲染适配，不回收为业务权威。
- 允许把本流程推广到一个相邻模块试行，首选装备/法宝；禁止多模块并行或批量 C#→Lua 重写。
- 神将培养/进阶/技能/图鉴。
- 法宝强化/炼化、装备精炼/觉醒/神铸、合成、分解、回收、完整属性模型。

## 阵容逐控件重新审计（2026-07-19）

- 产品归属已改为从《道友来封神》当前 `MainUI` 构建静态闭包，禁止再把全仓旧 Lua 当作当前功能。
- 机器矩阵：`docs/unityclient/matrices/HERO_CONTROLS.json`。
- 阵容登记 16 项，按新迁移完整标准完成 `0/16`。
- Unity 仅找到公共关闭、已占用阵位选择、布阵入口 3 个 Listener；三项都缺完整真实入口、异常、重连、自动和人工证据，状态仍非 complete。
- 空/锁定阵位、空位上阵、养成、强化大师、替换、装备槽 1-4、法宝槽 1-2、详细属性均缺 Listener 或完整子流程。
- 本节结论覆盖上文所有旧 `visual-1to1-complete`/G6 描述；旧记录只作历史证据。
