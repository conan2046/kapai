# 神将流派数据化续接（2026-10-16）

## 结论与授权

2026-10-19 r88：用户明确授权“允许将C1作为已知编辑器问题继续记录，先合入功能分支”。本次按调整后的合入条件将codex/hero-affix-data-driven合入main；C1继续未关闭，但不再阻塞本次合入，不宣称已定位或修复。C2–C6及r86两项P2修复的既有验证保持原适用范围，不重跑已通过战斗池或人工画面验收。E其他94项脏文件、玩家存档、最新Prefab及.meta独立保留；未授权子代理。

本文件为阶段续接入口；长期实施事实和证据以 `HERO_AFFIX_INTEGRATION.md` 为准，避免另外维护状态表。

## 当前检查点（2026-10-19 r88，获准保留C1并合入main）

- 已完成：r87确认main可快进至功能分支；r88重新核对并备份E的217项脏文件、真实索引与Slot10，重新检查104原玩家文件、91保护、1240份最新Prefab/meta、171原生源码、155原版逻辑、318冻结正式输入及二进制。
- 当前工作：仅发布本次功能分支及合入授权记录，通过已适配文件准备索引后执行快进，保留E文件原字节；不整树暂存，不写Unity资源或运行Unity。实际提交、远端结果与保护报告见D实施树.local/hero-affix-merge-r88。
- 剩余：C1历史异常强制域重载的精确触发文件/调用者仍未知，继续作为已知编辑器问题追踪；无复发不等于根因关闭。独立物理Esc尚无实测、远端没有CI检查记录均为如实披露的测试范围，不新增合入门槛。
- 验收：merge_ready=true仅指用户批准的本次调整条件；original_C1_root_cause_closed=false。不扩大467适用项批准、r75参考模型或r84画面批准范围。

## r86历史检查点（审查两项P2定向修复，合入结论由r88覆盖）

- 已按用户授权修复两项P2，D/E仅同步5份生产文件：选择Store、App.HeroBuild、BuildController.lua、策略View和Navigation。原43/44协议、原生源码、正式表、Prefab/meta均不变。新增D盘独立回归工程直接编译生产Store，不启动Unity或访问数据库。
- 迟到回包：保留按英雄和发送顺序排列的请求token/操作类型；超时只取消当前等待，不删除待回包位置。旧回包仅排空旧请求，不改新请求、已保存选择、错误或通知；发送失败单独移除未发送项，断线清空队列；过期错误不弹Toast。7组生产源码回归及MCP独立Lua协议/错误提示回归通过。真实Slot10→神将→苏全忠→流派策略查询成功，返回当前用户保存的A/控制（1/3），未点击保存。
- 返回：新弹窗公开TryHandleBack，全局HandleBack优先消费。真实Raycast返回入口验证第一次只关策略弹窗并保留神将页，第二次正常退出神将页。GameView.SendEvent及QueueGameViewInputEvent虽报告投递，但均未产生可观测Esc关闭，不计键盘实测；原始证据保留，未用内部HandleBack调用冒充真实输入。Esc仍走已验证的同一全局HandleBack路径，物理键独立验收未覆盖。
- E编译通过、Console错误0；全程仅MCP操作现有E工程，因源码修复退出/重进一次Play，未重启Editor。未二次Setup、不改存档夹具、不回滚正常离线到账/召唤消耗奖励。最终保留Slot10苏全忠详情、策略弹窗关闭；项目MCP覆盖恢复false，用户Editor/8081服务保留。保护结果见.local/hero-affix-review-fix-r86/preservation.json。
- 原122项已在5b86b135提交推送；本轮5生产+2回归文件+2文档增量已获用户明确授权，随本次提交发布至origin/codex/hero-affix-data-driven，未启用子代理。审查两项技术修复不替代新的用户画面确认，也不扩大r84批准范围。C1历史重载精确触发文件/调用者仍开放，整体仍不可合并；不重跑99批/表作者或此前已通过的召唤验收。

## r85历史检查点（原C5最终合并审计）

- C5完成：最终122项变更及全部main-adaptation阶段/r76–r84直接修改已逐文件汇总。D实施补丁和E候选补丁使用独立索引生成，未改真实暂存区；E其他94项脏文件排除。原104玩家文件、91保护、全部最新Prefab/meta、171当前原生源码、155原版逻辑（仅既有回归入口hook按原合同剥离核对）、冻结二进制/318正式输入及Slot10完整性通过，写锁可取得且审计未改数据库。证据final-r85-preservation.json、final-change-inventory-r85.md/json。
- E的suit.xlsx当前包装/打印/自定义属性和关系ID不同，全部非空单元格类型/值/公式/实际工作表映射一致，保留E文件，不冒称字节相同。D/E177正式输入内容一致。完整候选diff --check退出2，仅17份原有Unity meta的51项默认空字段尾空格；保持原字节，非meta检查退出0、无未解释项/索引冲突。初次比较器失败证据保留。
- C1取证已定点复核r72/r75/r84及当前日志。主动公共API请求能追到RefreshUnity.cs:62，但异常Assetdatabase编译相关文件变更没有同时期文件路径、写入者或调用栈，不能把已知主动调用当异常根因，不能用无复发或mtime关闭。历史USN已被拒绝，本轮未重试；未加锁或重启。证据c1-historical-reload-r85.json，台账editor-forced-domain-reload-recurrence-r72仍开放。
- 当前环境：窗口cwd在C盘2605，实施树D盘6513，目标E盘。进程复核确认实际Editor -projectPath为E盘unityclient、Slot10原生进程仍在，用户运行状态保留；项目MCP覆盖仍false，本轮未操作Unity或启动服务。不二次Setup、不回滚正常消耗奖励，不重跑99批/表作者/召唤，不提交/推送/子代理。
- 下次只追C1精确归因；完整审查补丁为implementation-r85.patch/main-candidate-r85.patch，位于D实施树.local/hero-affix-integration。E候选保留重叠路径的既有编辑，不能整树暂存。证据不足仍保留acceptance_passed/merge_ready=false；后续工作树或玩家状态变化再定向更新C5时点报告。

## r84历史检查点（已由r85续接）

当前任务记录已达32.84MiB，超过AGENTS的20MiB上限，停止新增验证并收口，须新任务续接。用户已授权继续六项，唯一状态表在HERO_AFFIX_INTEGRATION.md顶部C1–C6：C2实际十连及重复转化完成；C3用户批准本轮工程性能门槛且通过；C4汇总口径完成；C6用户最终实际Play画面确认通过，证据user-real-play-acceptance-r84.json；C1历史重载精确归因未关闭；C5最终完整合并检查未完成。未授权提交/推送/子代理。

- r84十连发现并修复：继续按钮未绑定券图标/数量；GuaranteedRewards占第一格截掉第十奖励；直接物品残留转化文案；多项十连不应被首个转化压成单项。DrawPresenter按实际Rewards显示10项，额外赠送单独显示；券图标和968/10绑定正确。最新Prefab只经MCP调整btn_Continue/Value的4项Rect字段，D仅补相同字段，禁止D旧Prefab覆盖E。r84b真实高级十连逐项核对10项名称/正式图片/数量，其中张奎重复转化60，Console错误0。截图hero-affix-r84b-ten-final.png；证据draw-r84-ten-before.json、draw-r84b-ten-verified.json、draw-r84-quantity-layout-fix.json。Slot10正常召唤消耗/奖励保留，不二次Setup或回滚。
- C3合同acceptance-contract-r75.json：用户明确选择计算P95≤500ms、Editor帧P95≤16.7ms，现有256.939/4.3455通过，不宣称独立Player。已仅重汇总现有r75证据：actual_trigger_acceptance_passed=true指批准的467适用项；all_expected_skills_actually_triggered=false保留5未触发，formal_performance_passed=true；774场/9288点、参考声明不变，整体不可合并。
- C1本轮只读监视仅开始/停止2条文件事件、编译/重载事件0；在有意脚本修改前已移除回调、停止监视，无锁。不能以无复发关闭历史根因。用户8081服务保留、项目MCP覆盖恢复enabled=false，Unity保留当前十连结果Play；当前完整保护检查尚未完成，旧报告不可冒充最新证据。
- 下次只处理C1/C5：先看顶部状态、final-unified-r75-summary.json、acceptance-contract-r75.json、user-real-play-acceptance-r84.json、draw-r84b-ten-verified.json、收口保护说明；不重跑99批、作者、已过十连与转化。C5须汇总临时索引阶段及r76–r84手动定向修改清单，核对真实暂存区/玩家文件/最新Prefab/meta/冻结原生；C6已完成，无需再问或重验。下方历史待确认描述保留为当时记录，以本检查点为准。

- r82：按用户要求移除DrawPresenter创建RuntimeContinueLabel的代码，复用btn_Continue/Panel_3/Text，仅刷新文字/显示，保留Prefab字号24/颜色/位置。r82三种召唤Kind1/2/3实际结果均核对原节点，Prefab/meta/真实暂存区不变；截图及draw-continue-r82-{current-result,kind2,kind3}.json保留。用户随后指出名称/图标错配，旧截图不作为整体结果画面通过。
- r83根因：/224奖励Type2457名称郑伦神魂，但代码将itemId当图片ID加载equip2457（另一角色）；旧DescribeReward优先Cocos配置pic907，正式DescribeServerReward/item.json为pic2453。DrawPresenter统一通过正式item.pic加载直接道具、单抽转化、十连及重复转化图标/名称；移除技能641/名称固定值，纯道具隐藏技能区域。未改数据表/资源/Prefab。编译及Console错误0；Slot10真实单抽再现2457×2，实际equip2453与郑伦头像一致，名称郑伦神魂、技能隐藏、“继续召唤”仍为Panel_3/Text且无动态标签。郑伦/陈奇直接道具与转化4项解析回归通过，明确属于isolated_helper，不冒充实际十连/转化触发；本轮未跑十连。证据draw-icon-r83-{before,first-result-valid,helper-regression,final-ui,preservation}.json与hero-affix-r83-fragment-first.png。诊断首段MCP代码因RewardRecord结构体与null条件类型不匹配编译失败，保留原日志，改object装箱后通过，未改生产源码掩盖。当前Play保留结果页，MCP覆盖恢复enabled=false；历史Editor重载精确归因及最终相关画面人工确认仍开放。

- r81：用户指出转盘0钥匙仍显示单次/十次红点。CanSpin与红点数据已正确为false，根因是ZhuanpanLayer两个原生节点名Dot不匹配公共RedDotVisual查找的Prompt。MCP在E最新Prefab仅重命名这2节点，并同步当前实例；D仅同步对应2行，布局/Sprite/meta/真实暂存区不变。用户返回真实转盘入口后核对权威钥匙0、消耗1/9，两处Prompt均隐藏，无遗留Dot，Console错误0；未抽奖/改存档/重启Play。截图hero-affix-r81-wheel-insufficient-keys.png，证据wheel-dots-r81-{before,fix,after,summary}.json；台账wheel-authored-dot-name-mismatch-r81关闭。当前保留转盘页Play，MCP覆盖恢复enabled=false；整体历史Editor重载精确归因及最终相关画面人工确认仍开放。

- r80按用户要求取消yingxiongInfoLayer空位addnew和养成按钮红点，保留左侧阵位/页签提示。“流派策略”是正式战前配置入口；原截图选中空位hero=0，interactable=false，disabledColor alpha=.502，故半透明且无响应。HeroBuildSelectionView现空位隐藏按钮，选中英雄后恢复显示可用。D/E仅2源码的对应绑定/可见性修改，Prefab/meta/真实暂存区保持。MCP Edit编译后沿Slot10真实入口验证：hero57实际Raycast点击成功打开面板；切空位hero0按钮隐藏、详情红点0；再选hero57按钮显示可点击、详情红点0。Console错误0，未保存流派/策略。期间页面变化导致两次输入预检拒绝（目标消失/活动弹窗遮挡），原日志保留，用户回复“继续验证”后完成真实路线；未绕过遮挡。证据hero-detail-r80-{before,hero-build-open,empty,restored,summary}.json与对应截图。当前Play停留苏全忠详情，MCP覆盖恢复enabled=false；历史Editor重载精确归因及最终相关画面人工确认仍开放。

- r79按用户要求取消10处详情红点：yingxiongshuxingLayer四材料框/升级/一键升级，yingxiongtupoLayer材料框/突破，shenjiangzhenxingLayer书籍数量/升级。HeroCultivationPresenter与FormationPopupPresenter只改对应显示绑定为SetAuthored(false)，页签/阵法列表及其他入口逻辑保持。MCP退出Play后编译通过，再沿标题→旧的回忆→Slot10→神将→养成升级/突破→返回→布阵真实Raycast入口核对10处全部关闭；突破页签及阵法列表6红点保留，Console错误0。未点任何消耗操作，Prefab/meta/布局/真实暂存区不变，当前Play停留阵法页，MCP覆盖恢复enabled=false。证据cultivation-dots-r79-{level,break,formation,summary}.json及hero-affix-r79-{level,break,formation}-no-action-dots.png；不重跑战斗矩阵。整体历史Editor重载精确归因及最终相关画面人工确认仍开放。

- r78定向修复：直接查看用户当前法宝背包，中央白条来自共享zhuangbeibeibao.prefab/Point仍引用退役tipbg子Sprite；白色空态文字已正确绑定但落在白底上。FaBaoStore.HasAuthoritativeState=true、Count=0，空列表是当前权威数据。MCP只将Point背景重绑同图主Sprite，立即刷新当前节点；截图hero-affix-r78-fabao-fixed.png可见正常底色与“背包中还没有法宝哦！”。E差分仅1条Sprite引用，D仅同步该行；布局/字体/meta/真实暂存区不变，Console错误0。保留当前用户Play，无退出/重登/改存档/重跑矩阵；MCP覆盖恢复enabled=false。证据fabao-r78-authoritative-state.json、fabao-r78-after.json、fabao-r78-preservation.json；缺图根因修复，整体历史重载归因及最终相关画面人工确认仍开放。

