# 炼丹开发交接

- 2026-10-15 最新：已修复审查提出的3项P2和1项P3，涵盖缓存身份隔离、固定任务进度、配置整数边界与后台读取去重；完成定向编译、规则及实际入口验收。数据库新增可兼容补列的 `unity_alchemy.duration_ms`，无需打表；旧任务的原完成时间保留。证据及旧任务进度补齐限制见 `modules/DONGFU.md` 的“2026-10-15 审查问题修复”。隔离测试档已归档，用户存档和手调资源不变；用户已授权本轮验收后提交推送 `origin/main`。

- 最新续作：已接入已完成功能的洞府红点，炼器业务及红点继续留待后续。规则、后台读取、层级汇总和验证见 `modules/DONGFU.md` 的“2026-10-14 已完成功能红点接入”。2026-10-14 用户已授权将本轮红点代码、最新相关Prompt预制体及旧界面清理提交推送至 `origin/main`。本轮未改正式配置，保留最新手调布局；炼器预制体、独立资源、Bootstrap及境界Excel等无关改动继续保留在工作区。
- 使用独立Slot10完成实际收获、灵根升级、藏书激活、炼丹领取与主界面自动完工提醒验证后，测试档已归档至 `.local/dongfu-red-dots/retired-ui/Slot10`；Slot01字节不变。Editor已退出测试Play，保持用户编辑环境。最新状态以本条为准，勿恢复早期发放或旧夹具。

