# 协议覆盖矩阵

> 自动生成时间：2026-07-15 11:03:43
> 生成命令：`pwsh -ExecutionPolicy Bypass -File tools/local/Export-ProtocolCoverage.ps1`

当前文件用于跟踪本地测试服协议覆盖，不等同于完整人工 UI 验收。

## Unity 客户端增量覆盖

| 协议号 | 名称 | Unity 真实覆盖 | 视觉门禁 |
|---:|---|---|---|
| 319 | `PET_EQUIP_OPERATE` | `op=1/17` 分包列表、`op=16/22` Store 增量；隔离角色装备穿戴/强化/卸下、法宝穿戴/卸下 | Editor/Unity MCP 人工 QA 待补 |

## 覆盖统计

| 项 | 数量 |
|---|---:|
| 服务端注册协议 | 143 |
| smoke 已覆盖协议号 | 128 |
| 未覆盖注册协议 | 15 |

## 未覆盖分层统计

| 分层 | 未覆盖数量 | 推进方式 |
|---|---:|---|
| 人工 UI | 1 | 保留给客户端点击路径、复杂状态机或无法安全脚本化的入口。 |
| 服务端内部/跨服 | 14 | 默认不进客户端 smoke，除非本地有明确触发入口。 |

## 下一批优先补覆盖

| 协议号 | 名称 | 分层 |
|---:|---|---|

## 已覆盖注册协议