- r77定向修复：用户指出阵容空位双红点；MCP确认3/4/5位各有外层row/Prompt和bg_add/Prompt同时激活。HeroPresenter.BindRow保留外层原提示条件，内层统一SetAuthored(add,false)，兼顾池化复用，不改Prefab/布局/OpenHeroBuild。D/E仅同一处源码修改；MCP退出Play后定向导入编译，再进入Play，当前真实阵容页五行均只有1个激活红点（三空位/两英雄），内层Prompt关闭，Console错误0。用户在复测期间继续操作，旧Slot10列表快照失效导致一次scroll报Missing viewport；立即重读当前页面，未重复坐标尝试、未操作其他Slot。最新截图hero-affix-r77-formation-single-dot.png、证据formation-dot-r77-after.json及formation-dot-r77-preservation.json。当前Play保留、项目MCP覆盖恢复enabled=false；原历史Editor重载精确归因与r76修复后用户画面确认仍待办。

- 用户确认：r75已真实复测，原文“已真实复测，画面和顺序通过”。该确认仅对应r75，不自动覆盖后续资源修复。
- r76定向修复：E最新BattleHpNode.prefab的Quality_bg与Duihua仍引用已退役的ui_common_tipbg子Sprite；图片/GUID存在，两个旧fileID无法解析。通过MCP只将两处引用改为同图主Sprite fileID=21300000，当前Play内12节点同步刷新；E实际差分仅两行，布局/激活状态/meta不变。D实施树只补相同两行，未用旧Prefab覆盖E。MCP重读两处引用有效，Console错误0；未重跑战斗矩阵/数据作者，未停止用户Play。修复后画面待用户核对。

- 已完成：从r74原56批安全Resume，仅补43批；之后新增默认关闭的实际入场诊断，冻结最终r75并完整99批。最终774场/9288检查点零差异，467适用技能/被动实际观察齐全。原五项禁用/替换/参数拦截继续单列，不计实触发；所有表作者冻结，未改表或重跑作者。
- r75同一Release二进制/夹具/318正式输入/修正参考模型已汇总。48正式构筑实际穿戴48词条/141档位组合，纯CalculateFight P95=256.939ms/max407.744ms；输入穿戴不冒充效果触发。Release和E Debug原生回归/CTest均4/4；诊断开/关12检查点的HP/Buff/CD/RNG/协议完全相同。
- E已通过现有临时索引三方适配3源码，实际入场7份快照均为57A/爆发、64A/守护，苏全忠带词条28/T2。E/D109原生源码与177正式输入归一化内容一致（输入78仅EOL，三工作簿字节一致）。未覆盖E最新Prefab/meta。
- 普通无锁Slot10 Play约9分钟、Console错误0：第一章6场连续回放到最终结算；后一次既有进度Boss场Fight7/6成员/47动作完整回放，经真实结算“点击屏幕继续”返回第一章地图。仅后一次Boss完整段有全程帧采样：30.842秒/9846帧，Editor P95=4.3455ms/max83.0942ms，不宣称首次6场全程采样或独立Player性能。截图：E工程unityclient/Captures/Editor/hero-affix-r75-final-map.png。
- 已交付完整“实际战斗流程判定顺序”，见HERO_AFFIX_INTEGRATION.md对应章节。覆盖入场/开场/行动/CD/自动选技/命中/盾血/反击/治疗/复活/死亡扫描/再行动/回合及最终结算真实继续。
- **剩余阻塞**：历史Editor强制域重载的精确文件/调用者仍未定位；r75只读监视约9分钟无编译相关文件变更、无重载，不能以无复发关闭根因。历史USN读取被Windows拒绝，原始日志保留。r75人工验收已通过；r76资源修复后画面尚待确认，当前manualPassed=false；整体不可合并。
- r75自动验收结束时已退出Play、恢复临时证据环境、停止文件监视并移除两项只读回调；无重载锁或刷新禁止，项目MCP覆盖恢复enabled=false，Unity Editor与用户8081服务保留。final-r75-preservation.json确认当时原104玩家文件差异0、91保护/两Prefab及meta/真实暂存区未变；Slot10完整性ok、可取得写锁、仅原有schema触发器。171源码哈希与冻结版本一致，native/编译进程0、8711无监听。r76修复时用户已在Play，本轮保持该Play，不把旧清理报告当实时状态。Slot10保留、不二次Setup，不覆盖Slot01–03；未提交、推送或启用子代理。

核心证据：final-unified-r75-summary.json、formal-loadouts-r75-summary.json、unity-r75-runtime-summary.json、unity-r75-native-entry.jsonl、final-r75-preservation.json；均位于实施树.local/hero-affix-integration。

### 续接时只处理剩余项

1. 先读final-unified-r75-summary.json、unity-r75-runtime-summary.json、最终保护报告和当前未关闭Ledger；不重跑99批、表作者、已通过选择/保存/重铸/回放路线。
2. 若重载复发，用已备只读文件事件/编译回调抓具体触发者；不加锁或重启冒充修复。当前没有足以确认历史因果的证据。
3. r75画面与完整流程人工确认已记录；只待r76缺图修复后的画面核对，不重复已通过流程。提交/推送仍需单独授权。参考模型必须明确frozen-original-with-two-array-bound-corrections、pristine_original_equivalence_claimed=false；r73首次冷却差异与越界的精确因果仍为推断。

### r74停止检查点（已从新任务恢复，以下保留历史）

**2026-10-19 r74已在批次边界停止：会话记录超过项目20MiB硬上限，须新任务续接；目标未完成、不可合并。** Unity仍打开，未进入Play；未持重载锁，项目MCP覆盖已恢复enabled=false，用户8081服务保留，native/编译进程0。

- 已完成：当前两处护盾/中毒数组越界修复，65535个Buff ID逐项查询及原生回归通过，Release CTest4/4通过；最小ASan旧循环栈越界/修复循环退出0。E通过Git三方适配r74共5文件，91保护及真实暂存区未变；E原生Debug二进制尚未重编。r72保存截图已查看：真实4成员战斗结束后正常返回第一章地图，未发现停在首回合；最终用户画面确认仍待办。
- 最终统一r74：56/99批（0000–0559）560场/6720检查点全部零差异，批次边界主动停止，无失败批。参考为独立reference-query-r74，仅两处循环边界修正，冻结原155生产源未改；必须标reference_model=frozen-original-with-two-array-bound-corrections，pristine_original_equivalence_claimed=false。修复与r73首次冷却差异的精确因果尚未直接插桩证实，不能将推断当已证实根因。
- **下次直接执行**：先校验final-r74-progress.json、frozen-r74及最后56份results/input-fingerprints；确认源码/二进制/夹具/正式输入未变后移除final-r74-stop.request，给run-final-r73.ps1补安全Resume（现脚本拒绝已有freeze，不可直接重跑），仅执行剩余标准start560–710共16批、closure0/6/36共3批、loadout共24批。不要重跑已通过56批或任何表作者。全部完成后summarize-formal-loadouts.py r74，再summarize-unified-r52c.py r74；两工具已支持参考模型一致性，目标774场/9288点。当前Release SHA26766ACBDC143CBD7FC930EBB95AD05A7A1B8EE299F0F88B98B914040C47D0C4；修正版参考SHA946454709A9318083A1279B4F4F7C43B95D782C5BE905FF947D5B86B78BD144C；夹具97A9F120D1508575E4E36F371CFAD6D277E992CC68DD5E75401C986DDE16CD0B。
- 随后：E原生重编/回归→MCP核对实际E实例及稳定编译→沿既有Slot10真实入口继续分支/构筑入场快照、Unity整体性能及普通无重载锁Play，域重载精确触发者仍待定位；输出最终完整实际战斗判定顺序，再由用户验收画面。原5项禁用/替换/参数拦截口径不变，仍不计实触发。Slot10保留，不二次Setup，不覆盖玩家存档/最新Prefab/meta。未提交、推送或启用子代理。

### r74实施历史（以下为停止前记录）

用户已恢复继续；Unity仍为E工程Edit/Bootstrap，Console错误0，8081 MCP接通，项目覆盖enabled=true，未进入Play/未持重载锁。恢复前D/E原生165文件及2份Prefab一致。

- 已完成：r73最终99批计划前4批40场480检查点通过，第5批0040–0049发现248字段差异停止。首次encounter40/turn1/14B技能141冷却原3、现1；原失败证据保留。随后诊断单场/十场trace及非trace零差异，不能覆盖原失败或计验收通过。
- 当前工作：原/现护盾uint16[2]及中毒uint16[3]均按sizeof字节数遍历，分别越界2/3项。当前unityserver均改范围循环，65535个Buff ID逐项查询、空列表/无效位置、Release原生及CTest4/4通过；最小提取旧护盾循环AddressSanitizer确认index2处2字节栈越界，范围循环退出0。第一次新查询回归因未设有效成员memPtr失败，已修正夹具并保留失败日志。冻结原155生产源码未改，独立reference-query-r74仅修两处边界并留精确来源/替换清单，Debug构建中；差分/汇总明确reference_model且pristine_original_equivalence_claimed=false，不能冒称未修原版全等。首次冷却差异的精确因果仍为推断，台账保持开放待统一对照。
- 剩余/验收：先完成修复验证及参考越界问题处理，再以最终唯一版本汇总774场/9288检查点，旧r73不混计。Unity整体性能/入场分支构筑快照、域重载触发者、回放/画面核对及完整实际战斗判定顺序仍待办。不可合并；未提交/推送/子代理。所有表作者冻结，本次未改表。E尚未接入r74；Slot10不二次Setup。

### r72暂停历史（已恢复）

**用户于2026-10-19明确暂停，等待“继续”。** 本轮Play已MCP退出、临时程序集重载锁及AutoRefresh禁止均已释放，native进程0；Unity Editor保持打开。项目Codex Unity MCP覆盖已恢复enabled=false，8081服务当前为用户在Editor启动的PID12964，保留供用户使用；8080仍属Steam，不能误停。

- 最新代码/数据：r68正式118绑定开放，856效果/62规则/73事件/6目标、63导出；仅一次新作者修改236格，其他工作簿部件/样式保持，所有旧作者冻结。E原生Debug构建/原生回归/CTest4/4通过；D/E代码增量已适配至r72，未提交/推送/子代理。
- Unity选择真实入口已走Steam标题→旧的回忆→Slot10→主界面→神将：57A/B与策略保存、SQL故障后保持旧值/错误提示、重试、64独立选择、重启57B/爆发保持均有Raycast输入和SQLite证据。当前保存为57A/爆发、64A/守护。按用户要求，新按钮文字已改黑并核对画面，标题说明保留深底浅字；E最新Prefab经MCP制作、Git反向同步D，2份meta保持。
- r71真实穿戴入口暴露静态移层后的旧Transform路径，已统一HeroEquipmentPresenter/BagFlowPresenter/ProjectXApp路径，Bag预览复用Prefab内容；r72真实列表/详情/锁定/故障回滚/重铸通过，Console错误0。重铸扣60000，UID2121200001保留词条28、T1→T2、锁定1；同物品刷新保持滚动位置。穿戴运行时位置1，原穿戴沿普通保存周期，退出Play后SQLite也为1（不能要求旧op2像新op41/42一样立即落库）。
- 已由正式副本按钮→第一章→挑战进入真实战斗，服务端权威回放FightId4/type16、4成员/17动作、Won=true、统计4项；图片hero-affix-r72-real-battle*.png。未用跳过/内部完成方法。最后UI筛选未覆盖结算画面，仍需从保存截图和实际回放证据核对；不能称Unity最终可玩/视觉验收通过。暂停后钱4946000（重铸后4940000，再有战斗收益6000）。
- 原104个玩家文件哈希差异0，Slot10完整性ok、注入触发器0，见unity-slot10-r68/pause-r72-preservation.json。Slot10是本任务新建隔离夹具，保留续验，**恢复时不二次Setup、不覆盖Slot01–03、不删除玩家数据**。
- 当前剩余：r68开放后最终统一720+6+48版本证据/协议最终指纹；正式构筑与Unity整体性能/最终画面；战斗实际入场分支与构筑闭环的最终核对；最终完整战斗判定顺序。此前r52c467适用项与五项原不可触发口径保持，不重问/不冒充472实触发，不无变化重跑历史。
- 基础设施限制：本轮两次观察到Editor在Play期间强制域重载，应用单例/非序列化绑定丢失；r72日志含“Assetdatabase observed changes in script compilation related files”，精确触发者尚未定位。公共输入/截图工具已补应用图存活预检，后续本批临时锁重载后持续健康；锁已在暂停释放，不能当普通玩家自然运行已验。恢复先核对实例/工程、编译稳定和应用存活；新增编译请求不得带进Play。失败台账保留，不以重启冒充根因关闭。


