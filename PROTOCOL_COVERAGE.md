# 协议覆盖矩阵

> 自动生成时间：2026-07-08 09:51:26
> 生成命令：`pwsh -ExecutionPolicy Bypass -File tools/local/Export-ProtocolCoverage.ps1`

当前文件用于跟踪本地测试服协议覆盖，不等同于完整人工 UI 验收。

## 覆盖统计

| 项 | 数量 |
|---|---:|
| 服务端注册协议 | 148 |
| smoke 已覆盖协议号 | 67 |
| 未覆盖注册协议 | 81 |

## 未覆盖分层统计

| 分层 | 未覆盖数量 | 推进方式 |
|---|---:|---|
| 查询 | 13 | 优先补入 `-Extended`，要求有响应且日志干净。 |
| 低风险动作 | 10 | 优先补入 `-Actions`，使用空状态/无效参数/只读变更。 |
| 可控改档 | 6 | 补入 `-Mutations`，只操作一次性角色和本地测试字段。 |
| 真实消耗 | 9 | 补入 `-Positive`，一次性角色给足测试货币并校验扣减/返回。 |
| 战斗结算 | 3 | 单独分支验证，优先使用可重复的一次性角色和可控战斗入口。 |
| 人工 UI | 25 | 保留给客户端点击路径、复杂状态机或无法安全脚本化的入口。 |
| 服务端内部/跨服 | 15 | 默认不进客户端 smoke，除非本地有明确触发入口。 |

## 下一批优先补覆盖

| 协议号 | 名称 | 分层 |
|---:|---|---|
| 16 | `PRO_GET_ITEM_INFO` | 查询 |
| 19 | `PRO_OTHER_ITEM_INFO` | 查询 |
| 40 | `PRO_PET_SKILL` | 查询 |
| 49 | `PRO_FINISHED_MISSION` | 查询 |
| 51 | `PRO_QUERY_PET_INFO` | 查询 |
| 62 | `PRO_SYSTEM_INFO` | 查询 |
| 69 | `PRO_OTHER_PET` | 查询 |
| 100 | `MSG_QUERY_SCENE` | 查询 |
| 110 | `MSG_BANGPAI_ZHONGZHI` | 查询 |
| 117 | `MSG_CLIENT_LIST_FUQI` | 查询 |
| 178 | `MSG_GET_360_TOKEN` | 查询 |
| 195 | `MSG_WORLD_MAP_TRANSPORT` | 查询 |
| 238 | `MSG_USER_MSG_TO_WORLD` | 查询 |
| 9 | `PRO_ROLE_MOVE` | 低风险动作 |
| 10 | `PRO_JUMP_SCENE` | 低风险动作 |
| 26 | `PRO_MSG_CHAT` | 低风险动作 |
| 29 | `PRO_USER_TEAM` | 低风险动作 |
| 92 | `PRO_SPEC_CHAT` | 低风险动作 |
| 168 | `MSG_DOPTION_CALLBACK` | 低风险动作 |
| 190 | `MSG_FUBEN_OPTION` | 低风险动作 |
| 192 | `MSG_HE_CHENG_OPTION` | 低风险动作 |
| 199 | `MSG_HUODONG_OPTION` | 低风险动作 |
| 253 | `MSG_KUN_LUN_SHAN_TEAM` | 低风险动作 |
| 12 | `PRO_OPEN_INTERACT` | 可控改档 |
| 15 | `PRO_UPDATE_PACK` | 可控改档 |
| 20 | `PRO_IGNORE_DIALOG` | 可控改档 |
| 58 | `PRO_UPDATE_NPC` | 可控改档 |
| 261 | `MSG_IGNORE_QIECUO` | 可控改档 |
| 263 | `MSG_IGNORE_FUNC` | 可控改档 |

## 已覆盖注册协议