- 工程：`E:\neiwang_kapai\Game`；Unity `-projectPath`：`E:\neiwang_kapai\Game\unityclient`。发布分支 `main`，目标 `origin/main`；2026-10-14 用户已授权整理炼丹相关修改并提交推送。
- 发布范围：炼丹学习/制作/取消/离线计时/手动领取自动服用与超额折金币，丹方商店及材料入口，两类主角产速与上阵神将属性，正式Excel及导出链，道具堆叠，公共分组列表与藏书阁同步交互，炼丹及奖励弹窗必要资源。炼器预制体、头像、Bootstrap、境界Excel和独立资源改动保留在工作区；本次不发布炼器业务。图集配置只发布新增炼丹道具图标所属图集变化，独立图集/排除项不混入。
- 发布前定向检查：14张正式洞府表、1884条道具堆叠配置及41+5个拒绝回归通过；前后端编译、隔离制作/领取/学习/商店协议与此前公共列表回归已通过，用户确认最新界面实测通过。只检查发布差异，不重复启动或操作用户当前界面。用户现有存档及测试数据不随源码提交。
- 最终用户验收：用户明确“OK，我测试好了”，本轮反馈收口，停止重复UI操作，保持用户当前Play与页面。洞府内商店最新动态位置为(-50,38)。商城丹方页空白的追加根因是复用实例仍挂在OneLevelLayer下，被Canvas上的shop_bg遮住；商城入口现重新挂回Canvas，调用公共NormalizeShopLayerOrder(alchemyShopView)，保证商品在背景之上。99件商品已经收到，未改变配置或商品筛选。最新修复已编译通过，用户完成实测；证据 `.local/dongfu-alchemy-source/hub-missing-before.json`、`user-final-acceptance.json`。不再恢复或重放旧页面。
- 最新追加修复：Source丹方商店此前被识别为普通DongFu框架，隐藏了Bg、Panel_12/Bg并放到首个兄弟节点；现与炼丹房使用同一背景模式，商店置于背景之上。按用户“动态加载时切换”及最新位置要求，洞府商店根位置设置(-50,38)，商城入口恢复实例原位置(当前0,0)，共用shangcheng预制体不改。Source、材料入口、关闭返回与商城复用均已通过当前Slot01真实Raycast操作，最终保持Play在Source丹方商店。
- 同时查清Console五条PlayerLoop递归错误来自MCP同步截图工具ScreenshotUtility.cs:197的EditorApplication.Step，不是炼丹业务。保留原堆栈后改用工具已有的异步CaptureToProjectFolder；未修改MCP包，后续避免其同步截图路径。最新Console错误/警告均0，背景截图有效。证据 `.local/dongfu-alchemy-source/background-result.json`、`screenshot-recursion.json`、`background-console-final.json`、`final-preservation.json`；截图 `source-shop-background-fixed-offset.png`。最初黑色截图不作为画面证据。
- 本轮隔离Slot10已归档到 `.local/dongfu-alchemy-source/retired-ui/Slot10`。最终再次核对用户Slot01背包、金币、藏书阁和炼丹业务记录不变，三套最新洞府Prefab字节不变；未购买、学习、炼制、领取或服药。最终界面视觉仍由用户复测确认。
- 炼丹首版配置、代码、材料商店及公共弹窗已接入。完整规则、字段、默认价格与属性映射见 [DONGFU.md](modules/DONGFU.md) 的“2026-10-14 炼丹功能开发”。炼器业务、任务与洞府红点留待后续。
- 最新四项反馈：item/Text 在运行时隐藏，仅 SelectedRecipe 显示丹方名；进入炼丹房自动展开并滚动到主角当前境界，旧境界制作任务不改变左侧默认境界；最新 Popup/Source 绑定丹方商店，仅Source入口隐藏炼丹预制体，关闭恢复原选择/弹窗/滚动，材料入口保留炼丹根节点激活。
- 旧商店看不到炼气未学丹方的原因：用户Slot01实际境界是破虚（101），旧规则每系列只显示最高可用档。用户已明确改为“显示全部可学习的未学丹方”，服务端按境界使用等级筛选所有未学配方；未来境界与已学配方继续隐藏。前端商品ID排序支持超过255件，避免8位Grid序号回绕。
- 本轮只修改源码，不改Excel、JSON、Prefab及用户数据库。隔离协议已验证旧境界丹方购买、学习后隐藏、同系列高阶仍可购、未来/已学购买拒绝与重复请求；证据 `.local/dongfu-alchemy-source/protocol-result.json`。最高境界隔离Slot10用于真实UI回归，旧境界完成任务保留不领取。
- 真实UI回归通过：当前境界55自动展开并定位标题至视口顶端，旧炼气完成任务未干扰左侧；手动收起经定时同步后仍保持，重入重新定位；Source隐藏/关闭恢复原配方与弹窗/滚动；普通材料入口Alchemy根节点保持激活且商店在其上方。最高境界495件商品全部保留并按ID排序，无8位序号回绕，炼气灵动/磐石丹方存在；Console无错误。证据 `.local/dongfu-alchemy-source/ui-result.json`、`preservation.json`，截图 `source-popup-current-realm.png`。最终画面由用户复测确认，未自动提交推送。
- 最新用户规则已覆盖首版“领取入包再服用”：已学丹方显示 `丹方名(已服用次数/上限)`；领取直接自动服用至 `limit_count`，超额按 `item.jiage` 转金币，公共 ItemGet 显示真实服用数、累计新增属性和折金币。请求去重、原子回滚、金币上限保护和旧产速收益结算仍在服务端执行。
- 商城侧边“丹方商店”已补齐，固定入口位于 `Common/shop_bg.prefab/shopBg/Btn_ListView/Panel_Alchemy`，沿用 `shangcheng` 和当前最高境界档、已学隐藏规则。未进入炼丹房也能购买；商城、将魂商店、丹方商店切换与关闭经过真实 Raycast 输入验证。
- 用户的 item.xlsx 空行清理保留；核对1884条有效记录并同步994条已修改的出售价格（正式100、运行旧0），经正式 `AlchemyItems` 导出链更新995条关联道具。未修改Excel或直接修改生成JSON。
- 用户明确允许列表自动缩小：模板 BestFit 18～26，保留字体资源和全部布局；ItemGet 属性文字开启溢出显示，保留字号和几何。隔离 Slot10 实际验证 `48/50 + 5个产出 → 50/50、自动服用2、攻击+8、金币+300`；999/999列表字号自动收缩，弹窗三行完整显示。协议还覆盖全部服用、全部折金币、满包、写入失败回滚、重复领取、金币溢出保护及两种产速立即生效，用户Slot01始终未消费。
- 新证据 `.local/dongfu-auto-claim/`，截图 `unityclient/Captures/Editor/DongFuAlchemy/shop-hub-alchemy.png`、`auto-claim-final.png`；前后端编译通过、14表/1884叠加配置及41+5个拒绝回归通过，Console无错误。正式配置、其他Prefab及用户存档保护结果见本轮 preservation 证据；未提交推送。
- 本轮隔离 Slot10 已归档到 `.local/dongfu-auto-claim/retired-ui/Slot10`（包含数据库、WAL和日志），经数据库解锁及源档位不存在检查。归档遇到异步进程退出/锁定，已经改为终止错误、等待解锁、保留残留日志并完成归档，台账已关联解决证据。最终回到用户Slot01，Play停留“商城→丹方商店”；未领取用户成品，未购买或服药，背包、金币、藏书阁与炼丹业务记录保持原样。
- 正式 Excel：`unitydata/excel/item.xlsx`、`attr_type.xlsx`、`dongfu_config.xlsx`。境界使用等级引用用户现有 `jingjie_config.xlsx`，只导出不修改。JSON 经现有导出链生成，禁止手改。
- 同 ID 叠加使用 `item.max_stack`：普通丹药与丹方 99，旧渡劫系列 999。超出单格上限进入下一格；入包、整理、移动和背包显示已接入。服用上限独立存于 `dongfu_effect.limit_count`。
- 已验证：495条丹方与效果；15表两端一致；1884条正式叠加配置；42个临时配置拒绝用例及5个临时叠加拒绝用例；原生4项测试通过；最新服务端编译与实际协议回归通过。
- Unity 实际路线：隔离 Slot10 购买材料/丹方、背包学习、预览、批量取消返材、离线完成后领取 ItemGet、服用；隔离 Slot09 主角→背包显示99/2和999/2四格。全部通过 EventSystem/Raycast 输入，未调用内部业务方法完成操作。
- 邮件：炼丹溢出通过当前 SQLite 事务写入公共 `xin_shi`。真实附件、重复领取不重发、写入失败回滚与重试、公共邮件列表和附件领取均验证；不能以旧长连接接口返回成功代替邮件落库证据。
- 证据：`.local/dongfu-alchemy-development/`；失败与解决记录：`.local/unity-validation/dongfu-alchemy-operation-ledger.json`。本地测试夹具和日志不提交。
- 保留用户 Forge、Alchemy、Bootstrap、美术 meta 及其他本地改动；Slot01 的藏书阁预览数据不重置。只给 Alchemy 添加业务组件，不更改用户已确认的固定布局。
- 本轮创建的 Slot09、Slot10 已原样归档到 `.local/dongfu-alchemy-development/retired-fixtures/`，不再占用游戏存档位；Slot01 数据库 SHA256 与测试前一致。本轮 Play 和原生服务均已退出，Unity MCP 项目覆盖恢复为 `enabled=false`，用户原有 Editor 保留。
- 尚需用户实际 Play 确认最终画面与手感；此前用户预制体调整不重新审核。后续调整价格、配方、效果或叠加上限时修改正式 Excel，并执行对应导出与定向回归。当前阶段可收口，勿自动提交推送或启动炼器开发。