- **r68最新优先：正式118绑定已开放（新作者仅一次并冻结），63导出，236格精确回填仅sheet5；原5项仍按用户确认单列不计触发。** MCP服务器在8081，用户已连接实例unityclient@412d45435dc1aa1a/E工程；C#重编译错误0。已MCP增量编辑E最新神将/装备详情2Prefab（3流派6策略绑定、推荐与滚动内容Prefab布局），prefabs-r68-preservation.json确认现有节点/布局/样式及2meta保持。19项E制作资产/meta已用Git反向带入D，不能用D旧版覆盖E。
- 当前唯一重任务：E原生Debug构建，日志main-native-build-r68.log、exec session42383，先核对完成/进程再进入Play。未开始Play；原persistentDataPath为C:/Users/Admin/AppData/LocalLow/Xuancai/ProjectX，Slot01/02/03已有用户数据，Slot10尚不存在，计划创建独立Slot10夹具、哈希保护所有原文件并走真实Steam菜单续档。不要调用Presenter或onClick.Invoke。剩余当前正式输入的最终统一差分、Unity真实保存/回滚/重启/战斗/性能和最终实际流程。下面r67及更早为历史。

- **r66选择后端及Unity源码已完成；r67已通过Git临时索引三方适配，将94个允许文件接入E盘。** 无重叠/冲突，91保护文件及实际暂存区未变，未触碰Prefab/meta/存档。证据`.local/hero-affix-integration/main-adaptation-r67/manifest.json`，state=applied。不是Unity验收通过，也未提交/推送。
- r66新增319/43查询、44保存；真实bank_item保存/同锁失败恢复/原键不存在/高3位保留/旧档/重启/五策略10项均通过：`hero-build-selection-r66b-final/results.json`。共用ReadBattleSelection接入AddPet；Release原生及CTest4/4通过。正向测试仅启用隔离运行表57A/64B，正式118绑定仍禁用。Lua两文件语法通过；C#尚未Unity编译，新HeroBuildSelectionView尚无Prefab绑定。
- 下一步：核对E实际Unity实例和-projectPath，MCP编译、以E最新Prefab制作选择控件；将功能新增配装推荐的运行时布局改为Prefab布局。随后新正式作者一次启用绑定/导出，按最终代码、共享夹具和输入统一差分，验真实单机入口、存档往返/战斗与性能，最后输出实际战斗判定顺序。当前Unity未运行，8080为Steam调试服务，不能当MCP；已请求用户打开E工程并开启可用MCP端口，等待期间继续静态工作。不要重跑旧作者或旧关闭阶段。下面r65及更早均为历史。

- r65最新优先：r64b全部48场/576检查点零差异，实际穿戴48词条/141档位组合、10套装/40装备/70法宝；formal-loadouts-r64b-summary.json，P95=259.492ms/max423.239ms（纯CalculateFight，暂定500ms目标），不得把穿戴输入计为实际效果触发。原生/CTest4/4、优先级改表3项、63导出ValidateOnly和formal-workbook-r64-parity.json（37改+8新增）均通过。r65补回原feature防御性suitAttrs.clear，真实普通逐件8穿4脱在补回前后都完整恢复，未冒充复现残留；equipment-cycle-r65-final、protocol-release-r65-final/empty三结果全通过，含41/42保存/回滚/旧档/重启、完整二进制及运行表/三工作簿指纹保护。r65原生、CTest4/4及loadout影响480/660各2场共48点零差异。当前Release=.local/unityserver-build/hero-affix-release/Release/kapai.exe，原参考r63，所有作者冻结，无运行重任务。
- 下一步真正缺口：当前没有战前流派/策略选择写入和Unity控件。AddPet只读owner.GetExtData8(61000+hero)，低2位branch/后3位strategy；ExtData8由GetBankItem/SetBankItem序列化到role_info.bank_item（注意不是WriteSaveData的save_data固定16项！）。SetSaveVal仅uint8客户端选项索引不可复用。准备补专用查询/校验/即时UPDATE bank_item/同锁失败恢复（包括原键不存在、高3位保留、其他maps/tail不变）、重启及共用入场解码；可在319现有40/41/42之后新增43查询/44保存，先确认E无冲突。当前Formal118绑定仍禁用，正向A/B测试应只改隔离运行表副本并保护正式源；最终启用/统一最终版本/接入E与Unity仍待完成。只读hero_build_profile只有12英雄24档，不能把配装参考当选择UI已实现。r52c467适用项/五项原禁用替换按用户确认口径关闭，不重问，不无变化重跑。E仍未写、未提交/推送/子代理。下面为历史前序。

- r64b最新优先：r63自然UID扩展跑过16批32场384检查点，批480 encounter481 turn0仅death_packet Buff顺序差异：原57B增攻25先于词条16反震37，当前反过来。r64作者仅一次/graft C143 priority0→200，保留原受击事件内顺序，63导出通过；作者冻结。真实CalculateOnceAction顺序回归初版攻击1500实际1499，未达正式20%阈值，native失败已记账，现改攻击3000；当前build-release-r64b.log构建中。完成后原生/CTest、CaseName=revive_equipment_order_priority,received_hero_before_affix_priority（直接hashtable splat数组）、run-loadout-r57d.ps1 -Version r64b，成功后summarize-formal-loadouts.py r64b（现强制实际穿戴48项）、audit-formal-workbook-r61.py（输出formal-workbook-r64-parity.json，37改格+8新增）。原参考最新r63，共享fixture一致并ClearSkill；正式856/62/73/6、118绑定禁用、E未接入。r62已48场/576点零差异但45输入，只作旧版本；r63/r64后必须统一新版本。原feature漏适配的suitAttrs.clear仍待真实换装/卸装公共入口核对，别遗漏。下面为前序记录。

- r63最新优先：r62修法宝3复活减伤在女娲前的正式priority（C14 10→5），作者仅一次/graft并冻结；真实CalculateSkill_AddHp复活HP2500、Buff14→193原生通过。r62统一48场/576检查点零差异，formal-loadouts-r62-summary.json实际穿戴45词条（缺6/20/39）、10套装/40装备/70法宝；Release纯计算P95=258.236ms、max447.944ms，暂定500ms目标通过，不是Unity性能。r63共享夹具改UID=base+encounter*100+slot*10+part，仍真实LoadData/RollEquipAffix，不指定词条ID。只读formal-loadout-uids-r63-plan.json先与r62全部1920件装备的实际生成结果匹配，再预测新方案48项/141档位组合；必须等实际48场元数据。原参考r63已重编；当前build-release-r63.log构建中。下一步原生/CTest、revive_equipment_order_priority改表、run-loadout-r57d.ps1 -Version r63；若零差异summarize-formal-loadouts.py r63汇总。正式源码仍856/62/73/6、52/18列、63导出，作者全部冻结；formal-workbook-r62-parity.json证实累计36格修改+8格新增，其他部件/样式保留。另有源适配待核对：原feature的CalcEquipSuitAttr含wearEquips.suitAttrs.clear()，当前整合遗漏；正式换装/卸装前须按真实公共入口复现并补回，防止旧套装属性残留。E未接入、118绑定禁用、未提交/推送/子代理。下面为前序记录。

- r61最新：r60b原生全部、禁疗操作改表5项（含基准）、Release CTest4/4通过。48场构筑计划跑到第13批停下：前24场288检查点相同；encounter361只有cooldowns多出25/281。根因是SPet构造器不清空12技能槽，夹具仅填4槽，剩余8槽复用装备内存。已在共享addUnit及当前原生unit调用ClearSkill；未改原155生产源。当前build-original-r61.log正在重编，先查完成/进程，再顺序重编Release到build-release-r61.log；原生/CTest后run-loadout-r57d.ps1 -Version r61，从新初始化夹具统一48场。此前所有loadout批次仅诊断，不作为最终验收。之后summarize-formal-loadouts.py r61汇总覆盖/性能，若有差异仅诊断首个，不重跑作者。正式856/62/73/6、118绑定禁用、E未接入；仍要最终统一战斗版本、E适配/Unity入口、真实选择写入及最终流程。下面为前序记录。

- r60最新优先：r58嵌套破盾策略已恢复1880治疗；r59将event_hp_loss汇总后移至MakeBuffList/ShieldBrokenCheck之后，原生全部通过（嵌套扣430回400后实际净损失30，合计转盾84），encounter30完整12检查点现零差异。r59批030仅encounter31开场death_packet词条3恢复800/1000不同，原AddAffixHpAction统一受禁疗，正式四项3/10/13/36误配restore_hp。r60新作者已执行一次并冻结，4格op精确改heal（H97/H119/H120/H121），其他单元格/样式/ZIP部件不变，63导出通过。当前build-release-r60.log增量编译，先检查完成/进程；再原生、4项antiheal_operation改表、CTest，然后run-loadout-r57d.ps1 -Version r60（失败只诊断首个）。r58此前0拒绝/3改表、CTest4/4通过。现856效果/62规则/73事件/6目标，118绑定全禁用，E未接入。r56/r57/r58/r60作者全部冻结，不重跑。下面为前序记录。

- 最新优先：r57c原生全部通过，7拒绝/5改表通过。r57d批000两场24检查点零差异；批030 encounter30 turn9爆炸耗盾后漏词条3治疗1880，原版允许二次路径，当前漏事件深度策略，已停矩阵。r58作者已执行一次并冻结，追加事件72/73（after_owned/received_shield_loss，extra_depth7，保留公共八层上限及每来源每回合一次），精确追加sheet12的A76:D77，旧单元格/样式/其他部件不变，63导出通过。当前build-release-r58.log增量构建；完成后原生+两项深度改表/CTest，再`run-loadout-r57d.ps1 -Version r58`统一48场，仍有差异只诊断首个。不要重跑r56/r57/r58及更早作者。共享夹具UID已按roster变化，扩大正式自动生成词条组合，未强造词条。正式现856效果/62规则/73事件/6目标，118绑定禁用，E未接入。下项r57为历史前序。

0. r56原参考Debug/当前Release已顺序重编通过；单场第2回合来源/动作差异消除，装备核心属性实际保持。r56首差异已推进到第5回合犬神二次反击误派发装备after_attack，额外套装8封印并改变RNG；已恢复root-depth入口，普通反击保留，补真实二次反击包/RNG回归。r57作者仅执行一次并冻结，封印parameter_count从1改0，精确graft仅AS55；r56此前30格同样已graft/冻结，63导出通过。当前build-release-r57.log增量构建中，先检查进程/完成状态；随后单场与校验定向复验，仍有差异则只诊断首差异，不扩矩阵、不重跑作者或r52c池。共享夹具原/当前一致，原155生产源保持。旧第4项的“正在构建”已被本项替代。

1. r52c战斗阶段已按用户确认口径关闭：`final-unified-r52c-summary.json`为最终720+6场/8712检查点零差异，72主池批次+3公共闭环批次二进制/夹具/正式输入指纹唯一，实际467/472。六项实触发已补齐（14A142、36B363、38A/B384、67A/B673）。用户明确选择“保留原行为，五项单列后继续”：14B144/42A422原禁用、36A/B362被122替换、57A574原参数准入阻断，这五项仍未实际触发，不计通过。无需重新询问此口径，也不无变化重跑战斗池。冻结二进制与夹具在`frozen-r52c/`；原r51仅历史。
2. 当前进入op40/41、旧档/保存回滚。新真实协议工具`unityserver/tools/Test-HeroAffixSqliteProtocol.py`使用unityserver正式脱敏种子新建D盘隔离SQLite、真实1001/1004与319/40/41，不操作玩家DB。`protocol-r53-before-fix-r3/results.json`已证明21条分20+1页与错误UID/低品质拒绝，也复现锁定成功不即时保存、注入UPDATE失败仍成功且内存改变、重启丢失。原错误及两个预检修复记录在`unified-failures.json`，不得覆盖。
3. r54已关闭协议/保存定向检查：`protocol-r54-final/results.json`、`protocol-r54-empty/results.json`通过，含41即时保存/故障注入回滚、42钱物原子保存/失败回滚、旧档主体字节保持、进程重启往返、正式分档说明与空列表。修复在`pet_equip_manage.cpp`/`user.h`，所有失败保留。`runtime-unified-r54.log`原生通过、`ctest-unified-r54.log`4/4，`binary-diff-closure-r54-protocol-impact/results.json`24检查点零差异。
4. **当前r55独立Release正在构建，先检查进程和`build-release-r55.log`，不可并行启动另一个重任务。** 目录`.local/unityserver-build/hero-affix-release`，/O2及Release SQLite/依赖，单构建内CL/MP2；不是Windows分发包验收。共享5v5夹具新`BattleProfile=loadout`，每个成员从正式表挑4装备/2法宝，经原LoadData、属性/技能汇总和实际入场快照读取。原参考Debug已重编译通过，155生产源未改。当前`fight.cpp`入场装备读取已原样抽为`CombatSnapshotEquipment`供生产和该夹具共用；需用新Release验证正式混合构筑，失败只诊断首差异。工程预算暂按十人12回合单场P95≤500ms、冷启动单记；还没有性能通过结论。
5. 正式表仍856效果/62规则/71事件/6目标、52列效果/18列周期/63导出，作者全部冻结，不重跑。118绑定仍禁用、整体不可合并；尚未进行E适配/Unity入口与最终战斗顺序。仍需补实际选择写入至61000+hero的Unity闭环，不能把只读构筑推荐当流派选择已实现。
6. 本轮起点及r55期间E主线91保护哈希差异0，未改E文件/玩家DB/Prefab/meta，未提交/推送/子代理。Unity操作只用MCP且先核对E-projectPath；当前尚未启动Unity。所有修改仍在D盘实施树。

## r51历史检查点（已被顶部替代，不重新执行）

**r51最终统一版本720场/8640检查点零差异，72批二进制/夹具/正式输入指纹一致；实际观察461/472，11项未触发，整体验收未通过。118绑定全部禁用，不可合并。当前聊天已超过20MiB，按用户AGENTS规则收口，未做新增实施。**