| 协议号 | 名称 | smoke case |
|---:|---|---|
| 8 | `PRO_ROLE_PACKAGE` | package |
| 9 | `PRO_ROLE_MOVE` | npc_move_to_1, npc_move_to_501, role_move_invalid |
| 10 | `PRO_JUMP_SCENE` | jump_ack_idle, npc_scene_11_ready, npc_scene_ready |
| 12 | `PRO_OPEN_INTERACT` | npc_open_501, npc_open_option_1, open_interact_invalid |
| 13 | `PRO_INTERACT` | npc_dialog_close, npc_option_close, npc_select_option_802 |
| 15 | `PRO_UPDATE_PACK` | package_discard_invalid |
| 16 | `PRO_GET_ITEM_INFO` | item_info_self_slot0 |
| 19 | `PRO_OTHER_ITEM_INFO` | other_item_self_slot0 |
| 20 | `PRO_IGNORE_DIALOG` | ignore_dialog_idle |
| 24 | `PRO_PET` | pet_all |
| 26 | `PRO_MSG_CHAT` | nearby_chat |
| 27 | `PRO_Friend` | friend_apply_list, friend_black_list, friend_gift_list, friend_list, friend_recommend |
| 29 | `PRO_USER_TEAM` | team_list |
| 32 | `PRO_USER_PK` | player_pk_noop |
| 33 | `PRO_PLYAER_MATCH` | player_match_noop |
| 34 | `PRO_PLAYER_INFO` | player_info_self |
| 35 | `PRO_NEAR_PLAYER_LIST` | near_player_list |
| 37 | `PRO_TASK_LIST` | mission_daily, mission_fund, mission_main |
| 40 | `PRO_PET_SKILL` | pet_skill_57 |
| 46 | `PRO_CHONG_ZHI` | charge_panel |
| 47 | `PRO_USE_ITEM` | use_special_item_missing_rename_card, use_special_item_valid_rename |
| 48 | `PRO_ZHEN_FA` | formation_info |
| 49 | `PRO_FINISHED_MISSION` | finished_mission |
| 51 | `PRO_QUERY_PET_INFO` | query_pet_self_57 |
| 52 | `PRO_FIND_RESOURCE` | find_resource |
| 53 | `PRO_FENGSHEN_SHILIAN` | fengshen_boss_list |
| 54 | `PRO_BANGPAI` | bangpai_apply_missing, bangpai_apply_zero, bangpai_create_short_name, bangpai_create_unique, bangpai_donate_info, bangpai_donate_money_1, bangpai_info_self, bangpai_list, bangpai_member_list |
| 55 | `PRO_YAO_LING` | yaoling_cost |
| 56 | `PRO_BANG_ZHAN` | bangzhan_info |
| 58 | `PRO_UPDATE_NPC` | npc_state_501, npc_state_invalid |
| 64 | `PRO_BANGPAI_COPY` | bangpai_copy_buff, bangpai_copy_chapter, bangpai_copy_huoyue |
| 65 | `PRO_Func_HotPoint` | red_point_func |
| 68 | `PRO_SKILL_DESC` | skill_desc_1 |
| 69 | `PRO_OTHER_PET` | other_pet_self_57 |
| 73 | `PRO_SWITCH_CHANNEL` | chat_channel_close_world, chat_channel_open_world |
| 74 | `PRO_SWITCH_INFO` | switch_info |
| 80 | `PRO_MY_BANG` | my_bangpai |
| 83 | `PRO_ITEM_DESC` | query_item_desc_bad |
| 84 | `PRO_CHARGE` | charge_non_ios |
| 88 | `PRO_GONGGAO` | gonggao_query |
| 89 | `PRO_AVAILABLE_TASK` | available_task_bad_detail, available_task_list |
| 90 | `PRO_SCENE_POS` | scene_escape_pos |
| 100 | `MSG_QUERY_SCENE` | query_scene_map1 |
| 101 | `MSG_CLIENT_ITEM_DEF` | item_def_475 |
| 102 | `MSG_SERVER_HEART_BEAT` | heart_beat |
| 105 | `PRO_GET_TITLE_LIST` | title_list |
| 106 | `PRO_TITLE_OPTION` | title_hide_invalid, title_show_bad, title_unuse_invalid |
| 110 | `MSG_BANGPAI_ZHONGZHI` | bangpai_plant_noop |
| 117 | `MSG_CLIENT_LIST_FUQI` | fuqi |
| 133 | `GUANZHAN_ENTER_BATTLE` | guanzhan_missing_role |
| 134 | `LEAVE_GUANZHAN` | leave_guanzhan_idle |
| 145 | `MSG_CLIENT_SAVE_VAL` | save_val_set |
| 146 | `MSG_CLIENT_GET_SAVE_VAL` | save_val_get_one, save_vals |
| 152 | `MSG_HUODONG` | huodong_today |
| 153 | `MSG_YINDAO` | npc_guide_info |
| 154 | `MSG_GUAJI` | guaji_idle |
| 160 | `MSG_XIU_XIAN_LI_LIAN` | xiuxian_lilian_info |
| 161 | `MSG_ARENA` | arena_fight_dynamic_robot, arena_list, arena_list_only |
| 168 | `MSG_DOPTION_CALLBACK` | doption_zero |
| 175 | `MSG_CLIENT_NET_CHECK` | client_net_check |
| 176 | `MSG_GOOGLEPLAY` | googleplay_noop |
| 177 | `MSG_CLIENT_CALLBACK_FROM_SHOP` | client_shop_callback_noop |
| 178 | `MSG_GET_360_TOKEN` | token_360 |
| 180 | `MSG_WING` | wing_base, wing_hide, wing_hide_mutation |
| 182 | `MSG_TASK_TRACK` | task_track_zero |
| 185 | `MSG_MOUNT` | mount_base, mount_collect, mount_hide, mount_hide_mutation |
| 189 | `MSG_NPC_AUTO_TRANSPORT` | npc_auto_transport_noop |
| 190 | `MSG_FUBEN_OPTION` | fuben_daily_list |
| 191 | `MSG_XINSHOUYINDAO` | new_player_guide_noop |
| 192 | `MSG_HE_CHENG_OPTION` | hecheng_noop |
| 193 | `MSG_USER_RANK` | rank_level, rank_power |
| 194 | `MSG_USER_PACKAGE_ITEM` | package_item_empty |
| 195 | `MSG_WORLD_MAP_TRANSPORT` | npc_world_to_scene_11, world_transport_invalid |
| 198 | `MSG_ANSWER_QUESION` | answer_question_get |
| 199 | `MSG_HUODONG_OPTION` | huodong_state |
| 200 | `MSG_OPEN_PACKAGE_OPTION` | open_package_one |
| 201 | `PRO_PLAYER_DETAIL` | player_detail_self |
| 204 | `MSG_MEET_MONSTER` | meet_monster_noop |
| 206 | `MSG_SYNC_TIME` | sys_time |
| 208 | `MSG_HELP` | help_title_list |
| 209 | `MSG_DAILY_ACTIVITY` | daily_activity |
| 213 | `MSG_CHUANG_GUAN` | chuangguan_enable_count |
| 214 | `MSG_TONG_TIAN_TA` | tongtianta_noop |
| 216 | `MSG_GET_CHARGE_ORDER` | charge_order_non_ios |
| 217 | `MSG_FISH` | fish_room_list |
| 219 | `MSG_OFFLINE_EXP` | offline_exp_info |
| 220 | `MSG_VIP_OPTION` | vip_info |
| 221 | `MSG_SHOP` | shop_buy_bad_type, shop_buy_type4_tid1, shop_count_bad_type, shop_list, shop_refresh_bad_type, shop_refresh_type4 |
| 222 | `MSG_TMP_HUODONG` | tmp_huodong_gift_status |
| 223 | `MSG_STAGE_GOAL` | stage_award_1, stage_award_bad, stage_goal |
| 224 | `MSG_PET_RANDOM_DRAW` | pet_draw_bad_op, pet_draw_info, pet_draw_single_type1, pet_draw_single_type2 |
| 225 | `MSG_DailyBoss_TASK` | daily_boss_info |
| 228 | `MSG_LEI_TAI_SAI` | leitai_score |
| 229 | `MSG_HU_SONG` | husong_noop |
| 232 | `MSG_CAI_QUAN` | caiquan_invalid |
| 233 | `MSG_GET_SERVER_ID` | charge_server_id |
| 238 | `MSG_USER_MSG_TO_WORLD` | user_world_notice_empty |
| 239 | `MSG_MOBAI` | mobai_base, mobai_panel |
| 243 | `MSG_PET_COPY` | pet_copy_info |
| 244 | `MSG_TREASURE_MAP` | treasure_map_info |
| 245 | `MSG_SHI_LIAN` | shilian_info |
| 246 | `MSG_FEI_XIAN` | feixian_data |
| 248 | `MSG_QUERY_ROLE_BY_NAME` | role_query_self |
| 249 | `MSG_GET_WORLD_LEVEL` | world_level |
| 257 | `MSG_KOREA_MONEY_GIFT` | korea_money_gift_icon |
| 259 | `MSG_TRANSFORM` | transform_card_info, transform_current |
| 261 | `MSG_IGNORE_QIECUO` | ignore_qiecuo_off, ignore_qiecuo_on |
| 262 | `MSG_PK_NOTICE` | pk_notice_state |
| 263 | `MSG_IGNORE_FUNC` | ignore_vip_off, ignore_vip_on |
| 304 | `MSG_STOP_PROGRESSBAR` | stop_progressbar_noop |
| 305 | `MSG_XIANYUAN` | xianyuan_info |
| 306 | `MSG_JINGJIE` | jingjie_info_noop |
| 307 | `MSG_NEW_SHENQI` | new_shenqi_base, new_shenqi_current, new_shenqi_enhance_info |
| 309 | `MSG_CHONGZHI_TO_OTHER` | chongzhi_to_other_panel |
| 310 | `MSG_WEIXIN_SHARE_REWARD` | weixin_share_invalid |
| 312 | `MSG_MIANZHANPAI_TIME` | mianzhanpai_cd |
| 313 | `MSG_JIAOYI_HANG` | jiaoyi_buy_panel, jiaoyi_record, jiaoyi_sell_panel |
| 314 | `MSG_FLOWER` | flower_rank, flower_self |
| 319 | `PET_EQUIP_OPERATE` | fabao_list, fabao_takeoff_bad, fabao_wear_bad, pet_equip_list, pet_equip_master, pet_equip_search_count, pet_equip_strong_bad, pet_equip_takeoff_bad, pet_equip_wear_bad |
| 320 | `MSG_GUANQIA` | fuben_achievement, fuben_fight_bad, fuben_fix_empty, fuben_map_main, fuben_node_empty, fuben_reset_bad, fuben_sweep_bad |
| 321 | `MSG_SPIRIT` | tili_free_claim_1, tili_free_info, tili_info |
| 330 | `MSG_REAL_NAME_REG` | real_name_empty |
| 331 | `MSG_CLIENT_STRING_DATA_OPRATETION` | client_str_all, client_str_get_one, client_str_one_empty, client_str_set |
| 332 | `MSG_CLIENT_GETMISSIONAWARD` | mission_award_invalid |
| 1001 | `PRO_USER_LOGIN` | login/select/create |
| 1002 | `PRO_ROLE_NAME_CHECK` | role_name_check_smoke |
| 1003 | `PRO_CREATE_ROLE` | login/select/create |
| 1004 | `PRO_SELECT_ROLE` | login/select/create |