- 定向修复：炼丹错误复用洞府主页的框架模式，导致 `OneLevelLayer/Bg` 与 `Panel_12/Bg` 隐藏。新增炼丹模式，恢复两层背景并将炼丹内容置于背景之后；未修改任何 Prefab 或固定布局。框架切换、真实“洞府→炼丹房”入口、丹方选择、返回洞府及藏书阁显示已检查，Console 无错误。证据 `.local/dongfu-alchemy-development/background-result.json`；截图 `unityclient/Captures/Editor/alchemy-shared-background-20261014.png`。本项仅验证背景修复，不重新验收商店或炼丹业务。

- Workbench 无反馈定向修复：可见操作按钮保持可交互，点击时检查配方、同步状态、境界、学习状态、材料及数量上下限，通过公共 MessageBox 说明原因；未学习区域也可点击查看学习提示。材料不足不再静默钳制成1份，同步期间业务请求及材料商店也提供提示。保留服务端校验和请求去重，未修改 Prefab、Excel 或数据库夹具。
- 在用户当前 Slot01 实际点击验证：未选择时开始与四个数量按钮提示；选中未学习丹方、缺材料和数量下限提示；成品预览“炼气洗髓丹 / 攻击 +4”；材料图标进入商店并返回炼丹，背景保持正常。材料数量的5项边界回归通过（须在 Bootstrap 初始化后的 Play 运行），Console 无错误。证据 `.local/dongfu-alchemy-development/workbench-result.json`。
- 数据核对：Slot01 的藏书阁4表、炼丹4表、背包与金币均与重编译前备份一致，证据 `.local/dongfu-alchemy-development/workbench-data-check.json`；未学习、炼制、领取或购买。保留用户当前 Play 和本机服务，页面停留炼丹房供继续操作；Unity MCP 项目覆盖恢复为 `enabled=false`，未提交、未推送。

- 丹方分组交互：境界按钮可展开/再次点击收起；切换境界只展开当前分组。展开时 `HeaderBackground` 使用 `ui_btn_fuwuqi_xuanzhong`，收起或非当前分组恢复模板原 Sprite；显式收起不被2秒定时同步重置。`AlchemyScreen.realmSelectedSprite` 由 Prefab 引用正式 Sprite，模板布局和默认图不变。新增编辑器命令只绑定该引用，Prefab 本轮差异仅1行。实际点击展开、收起、等待同步、跨境界切换及重新选择丹方均通过，Console 无错误；证据 `.local/dongfu-alchemy-development/realm-toggle-result.json`。Slot01 的藏书阁、炼丹、背包与金币再次核对保持不变；保持 Play 在炼丹房，未提交推送。