1. 直接读.local/hero-affix-integration/final-unified-r51-summary.json。未触发11项：14/1/142、14/2/144、36/1/362、36/2/362、36/2/363、38/1/384、38/2/384、42/1/422、57/1/574、67/1/673、67/2/673。先按原生产写入/读取/准入核对，区分观察漏记、原禁用或替换、业务前置未满足；按公共机制补每场十名神将的5v5场景和提交后观察，不做逐英雄专项矩阵。未触发不得计通过；原禁止/替换也不能冒充旧技能已实际触发。代码完成前不转数据表讨论。
2. 当前正式856效果/62公共规则/71事件策略/6目标策略，combat_effect52列A:AZ，combat_periodic18列A:R，63导出通过。当前binary=.local/unityserver-build/hero-affix-unified/Debug/kapai.exe，r51。所有作者已执行并冻结，包括fix-emergency-regular-usefulness；不重跑任何旧48/52列效果作者或16/17/18列周期作者。
3. 最终72批目录binary-diff-all-heroes-r51-final-full-0000-0009至0710-0719均通过，不要无变化重复。统一报告input_fingerprint_variants=1，original/current binary与fixture唯一；原155生产源未变。观察保留kind分类，data_damage_applied等是实际目标结果应用数，不能相加当施法次数。r49真实属性增量/数据HP、护盾、复活观察已补，零值/查表不计。后续变更需按最终版本重新汇总受影响证据。
4. r51编译/原生全部、应急治疗2敏感性、CTest4/4通过。最近关闭：原AI战术→常规各一次准入/复活选靶RNG；稳健策略濒危常规治疗价值豁免（仍检查冷却/35%边界）；44B普反+1000；42B生命费用及倍率；47B主动附被动关闭/61B原列表准入；46A462所有带参状态1500/2；56A561 >70%暴率/暴伤各1500；禁疗零值记录、11B概率失败返战意5、多实例全状态参数汇总/首来源一次反噬。根因和原错误均在unified-failures.json；不要重做历史关闭阶段。
5. 工具仍用Build-UnityServer.ps1、Test-HeroAffixBinaryDiff.ps1、Test-CombatDataExport.ps1；BuildDir=.local/unityserver-build/hero-affix-unified。原参考=.local/hero-affix-integration/original-server-build/Debug/kapai.exe，冻结源original-1a242cf3。每批10场，失败先保存/诊断首差异，原始证据保留。decode-first-battle-difference.py支持完整/partial和首失败回合Trace。
6. 后续顺序：完成实际触发缺口/统一战斗验收→op40/41、旧档保存回滚、正式构筑性能→E盘脏主线适配/Unity真实入口→最终完整战斗判定顺序。正式性能未验收，Debug批处理耗时不能代替。最终流程必须写明原死亡阶段复活删除当前项后索引仍递增、跳过移位后继；行动内额度重置在原UserActBegin状态结算及冷却递减之后。
7. E尚未接入。main-preservation-r51-final.json：91保护哈希差异0、脏清单差异0、diff-check-r51-final=0、作者进程0、离线native进程0。没有操作Unity/玩家存档/Prefab/meta，无提交/推送/子代理。实施D:\Relo\.codex\worktrees\6513\Game，目标E:\neiwang_kapai\Game；Prefab以E最新为准，Unity操作前核对实际实例及E-projectPath，只用MCP。

### r20历史检查点（已关闭，不重新执行）

1. r20编译与270/271复验已经完成，见后续进度单。
2. 270/271原失败r19首差异在270第9回合复制增益时长3/4；原复制路径没有自身+1，新实现遗漏删除。r20去掉最后一处补偿，新增真实复制及当前/下一行动时长回归；既有unified_active_buff_tick_policy改表用例已扩展到主动/复制两条消费者。按影响跑此用例，不重做历史全矩阵。
3. 之前公共净化/驱散/窃取选择器漏迁原分支buffPos候选下标映射，r19已修复3处并真实验证正负混排与窃取。此前错误“保留误选正面”判断已撤销并修正16A混排回归；失败台账保留原错误和纠正。成功移除、实际新增复制已接入实际触发观察器，不能把仅查询或失败机会记为成功。
4. 最新正式作者均已执行/graft，不重跑：fix-revived-action-rule；fix-opening-branch-effects/description（806–807）；fix-cleanse-success-compensation（808）；fix-thorns-query-phases（809–811）；fix-passive-post-target-plans（812–822）；fix-passive-action-reset-scope（67A按原67400重置为自身行动一次，不能按全战）；fix-shield-branch-consumers/policy-flag（823–825）。更早批量作者、旧48列作者同样不重跑。最新export-shield-branch-r2.log静态63输出通过。
5. 已完成公共原生/定向改表：r6b11拒绝/12改表；复活1拒绝/3改表；开场净化4改表；反震1拒绝/3改表；目标r16为2拒绝/2改表（此前r15尝试数/人数改表完成，错误全战限制用例作废）；主动计时r17为2改表；护盾r18为3改表。含各批通用基准。r16 CTest4/4。r12/r13原生夹具旁观者误杀已纠正，r14实际目标存活、封印2→1；不能把旧错误夹具当业务故障。
6. 5v5先后通过24场/288检查点：0/1至330/331，每隔30首两场，跨多个修复版本，不代表同一最终版本覆盖。r27后继续360/361，再390等轮换。720只是候选池，最终同版本全技能/被动实际触发与结果必须汇总；未触发不通过。
7. 二进制参考仍original-server-build/Debug/kapai.exe，原冻结源original-1a242cf3；现有Test-HeroAffixBinaryDiff.ps1检查155生产源保护及共享夹具/二进制SHA。新增只读诊断decode-first-battle-difference.py可读已保存报文定位首个实际动作差异；不重新运行失败整批代替诊断。所有原错误在unified-failures.json。Debug索引优化已把首场58秒降5.1秒，多数两场约2–3秒，仍未过正式性能预算。
8. 91主线保护哈希/脏清单差异0（main-preservation-r27.json），尚未接入E，无Unity操作/存档/Prefab/meta变更、提交、推送或子代理。实施D路径，目标E路径。战斗统一收尾后继续op40/41、旧档/保存回滚、正式构筑/预算、E脏主线适配、MCP核对E-projectPath并走真实入口，最后按最终代码交付完整战斗判定顺序。

### 先前批次历史（已被以上检查点替代，不重新执行）

1. 本次四个作者均已执行/graft，不重跑：bulk-attribute-transfer（729–734，6条）、bulk-passive-closure（735–774，40条，含19A按自身行动次数修正及40110援护贡献合并取整）、bulk-passive-attempt-closure（775–794，20条）、bulk-opening-and-shared-link（795–805，11条）。最新静态导出export-bulk-opening-shared.log通过，63份。combat_effect仍52列A:AZ；不运行旧48列作者。
2. 68A装备开场之后/全部开场被动之前快照与窃取上限、19A命中内计数、40B/41A行动限时状态、14A成长被动第五次行动关闭、23A/B援护候选/次数/护盾/追击、34A/B回血/低血记忆、39A回血次数、42B死亡序列关闭、16被动概率前占次/失败抗控、52B受控概率、35B死亡复活30%/独立机会、26B溅射上限、31被动吸血禁疗/同源通知、20A当前反间施加者绑定、13A开场效果/排序、29A首领附伤、25A实际生命恢复倍率、47B共同分伤排除、共同分伤最低血比单目标、60A周期实际扣血后延长604来源状态均已补齐首轮生产调用。召唤已核对已有ApplyAffixSummonBonus/EOTZhaoHuan路径，不新增原生产没有的18B召唤机制。
3. 统一编译使用独立目录`.local/unityserver-build/hero-affix-unified`。最新`build-unified-r6-limit-reference.log`、`runtime-unified-r6.log`均退出0；r5 CTest 4/4。保留旧61B r2目录，不运行旧binary读新表。已加入离线实际触发观察器/all_heroes_battle共享夹具。集中变表先关闭旧查询断言漂移及夹具列错误，又发现per_action改2时抑制仍等3的真实缺口；现用通用`counter_action_limit_ID`读同一正式Gate定义，0为不限。`fix-action-limit-reference.mjs`已执行/graft，不重跑；最新静态日志export-action-limit-reference.log。**run-unified-boundaries.ps1正在跑22项集中测试，证据unified-boundaries-r6；先检查日志/进程，失败先诊断，不盲跑整批。** 原错误与修复在unified-failures.json/两个失败夹具中保留。
4. 新scope每场固定5v5十个成员，12回合检查点；720场计划覆盖12组轮换阵容、A/B对置、三种子、五策略、两组基础属性。Test-HeroAffixBinaryDiff.ps1新增EncounterStart/EncounterCount，默认只跑一场以便首差异诊断；actual-trigger-coverage.json将未触发技能单列，不计通过。共享夹具已复制到原冻结树server/tests；`build-original-all-heroes-r1.log`已编译原参考，原生产源码未修改。集中边界通过后启动all_heroes_battle首场差分，再推进全部技能实际触发/差分、op40/41、旧档/保存回滚、正式构筑预算、脏主线适配、Unity MCP真实入口与最终判定顺序。
5. 续接起点91个E主线保护哈希/脏清单差异0，编译前diff检查0。本轮无提交/推送、子代理、E文件/存档/Prefab操作；只读核对Unity进程指向E工程，未操作Unity。后续主线/用户画面验收仍未开始。

### 本轮批次记录（只读，以下旧计数不作续接依据）

0. **最新694效果/54规则/49事件/6目标策略/118禁用绑定；63静态导出。** 新增作者均已执行/graft，不重跑：bulk-cast-passive-plans（614–654，41条，含16重复施法/兵器/对盾，36B自复活，54/56忽防，60行动前被动/原列表关闭，31/51原列表关闭、46A目标次序）；bulk-kill-followups（655–678，24条，16A/B、21B、43B/44A/59B的击杀后动作、倍率、次数/预算时点）；bulk-removal-compensation（679–683，5条，来源技能及实际移除批次、每次自身行动累计战意预算）；bulk-passive-attempts（684–698，15条，35A入口占次/37B成功复制占次及原时长、46A保留归属结果/本次自身行动目标次数、18A原抽取后反伤值与次数、23A/B反伤扣血前补偿）。对应export-bulk-{cast-passive,kill,removal,passive-attempts}.log均静态通过。源码仍未统一编译/运行。C++新增before_kill_followup/kill_followup_damage、before_skill_cast/before_self_revive、before_effect_attempt/before_passive_value、before_thorns_damage、after_dispel_batch/after_cleanse_batch；Counter增加行动/回合读取事实，amount_budget增加source_action且event.action实际来自**成员自己的combatActionIndex**。46A的46200实际写入在原HeroBuildDebuffApplied，不是未写死状态；最新结果已连写入与查询，旧plan误注已纠正。
0. 下一步仍为新机制实施：11A/B周期额外触发/治疗反噬（原113概率固定8000，倍率20000＋(等级−1)×500；B慢速在概率前、B每目标每两回合延长且初始计时0；112施加才重置应用时间/慢速标记）；属性转移/借用及剩余原生产调用查漏。先全部机制/配置，再统一编译/边界/10人战斗，不能为了数据入口118/118提前验收。下列609等计数为上一批次历史。
1. **当前正式源609效果/54规则/40事件/6目标策略/118条禁用绑定，63导出。118/118只表示配置入口齐全，完整机制仍有缺项，未到统一编译/边界/批量战斗阶段，不能开放或称可合并。** 进度以HERO_AFFIX_INTEGRATION.md顶部为准。
2. 下列作者已全部执行/graft/静态导出，不重跑：bulk-actions（505–547，43条）、bulk-cross-role-actions（548–560，13条，含507行51B零伤害占次修正）、bulk-target-counter-plans（561–585，25条）、bulk-heal-growth（586–605，20条）、bulk-periodic-consumption（606–608，3条）、bulk-healing-distribution（609–613，5条）。最新静态日志为export-bulk-{actions-r3,cross-role,target-counter-r2,heal-growth,periodic,healing-distribution}.log。二进制仍61B r2，不能运行新表。
3. 本批公共实现：cleanse/dispel、strike/apply_skill_passives；按当前HP/基础攻击选靶及同事件锁定接收方；after_dodge/secondary_attack_observed；守护mark_group与before_protection；原始周期伤害/剩余量和consume_periodic；after_landed_skill在原首段附加被动完成后、反震前；before_target_plan与before_counter、promote_buff、before_skill_growth；reserve_overheal/split_heal及healing_total/recipient_count。Typed反击等级系数放宽至10M仅限before_counter/set_parameter/source_skill_level，不放宽其他效果。
4. **下一步继续公共机制查漏，不执行边界/批量战斗**：攻击类型与被动目标变换，60A/B行动前被动、16B第三段/条件护盾压力，余下净化驱散补偿/治疗护盾联动、援护与死亡/击杀追加动作；召唤路径需按原生产引用核对是否已有公共覆盖，不能凭“待召唤”字样重复造英雄机制。所有118分支入口已有配置，但原生产73个方法引用尚未逐项关闭；legacy-mechanism-inventory.json是来源索引，不是完成率。
5. 所有新机制和配置完成后才统一编译、集中边界、5v5每场10人全技能触发统计与原二进制固定种子差分，随后op40/41、旧档/保存回滚、正式构筑预算、E主线适配、Unity MCP真实入口、最终完整战斗判定顺序。禁止回到逐英雄矩阵。
6. main-protection-bulk-periodic.json：91文件哈希/脏清单差异均0；diff-bulk-periodic.log检查0。无提交/推送、无子代理，无E文件/存档/Prefab改动。本轮未操作Unity。会话已超过15MiB预警，20MiB须收口；最新作者进程完成后检查本地日志，不重跑旧作者。