| 协议号 | 名称 | smoke case |
|---:|---|---|
| 8 | `PRO_ROLE_PACKAGE` | package |
| 24 | `PRO_PET` | pet_all |
| 27 | `PRO_Friend` | friend_apply_list, friend_black_list, friend_gift_list, friend_list, friend_recommend |
| 34 | `PRO_PLAYER_INFO` | player_info_self |
| 35 | `PRO_NEAR_PLAYER_LIST` | near_player_list |
| 37 | `PRO_TASK_LIST` | mission_daily, mission_fund, mission_main |
| 48 | `PRO_ZHEN_FA` | formation_info |
| 52 | `PRO_FIND_RESOURCE` | find_resource |
| 54 | `PRO_BANGPAI` | bangpai_apply_missing, bangpai_apply_zero, bangpai_create_short_name, bangpai_create_unique, bangpai_donate_info, bangpai_donate_money_1, bangpai_info_self, bangpai_list, bangpai_member_list |
| 55 | `PRO_YAO_LING` | yaoling_cost |
| 56 | `PRO_BANG_ZHAN` | bangzhan_info |
| 64 | `PRO_BANGPAI_COPY` | bangpai_copy_buff, bangpai_copy_chapter, bangpai_copy_huoyue |
| 65 | `PRO_Func_HotPoint` | red_point_func |
| 73 | `PRO_SWITCH_CHANNEL` | chat_channel_close_world, chat_channel_open_world |
| 74 | `PRO_SWITCH_INFO` | switch_info |
| 80 | `PRO_MY_BANG` | my_bangpai |
| 83 | `PRO_ITEM_DESC` | query_item_desc_bad |
| 88 | `PRO_GONGGAO` | gonggao_query |
| 89 | `PRO_AVAILABLE_TASK` | available_task_bad_detail, available_task_list |
| 90 | `PRO_SCENE_POS` | scene_escape_pos |
| 102 | `MSG_SERVER_HEART_BEAT` | heart_beat |
| 105 | `PRO_GET_TITLE_LIST` | title_list |
| 106 | `PRO_TITLE_OPTION` | title_hide_invalid, title_show_bad, title_unuse_invalid |
| 145 | `MSG_CLIENT_SAVE_VAL` | save_val_set |
| 146 | `MSG_CLIENT_GET_SAVE_VAL` | save_val_get_one, save_vals |
| 175 | `MSG_CLIENT_NET_CHECK` | client_net_check |
| 180 | `MSG_WING` | wing_base, wing_hide, wing_hide_mutation |
| 182 | `MSG_TASK_TRACK` | task_track_zero |
| 185 | `MSG_MOUNT` | mount_base, mount_collect, mount_hide, mount_hide_mutation |
| 193 | `MSG_USER_RANK` | rank_level, rank_power |
| 194 | `MSG_USER_PACKAGE_ITEM` | package_item_empty |
| 198 | `MSG_ANSWER_QUESION` | answer_question_get |
| 206 | `MSG_SYNC_TIME` | sys_time |
| 208 | `MSG_HELP` | help_title_list |
| 209 | `MSG_DAILY_ACTIVITY` | daily_activity |
| 217 | `MSG_FISH` | fish_room_list |
| 219 | `MSG_OFFLINE_EXP` | offline_exp_info |
| 220 | `MSG_VIP_OPTION` | vip_info |
| 221 | `MSG_SHOP` | shop_buy_bad_type, shop_buy_type4_tid1, shop_count_bad_type, shop_list, shop_refresh_bad_type, shop_refresh_type4 |
| 223 | `MSG_STAGE_GOAL` | stage_award_1, stage_award_bad, stage_goal |
| 224 | `MSG_PET_RANDOM_DRAW` | pet_draw_bad_op, pet_draw_info, pet_draw_single_type1, pet_draw_single_type2 |
| 225 | `MSG_DailyBoss_TASK` | daily_boss_info |
| 228 | `MSG_LEI_TAI_SAI` | leitai_score |
| 232 | `MSG_CAI_QUAN` | caiquan_invalid |
| 233 | `MSG_GET_SERVER_ID` | charge_server_id |
| 239 | `MSG_MOBAI` | mobai_base, mobai_panel |
| 243 | `MSG_PET_COPY` | pet_copy_info |
| 244 | `MSG_TREASURE_MAP` | treasure_map_info |
| 245 | `MSG_SHI_LIAN` | shilian_info |
| 246 | `MSG_FEI_XIAN` | feixian_data |
| 248 | `MSG_QUERY_ROLE_BY_NAME` | role_query_self |
| 249 | `MSG_GET_WORLD_LEVEL` | world_level |
| 259 | `MSG_TRANSFORM` | transform_card_info, transform_current |
| 262 | `MSG_PK_NOTICE` | pk_notice_state |
| 307 | `MSG_NEW_SHENQI` | new_shenqi_base, new_shenqi_current, new_shenqi_enhance_info |
| 312 | `MSG_MIANZHANPAI_TIME` | mianzhanpai_cd |
| 313 | `MSG_JIAOYI_HANG` | jiaoyi_buy_panel, jiaoyi_record, jiaoyi_sell_panel |
| 314 | `MSG_FLOWER` | flower_rank, flower_self |
| 319 | `PET_EQUIP_OPERATE` | fabao_list, fabao_takeoff_bad, fabao_wear_bad, pet_equip_list, pet_equip_master, pet_equip_search_count, pet_equip_strong_bad, pet_equip_takeoff_bad, pet_equip_wear_bad |
| 320 | `MSG_GUANQIA` | fuben_achievement, fuben_fight_bad, fuben_fix_empty, fuben_map_main, fuben_node_empty, fuben_reset_bad, fuben_sweep_bad |
| 321 | `MSG_SPIRIT` | tili_free_claim_1, tili_free_info, tili_info |
| 330 | `MSG_REAL_NAME_REG` | real_name_empty |
| 331 | `MSG_CLIENT_STRING_DATA_OPRATETION` | client_str_all, client_str_get_one, client_str_one_empty, client_str_set |
| 1001 | `PRO_USER_LOGIN` | login/select/create |
| 1002 | `PRO_ROLE_NAME_CHECK` | role_name_check_smoke |
| 1003 | `PRO_CREATE_ROLE` | login/select/create |
| 1004 | `PRO_SELECT_ROLE` | login/select/create |