- 上一条分组实现已抽为公共 `GroupedTemplateList`：炼丹和藏书阁统一使用，炼器 Prefab 预绑定同一组件。标题点击由组件自动切换，模块只处理当前分组ID/0对应的业务选择；数据初始化保留显式收起，加载禁用也使用公共入口。接入合同见 `modules/DONGFU.md` 的“共享分组列表交互”。旧 `AlchemyScreen.realmSelectedSprite` 已迁移到公共组件的 `selectedHeaderSprite`。
- 三套原有节点逐块对比保持不变，仅新增公共组件与 Screen 引用；绑定工具显式保留原有 RectTransform，防止 Unity 保存时重算藏书阁根坐标。真实炼丹/藏书阁展开、收起、选中图片切换与恢复通过，藏书阁仍为 `(-30,20)`；三套模板公共回归、加载状态回归通过，Console 无错误。证据 `.local/dongfu-alchemy-development/shared-groups-result.json`、`shared-group-prefab-check.json`。
- 验收中若发生脚本重载，当前 Play 的运行时服务和按钮回调可能丢失；不能把无响应误判成业务条件。记录检查点后重启当前 Play，从未完成路线继续；外部源代码变更需先导入，再等待编译结束，避免在 Play 中重复请求编译。本轮已续验藏书阁并保持 Play 在藏书阁供用户复测；Slot01 业务数据保留，未提交推送。

- 用户验收：2026-10-14 用户确认“我已测试，没问题”，本轮公共分组列表交互验收通过，阶段收口。炼丹房和藏书阁使用同一实现；炼器室已预绑定，炼器业务仍待后续开发。保留全部未提交修改，未获提交推送授权。

- 用户后续明确授权在当前 Slot01 补充炼丹全流程测试数据：已学习炼气洗髓/玄甲/长生/风行/悟性5个丹方（1、56、111、166、331）；千年人参/千年灵芝/血精草/千年虫草/清灵草各新增500；另给1本未学习的炼气灵动丹方11239，供背包学习测试。发放前完整SQLite备份和实际增量见 `.local/dongfu-alchemy-development/user-flow-grant-latest.json`，运行时同步证据 `user-flow-grant-runtime.json`。
- 本次授权只修改角色背包、学习记录和炼丹状态版本；原有道具数量、角色其他字段及其他存档表保持不变。不要因旧保护校验基线不一致而恢复发放前存档，也不要自动删除这些用户测试数据。已通过实际入口回到 Slot01 炼丹房，选中炼气洗髓丹方，未开始制作、未消费材料、未服药；保留 Play 供用户完成全流程验收。

- 用户更新炼丹进度条预制体后，代码倒计时改为写入 `Workbench/Progress/Value`，旧 `Working/Time` 如仍存在则清空文字。最新 LoadingBar 为水平 Filled，沿用其尺寸、Sprite、颜色和填充方向；Prefab 不修改。保留用户当前洗髓丹制作任务，验证时不自动领取或消耗额外材料。
- `Progress/Reset` 和 `Progress/Value` 互斥：制作中只显示 Value 倒计时；完成待领取只显示 Reset“炼制完成”；无制作任务时两者都隐藏，Progress 本身也隐藏。
- 用户确认清理旧通用配方表：已删除正式 `dongfu_config.xlsx` 中的 `dongfu_recipe` 工作表以及schema/导出/校验定义，通过正式导出链清理4份JSON和Unity meta。其他14个工作表与无关XLSX包内容逐字节保持，全部有效JSON导出内容不变；备份和证据位于 `.local/dongfu-recipe-retirement/`。服用上限字段为 `dongfu_effect.limit_count`，按 `limit_group` 累计；炼制数量上限是 `dongfu_alchemy_recipe.batch_limit`。
- 验证：隔离的最新 Prefab 显示检查覆盖制作中、完成、无任务三种状态；实际 Slot01 经旧忆→洞府→炼丹房进入，完成状态 Value 隐藏、Reset 显示“炼制完成”、进度为1、领取按钮可见，旧 Working/Time 文字为空，Console 无错误。Prefab SHA256 保持 `9C0CF66FAF38DA72F696A9E90A961EE261038172E1164AD112099458EA9EEC2A`；证据 `.local/dongfu-alchemy-development/alchemy-progress-mutual-result.json`。Play 停留炼丹房，成品未领取，未额外制作或修改背包。