## 历史阶段记录（只读，不按旧计数或旧待办重做）

- **最新覆盖点：543效果/54规则/35事件/6目标策略/110禁用绑定，63导出。** bulk-actions.mjs已执行/graft（505–547行43条，policy第38–39行），export-bulk-actions-r3.log静态导出通过；首次占位符错误已改为coefficient_pct，31A说明时长也已使用duration。新增cleanse/dispel（移除事件保留根深度）、strike（先原CalculateDamage/攻击类型RAII，再二次被动伤害）、apply_skill_passives（保留原根触发）、按当前生命/基础攻击选择并在同事件锁定接收方、first_other_enemy、target_shield_amount/target_hero_ID/enemies_alive、after_dodge/secondary_attack_observed。命中/完整技能后效及17B观察已配置。源码仍未统一编译运行。before_protection/mark_group_ID正在接入，尚未加入事件词汇/PS及正式配置，继续补齐再导出。全部新机制完成前不跑边界/批量战斗。会话文件已15.09MiB，20MiB必须收口。
- **最新覆盖点：500效果/54规则/33事件/6目标策略/104禁用绑定，63导出。** bulk-sequences.mjs已执行并graft（484–504行21条，policy第33–37行5条，42B/44A新增绑定）；export-bulk-sequences.log静态导出通过。新增before_skill_sequence/before_passive_list/before_direct_amount/before_combo_amount/before_self_damage；固定三段、逐段被动替换、伤害倍率、连击倍率、暴击开关/概率及命中加值已接入，未统一编译运行。继续公共动作/选靶/净化驱散/追加攻击及其余机制；全部新机制完成前不跑边界或批量战斗。下方旧计数均为历史，不回退。
- **最新：479效果/54规则/28事件/6目标策略/102禁用绑定，63导出**。bulk-stats.mjs已执行/graft（449–481行33条、规则sheet7第56–58行3条、policy第32行）；bulk-recipient-marks.mjs已执行/graft（482–483行2条、31A新绑定）。export-bulk-stats.log/export-bulk-marks.log均静态导出通过，未统一编译或运行，二进制仍61B r2。新增公共CombatStat/CombatBoss、before_stat、属性查询防递归标识m_combatStatQuery、targetTeamValues与team_skill_level_ID独立于owner内容、enemy_buff_units_ID、event_depth/had_shield；GetUnitAttack/FangYu用正式首领/普通削弱上限。属性33条含14A持盾攻击成长、14B行动准备/速度与对盾压力/保底穿盾、28A速度成长、13A/27A开场速度、22B攻速、59A速度、33B受魅惑敌人数减伤、31B法防光环。
- 接收方限时标记公共层：Counter.value存数值状态；State.marks以(接收方,mark生产效果/别名)保存source/group/value/到期回合，Event.target保留事件目标；mark/source_mark/target_mark绑定与mark_value/source/present、source_mark_*事实可跨角色读取并在原施加者死亡后保持到期语义。31A有效治疗标记2回合，受治疗者物防+8%已配置，未运行。标记说明仍有文字“两回合”，最终说明核对时改为duration占位（不影响当前执行）。
- 当前所有批量作者/导出已结束；继续按进度单补命中/暴击/反击与援护、施法/目标/攻击类型计划、追加动作、召唤、治疗/溢出分配、驱散/净化及死亡/击杀。所有新机制完成前不跑边界或批量战斗，不回到单英雄循环。源码/header均仍未统一编译；新增schema与正式表已同步静态导出，旧binary读新表会报未知词汇/规则，不运行旧binary。
- **最新整体批量点**：正式444效果、51规则/27事件/6目标策略、101条禁用绑定、63导出。四个批量作者均已执行并graft，不重跑：bulk-raw-parameters.mjs（214–261，48条）、bulk-buff-attempts.mjs（262–362，101条）、bulk-direct-bonuses.mjs（363–412，50条）、bulk-state-controls.mjs（413–448，36条）。各自plan.json与export-bulk-{raw,buff,direct,state}.log为静态来源/导出证据，**不是运行时/边界/战斗通过**。当前已无作者/测试进程在跑；当前二进制仍61B r2，不能运行新表。原生/边界/批量战斗继续等待全部新机制完成。
- 新增公共层：before_passive_raw_parameters保留原含零参数；before_buff_attempt逐目标改变概率/参数/时长及replace_buff；buff_attempt_failed保留免疫标识；buff_attempt_applied在原被动调用处添加成功/返回后效，直接AddBuff/传播不会重复派发；source_team_hero_ID按存活队友、source_owns_buff_ID、parameter_value_1..5、target_category_count_ID；state_set/state_add以argument作累计上限，state_value_ID/target_state_value_ID按来源/目标查询，counter_key仅同组同scope状态可别名。新增Modifiers.buff、Counter.value，尚未统一编译。copy_buff及目标器已扩展原施加后事件，same_row_enemies/first_unstacked_susceptible_enemy用于传播。
- 36条状态/后效已包含29B首五次行动、16B受控参数/本行动成功计数与增伤、27B累计减速、48A累计强化/重置、13A随机加时、33B/63A每回合控制抑制、46B存活队友协同、30A失败返战意、13B失败易伤、13A成功减速、30B全队减伤、60A毒/同排传播。它们只有静态导出，仍需后续整体边界/差分；不要称机制已验证完成。
- `inventory-legacy-mechanisms.py`已生成legacy-mechanism-inventory.json：原生产73个含分支引用的方法，仅为来源索引，不是覆盖结论。下一步按公共能力继续GetUnitSpeed/GetUnitAttack/GetUnitFangYu/CalUnitZengShangLv等属性查询，再补BasicFightAction/技能和目标变换/追击/召唤/治疗分配/驱散联动。未建立配置入口的17分支从inventory读取最新列表；已有101分支仍可能缺效果，不按绑定率计算完成率。
- **当前批量实现点（覆盖历史单英雄顺序）**：正式358效果、51规则/26事件/6目标策略、81条禁用绑定、63导出。`bulk-raw-parameters.mjs`已执行并graft：214–261行48条、33个新分支绑定；raw含零字段查询在GetPassivePara/GetPassiveBuffPara转换前执行。`bulk-buff-attempts.mjs`已执行并graft：262–362行101条、38个新绑定；逐目标before_buff_attempt支持概率/参数/时长/Buff替换，buff_attempt_failed保留技能和Buff。计划JSON分别bulk-raw-plan.json/bulk-buff-plan.json；静态导出export-bulk-raw.log/export-bulk-buff.log通过，未执行新运行时/边界/战斗测试，当前二进制仍是61B r2，不能拿旧二进制运行新表。
- `bulk-direct-bonuses.mjs`正在生成候选（尚未graft）：从当前358/81起，拟追加363行起的直接伤害条件配置；新增target_hp_bp_ceil保留原严格高血线判定，target_category_count_ID复用正式Buff分类统计实例，target_has_debuff/source_hard_control/target_hard_control/source_position为通用事实。作者未完成时先检查进程/本地日志，不重跑已graft的旧作者。
- 后续集中补原参数的29B首五次行动/16B受控条件，13A随机加时、33B/63A每回合控制限制、27B/48A累计参数、46B队友协同，以及其余状态/动作/目标/召唤/治疗分配机制。先完成全部新机制/配置，再统一边界及10人批量战斗，不回到单英雄矩阵。详见整合文档顶部进度单。
- **用户最新执行顺序（优先于下方历史逐英雄续接）**：先把全部新机制和118分支正式配置补齐，再统一处理边界问题与每场10名神将的批量战斗测试。通用机制只实现一次，同类分支先核对配置，不再逐英雄新增矩阵/完整战斗。当前停止新增单英雄测试，不启动61B定向改表矩阵。已完成的测试保留，不重做；先按机制族盘点原版剩余调用并集中实施，全部新机制完成后才启动边界和批量差分。
- 61B现已实施并编译：209效果/51规则/23事件/6目标策略/10禁用绑定，63导出；after_passive_sequence与原参数比例修饰已接入。`build-hero61b-r2.log`、`runtime-hero61b-r2.log`退出0；`binary-diff-hero61b-r2`108组及`binary-diff-hero61b_battle-r2`60场480检查点均零差异，原源码保护通过。上述运行发生在用户调整顺序前，后续不沿用逐英雄模式。hero61b.mjs已执行并graft，不重跑。当前无需再补61B专项矩阵，待整体边界阶段统一验证。
- **65B 已关闭本次机制及连续战斗验证**：正式203效果、51规则/22事件/6目标策略、9禁用绑定、63导出。6521/6522为652法防降低4000/2回合；6523为654原查询参数+800。真实SetUnitBasicData已证明原实际初始化仍1100/75级8500，查询1900/9300；保留原行为，不将查询规则扩展至初始化。二次652不附加负面Buff，原生断言已修正，生产行为未改。`build-hero65b-r2.log`、`runtime-hero65b-r2.log`退出0、`ctest-hero65b-r2.log`4/4；`hero65b-tests-r2/results.json`13拒绝/8改表，同源及源/二进制SHA保护通过。全部14个差分scope后缀`-hero65b-r2`均通过：组件48/30/186/132/120/216/72/84/96；15A/15B/61A/65A/65B各60场480检查点。连续战斗夹具现填充SPet技能并走真实初始化，观测新增famianLv；原生产源码保护通过，无白名单。
- 当前 **61B 实施中**：原613第二参数×125%、第三参数20000；原被动序列末尾占每战一次并返战意8，即使无敌人仍占用；召唤来源跳过，之后不再抽取原概率。已准备hero61b.mjs（208–213行、binding第14行、事件策略第27行），新增通用after_passive_sequence和被动参数比例修饰。作者尚未执行，源码未编译；后续走原生/原二进制完整证明。
- **65A 已关闭本次机制及连续战斗验证**：正式200效果，其他策略/绑定数沿用61A。6503以通用before_passive_parameters/add_parameter_flat给653第二个原参数−800；参数加值支持有符号且上下界截断，护盾参数仍拒绝负数。真实651施法毒参数732/120、3回合，高等级1620，对照基础610；653实际敌方全体−1900，高等级−9300，自身/友方不受影响。`build-hero65a-r1.log`、`runtime-hero65a-r1.log`退出0、`ctest-hero65a-r1.log`4/4，`hero65a-tests-final/results.json`14拒绝/8改表，同源及源/二进制SHA保护通过。`binary-diff-hero65a-r1-count-fixed`84组、`binary-diff-hero65a_battle-r1-count-fixed`60场480检查点零差异；观测新增实际fumianAdd。main-protection-hero65a.json：91哈希/脏清单差异均0。失败记录：首次差分工具漏注册84计数已修；运行时负盾夹具先触发字段不可用，已改为1213纯负值夹具，最终精确错误通过。
- 65B原审计缺项由顶部当前结果关闭；实际初始化与原查询区别保留为来源事实。
- **61A 已关闭本次机制及连续战斗验证**：正式199效果/51规则/22事件/6目标策略，8条绑定仍禁用、导出63。6102在整次611伤害与自身扣血序列化后静默施加1200减伤/2回合，保留二次施法、死亡来源、origin611及免疫绕过；新增通用after_skill_damage，无生产英雄ID分支。`build-hero61a-r3.log`、`runtime-hero61a-r3.log`退出0，`ctest-hero61a-r3.log`4/4；`hero61a-tests-r3-exact/results.json`12拒绝/13改表通过，同源及源/二进制SHA保护通过，非全量矩阵。`binary-diff-hero61a-r3`72组、`binary-diff-hero61a_battle-r3`60场480检查点零差异，原生产源码保护通过。作者hero61a.mjs已执行，不重跑旧作者。测试器只接受精确CaseName，首次通配符调用被拒绝，后已精确选择复验。
- 65A原缺项已由顶部关闭；从65B当前执行点继续，不重跑已执行作者。
- **15A 已关闭本次机制及连续战斗验证**：正式 198 效果、51 公共规则、8 条禁用绑定，导出 63。常规最新编译 `build-hero15a-r4.log`，`runtime-hero15a-r4.log` 全断言退出0、`ctest-hero15a-r4.log` 4/4。`hero15a-results.json` / `hero15a-tests-final/results.json` 为 **34 拒绝/21 改表**，含缺失共享规则的运行时拒绝；同源说明和源/二进制前后SHA通过，非全量矩阵。
- 15A 最新原二进制差分为 `binary-diff-hero15a-hero15a-r4` **216组**、`binary-diff-hero15a_battle-hero15a-r4` **60场480检查点**，全部零差异。同期 `{nuwa,shield_core,shield_full,pursuit,hero15b,hero15b_battle}` 后缀 `-hero15a-r4`（48/30/186/132/120/480）也通过；原生产源码保护通过，无白名单。共享 inc 已同步并重编译。`hero15a-final-verification.json` 的91主线哈希/脏清单差异均0、diff检查0，离线进程已结束，未提交/推送。
- 15A 作者 `hero15a.mjs`（187–202行、binding第12行），不要用旧作者覆盖。已实现151易伤1500/3回合、152活目标易伤低于800时补800/2回合、旧153永久速度抑制、击杀速度2000或3000+等级×100/2回合、原时点50%追击抽取、成功选择后每回合一次记录、复活限制、152再次攻击70%、阵亡成长400/五层/召唤排除。通用 `source_skill_level_ID`/`target_buff_value_ID`、`kill_confirmed`/`accepted_kill_action`/`before_action_repeat`，没有生产英雄ID分支。
- 失败与修复保留 `hero15a-failure.txt`：属性编号54误作速度Buff，已修为55；Random消耗多次rand，成功/失败种子由实际Random函数选择；Clear遗漏行动/死亡名单与当前行动者，当前生产清理已补齐，原/当前共享夹具显式冻结相同初态。旧R1/R2诊断不代表当前失败，勿回退。已学技能事实引用验证、重复倍率/被动布尔查询均拒绝非法配置。
- 61A原审计缺项现已由顶部记录关闭；65A从顶部当前执行点继续。
- **15B 冻结验证点**；下面 shield-full 是历史有效证据，不要退回重做。该阶段二进制 `build-hero15b-battle-r9.log`，`runtime-hero15b-r9.log` 全断言退出 0、`ctest-hero15b-r9.log` 4/4。该阶段正式 182 效果、51 公共规则、21 事件策略、6 目标策略，导出 63 份，7 条绑定禁用；当前数据/二进制见顶部15A段。
- `binary-diff-hero15b-battle-r9/results.json` 为 60 场、480 个逐回合检查点，HP/属性/Buff/全部成员 CD/双方战意/后继 RNG/完整协议零差异；五种策略、三个种子、两组有效基础属性，双方原生产源码保护通过，无白名单。最新 `{nuwa,shield_core,shield_full,pursuit,hero15b}` 组件差分后缀 `-hero15b-r9`，48/30/186/132/120 组均通过。当前只有 15B 与基础 23 队伍的连续战斗，不能宣称全 118 分支完整战斗通过。
- 15B/追击最新定向改表复验已通过：`hero15b-pursuit-results.json` / `hero15b-pursuit-tests-r9/results.json` 为 **38 拒绝/22 改表**，同源说明、正式源和二进制前后 SHA 检查通过，非全量矩阵。`hero15b-final-verification.json` 为 91 个 E 主线保护哈希差异 0、脏清单差异 0、diff 检查 0；全部离线进程已结束。此前 `pursuit-full-results.json` 和 `hero15b-results-r4.json` 保留各自历史测试哈希，不混称当前结果。
- 上述15A原缺项已由顶部段关闭，后续从61A继续，不回退15A。
- 15B 全机制实现和公共调用修复详见长期文档最新段；失败保留 `hero15b-failure.txt`。完整战斗发现的 CD 前置/被动重复 +1/普通反击错误深度/援护多发战意均已修；不要重复实现此前关闭的公共 Buff 计时。新共享夹具已补齐基础属性 Base/Ratio 与 pet 基线，并输出所有成员属性/CD、双方战意；原/当前同一夹具。工具超时现在会保存部分日志，连续战斗上限 60 秒、组件仍 30 秒，进程计时随结果记录。Debug执行器先过滤事件/绑定后再处理深度，当前约4.4秒；不是最终构筑预算结论。
- 当前全部离线进程已退出，无测试在跑。普通 kapai.exe 最新编译为 `build-shield-full-r6.log`，`runtime-shield-full-final.log` 全原生断言退出 0；`ctest-shield-full.log` 4/4。英雄 12 A/B 完整护盾与此次发现的公共反震缺口已关闭本次定向实现；不要重新实现或无修改重跑。
- `shield-full-results.json` 汇总 **38 拒绝/29 改表**：21 个正式导出拒绝、17 个运行时拒绝，同源说明和测试期间源/二进制 SHA 检查通过。原报告分别为 shield-full-export-sensitivity-final/results.json、shield-full-runtime-rejections/results.json。该汇总不是全部分支/完整矩阵。最后仅调两行行高，8352 个单元格值/类型、其余 XLSX 包部件与 318 份现有导出 JSON 均未改变；证据 shield-full-format-cell-parity.json / shield-full-format-parity.json，汇总中分别保留测试源哈希和交付源哈希。
- 最新原二进制差分为 `binary-diff-shield_full-shield-full-r6/results.json` **186 组**、`binary-diff-nuwa-shield-full-r6/results.json` **48 组**、`binary-diff-shield_core-shield-full-r6/results.json` **30 组**；状态、后继 RNG 和协议字节均 0 差异，原战斗源码保护通过，无白名单。两端共享 inc 已一致并重编译。计数为定向场景，不是完整战斗通过。
- E 主线仍为 `8b5d9b45e5d9353d7e9a507f9ff659b88b04749d`，91 个保护哈希差异 0、脏清单差异 0（main-protection-shield-full.json / main-status-shield-full.txt），未改 Prefab、存档，未提交/推送。仅核对既有 Unity PID 28736，`-projectPath` 为 E 盘工程，本轮未调用 MCP、未启动新 Play；下次实际操作前重新核对实例。
- 原 15B 缺项已由顶部续接段关闭；原 `after_hit` 部分切片说明作废，以当前 `after_primary_hit` gate1500/伤害1501/低血增伤1502及154/击杀查询为准。
- 仍未完成：全部 118 分支、完整固定种子原二进制战斗差分、op40/41 与旧档/回滚、正式构筑/预算、E 主线三方适配和 Unity MCP 真实入口/最终画面。7 条绑定均禁用。最终战斗判定顺序必须在战斗代码收尾后输出，当前不生成伪终稿。
- 本次继续使用 D 盘 6513 工作树，不在 app 当前 ed02 或旧 e54f 路径重新实现；不得把旧 D Prefab 覆盖 E 最新版本。上一任务的约 20 MB 收口记录为历史，不代表本次任务文件大小。