## 未覆盖注册协议

| 协议号 | 名称 | 分层 |
|---:|---|---|
| 16 | `PRO_GET_ITEM_INFO` | 查询 |
| 19 | `PRO_OTHER_ITEM_INFO` | 查询 |
| 40 | `PRO_PET_SKILL` | 查询 |
| 49 | `PRO_FINISHED_MISSION` | 查询 |
| 51 | `PRO_QUERY_PET_INFO` | 查询 |
| 62 | `PRO_SYSTEM_INFO` | 查询 |
| 69 | `PRO_OTHER_PET` | 查询 |
| 100 | `MSG_QUERY_SCENE` | 查询 |
| 110 | `MSG_BANGPAI_ZHONGZHI` | 查询 |
| 117 | `MSG_CLIENT_LIST_FUQI` | 查询 |
| 178 | `MSG_GET_360_TOKEN` | 查询 |
| 195 | `MSG_WORLD_MAP_TRANSPORT` | 查询 |
| 238 | `MSG_USER_MSG_TO_WORLD` | 查询 |
| 9 | `PRO_ROLE_MOVE` | 低风险动作 |
| 10 | `PRO_JUMP_SCENE` | 低风险动作 |
| 26 | `PRO_MSG_CHAT` | 低风险动作 |
| 29 | `PRO_USER_TEAM` | 低风险动作 |
| 92 | `PRO_SPEC_CHAT` | 低风险动作 |
| 168 | `MSG_DOPTION_CALLBACK` | 低风险动作 |
| 190 | `MSG_FUBEN_OPTION` | 低风险动作 |
| 192 | `MSG_HE_CHENG_OPTION` | 低风险动作 |
| 199 | `MSG_HUODONG_OPTION` | 低风险动作 |
| 253 | `MSG_KUN_LUN_SHAN_TEAM` | 低风险动作 |
| 128 | `MSG_SERVER_XINSHI` | 服务端内部/跨服 |
| 255 | `MSG_KUA_FU_1V1` | 服务端内部/跨服 |
| 334 | `MSG_QUERY_KF_STATE` | 服务端内部/跨服 |
| 401 | `MSG_SERVER_KF_BANG_PAI` | 服务端内部/跨服 |
| 402 | `MSG_SERVER_SYSINFO` | 服务端内部/跨服 |
| 403 | `MSG_SERVER_KF_BANGZHAN_INFO` | 服务端内部/跨服 |
| 601 | `PRO_SERVER_QUERY_ONLINE_NUM` | 服务端内部/跨服 |
| 10001 | `MSG_SERVER_RANK` | 服务端内部/跨服 |
| 10002 | `MSG_SERVER_TONGTIANTA` | 服务端内部/跨服 |
| 10005 | `MSG_SERVER_SERVER_XINSHI` | 服务端内部/跨服 |
| 10006 | `MSG_SERVER_ARENA` | 服务端内部/跨服 |
| 10009 | `MSG_SERVER_ROLE_NAME` | 服务端内部/跨服 |
| 10022 | `MSG_SERVER_USER_POWER` | 服务端内部/跨服 |
| 20001 | `MSG_KF_LOGIN` | 服务端内部/跨服 |
| 65534 | `MSG_MGR` | 服务端内部/跨服 |
| 12 | `PRO_OPEN_INTERACT` | 可控改档 |
| 15 | `PRO_UPDATE_PACK` | 可控改档 |
| 20 | `PRO_IGNORE_DIALOG` | 可控改档 |
| 58 | `PRO_UPDATE_NPC` | 可控改档 |
| 261 | `MSG_IGNORE_QIECUO` | 可控改档 |
| 263 | `MSG_IGNORE_FUNC` | 可控改档 |
| 13 | `PRO_INTERACT` | 人工 UI |
| 32 | `PRO_USER_PK` | 人工 UI |
| 33 | `PRO_PLYAER_MATCH` | 人工 UI |
| 46 | `PRO_CHONG_ZHI` | 人工 UI |
| 53 | `PRO_FENGSHEN_SHILIAN` | 人工 UI |
| 68 | `PRO_SKILL_DESC` | 人工 UI |
| 101 | `MSG_CLIENT_ITEM_DEF` | 人工 UI |
| 152 | `MSG_HUODONG` | 人工 UI |
| 153 | `MSG_YINDAO` | 人工 UI |
| 154 | `MSG_GUAJI` | 人工 UI |
| 160 | `MSG_XIU_XIAN_LI_LIAN` | 人工 UI |
| 176 | `MSG_GOOGLEPLAY` | 人工 UI |
| 189 | `MSG_NPC_AUTO_TRANSPORT` | 人工 UI |
| 191 | `MSG_XINSHOUYINDAO` | 人工 UI |
| 201 | `PRO_PLAYER_DETAIL` | 人工 UI |
| 204 | `MSG_MEET_MONSTER` | 人工 UI |
| 211 | `MSG_PLAY_ANIMATION` | 人工 UI |
| 213 | `MSG_CHUANG_GUAN` | 人工 UI |
| 214 | `MSG_TONG_TIAN_TA` | 人工 UI |
| 222 | `MSG_TMP_HUODONG` | 人工 UI |
| 229 | `MSG_HU_SONG` | 人工 UI |
| 304 | `MSG_STOP_PROGRESSBAR` | 人工 UI |
| 305 | `MSG_XIANYUAN` | 人工 UI |
| 306 | `MSG_JINGJIE` | 人工 UI |
| 311 | `MSG_QUNXIANZHENGBA` | 人工 UI |
| 133 | `GUANZHAN_ENTER_BATTLE` | 战斗结算 |
| 134 | `LEAVE_GUANZHAN` | 战斗结算 |
| 161 | `MSG_ARENA` | 战斗结算 |
| 47 | `PRO_USE_ITEM` | 真实消耗 |
| 84 | `PRO_CHARGE` | 真实消耗 |
| 177 | `MSG_CLIENT_CALLBACK_FROM_SHOP` | 真实消耗 |
| 200 | `MSG_OPEN_PACKAGE_OPTION` | 真实消耗 |
| 216 | `MSG_GET_CHARGE_ORDER` | 真实消耗 |
| 257 | `MSG_KOREA_MONEY_GIFT` | 真实消耗 |
| 309 | `MSG_CHONGZHI_TO_OTHER` | 真实消耗 |
| 310 | `MSG_WEIXIN_SHARE_REWARD` | 真实消耗 |
| 332 | `MSG_CLIENT_GETMISSIONAWARD` | 真实消耗 |

## smoke 中未匹配注册名的协议号

| 协议号 | protocol.h 名称 | smoke case |
|---:|---|---|
| 322 | `MSG_HERO_BOOK` | hero_book, hero_book_level_bad |
| 323 | `MSG_BLOOD_FIGHT` | blood_fight_activity, blood_fight_box_empty, blood_fight_info, blood_fight_rank, blood_fight_retry, blood_fight_revive_bad, blood_fight_start, blood_fight_try_easy |
| 335 | `MSG_YOU_LI` | youli_award_1, youli_award_empty, youli_info, youli_start_empty, youli_start_pet57 |