## 未覆盖注册协议

| 协议号 | 名称 | 分层 |
|---:|---|---|
| 62 | `PRO_SYSTEM_INFO` | 服务端内部/跨服 |
| 92 | `PRO_SPEC_CHAT` | 服务端内部/跨服 |
| 128 | `MSG_SERVER_XINSHI` | 服务端内部/跨服 |
| 334 | `MSG_QUERY_KF_STATE` | 服务端内部/跨服 |
| 401 | `MSG_SERVER_KF_BANG_PAI` | 服务端内部/跨服 |
| 402 | `MSG_SERVER_SYSINFO` | 服务端内部/跨服 |
| 601 | `PRO_SERVER_QUERY_ONLINE_NUM` | 服务端内部/跨服 |
| 10001 | `MSG_SERVER_RANK` | 服务端内部/跨服 |
| 10002 | `MSG_SERVER_TONGTIANTA` | 服务端内部/跨服 |
| 10005 | `MSG_SERVER_SERVER_XINSHI` | 服务端内部/跨服 |
| 10006 | `MSG_SERVER_ARENA` | 服务端内部/跨服 |
| 10009 | `MSG_SERVER_ROLE_NAME` | 服务端内部/跨服 |
| 10022 | `MSG_SERVER_USER_POWER` | 服务端内部/跨服 |
| 65534 | `MSG_MGR` | 服务端内部/跨服 |
| 211 | `MSG_PLAY_ANIMATION` | 人工 UI |

## smoke 中未匹配注册名的协议号

| 协议号 | protocol.h 名称 | smoke case |
|---:|---|---|
| 322 | `MSG_HERO_BOOK` | hero_book, hero_book_level_bad |
| 323 | `MSG_BLOOD_FIGHT` | blood_fight_activity, blood_fight_box_empty, blood_fight_info, blood_fight_rank, blood_fight_retry, blood_fight_revive_bad, blood_fight_start, blood_fight_try_easy |
| 335 | `MSG_YOU_LI` | youli_award_1, youli_award_empty, youli_info, youli_start_empty, youli_start_pet57 |