## 工作区与保护

- 目标主线：`E:\neiwang_kapai\Game`，Unity：其下 `unityclient`。本任务不直接修改脏主线。
- 实施工作树：`D:\Relo\.codex\worktrees\6513\Game`，分支 `codex/hero-affix-data-driven`。C 盘同尾路径是该目录的别名，不是另一个实现。
- HEAD 与本地 origin/main：`8b5d9b45e5d9353d7e9a507f9ff659b88b04749d`；本地 feature 引用：`1a242cf3804861af50e24228c166f34027c94ee8`。这是本次读取结果，后续整合前仍需 fetch、重做差异/冲突核对；旧 18 个冲突只作历史。
- E 盘 `.local/integration/hero-skill-affix-v1` 是旧的不完整集成现场，不覆盖、不重置。不要把 D 盘文件批量复制到 E 盘。
- 本次主线脏文件列表与 `.local/hero-affix-integration/main-status-gated.txt` 比对差异为 0；这只是列表比较，不是内容哈希保证。
- 用户后续明确：Prefab 应基于 E 盘主线最新版本调整。进入 UI 阶段先逐个核对目标 Prefab/绑定，保留手调布局与资源，不用 D 工作树旧版本覆盖主线。重启前另冻结 main-before-unity-restart.json 的 91 个主线已修改/未跟踪文件内容哈希；首次同路径 OpenProject 后差异为 0。
- 已通过 MCP 重启 E 盘 Unity，PID 24692→28736；用户重启 MCP Server 后连接恢复，实例 `unityclient@412d45435dc1aa1a`，Bootstrap 未 Play、未编译、Console error 0，91 个受保护文件内容哈希差异 0。未改 SQLite/存档。D 工作树客户端尚未编译/真实验收。
- 不运行 Cocos、不改旧 server、不恢复已排除功能、不清理无关文件、不用 git add -A。所有修改未提交。

## 当前实现边界

- 正式 `hero_combat.xlsx` 当前 170 条 combat_effect（数据行 5–174）、47 条 combat_rule、21 条 combat_event_policy、6 条 combat_target_policy（第 13 张表），7 条绑定（5 名英雄）均禁用；最新英雄 12 完整护盾 38/29、原二进制定向 186+48+30 已通过。此前已关闭的阶段：18/23 定向 59/14、16/33 定向 52/25、30/44 定向 44/21（44 超 255 边界已更正，见下文）、43 定向 34/15、34/37 定向 31/22、41/42 定向 29/19、10/13/36 定向 24/24、15/20/31 定向 32/23，26/28/38 定向 23/21、7/40 定向 21/19。女娲来源 58/12、独立复活 68/8；护盾展示/五策略目标排序 85/16。其他分支仍不完整。不能把这些记录当成 59 名/118 分支全迁完。
- 法宝 14 族、套装 10 套有组件证据，正式 fabao/suit 字段已接当前服务端；不等于全部实际穿戴/保存/战斗路径通过。
- 48 个装备词条均已覆盖本轮定向迁移和改表验证；完整英雄分支、正式构筑/保存和实际入口尚未完成，不能把词条切片通过当作完整战斗验收。
- 导出链当前产出 63 份文件（新增第 13 张目标策略表，之前各阶段为 59），客户端说明和服务端由同一正式源生成。不要手改生成 JSON。
- 后续定向矩阵：词条 19（9/9）、词条 1/3（9/11）、词条 2（13/9）；均不代替全分支验收。
- 历史完整矩阵 `full-post-description-results.json` 已通过：132 项错误拦截、228 项同二进制改表对照、客户端/服务端同源说明校验。之后的新增内容以上述定向矩阵为证据，不把历史完整矩阵称为当前全量。原说明量纲错误及修复记录保留；该矩阵不代表全部 118 分支。

## 最新数据/执行细节

- 12 A/B 完整实现见整合文档最新续接段；作者 shield-full.mjs（170 效果/47 规则，AV binding_scope）已执行，不要重跑旧 shield-core 作者覆盖。团队光环按受盾方活人队伍单例，效率合并一次取整；A 121/122 的效率/第三参数/构造后加时、目标每回合一次缺血治疗；B 121 反击、122 常驻 18% 和前两次 35% 合系数爆发、过期剩余一半、实际扣血 15% 转盾和来源每回合最大 HP 12% 原始预算均已表驱动。驱散不触发英雄专属回报；死亡/二次/124 转换盾仍只抑制旧被动。自盾分享用分支加时前 uint8 effectTurn，本体 256/分享 255 已由原二进制证实。
- 公共反震已补原分支的实际扣血基数/门控、每回合 3 次、50% 扣血上限、二次伤害抑制；参数由第 45–47 条规则维护。旧 thorns 定向的 160/1200 只代表旧公共输入，当前对应 80/720；改表重新覆盖并冻结，不把旧记录当当前来源一致性证据。
- 失败诊断保留 shield-full-failure.txt：查询预算校验过严、原测试注入二次位串场、全盾吸收多抽反震 RNG、旧非法预算夹具已变合法、选择器非法上下文先报字段错误。测试器现在对运行时负例也应用精确 CaseName；默认空选择仍执行全矩阵。38/29 是明确筛选范围，不能与历史 82/7 比作覆盖率升降。
- combat_effect AM 为 `cap_ratio_source`，支持 constant、gear_value、affix_value1、affix_value2。动态比例与动态上限有绑定/范围校验，描述使用同一系数并按执行器截断。
- duration=-1 表示导出时继承所绑词条的 duration；值必须 1–255。次数 -1 继承对应词条次数，0 次数仍表示不限。
- 词条 5、14 原 equipment_affix.duration 为 0，而旧代码写死 2；目前由正式 combat_effect 的 duration=2 维护，不盲目继承 0。
- 护盾贡献在同一次事件内保留万分比精度，合并后统一取整。overheal 部分另受正式 overheal_shield_conversion_cap_bp（当前 10000）约束，再进入护盾效率和全身盾上限。英雄 31 的 reservedOverheal 尚未迁移，不能用这个总上限替代其分配规则。
- 词条 8 在分支/法宝 after_revive 之后执行（优先级 20）。每战一次给实际第一个处理的复活目标，同条件死者不保证按站位升序。测试从主协议读处理顺序。
- after_thorns 在反震 DecreaseHp 后触发；先 gate 占次数，再按剩余伤害转盾。反震全部被盾吸收仍占次数。反震持有者死亡不触发。
- 公共规则影响双方和分支 0。被动复活清死亡状态过早、死亡名单删除后跳过后继等问题已修复；完整原二进制固定种子差分尚未完成，不能把局部公式参照冒充差分。
- 词条 19 的 after_direct_kill 先 gate 占次数，再以原受击排序选其他存活敌人中当前 HP 最低者；0 溢出不占次数、无候选占次数、反击不触发。原此目标器不消耗 RNG；新增通用 gate 预判保证未通过门控时不会调用可能有 RNG 的目标器。定向矩阵 overkill-results.json 为 9/9，通过，不重跑该阶段。
- 词条 1/3 在原 OnAffixShieldLost 调用点派发通用 source/bearer 两个事件；累计吸收量大于 0 才派发，过期/驱散也可能触发。词条 3 原本忽略禁疗，正式表以 restore_hp 保留，不能改成普通 heal。二次移除遵守公共深度限制；与原分支未限制递归的差异仍需解释。
- 原 r3 的 RunCombatDataRegression 组件断言退出 0，实际事件协议编号 5001/5003/5019 通过；后续常规 kapai.exe 的护盾分享、援护组件已通过。它们仍不能替代全部 118 分支或 Unity 真实入口验收。
- 词条 2 使用 after_self_shield、lowest_other_ally 和 duration_source=event_duration；接受后的自盾量/持续时间进入事件，排除自身，按万分比整数血比排序、同值沿用队列；无候选也占次数。源盾持续 0 不接受、不占次数，255 可继承，损坏事件 0/256 显式拒绝。嵌套深度由正式 combat_event_policy 第 8 行维护。女娲原队友溢出盾 150 随后被同源分享盾刷新为 39；关闭分享事件仍保留 150，不是 0。
- shield-share-results.json 为 13 拒绝/9 改表，runtime-shield-share-boundaries.log 全组件退出 0、ctest-shield-share.log 4/4、diff-shield-share-final.log 通过。当前最新二进制恢复常规 kapai.exe（build-shield-share-boundaries.log）；不要用旧 r3 代替。

## 可复用工具与证据

PowerShell 7/UTF-8。Git 使用 `C:\Program Files\Git\cmd\git.exe`。Python/Node 使用 `C:\Users\Admin\.cache\codex-runtimes\codex-primary-runtime\dependencies` 下的运行时，普通 python 别名不可用。

所有辅助脚本/日志在本工作树 `.local/hero-affix-integration/`；不要全量输出日志或整个 COMBAT_DATA_RESULT。

- 服务端编译：`unityserver/tools/Build-UnityServer.ps1 -VcpkgRoot E:/neiwang_kapai/Game/tools/local/vcpkg`。头文件变更约 6–8 分钟，普通源文件约 30–60 秒。日志须检查实际编译结果及 DLL 部署，不能只看外层 exit code。
- 二进制：`.local/unityserver-build/server-win/Debug/kapai.exe`；cwd 必须 `unityserver/config`；`--combat-data-regression` 全断言，`--combat-data-probe` 供改表差分。不会打开数据库或监听网络。
- 正式导出：`unitydata/tools/Export-UnityOwnedTables.ps1 -Group HeroCombat`。
- 改表测试：`unitydata/tools/Test-CombatDataExport.ps1`，传 ServerExecutable/EvidenceDirectory；可用 CaseName 做精确筛选，通过同进程 hashtable splatting 传数组。无 CaseName 为完整矩阵。测试运行时禁止修改正式表、导出器或二进制。
- `ctest.exe --test-dir .local/unityserver-build/server-win -C Debug --output-on-failure`，最新 thorns 4/4 通过。
- 工作簿必须用 artifact-tool 编辑。现有 `.mjs` 作者脚本和 graft-rule-sheet.py 组合保留无关 XLSX 包部件；不可直接用有损全书重导替换正式文件。列头约定：第 1 行 key、第 2 行 CS、第 3 行说明、第 4 行类型。
- 最新作者：shield-conversion.mjs、revive-guard.mjs、thorns-shield.mjs。不要重新跑旧作者覆盖新行/字段。append-sheets.py 只用于新增 sheet，不能重复追加。
- 本轮最新作者为 shield-loss-affixes.mjs（正式列名映射），包括第 94–97 行及词条 19 的 presentation_skill 修正。不要重新跑旧 overkill/thorns 作者覆盖这些新内容。正式表已导出；无需为续接再次跑作者。
- 构建缓存使用 C:\Users\Admin\.codex\worktrees\6513\Game（与 D 路径同一 checkout）。当前已恢复常规 `.local/unityserver-build/server-win/Debug/kapai.exe` 和默认构建，不再需要 r3 的 TargetName 绕行。原 build-shield-loss-protocol.log/r3 仅为文件锁历史证据。
- 文件锁在用户关闭杀毒软件后未再阻断定向矩阵，复试证据 test-shield-loss-antivirus-retry.log / shield-loss-results.json。没有取得防护拦截记录，不能认定唯一根因。原 Restart Manager 无结果、原生句柄枚举中断及 test-shield-loss-launch.log 失败都保留；没有由代理修改防护设置或关闭无关程序。
- 现有 Test-CombatDataExport 增加共享只读哈希及显式 Dispose 的子进程执行；保留测试前后 SHA 相等、正式源不变检查，仅 CreateProcess 32/33 重试，已启动的断言不重跑。已通过本次词条 1/3 的实际矩阵，不宣称代理修复了外部防护设置。
- 最新组件证据 runtime-shield-loss-final-attempt.log（退出 0），基础 ctest-shield-loss.log（4/4），静态 shield-loss-policy-static-tests/results.json（3 拒绝、0 改表、runtime_tested=false）、diff-shield-loss-policy.log。失败与夹具修正详见 shield-loss-failure.txt，不能删除或覆盖原日志。临时依赖副本在 runtime-temp-path.txt 指向的本轮 Temp 子目录，待锁释放后仅清理该已核对目录；正式交付和源码都在项目内。
- 本轮 Temp 副本已核对绝对路径和限定目录名；自动审批拒绝删除（仅返回 blocked by policy）。副本保留，不绕过策略或重复请求清理；不影响当前构建与测试。
- 最新通过日志：build-thorns-shield.log、runtime-thorns-shield.log、ctest-thorns-shield.log、verify-thorns-shield-workbooks.log、diff-thorns-shield.log。
- 冻结结果：shield-conversion-results.json、revive-guard-results.json、thorns-shield-results.json。原错误：shield-rounding-failure.txt、revive-guard-failure.txt；不要删或覆盖失败证据。
- MCP 备用桥：Invoke-Mcp.ps1，http://127.0.0.1:8080/health，mcp-session.txt。仅在 Unity 编译/Prefab/Play 时使用；当前没有启动本工作树 Editor。

## 下一步与未完成验收

1. 历史完整矩阵冻结为 full-post-description-results.json（132/228），无需无修改重复重跑。原失败保留在 test-full-post-shield.log/full-post-shield-failure.txt，不能覆盖。恢复执行前先检查当前构建/测试会话，禁止同时启动第二个重任务。
2. 词条 1/3、2、19 当前定向验证已关闭，不要无修改重跑。用户授权的 E 盘 Unity 重启已完成且 MCP 恢复；不需再次重启。
3. 词条 26/28/38 定向 23/21 已完成（break-dispel-results.json），无需重跑。after_shield_break、after_enemy_dispel 共用次数键 40280，after_buff 按三种易伤和攻击类型追加减防。AO emit_action（Buff 随原动作展示）和 AP check_skill_immunity（只控制技能层过滤，底层控制规则仍执行）仅 buff 可设 0。原回调绕过技能层过滤，新增行设为 0；不改变原免疫行为。
   最新 build-cleanse-dispel.log / runtime-cleanse-dispel.log 全组件退出 0、ctest-cleanse-dispel.log 4/4、diff-cleanse-dispel.log 通过。cleanse-dispel-results.json 为 21/19；词条 7/40 同样保留死亡来源/目标、技能层过滤和随原动作展示，已关闭本次定向验证，无需重复。下一切片为 10/13/36 的每回合累计恢复预算；满血尝试也占量、原回调忽略禁疗、10/13 无存活限定而 36 有存活限定。不要提前启用绑定。
   10/13/36 实现已写入并导出（作者 heal-amount-budgets.mjs 已执行），新增 AQ amount_budget=source_turn，以来源/次数键累计每回合尝试量，先预留同事件多目标额度，概率/额外预算通过后在实际 HP 处理前占量。只有 heal/restore_hp/damage、source 计数域、正 cap_bp 可用，动态 cap 系数为 0 表示累计额度 0。restore_hp 配 self_any/target_any 时允许走原统一复活路径，36 则保持来源存活要求。新增 State.amounts 在 Clear 时必须清空。
   10/13/36 已关闭本次定向验证：heal-budget-results.json 冻结 24 项错误拦截、24 项同二进制改表对照；同源说明、正式源及二进制 SHA 通过。build-heal-budgets-natural.log / runtime-heal-budgets-natural.log 退出 0，真实反击恢复 800、二层 DOT 恢复 600；满血尝试、禁疗、禁止复活、动态零上限和同事件多目标共用量均有证据。ctest-heal-budgets.log 为 4/4，diff-heal-budgets-final.log 通过，不重跑此阶段。
   原暂停、编译部署共享锁、错误夹具列均保留在 heal-budget-failure.txt。Build-UnityServer.ps1 默认 ParallelJobs=1，避免多个目标同时部署同目录 DLL；串行构建已通过，不能据此认定杀毒软件为唯一根因。Test-CombatDataExport 支持按正式列头定位夹具字段。
   15/20/31 概率切片已通过：chance-affixes.mjs 已执行并正式导出；AR probability_source 为 constant/affix_value1/affix_value2。先 gate 消耗尝试次数，再 chance_gate 抽一次 Random（0%/100% 也抽），再按成功门控执行。15 在完整反击返回成功后派发 after_counter_success；20 在扣 Buff/死亡被动/击杀奖励后派发 after_kill_rewards，包括召唤物；31 保留原抵抗调用点。cooldown.argument_role=all 供全部技能减冷却。
   chance-affixes-results.json 冻结 32 项错误拦截、23 项同二进制改表对照，同源说明、源及二进制 SHA 通过。build-chance-affixes-native.log / runtime-chance-affixes-native.log 退出 0：自然反击减冷却 1、后继 RNG 相同；自动回合击杀/召唤物击杀均减全部技能 CD 1；真实 612 技能控制抵抗补偿 8 战意、尝试 1 次且无嘲讽。ctest-chance-affixes.log 4/4、diff-chance-affixes-final.log 通过。下一切片为死亡词条 41/42；42 统计双方非召唤物死亡，不能误缩成友方。
   41/42 已关闭定向验证，作者 death-affixes.mjs 已执行；build-death-affixes.log / runtime-death-affixes.log 退出 0。41 在原 death 事件后派发 after_death_guard，先 gate 占次数，再 other_allies 给存活队友免伤；即使原 death 将持有者复活也排除自身。42 在同一旧回调的后继位置向双方活人派发 death_observed；victim_summoned 条件和 effect_battle_count < affix_value2 由正式表维护，Buff 消失不退回每战计数。两者原回调无独立动作，保持 emit_action/check_skill_immunity=0。
   death-affixes-results.json 为 29 拒绝/19 改表（含原 death 路线受影响的 4 个对照），同源说明、源及二进制 SHA 通过；真实 DecreaseHp→DiePassiveAcion、二次深度和无 RNG 断言通过。ctest-death-affixes.log 4/4、diff-death-affixes.log 通过。death-affix-failure.txt 保留无限次数夹具将两层误算为一层的错误及修正，原失败日志不覆盖。
   34/37 已关闭定向验证：removed-antiheal-affixes.mjs 最新作者已执行，新增 after_buff_removed（参数/剩余回合快照）和 after_heal_with_antiheal（原主动治疗结算位置）；34 用原参数 × max(1,剩余回合) × value1，单次来源攻击 value2 上限，0 上限不限。伤害 target_any 保留死亡目标残留盾的处理；无实际 HP/盾变化时先返回再登记击杀，避免空恢复/空伤害伪记击杀。37 使用禁疗首个来源，保留死亡来源与原技能层绕过、随原动作展示，持续固定 1 写在正式效果表（原词条 duration=0，不能继承）。
   removed-antiheal-results.json 为 31 拒绝/22 改表，同源说明、源及二进制 SHA 通过。build-removed-antiheal.log / runtime-removed-antiheal-final.log 退出 0；原生 ClearBuff 灼烧 1200、过期 400、封顶 8000；真实治疗在全禁疗/零禁疗比例时均减速 1000。ctest-removed-antiheal.log 4/4、diff-removed-antiheal.log 通过。三档灼烧说明 20/30/40%，动态上限 0 显示不限。剩余词条 16/18/23/30/33/43/44，下一步 43；原 GetTeamBestAffixValue 不排除死亡队友，且 value1/value2 分别取最高，必须保留。
   43 已关闭定向验证：summon-affix.mjs 已执行并导出，before_summon_attack/hp 为确定性查询；新增 affix_scope=team_highest_value2 与既有 team_highest 让两种曲线独立取高，均保留死亡队友。先查询两种加成，再改基础攻击/最大 HP/当前 HP，保持缺失生命绝对值。当前仍在原 ApplyAffixSummonBonus 调用点标记召唤物，未改变召唤来源路径。
   summon-affix-results.json 为 34 拒绝/15 改表，同源说明和源/二进制 SHA 通过；build-summon-affix.log / runtime-summon-affix.log 退出 0、ctest-summon-affix.log 4/4、diff-summon-affix.log 通过。独立非单调曲线、死亡候选、双方、无持有者、整数取整、无 RNG、召唤物不计死亡层数均有证据。有意修复旧 32 位攻击乘法溢出，2,000,000→2,480,000，并按属性类型上限封顶，完整原二进制差分仍待完成。剩余词条 16/18/23/30/33/44，下一步 30/44 的概率持续时间处理。
   30/44 已关闭定向验证：duration-chance-affixes.mjs 已执行；accepted_control 在 ApplyCombatControl 之后派发，hard_control 读取替代后的正式分类，chance_gate 再 add_duration；value2 只作大于 0 的开关，固定 +1 来自效果行，0%/100% 仍抽一次 RNG。44 在 BasicFightAction 原位置派发 before_hp_change，以每目标 chance_gate 成功计数替换原位掩码；失败不占次，extend_buff 延长目标现存各来源状态，随原攻击显示。目标计数的 gate_count 使用该目标的成功次数。
   duration-chance-results.json 为历史 44 拒绝/21 改表；第二次 4 回合控制先减到 2 再加到 3、首领替代不抽该词条 RNG、44 主动延长至 6 及每目标预算仍有效。但当时将 44 的 255 边界误判为 uint8，该断言已由下面 shield_core 原字段/原二进制检查纠正：30 的显式 uint8 255+1→0，44 的 int leftTurn 255+1→256。历史报告不再作为 44 溢出边界证据。首领替代持续夹具错误仍保留 duration-chance-failure.txt。
   16/33 已写入和正式导出，最新作者 buff-payload-affixes.mjs 已执行；新增 AS parameter_count（buff 重复 1–4 个算出值，copy_buff 用 0 复制事件载荷）和 AT origin_level（0 继承事件，正数固定）。原词条直接 AddBuff 的效果行固定来源等级 1，补修此前适配器误继承高等级事件的问题（新检查 38 的等级 9 原事件）。16 的 after_direct_hp_loss 保留原位置，按实际生命损失/当前最大生命阈值给两个相同反震参数，原本可在本次反震前立即生效。
   33 的 after_buff 带完整参数快照和接受后持续回合；event_stack_group/count 读取正式周期族并统计所有来源。先 gate 占尝试次数，再 chance_gate 抽概率，再 first_unstacked_enemy 找第一个存活且无该族的敌人；无候选仍占次数并抽 RNG。copy_buff 复制全部载荷（不截成 4 个参数），独立来源技能 0/等级 1 由表维护，随原动作且绕过技能层过滤，公共 AddBuff 规则仍执行。公共 CombatEvent 增加可选载荷参数，Event/Command 有自有 vector 快照。
   16/33 已关闭定向验证：buff-payload-results.json 冻结 52 拒绝/25 改表，同源说明、源及二进制 SHA 通过。build-buff-payload-actions.log / runtime-buff-payload-actions.log 退出 0、ctest-buff-payload.log 4/4、diff-buff-payload.log 通过。16 双参数各 1600，当次反震立即造成 320；普通受击战意消息保留，装备与未装备同路径新增动作差额 0。33 原生完整复制 5 参数、接受后 5 回合、来源技能 0/等级 1，随机数后继一致；2/3 层边界、失败/无候选占次、混合来源与另一族改表均覆盖。族编号来自正式表：毒共用 1，灼烧为 11，不能猜成 2；失败与夹具修正保留在 buff-payload-failure.txt。原 PowerShell 错误有一次逃出重定向，已在台账抄录原 tool 错误，后续外层 catch 保存 ErrorRecord 再退出。
   余下 18/23 的源语义：18 在命中后的暴击判定成功时清层、非暴击时加层且封顶，before_attack 用旧层数加暴击；未命中不变。23 的击杀尝试预算与待消费标志必须分开，下一次非首段、非反击且已命中的攻击才消费，跨到击杀下一回合有效，之后过期。不要在命中前消费。可复用 State.counts 表达持久计数及 lastTriggered，不应把清标志当成退还尝试预算。
   18/23 已关闭定向验证：stateful-affixes.mjs 已执行并导出，新增 counter_count_ID/counter_age_ID 持久事实及 reset_counter；引用须是 source gate，重置只允许无频次/间隔预算的记录，禁止返还尝试预算。after_critical_roll 在真实暴击判定后派发；landed_attack 在命中后、计算伤害前消费。23 先 gate 占次数，再替换待用记录，记录安装先于词条 19 的后继伤害；消费不退次数，失效记录可由下一次合法击杀替换。
   stateful-affix-results.json 冻结 59 拒绝/14 改表（含三档不限次数说明检查），build-stateful-deterministic.log / runtime-stateful-deterministic.log 退出 0；暴击加成 800→1600→2400、暴击归零，真实击杀后 1000→1300→1000，未命中/首段/反击保留待用，下一回合有效、再后一回合失效，二层回调和无额外 RNG 通过。ctest-stateful-affixes.log 4/4、diff-stateful-affixes.log 0，main-protection-stateful.json 91 文件差异 0。失败/夹具修正保留 stateful-affix-failure.txt；第一次编译错误后的旧二进制加载拒绝不是验收。下一步核对女娲 A/B 的原始 AddBuff 来源/免疫语义与治疗后重新选择最低目标，仍不启用绑定。
   最新已执行作者为 nuwa-origin-contract.mjs，嫁接 sheet4 并导出 59 份文件；新增 AU origin_skill（-1 沿用展示技能，0 原始无技能来源，正数固定）。旧作者最高只读到 AT，禁止重跑覆盖 AU。女娲 1002/1010 原 AddBuff 无技能免疫过滤、来源技能 0/等级 1；1002 无独立动作，1010 独立展示 101、来源仍为 0。六条既有护盾效果均来自原 AddAffixShield，正式设来源/展示技能 0、等级 1；适配器同事件合盾必须保持来源/等级/展示一致，否则拒绝歧义配置。
   nuwa-origin-results.json 已冻结 58 拒绝/12 改表；build-nuwa-origin-zero-metrics.log / runtime-nuwa-origin-stable-metrics.log 退出 0，ctest-nuwa-origin.log 4/4、diff-nuwa-origin.log 0，main-protection-nuwa-origin.json 91 文件差异 0。真实治疗后最低血比从站位 2 变 3，免伤只落在 3；高等级施法仍保持原始 Buff/合盾来源技能 0、等级 1；独立展示字段、过滤开关和来源曲线均有改表对照。遗漏导出清单、缺失 Buff 指标 null、旧损坏 op 夹具被新来源校验先拦的诊断保留 nuwa-origin-failure.txt；运行时损坏诊断失败现自动保存原始输出。不要重复该阶段。
   女娲独立 SourceReviveFlags 已关闭定向验证：原 source 的 heroBuildRevivedTargets 只记录成功的 102，不能用默认公共 revive_per_source_target=1 冒充。最新作者 nuwa-revive-record.mjs 已执行、嫁接 sheet4 并导出 59 份，新增 1017/1018（行 156/157、组 103）；after_revive 的确定性 target gate 记实际次数，before_revive_eligibility 读取 target_counter_count_ID，目标年龄事实为 target_counter_age_ID。source/target 事实引用必须匹配 gate 计数域，reset_counter 仍只能重置 source 记录。公共 CombatCanRevive/CombatHaveReviveTarget 增加可选 skill；AI IsRoleSkillUseful、GetSkillTargetRange 和实际治疗逐目标复查传入实际技能，公共无技能预算查询保持原义。
   build-nuwa-revive-ai.log / runtime-nuwa-revive-ai.log 原生退出 0：A/B 首次恢复 2500/4000；GetUnitAISkillId 从 102 回退 0；同目标重复/跨回合被禁，其他来源/新目标仍可用，104 查询不继承 102 标记，无额外 RNG。nuwa-revive-record-results.json 冻结 68 拒绝/8 改表：公共同源上限 2 时 public_can_revive=1、技能资格和 AI 仍 0；独立阈值 2 后实际复活 2500/4000、AI 102、次数 2。别名、目标年龄和三处实际调用同步生效。ctest-nuwa-revive-record.log 4/4、diff-nuwa-revive-record.log 0、main-protection-nuwa-revive-record.json 91 文件差异 0。首次导出模板 alive_only 与组 103 冲突已修正为 1，原日志与拒写说明保留 nuwa-revive-record-failure.txt。6 条绑定未开放，不重做已通过切片。
4. 完成其余 118 分支，保持基线机制；不要提前启用不完整绑定。补女娲治疗后最低目标变化、特殊免疫与被动治疗调用链。
   原二进制差分环境已建立：原提交隔离到 .local/hero-affix-integration/original-1a242cf3，原二进制 original-server-build/Debug/kapai.exe，cwd 原目录 server/config。original-source-fingerprint.json 冻结 155 个源码文件，原始构建/回归通过（runtime-original-unmodified.log，包括原版 118 合成冒烟），这不代表当前数据版 118 已迁移。构建脚本副本只改并发 4→1。随后仅在原 RunHeroBuildRegression 添加环境变量测试入口和共享 inc，original-harness.patch 保存差异；Test-HeroAffixBinaryDiff.ps1 校验其余源哈希及移除入口后原文件一致。原版生产战斗代码不改。
   共享 fixture 为 unityserver/tests/HeroAffixBinaryDiff.inc，原副本 server/tests 下必须同哈希；HERO_AFFIX_BINARY_DIFF=1 仅子进程环境使用。当前版 --combat-data-regression、原版 --hero-build-regression，均在 DB/网络启动前进入离线入口。首次 48 对照（A/B×3种子×8场景）记录 binary-diff-nuwa-first/results.json 的 29 个协议差异（其余状态/RNG 一致）；已修复，不加白名单。原 AddAffixShield 无独立动作，故六条盾效果正式 emit_action=0，合盾展示元数据必须一致。五策略目标排序加入第 13 张 combat_target_policy，先保留原 GetSkillTargetSelCondition 的 RNG，再按表排序、最后截人数；DOT 计数明确来自表 [8,9,10,11,46]，不擅自计入另两个周期伤害状态。
   最新作者 shield-target-policies.mjs 已执行；sheet4 只嫁接盾标记，第 13 表首次用 append-sheets.py 追加、后续仅嫁接 sheet13。禁止再次 append。当前 63 产物，sheet13 列宽已从误用像素数修正为 Excel 字符宽，未改其余工作簿部件。shield-target-policy-results.json 冻结 85 拒绝/16 改表（含 5 个被展示校验改动影响的旧负例）；build-target-policy-formal-roles.log / runtime-target-policy-formal-roles.log 退出 0；双边、先排序后截 5 人、站位同值、仅自身指定 DOT、无额外 RNG 均通过。多宝正式常规 152/战法 151，夹具已按 HeroSkillRoleCfg 读取，禁止猜编号。RapidJSON 旧版 GetArray 编译失败与夹具角色误置保留 shield-target-failure.txt。
   最终 binary-diff-nuwa-final/results.json 为 48 组全字段/协议字节 0 差异；原源码保护检查通过，CTest 4/4、diff 0、main-protection-shield-target.json 91 文件差异 0。早期 nuwa-origin-results 的合盾首包 0 来自当时多发的盾动作，展示证据由此阶段取代；现在合盾不另发动作，仅治疗结束免伤独立展示 101。不要重跑该阶段。下一步英雄 12 A/B 完整护盾：当前组 122 只有 1201 盾破伤害，效率、持续、初始免伤、破盾/过期回报和特殊回调仍待源闭环；原源位于参考 fight.cpp 2528/2746/2887 和 fight_hero_build.cpp 548 附近。
   英雄 12 公共前置已关闭验证：原 appliedDuringRound 在当前版缺失，SFightBuffData 新补字段和正式 buff_tick_same_action_skip=1（规则 44/行 48）；出手者本次行动新加 Buff 不立即扣时，其他目标照常。过期盾旧被动改按 max(0,原量-剩余)；before_shield_passive 确定性布尔查询使 12 A/B 对死亡来源、二次伤害、转换盾均抑制旧持有者被动。新增仍禁用的绑定 121/12A、效果 1210/1220（行 158/159）；1201 补 event_skill!=124，防转换盾回炸。原 12B 其他爆发/转换尚未迁移，不能启用。最新作者 shield-core-rules.mjs 已执行，嫁接 sheet4/5/7、导出 63；当前/原编译已完成。
   Test-HeroAffixBinaryDiff.ps1 新增 Scope=shield_core（30 组），Nuwa 默认仍 48；共享 inc 新增同动作计时、过期吸收量、转换盾/死亡来源/二次伤害抑制和 44 的 int >255 实际攻击。原 CPP 仅测试入口不变；build-shield-core-int-duration.log / runtime-shield-core.log 原生退出 0，build-original-shield-core.log 原引用构建通过。binary-diff-shield_core-core-final/results.json 30 组、binary-diff-nuwa-core-final/results.json 48 组全字段/协议 0 差异；原源码保护通过。shield-core-results.json 冻结 82 拒绝/7 改表，含 44 的 amount=2 时 257 边界；同源说明、源及二进制 SHA 不变。CTest 4/4、diff 0、主线哈希/清单差异 0，离线进程残留 0。原生旧被动伤害总量 1000 对应 300、过期已吸收 600 对应 180；规则关闭/抑制开关/来源技能过滤的改表均生效。不重跑本阶段。
   12 后续源事实：A 的友方活人盾效率光环 +1200 单例，按受盾方队伍找来源；121 额外 +2500 效率且已有第三参数 +800，122 +2000 效率并 ++data.leftTurn；B 的 121/122 效率 -1500/-2000。A 盾失按目标每回合一次恢复缺血 5%，即使死目标也先占次；B 破裂 121 返攻击者吸收量 30%，破裂 122 每次额外全体 18%，前两次另加全体 35%，过期 basis=剩余/2；实际 HP 损失合计 15% 转最低血比队友护盾、来源每回合最多自身最大 HP 12%，origin=124、2 回合、独立动作。二次伤害、origin124、来源死亡均直接退出特殊回报但仍抑制旧被动。
   注意原 SFightBuffData.leftTurn 是 int，12A 的 ++data.leftTurn 和 44 的 +=value2 都不回绕；只有 30 等直接改 uint8 effectTurn 的路径回绕。当前 extend_buff 已纠正为 int 加法（正常 255+1=256、255+2=257，并防 int 上界溢出）。原自盾分享用 effectTurn（加分支时长前），不能盲目把分支后的 256 传给原 uint8 分享接口。完整 A/B 仍需团队光环/参数加值/数据构造后时长、实际伤害回填与转盾预算的通用原语，禁止硬编码英雄编号绕过。44 误判和允许旧被动后额外动作数猜错的夹具诊断保留 shield-core-failure.txt；后者实际造成旧被动伤害 300，m_extActionMsg 仍 0，已更正断言，未改生产消息通道。
5. 完整原分支二进制同输入/固定种子差分并解释有意差异；正式角色与装备预算平衡验收。
6. Unity 正式 Prefab/Catalog/协议/说明消费/SQLite 保存与失败回滚、旧档重登、入场快照、数据打包。布局和资源引用留在 Prefab。
7. 通过 MCP 真实入口选流派/策略/换装/自动连战；连续使用同一次 Play，除真实问题外不重登。当前这些全部未验收。
8. 重新同步主线并处理冲突，保留境界/洞府/资源维护成果；交付具体范围和验证后等待单独提交授权。
9. 用户追加的最终战斗判定顺序文档尚未交付：按最终代码标出入场、排序、策略、选技、命中/暴击/护盾、追击/反击、DOT、死亡/复活、回合末，以及内容插入点、预算、递归和冲突案例。不要把当前切片顺序当最终版。

验收报告必须区分静态、服务端编译、自动测试、Unity 编译、真实交互及用户最终体验，不能合并为“全部完成”。
