-- Generated from server/sql/local_min_schema.sql. Do not edit by hand.
-- Source SHA-256: 91C71452B603940A96DD35C98EE3B14F383C50A09405BB9871AAD903C311F022
PRAGMA foreign_keys=ON;
BEGIN IMMEDIATE;

CREATE TABLE IF NOT EXISTS `admin` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `allows` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `another` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `arena_log` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `role1_id` INTEGER NOT NULL DEFAULT '0',
  `type1` INTEGER NOT NULL DEFAULT '0',
  `role1_name` TEXT NOT NULL DEFAULT '',
  `role1_head` INTEGER NOT NULL DEFAULT '0',
  `role1_lv` INTEGER NOT NULL DEFAULT '0',
  `role1_vip` INTEGER NOT NULL DEFAULT '0',
  `role1_power` INTEGER NOT NULL DEFAULT '0',
  `role2_id` INTEGER NOT NULL DEFAULT '0',
  `type2` INTEGER NOT NULL DEFAULT '0',
  `role2_name` TEXT NOT NULL DEFAULT '',
  `role2_head` INTEGER NOT NULL DEFAULT '0',
  `role2_lv` INTEGER NOT NULL DEFAULT '0',
  `role2_vip` INTEGER NOT NULL DEFAULT '0',
  `role2_power` INTEGER NOT NULL DEFAULT '0',
  `result` INTEGER NOT NULL DEFAULT '0',
  `rank1` INTEGER NOT NULL DEFAULT '0',
  `rank2` INTEGER NOT NULL DEFAULT '0',
  `time` INTEGER NOT NULL DEFAULT '0',
  `fightdata` INTEGER NOT NULL DEFAULT '0'
);
CREATE INDEX IF NOT EXISTS `idx_arena_log_rank1` ON `arena_log` (`rank1`);
CREATE INDEX IF NOT EXISTS `idx_arena_log_rank2` ON `arena_log` (`rank2`);
CREATE INDEX IF NOT EXISTS `idx_arena_log_time` ON `arena_log` (`time`);

CREATE TABLE IF NOT EXISTS `arena_paihang` (
  `rank` INTEGER PRIMARY KEY AUTOINCREMENT,
  `robot` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `win_num` INTEGER NOT NULL DEFAULT '0',
  `up_down` INTEGER NOT NULL DEFAULT '0',
  `jiangli` INTEGER NOT NULL DEFAULT '0',
  `name` TEXT NOT NULL DEFAULT '',
  `level` INTEGER NOT NULL DEFAULT '0',
  `vip_lv` INTEGER NOT NULL DEFAULT '0',
  `xiang` INTEGER NOT NULL DEFAULT '0',
  `mount_id` INTEGER NOT NULL DEFAULT '0',
  `wing_id` INTEGER NOT NULL DEFAULT '0',
  `wuqi` INTEGER NOT NULL DEFAULT '0',
  `lighteffect` INTEGER NOT NULL DEFAULT '0',
  `shenqi` INTEGER NOT NULL DEFAULT '0',
  `bow_count` INTEGER NOT NULL DEFAULT '0',
  `egg_count` INTEGER NOT NULL DEFAULT '0',
  `act_time` INTEGER NOT NULL DEFAULT '0'
);
CREATE UNIQUE INDEX IF NOT EXISTS `idx_arena_paihang_rank_2` ON `arena_paihang` (`rank`);
CREATE INDEX IF NOT EXISTS `idx_arena_paihang_jiangli` ON `arena_paihang` (`jiangli`);
CREATE INDEX IF NOT EXISTS `idx_arena_paihang_robot` ON `arena_paihang` (`robot`);
CREATE INDEX IF NOT EXISTS `idx_arena_paihang_role_id` ON `arena_paihang` (`role_id`);

CREATE TABLE IF NOT EXISTS `arena_paihang_save` (
  `rank` INTEGER PRIMARY KEY AUTOINCREMENT,
  `robot` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `win_num` INTEGER NOT NULL DEFAULT '0',
  `up_down` INTEGER NOT NULL DEFAULT '0',
  `jiangli` INTEGER NOT NULL DEFAULT '0',
  `name` TEXT NOT NULL DEFAULT '',
  `level` INTEGER NOT NULL DEFAULT '0',
  `vip_lv` INTEGER NOT NULL DEFAULT '0',
  `xiang` INTEGER NOT NULL DEFAULT '0',
  `mount_id` INTEGER NOT NULL DEFAULT '0',
  `wing_id` INTEGER NOT NULL DEFAULT '0',
  `wuqi` INTEGER NOT NULL DEFAULT '0',
  `lighteffect` INTEGER NOT NULL DEFAULT '0',
  `shenqi` INTEGER NOT NULL DEFAULT '0',
  `bow_count` INTEGER NOT NULL DEFAULT '0',
  `egg_count` INTEGER NOT NULL DEFAULT '0',
  `act_time` INTEGER NOT NULL DEFAULT '0'
);
CREATE UNIQUE INDEX IF NOT EXISTS `idx_arena_paihang_save_rank_2` ON `arena_paihang_save` (`rank`);
CREATE INDEX IF NOT EXISTS `idx_arena_paihang_save_jiangli` ON `arena_paihang_save` (`jiangli`);
CREATE INDEX IF NOT EXISTS `idx_arena_paihang_save_robot` ON `arena_paihang_save` (`robot`);
CREATE INDEX IF NOT EXISTS `idx_arena_paihang_save_role_id` ON `arena_paihang_save` (`role_id`);

CREATE TABLE IF NOT EXISTS `arena_robot` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `array` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `ascii` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `back_libao_info` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `bad` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `bang_pai` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT NOT NULL DEFAULT '',
  `info` TEXT,
  `level` INTEGER NOT NULL DEFAULT '1',
  `fanrong` INTEGER NOT NULL DEFAULT '0',
  `money` INTEGER NOT NULL DEFAULT '0',
  `kouhao` TEXT NOT NULL DEFAULT '',
  `gonggao` TEXT,
  `title` INTEGER NOT NULL DEFAULT '0',
  `copy` TEXT,
  `res2` INTEGER NOT NULL DEFAULT '0',
  `res3` INTEGER NOT NULL DEFAULT '0',
  `res4` INTEGER NOT NULL DEFAULT '0',
  `create_time` TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `activity` INTEGER NOT NULL DEFAULT '0',
  `gongXian` INTEGER NOT NULL DEFAULT '0',
  `exp` INTEGER NOT NULL DEFAULT '0',
  `fireState` INTEGER NOT NULL DEFAULT '0',
  `onFireTime` INTEGER NOT NULL DEFAULT '0',
  `robNum` INTEGER NOT NULL DEFAULT '0',
  `robExp` INTEGER NOT NULL DEFAULT '0',
  `treeExp` INTEGER NOT NULL DEFAULT '0',
  `prayExp` INTEGER NOT NULL DEFAULT '0',
  `treeLv` INTEGER NOT NULL DEFAULT '1',
  `prayNum` INTEGER NOT NULL DEFAULT '0',
  `addTreeExpTime` INTEGER NOT NULL DEFAULT '0',
  `memberReward` TEXT,
  `treeTotalExp` INTEGER NOT NULL DEFAULT '0',
  `bz_jifen` INTEGER NOT NULL DEFAULT '0',
  `xianzhun_lv` INTEGER NOT NULL DEFAULT '0',
  `yingxiangli` INTEGER NOT NULL DEFAULT '0',
  `shangxian_info` TEXT,
  `mission` TEXT,
  `juanxian_rank` TEXT,
  `auto_limit_lv` INTEGER NOT NULL DEFAULT '0',
  `huoyue` INTEGER NOT NULL DEFAULT '0',
  `lianqi_lv` TEXT,
  `skills` TEXT,
  `state` INTEGER NOT NULL DEFAULT '1',
  `rank` INTEGER NOT NULL DEFAULT '1',
  `pic` INTEGER NOT NULL DEFAULT '0',
  `chuanwei` INTEGER NOT NULL DEFAULT '0',
  `jiesan_time` INTEGER NOT NULL DEFAULT '0',
  `del_time` TEXT NULL DEFAULT NULL
);
CREATE INDEX IF NOT EXISTS `idx_bang_pai_state` ON `bang_pai` (`state`);
CREATE INDEX IF NOT EXISTS `idx_bang_pai_level` ON `bang_pai` (`level`);
CREATE INDEX IF NOT EXISTS `idx_bang_pai_exp` ON `bang_pai` (`exp`);

CREATE TABLE IF NOT EXISTS `bang_pai_guard` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bang_id` INTEGER NOT NULL DEFAULT '0',
  `guardIdx` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `bang_pai_log` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bang_id` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `type` INTEGER NOT NULL DEFAULT '0',
  `msg` TEXT,
  `msg2` TEXT,
  `time` INTEGER NOT NULL DEFAULT '0',
  `time_str` TEXT NOT NULL DEFAULT '',
  `tar_bang_id` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `bang_pai_mission` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `award1` TEXT,
  `award2` TEXT,
  `desc_str` TEXT,
  `name` TEXT,
  `num1` TEXT,
  `num2` TEXT,
  `type` TEXT,
  `value` TEXT
);

CREATE TABLE IF NOT EXISTS `bang_pai_plant` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `bang_pai_role` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bangpai_id` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `ank` INTEGER NOT NULL DEFAULT '4',
  `join_time` INTEGER NOT NULL DEFAULT '0',
  `total_bangGong` INTEGER NOT NULL DEFAULT '0',
  `huoyue` INTEGER NOT NULL DEFAULT '0',
  `rank` INTEGER NOT NULL DEFAULT '4'
);
CREATE INDEX IF NOT EXISTS `idx_bang_pai_role_bangpai_id` ON `bang_pai_role` (`bangpai_id`);
CREATE INDEX IF NOT EXISTS `idx_bang_pai_role_role_id` ON `bang_pai_role` (`role_id`);

CREATE TABLE IF NOT EXISTS `bang_pai_seed_config` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `gainItem` TEXT,
  `gainType` TEXT,
  `gainValue` TEXT,
  `itemId` TEXT,
  `killBugLimit` TEXT,
  `killBugTimeGap` TEXT,
  `pic1` TEXT,
  `pic2` TEXT,
  `pic3` TEXT,
  `price` TEXT,
  `priceType` TEXT,
  `ripeTimeGap` TEXT,
  `stealNum` TEXT,
  `treeName` TEXT,
  `wateringLimit` TEXT,
  `wateringReduce` TEXT,
  `wateringTimeGap` TEXT,
  `witheredTimeGap` TEXT
);

CREATE TABLE IF NOT EXISTS `bang_pai_shangxian` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT NOT NULL DEFAULT '',
  `bangpai_id` INTEGER NOT NULL DEFAULT '0',
  `qin_mi` INTEGER NOT NULL DEFAULT '0',
  `add_type` INTEGER NOT NULL DEFAULT '0',
  `add_value` INTEGER NOT NULL DEFAULT '0',
  `gift_item_id` INTEGER NOT NULL DEFAULT '0',
  `gift_item_num` INTEGER NOT NULL DEFAULT '0',
  `gift_banggong` INTEGER NOT NULL DEFAULT '0',
  `src_bangpai_id` INTEGER NOT NULL DEFAULT '0',
  `lalong_time` INTEGER NOT NULL DEFAULT '0',
  `timer_time` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `bang_pai_shangxian_mode` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `gain_type1` TEXT,
  `gain_type2` TEXT,
  `gain_value1` TEXT,
  `gain_value2` TEXT,
  `loss_type` TEXT,
  `loss_value` TEXT,
  `name` TEXT,
  `succ_ratio` TEXT,
  `type` TEXT,
  `use_item_id1` TEXT,
  `use_item_id2` TEXT,
  `use_item_num1` TEXT,
  `use_item_num2` TEXT,
  `vip_limit` TEXT
);

CREATE TABLE IF NOT EXISTS `bang_tiaozhan` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `bangzhan` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bangpai_id` INTEGER NOT NULL DEFAULT '0',
  `group` INTEGER NOT NULL DEFAULT '0',
  `type` INTEGER NOT NULL DEFAULT '0'
);
CREATE INDEX IF NOT EXISTS `idx_bangzhan_bangpai_id` ON `bangzhan` (`bangpai_id`);

CREATE TABLE IF NOT EXISTS `bangzhan_role` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `bang_id` INTEGER NOT NULL DEFAULT '0',
  `role_name` TEXT NOT NULL DEFAULT '',
  `jifen` INTEGER NOT NULL DEFAULT '0'
);
CREATE INDEX IF NOT EXISTS `idx_bangzhan_role_role_id` ON `bangzhan_role` (`role_id`);
CREATE INDEX IF NOT EXISTS `idx_bangzhan_role_bang_id` ON `bangzhan_role` (`bang_id`);

CREATE TABLE IF NOT EXISTS `black_ip` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `boost` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `chat_ignore_word` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `chat_log` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `chong_fanli` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `chongzhi` TEXT,
  `fanli` TEXT,
  `first_fanli` TEXT,
  `first_item_id` TEXT,
  `first_item_num` TEXT,
  `item_id` TEXT,
  `item_num` TEXT,
  `pic_idx` TEXT,
  `show_idx` TEXT,
  `type` TEXT
);

CREATE TABLE IF NOT EXISTS `chongfanli` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `config` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `consideration` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `cz_complete` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `ad` TEXT,
  `card_num` TEXT,
  `err_msg` TEXT,
  `is_deal` TEXT,
  `money` TEXT,
  `role_id` TEXT,
  `role_level` TEXT,
  `role_name` TEXT,
  `server_id` TEXT,
  `state` TEXT,
  `time` TEXT,
  `type` TEXT,
  `user_id` TEXT
);

CREATE TABLE IF NOT EXISTS `cz_notice` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `is_first` TEXT,
  `money` TEXT,
  `msg` TEXT,
  `user_id` TEXT
);

CREATE TABLE IF NOT EXISTS `cz_to_other_reward` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `RMB` INTEGER NOT NULL DEFAULT '0',
  `self_award1` INTEGER NOT NULL DEFAULT '0',
  `self_num1` INTEGER NOT NULL DEFAULT '0',
  `self_award2` INTEGER NOT NULL DEFAULT '0',
  `self_num2` INTEGER NOT NULL DEFAULT '0',
  `self_award3` INTEGER NOT NULL DEFAULT '0',
  `self_num3` INTEGER NOT NULL DEFAULT '0',
  `self_award4` INTEGER NOT NULL DEFAULT '0',
  `self_num4` INTEGER NOT NULL DEFAULT '0',
  `f_award1` INTEGER NOT NULL DEFAULT '0',
  `f_num1` INTEGER NOT NULL DEFAULT '0',
  `f_award2` INTEGER NOT NULL DEFAULT '0',
  `f_num2` INTEGER NOT NULL DEFAULT '0',
  `f_award3` INTEGER NOT NULL DEFAULT '0',
  `f_num3` INTEGER NOT NULL DEFAULT '0',
  `f_award4` INTEGER NOT NULL DEFAULT '0',
  `f_num4` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `dailysign` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `_1` TEXT,
  `award_num` TEXT,
  `award_type` TEXT,
  `award_value` TEXT,
  `day_idx` TEXT,
  `mon_type` TEXT,
  `vip_lv` TEXT,
  `vip_multiple` TEXT
);

CREATE TABLE IF NOT EXISTS `defining` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `dengjilibao` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `goods1` TEXT,
  `goods2` TEXT,
  `goods3` TEXT,
  `level` TEXT,
  `num1` TEXT,
  `num2` TEXT,
  `num3` TEXT,
  `value1` TEXT,
  `value2` TEXT,
  `value3` TEXT
);

CREATE TABLE IF NOT EXISTS `doxygen` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `encoding` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `equip` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `fabao` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `fanli_jihuoma` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `festival_award` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `type` INTEGER NOT NULL DEFAULT '0',
  `start_id` INTEGER NOT NULL DEFAULT '0',
  `end_id` INTEGER NOT NULL DEFAULT '0',
  `score` INTEGER NOT NULL DEFAULT '0',
  `idx` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `festival_box` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `box_id` INTEGER NOT NULL DEFAULT '0',
  `item_id` INTEGER NOT NULL DEFAULT '0',
  `odds` INTEGER NOT NULL DEFAULT '0',
  `num` INTEGER NOT NULL DEFAULT '0',
  `quality` INTEGER NOT NULL DEFAULT '0',
  `quality_level` INTEGER NOT NULL DEFAULT '0',
  `isnotice` INTEGER NOT NULL DEFAULT '0',
  `day_limit` INTEGER NOT NULL DEFAULT '0'
);
CREATE INDEX IF NOT EXISTS `idx_festival_box_box_id` ON `festival_box` (`box_id`);

CREATE TABLE IF NOT EXISTS `festival_record` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `fight_cg` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `fightMsg` TEXT
);

CREATE TABLE IF NOT EXISTS `fight_playback` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `type` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `tar_role_id` INTEGER NOT NULL DEFAULT '0',
  `fightMsg` TEXT NOT NULL,
  `notice` TEXT NOT NULL DEFAULT '',
  `time` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `flower_config` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `buy_type` TEXT,
  `item_id` TEXT,
  `mei_li` TEXT,
  `price` TEXT,
  `qin_mi` TEXT,
  `rank` TEXT
);

CREATE TABLE IF NOT EXISTS `footprint_config` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `buy_type` TEXT,
  `desc` TEXT,
  `name` TEXT,
  `price` TEXT,
  `rank` TEXT,
  `time` TEXT,
  `item` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `friend_list` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `role_id` INTEGER NOT NULL,
  `friend_info` TEXT NOT NULL,
  `apply_list` TEXT NOT NULL,
  `black_list` TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS `idx_friend_list_role_id` ON `friend_list` (`role_id`);

CREATE TABLE IF NOT EXISTS `friend_list_save` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `role_id` INTEGER NOT NULL,
  `friend_info` TEXT NOT NULL,
  `apply_list` TEXT NOT NULL,
  `black_list` TEXT NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS `idx_friend_list_save_role_id` ON `friend_list_save` (`role_id`);

CREATE TABLE IF NOT EXISTS `fuben_richang` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `condes1` TEXT,
  `condes2` TEXT,
  `condes3` TEXT,
  `condes4` TEXT,
  `desc_ratio` TEXT,
  `desc_ratio1` TEXT,
  `desc_title` TEXT,
  `enterlimit` TEXT,
  `extdata8` TEXT,
  `fuben_index` TEXT,
  `isShow` TEXT,
  `level` TEXT,
  `lvup_type1` TEXT,
  `lvup_type2` TEXT,
  `lvup_type3` TEXT,
  `lvup_type4` TEXT,
  `lvup_value1` TEXT,
  `lvup_value2` TEXT,
  `lvup_value3` TEXT,
  `lvup_value4` TEXT,
  `mobs` TEXT,
  `mop_time` TEXT,
  `name` TEXT,
  `reward1` TEXT,
  `reward2` TEXT,
  `reward3` TEXT,
  `reward4` TEXT,
  `sceneId` TEXT,
  `tili` TEXT,
  `type` TEXT
);

CREATE TABLE IF NOT EXISTS `function_switch` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `function_type` INTEGER NOT NULL DEFAULT '0',
  `switch_state` INTEGER NOT NULL DEFAULT '1'
);
CREATE UNIQUE INDEX IF NOT EXISTS `idx_function_switch_function_type` ON `function_switch` (`function_type`);

CREATE TABLE IF NOT EXISTS `game_scene` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `fight_step` TEXT,
  `fight_type` TEXT,
  `group_id` TEXT,
  `height` TEXT,
  `map_id` TEXT,
  `monster` TEXT,
  `name` TEXT,
  `show_type` TEXT,
  `width` TEXT,
  `world_trans` TEXT,
  `x` TEXT,
  `y` TEXT,
  `pai_ming` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `genericreader` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `genericvalue` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `global_variable` (
  `id` INTEGER NOT NULL,
  `value` INTEGER NOT NULL DEFAULT '0',
  `data` TEXT,
  `time` TEXT NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `happening` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `hd_7ridenglu` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `hd_bang_goods` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `award1` TEXT,
  `pic` TEXT,
  `score1_get` TEXT,
  `score1_give` TEXT,
  `award2` INTEGER NOT NULL DEFAULT '0',
  `score2_give` INTEGER NOT NULL DEFAULT '0',
  `score2_get` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `hd_chou_record` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `role_name` TEXT NOT NULL DEFAULT '',
  `time` TEXT DEFAULT NULL,
  `award` INTEGER NOT NULL DEFAULT '0',
  `level` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `hd_exchange_drop` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `hd_exchange_list` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `hd_paihang_info` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `huodong_type` INTEGER NOT NULL DEFAULT '0',
  `start_id` INTEGER NOT NULL DEFAULT '0',
  `end_id` INTEGER NOT NULL DEFAULT '0',
  `idx` INTEGER NOT NULL DEFAULT '0',
  `score` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `hd_paihang_record` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `huodong_type` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `role_name` TEXT NOT NULL DEFAULT '',
  `bangpai_name` TEXT NOT NULL DEFAULT '',
  `data` INTEGER NOT NULL DEFAULT '0',
  `role_lv` INTEGER NOT NULL DEFAULT '0',
  `role_zhandouli` INTEGER NOT NULL DEFAULT '0',
  `time` INTEGER NOT NULL DEFAULT '0',
  `xiang` INTEGER NOT NULL DEFAULT '0',
  `sex` INTEGER NOT NULL DEFAULT '0',
  `rank` INTEGER NOT NULL DEFAULT '0',
  `start_time` INTEGER NOT NULL DEFAULT '0',
  `send_award` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `hd_peizhi_info` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bug_cz` TEXT,
  `cdTime` TEXT,
  `count` TEXT,
  `count_ext8` TEXT,
  `idx` TEXT,
  `lastTime_ext32` TEXT,
  `lv` TEXT,
  `price` TEXT,
  `step1_cz` TEXT,
  `step2_cz` TEXT,
  `type` TEXT,
  `water_cz` TEXT,
  `yb` TEXT,
  `zhenying1_name` TEXT,
  `zhenying2_name` TEXT
);

CREATE TABLE IF NOT EXISTS `hd_rand_award` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `huodong_type` INTEGER NOT NULL DEFAULT '0',
  `award` INTEGER NOT NULL DEFAULT '0',
  `num` INTEGER NOT NULL DEFAULT '0',
  `petQt` INTEGER NOT NULL DEFAULT '0',
  `petQtLv` INTEGER NOT NULL DEFAULT '0',
  `rate` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `hd_save_data` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `hd_type` INTEGER NOT NULL DEFAULT '0',
  `save_data` TEXT
);

CREATE TABLE IF NOT EXISTS `hd_show_log` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `help` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `huan_haoli_drop` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `ext8_idx` TEXT,
  `item_id` TEXT,
  `limit_num` TEXT,
  `name` TEXT,
  `type` TEXT
);

CREATE TABLE IF NOT EXISTS `huodong_award` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `award1` TEXT,
  `award2` TEXT,
  `award3` TEXT,
  `award4` TEXT,
  `award5` TEXT,
  `award6` TEXT,
  `idx` TEXT,
  `idx2` TEXT,
  `idx3` TEXT,
  `num1` TEXT,
  `num2` TEXT,
  `num3` TEXT,
  `num4` TEXT,
  `num5` TEXT,
  `num6` TEXT,
  `petQt1` TEXT,
  `petQt2` TEXT,
  `petQt3` TEXT,
  `petQt4` TEXT,
  `petQt5` TEXT,
  `petQt6` TEXT,
  `petQtLv1` TEXT,
  `petQtLv2` TEXT,
  `petQtLv3` TEXT,
  `petQtLv4` TEXT,
  `petQtLv5` TEXT,
  `petQtLv6` TEXT,
  `type` TEXT,
  `YB` TEXT
);

CREATE TABLE IF NOT EXISTS `huodong_exchange` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `award1` TEXT,
  `award2` TEXT,
  `award3` TEXT,
  `award4` TEXT,
  `award5` TEXT,
  `award6` TEXT,
  `exchange_num_limit` TEXT,
  `idx` TEXT,
  `isShow` TEXT,
  `material_1` TEXT,
  `material_1_num` TEXT,
  `material_2` TEXT,
  `material_2_num` TEXT,
  `material_3` TEXT,
  `material_3_num` TEXT,
  `material_4` TEXT,
  `material_4_num` TEXT,
  `material_5` TEXT,
  `material_5_num` TEXT,
  `material_is_or` TEXT,
  `num1` TEXT,
  `num2` TEXT,
  `num3` TEXT,
  `num4` TEXT,
  `num5` TEXT,
  `num6` TEXT,
  `petQt1` TEXT,
  `petQt2` TEXT,
  `petQt3` TEXT,
  `petQt4` TEXT,
  `petQt5` TEXT,
  `petQt6` TEXT,
  `petQtLv1` TEXT,
  `petQtLv2` TEXT,
  `petQtLv3` TEXT,
  `petQtLv4` TEXT,
  `petQtLv5` TEXT,
  `petQtLv6` TEXT,
  `saveExt8` TEXT,
  `type` TEXT
);

CREATE TABLE IF NOT EXISTS `huodong_exp` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `exp1` TEXT,
  `exp10` TEXT,
  `exp100` TEXT,
  `exp101` TEXT,
  `exp102` TEXT,
  `exp103` TEXT,
  `exp104` TEXT,
  `exp105` TEXT,
  `exp106` TEXT,
  `exp107` TEXT,
  `exp108` TEXT,
  `exp109` TEXT,
  `exp11` TEXT,
  `exp110` TEXT,
  `exp111` TEXT,
  `exp112` TEXT,
  `exp113` TEXT,
  `exp114` TEXT,
  `exp115` TEXT,
  `exp116` TEXT,
  `exp117` TEXT,
  `exp118` TEXT,
  `exp119` TEXT,
  `exp12` TEXT,
  `exp120` TEXT,
  `exp121` TEXT,
  `exp122` TEXT,
  `exp123` TEXT,
  `exp124` TEXT,
  `exp125` TEXT,
  `exp126` TEXT,
  `exp127` TEXT,
  `exp128` TEXT,
  `exp129` TEXT,
  `exp13` TEXT,
  `exp130` TEXT,
  `exp14` TEXT,
  `exp15` TEXT,
  `exp16` TEXT,
  `exp17` TEXT,
  `exp18` TEXT,
  `exp19` TEXT,
  `exp2` TEXT,
  `exp20` TEXT,
  `exp21` TEXT,
  `exp22` TEXT,
  `exp23` TEXT,
  `exp24` TEXT,
  `exp25` TEXT,
  `exp26` TEXT,
  `exp27` TEXT,
  `exp28` TEXT,
  `exp29` TEXT,
  `exp3` TEXT,
  `exp30` TEXT,
  `exp31` TEXT,
  `exp32` TEXT,
  `exp33` TEXT,
  `exp34` TEXT,
  `exp35` TEXT,
  `exp36` TEXT,
  `exp37` TEXT,
  `exp38` TEXT,
  `exp39` TEXT,
  `exp4` TEXT,
  `exp40` TEXT,
  `exp41` TEXT,
  `exp42` TEXT,
  `exp43` TEXT,
  `exp44` TEXT,
  `exp45` TEXT,
  `exp46` TEXT,
  `exp47` TEXT,
  `exp48` TEXT,
  `exp49` TEXT,
  `exp5` TEXT,
  `exp50` TEXT,
  `exp51` TEXT,
  `exp52` TEXT,
  `exp53` TEXT,
  `exp54` TEXT,
  `exp55` TEXT,
  `exp56` TEXT,
  `exp57` TEXT,
  `exp58` TEXT,
  `exp59` TEXT,
  `exp6` TEXT,
  `exp60` TEXT,
  `exp61` TEXT,
  `exp62` TEXT,
  `exp63` TEXT,
  `exp64` TEXT,
  `exp65` TEXT,
  `exp66` TEXT,
  `exp67` TEXT,
  `exp68` TEXT,
  `exp69` TEXT,
  `exp7` TEXT,
  `exp70` TEXT,
  `exp71` TEXT,
  `exp72` TEXT,
  `exp73` TEXT,
  `exp74` TEXT,
  `exp75` TEXT,
  `exp76` TEXT,
  `exp77` TEXT,
  `exp78` TEXT,
  `exp79` TEXT,
  `exp8` TEXT,
  `exp80` TEXT,
  `exp81` TEXT,
  `exp82` TEXT,
  `exp83` TEXT,
  `exp84` TEXT,
  `exp85` TEXT,
  `exp86` TEXT,
  `exp87` TEXT,
  `exp88` TEXT,
  `exp89` TEXT,
  `exp9` TEXT,
  `exp90` TEXT,
  `exp91` TEXT,
  `exp92` TEXT,
  `exp93` TEXT,
  `exp94` TEXT,
  `exp95` TEXT,
  `exp96` TEXT,
  `exp97` TEXT,
  `exp98` TEXT,
  `exp99` TEXT,
  `name` TEXT,
  `type` TEXT
);

CREATE TABLE IF NOT EXISTS `huodong_info` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `day` TEXT,
  `endHour` TEXT,
  `endTime` TEXT,
  `isShow` TEXT,
  `name` TEXT,
  `pic` TEXT,
  `showIdx` TEXT,
  `startHour` TEXT,
  `startTime` TEXT,
  `type` TEXT
);

CREATE TABLE IF NOT EXISTS `huodong_time` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `beilv` INTEGER NOT NULL DEFAULT '1',
  `begin_time` TEXT NULL DEFAULT NULL,
  `end_time` TEXT NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `input` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `integer` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `item` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT NOT NULL,
  `des` TEXT NOT NULL,
  `pic` INTEGER NOT NULL,
  `quality` INTEGER NOT NULL DEFAULT '0',
  `type` INTEGER NOT NULL,
  `use_type` INTEGER NOT NULL,
  `sub_value` TEXT NOT NULL,
  `limit_lv` INTEGER NOT NULL,
  `limit_time` TEXT NOT NULL,
  `sell` INTEGER NOT NULL,
  `sort_priority` INTEGER NOT NULL DEFAULT '1',
  `jiage` INTEGER NOT NULL,
  `item_from` TEXT NOT NULL,
  `item_source` TEXT NOT NULL,
  `script` INTEGER NOT NULL,
  `use_jump` INTEGER NOT NULL DEFAULT '0'
);
CREATE INDEX IF NOT EXISTS `idx_item_sort_priority` ON `item` (`sort_priority`);

CREATE TABLE IF NOT EXISTS `item_score_exchange` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `item_id` INTEGER NOT NULL DEFAULT '0',
  `score_give` INTEGER NOT NULL DEFAULT '0',
  `score_get` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `item_template` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `add_qixue` TEXT,
  `add_sudu` TEXT,
  `baoji` TEXT,
  `des` TEXT,
  `equip_pos` TEXT,
  `fafang` TEXT,
  `fangyu` TEXT,
  `gongji` TEXT,
  `item_from` TEXT,
  `item_source` TEXT,
  `jiage` TEXT,
  `kangbao` TEXT,
  `level` TEXT,
  `mingzhong` TEXT,
  `mod` TEXT,
  `naijiu` TEXT,
  `name` TEXT,
  `pic` TEXT,
  `quality` TEXT,
  `sell` TEXT,
  `sex` TEXT,
  `shanbi` TEXT,
  `sort_priority` TEXT,
  `type` TEXT
);

CREATE TABLE IF NOT EXISTS `iterator` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `jiaoyi_gold_yuzhi` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `gold` INTEGER NOT NULL DEFAULT '30000',
  `time` TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS `jiaoyi_info` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `time` TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `seller_id` INTEGER NOT NULL DEFAULT '0',
  `seller_name` TEXT NOT NULL DEFAULT '',
  `sell_yb` INTEGER NOT NULL DEFAULT '0',
  `buy_gold` INTEGER NOT NULL DEFAULT '0',
  `already_sell_yb` INTEGER NOT NULL DEFAULT '0',
  `state` INTEGER NOT NULL DEFAULT '0'
);
CREATE INDEX IF NOT EXISTS `idx_jiaoyi_info_state` ON `jiaoyi_info` (`state`);
CREATE INDEX IF NOT EXISTS `idx_jiaoyi_info_seller_id` ON `jiaoyi_info` (`seller_id`);

CREATE TABLE IF NOT EXISTS `jiaoyi_record` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `time` TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `seller_id` INTEGER NOT NULL DEFAULT '0',
  `seller_name` TEXT NOT NULL DEFAULT '',
  `buyer_id` INTEGER NOT NULL DEFAULT '0',
  `buyer_name` TEXT NOT NULL DEFAULT '',
  `sell_yb` INTEGER NOT NULL DEFAULT '0',
  `buy_gold` INTEGER NOT NULL DEFAULT '0',
  `state` INTEGER NOT NULL DEFAULT '0',
  `poundage` INTEGER NOT NULL DEFAULT '0'
);
CREATE INDEX IF NOT EXISTS `idx_jiaoyi_record_seller_id` ON `jiaoyi_record` (`seller_id`);
CREATE INDEX IF NOT EXISTS `idx_jiaoyi_record_buyer_id` ON `jiaoyi_record` (`buyer_id`);
CREATE INDEX IF NOT EXISTS `idx_jiaoyi_record_state` ON `jiaoyi_record` (`state`);

CREATE TABLE IF NOT EXISTS `jihuoma` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `jihuoma_fa` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `jump_point` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `face` TEXT,
  `from_scene` TEXT,
  `from_x` TEXT,
  `from_y` TEXT,
  `to_scene` TEXT,
  `to_x` TEXT,
  `to_y` TEXT
);

CREATE TABLE IF NOT EXISTS `kf_config` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `kuafu_1vs1_final_data` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `kuafu_1vs1_final_vote` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `kuafu_1vs1_preliminary` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `kuafu_paihang` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `leitai_paiming` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `level_rank` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `login_log_7` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `role_id` INTEGER NOT NULL,
  `level` INTEGER NOT NULL,
  `ad` INTEGER NOT NULL DEFAULT '0',
  `ip` TEXT NOT NULL,
  `net_info` TEXT NOT NULL,
  `mac` TEXT NOT NULL,
  `IMEI` TEXT NOT NULL,
  `IDFA` TEXT NOT NULL,
  `login_time` TEXT NOT NULL,
  `logout_time` TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS `idx_login_log_7_role_id` ON `login_log_7` (`role_id`);
CREATE INDEX IF NOT EXISTS `idx_login_log_7_ad` ON `login_log_7` (`ad`);

CREATE TABLE IF NOT EXISTS `mei_li_history` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `round` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `name` TEXT NOT NULL DEFAULT '',
  `mei_li` INTEGER NOT NULL DEFAULT '0',
  `title` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `mei_li_paihang` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `name` TEXT NOT NULL DEFAULT '',
  `mei_li` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `mei_li_send_log` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `microsoft` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `mijing_boss_ratio` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `mobai` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `money_giftbag_huodong` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `hd_type` INTEGER NOT NULL DEFAULT '0',
  `gift_id` INTEGER NOT NULL DEFAULT '0',
  `gift_name` TEXT NOT NULL DEFAULT '',
  `money` INTEGER NOT NULL DEFAULT '0',
  `startTime` TEXT DEFAULT NULL,
  `endTime` TEXT DEFAULT NULL,
  `limit_buy_num` INTEGER NOT NULL DEFAULT '0',
  `limit_type` INTEGER NOT NULL DEFAULT '0',
  `limit_data1` INTEGER NOT NULL DEFAULT '0',
  `limit_data2` INTEGER NOT NULL DEFAULT '0',
  `award1` INTEGER NOT NULL DEFAULT '0',
  `num1` INTEGER NOT NULL DEFAULT '0',
  `petQt1` INTEGER NOT NULL DEFAULT '0',
  `petQtLv1` INTEGER NOT NULL DEFAULT '0',
  `award2` INTEGER NOT NULL DEFAULT '0',
  `num2` INTEGER NOT NULL DEFAULT '0',
  `petQt2` INTEGER NOT NULL DEFAULT '0',
  `petQtLv2` INTEGER NOT NULL DEFAULT '0',
  `award3` INTEGER NOT NULL DEFAULT '0',
  `num3` INTEGER NOT NULL DEFAULT '0',
  `petQt3` INTEGER NOT NULL DEFAULT '0',
  `petQtLv3` INTEGER NOT NULL DEFAULT '0',
  `pay_id` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `money_giftbag_pay` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `money` INTEGER NOT NULL DEFAULT '0',
  `ad` INTEGER NOT NULL DEFAULT '0',
  `pay_id` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `monster` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `attack` TEXT,
  `attackRatio` TEXT,
  `attackStepRatio` TEXT,
  `defence` TEXT,
  `defenceRatio` TEXT,
  `defenceStepRatio` TEXT,
  `drop_item` TEXT,
  `exp` TEXT,
  `huanhua_material` TEXT,
  `huanhuaPetId` TEXT,
  `inTuJian` TEXT,
  `isJueXingPet` TEXT,
  `juexingPetId` TEXT,
  `max_level` TEXT,
  `max_quality` TEXT,
  `maxHp` TEXT,
  `maxHpRatio` TEXT,
  `maxHpStepRatio` TEXT,
  `min_level` TEXT,
  `min_quality` TEXT,
  `monsterName` TEXT,
  `petName` TEXT,
  `skill` TEXT,
  `skillAttack` TEXT,
  `skillAttackRatio` TEXT,
  `skillAttackStepRatio` TEXT,
  `speed` TEXT,
  `speedRatio` TEXT,
  `speedStepRatio` TEXT,
  `t_drop_item` TEXT,
  `tujianIdx` TEXT,
  `type` TEXT,
  `xiang` TEXT,
  `zizhi` TEXT
);

CREATE TABLE IF NOT EXISTS `monster_boss_distribution` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `dropItem` TEXT,
  `face` TEXT,
  `fightPos1` TEXT,
  `fightPos2` TEXT,
  `fightPos3` TEXT,
  `fightPos4` TEXT,
  `fightPos5` TEXT,
  `fightPos6` TEXT,
  `meetDistance` TEXT,
  `name` TEXT,
  `pic` TEXT,
  `pos_x` TEXT,
  `pos_y` TEXT,
  `radius` TEXT,
  `sayContent` TEXT,
  `scale1` TEXT,
  `scale2` TEXT,
  `scale3` TEXT,
  `scale4` TEXT,
  `scale5` TEXT,
  `scale6` TEXT,
  `sceneId` TEXT,
  `step` TEXT,
  `type` TEXT
);

CREATE TABLE IF NOT EXISTS `monster_distribution` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `findPath_x` TEXT,
  `findPath_y` TEXT,
  `max_fightId` TEXT,
  `meetDistance` TEXT,
  `min_fightId` TEXT,
  `monster_id` TEXT,
  `pos` TEXT,
  `radius` TEXT,
  `scene_id` TEXT
);

CREATE TABLE IF NOT EXISTS `mutable` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `name_reg0` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `name_reg1` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `names` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `non` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `notice` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `begin_time` TEXT,
  `end_time` TEXT,
  `msg` TEXT,
  `time_space` TEXT,
  `type` TEXT,
  `type1` TEXT
);

CREATE TABLE IF NOT EXISTS `notice_login` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `title` TEXT NOT NULL DEFAULT '',
  `msg` TEXT,
  `showType` INTEGER NOT NULL DEFAULT '0',
  `jumpType` INTEGER NOT NULL DEFAULT '0',
  `beginTime` INTEGER NOT NULL DEFAULT '0',
  `endTime` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `npc_instance` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `face` TEXT,
  `scene_id` TEXT,
  `show_type` TEXT,
  `template_id` TEXT,
  `x_pos` TEXT,
  `y_pos` TEXT
);

CREATE TABLE IF NOT EXISTS `npc_template` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `name` TEXT,
  `npc_type` TEXT,
  `picture` TEXT,
  `script` TEXT
);

CREATE TABLE IF NOT EXISTS `old_account` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `online_user_num` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `num` TEXT,
  `time` TEXT
);

CREATE TABLE IF NOT EXISTS `operator` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `parsestream` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `plain` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `pointer` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `pre` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `predict` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `primary` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `qiang_hongbao_record` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `send_hb_count` INTEGER NOT NULL DEFAULT '0',
  `renqi_king_count` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `qin_mi_log` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `role1` INTEGER NOT NULL DEFAULT '0',
  `role2` INTEGER NOT NULL DEFAULT '0',
  `qin_mi` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `question` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `question` TEXT NOT NULL DEFAULT '',
  `answer1` TEXT NOT NULL DEFAULT '',
  `answer2` TEXT NOT NULL DEFAULT '',
  `answer3` TEXT NOT NULL DEFAULT '',
  `answer4` TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS `qunxian_paihang` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `randombox_cfg` (
  `seq` INTEGER PRIMARY KEY AUTOINCREMENT,
  `box_id` INTEGER NOT NULL DEFAULT '0',
  `item_id` INTEGER NOT NULL DEFAULT '0',
  `odds` INTEGER NOT NULL DEFAULT '0',
  `id` INTEGER NOT NULL DEFAULT '0',
  `num` INTEGER NOT NULL DEFAULT '0',
  `quality` INTEGER NOT NULL DEFAULT '0',
  `quality_level` INTEGER NOT NULL DEFAULT '0',
  `isnotice` INTEGER NOT NULL DEFAULT '0',
  `day_limit` INTEGER NOT NULL DEFAULT '0'
);
CREATE INDEX IF NOT EXISTS `idx_randombox_cfg_box_id` ON `randombox_cfg` (`box_id`);

CREATE TABLE IF NOT EXISTS `rank_list` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `type` INTEGER NOT NULL DEFAULT '0',
  `rank` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `data1` INTEGER NOT NULL DEFAULT '0',
  `data2` INTEGER NOT NULL DEFAULT '0',
  `value1` INTEGER NOT NULL DEFAULT '0',
  `time` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `rank_list_save` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `type` INTEGER NOT NULL DEFAULT '0',
  `rank` INTEGER NOT NULL DEFAULT '0',
  `role_id` INTEGER NOT NULL DEFAULT '0',
  `data1` INTEGER NOT NULL DEFAULT '0',
  `data2` INTEGER NOT NULL DEFAULT '0',
  `value1` INTEGER NOT NULL DEFAULT '0',
  `time` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `read` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `rob` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `role_info` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `admin` TEXT,
  `bank_item` TEXT,
  `bd_money` TEXT,
  `bitset` TEXT,
  `chat_time` TEXT,
  `exp` TEXT,
  `head` TEXT,
  `hots` TEXT,
  `korea_money_gift` TEXT,
  `kuafu_state` TEXT,
  `level` TEXT,
  `login_time` TEXT,
  `model` TEXT,
  `money` TEXT,
  `mount` TEXT,
  `name` TEXT,
  `package` TEXT,
  `pet` TEXT,
  `pet_equip` TEXT,
  `petZhanDouLi` TEXT,
  `reg_time` TEXT,
  `save_data` TEXT,
  `sex` TEXT,
  `sg_bitset` TEXT,
  `shenqi` TEXT,
  `state` TEXT,
  `title` TEXT,
  `user_book` TEXT,
  `wing` TEXT,
  `xianyuan` TEXT,
  `zhanDouLi` TEXT,
  `zhenfa` TEXT,
  `save_val` TEXT,
  `qianneng` TEXT,
  `chat_channel` TEXT,
  `bossFightStar` TEXT,
  `mysteryShop` TEXT,
  `xiuxian` TEXT,
  `transform` TEXT,
  `mission` TEXT,
  `clientstring` TEXT,
  `shenhunShop` TEXT,
  `questIds` TEXT,
  `find_res` TEXT,
  `xunbao` TEXT,
  `bang_skills` TEXT,
  `guan_qia` TEXT,
  `chou_ka` TEXT,
  `blood_fight` TEXT,
  `copyData` TEXT,
  `user_spirit` TEXT,
  `kuafu_1vs1` TEXT
);

CREATE TABLE IF NOT EXISTS `role_info_transfer` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `role_mirror` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `role_simple_list` (
  `id` INTEGER NOT NULL,
  `name` TEXT NOT NULL DEFAULT '',
  `level` INTEGER NOT NULL DEFAULT '0',
  `power` INTEGER NOT NULL DEFAULT '0',
  `sex` INTEGER NOT NULL DEFAULT '0',
  `head` INTEGER NOT NULL DEFAULT '0',
  `model` INTEGER NOT NULL DEFAULT '0',
  `vipLv` INTEGER NOT NULL DEFAULT '0',
  `bangId` INTEGER NOT NULL DEFAULT '0',
  `lastLoginTime` INTEGER NOT NULL DEFAULT '0',
  `huoyue_day` INTEGER NOT NULL DEFAULT '0',
  `huoyue_week` INTEGER NOT NULL DEFAULT '0',
  `jingJie` INTEGER NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
);
CREATE INDEX IF NOT EXISTS `idx_role_simple_list_name` ON `role_simple_list` (`name`);

CREATE TABLE IF NOT EXISTS `role_simple_list_save` (
  `id` INTEGER NOT NULL,
  `name` TEXT NOT NULL DEFAULT '',
  `level` INTEGER NOT NULL DEFAULT '0',
  `power` INTEGER NOT NULL DEFAULT '0',
  `sex` INTEGER NOT NULL DEFAULT '0',
  `head` INTEGER NOT NULL DEFAULT '0',
  `model` INTEGER NOT NULL DEFAULT '0',
  `vipLv` INTEGER NOT NULL DEFAULT '0',
  `bangId` INTEGER NOT NULL DEFAULT '0',
  `lastLoginTime` INTEGER NOT NULL DEFAULT '0',
  `huoyue_day` INTEGER NOT NULL DEFAULT '0',
  `huoyue_week` INTEGER NOT NULL DEFAULT '0',
  `jingJie` INTEGER NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
);
CREATE INDEX IF NOT EXISTS `idx_role_simple_list_save_name` ON `role_simple_list_save` (`name`);

CREATE TABLE IF NOT EXISTS `role_xiuxian` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `admin` TEXT,
  `bangpai` TEXT,
  `bank_item` TEXT,
  `bank_money` TEXT,
  `bitset` TEXT,
  `bossFightStar` TEXT,
  `chat_channel` TEXT,
  `chat_time` TEXT,
  `collect_npc` TEXT,
  `currency` TEXT,
  `daohang` TEXT,
  `drop_touchitem` TEXT,
  `equipment` TEXT,
  `exp` TEXT,
  `head` TEXT,
  `hots` TEXT,
  `hp` TEXT,
  `jianyu_time` TEXT,
  `level` TEXT,
  `login_time` TEXT,
  `map_id` TEXT,
  `menpai` TEXT,
  `money` TEXT,
  `mount` TEXT,
  `mp` TEXT,
  `mp_gongxian` TEXT,
  `mysteryShop` TEXT,
  `name` TEXT,
  `nextOpenTime` TEXT,
  `open_pack` TEXT,
  `package` TEXT,
  `pet` TEXT,
  `petKaiJia` TEXT,
  `petZhanDouLi` TEXT,
  `pk_time` TEXT,
  `pk_val` TEXT,
  `position` TEXT,
  `qianneng` TEXT,
  `reg_time` TEXT,
  `save_data` TEXT,
  `save_monster` TEXT,
  `save_npc` TEXT,
  `save_val` TEXT,
  `script_double` TEXT,
  `script_timer` TEXT,
  `sex` TEXT,
  `sg_bitset` TEXT,
  `shop` TEXT,
  `skills` TEXT,
  `state` TEXT,
  `tili` TEXT,
  `title` TEXT,
  `use_double_end` TEXT,
  `use_double_type` TEXT,
  `wing` TEXT,
  `wing_zhandouli` TEXT,
  `x_pos` TEXT,
  `xiang` TEXT,
  `y_pos` TEXT,
  `zhanDouLi` TEXT
);

CREATE TABLE IF NOT EXISTS `script_save_role` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `server_list` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `shilian_robot` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `shop` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `item` INTEGER NOT NULL DEFAULT '0',
  `price` INTEGER NOT NULL DEFAULT '0',
  `offprice` INTEGER NOT NULL DEFAULT '0',
  `type` INTEGER NOT NULL DEFAULT '0',
  `tag` TEXT NOT NULL DEFAULT '0',
  `starttime` INTEGER NOT NULL DEFAULT '0',
  `endtime` INTEGER NOT NULL DEFAULT '0',
  `limitcount` INTEGER NOT NULL DEFAULT '0',
  `count` INTEGER NOT NULL DEFAULT '0',
  `vipLimit` INTEGER NOT NULL DEFAULT '0',
  `value` INTEGER NOT NULL DEFAULT '0',
  `exvalue` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `shop_discount` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `awardID1` TEXT,
  `awardID2` TEXT,
  `awardID3` TEXT,
  `awardNum1` TEXT,
  `awardNum2` TEXT,
  `awardNum3` TEXT,
  `awardType1` TEXT,
  `awardType2` TEXT,
  `awardType3` TEXT,
  `def` TEXT,
  `discount` TEXT,
  `msg` TEXT,
  `name` TEXT,
  `srcPrice` TEXT,
  `type` TEXT,
  `vip0` TEXT,
  `vip1` TEXT,
  `vip10` TEXT,
  `vip11` TEXT,
  `vip12` TEXT,
  `vip13` TEXT,
  `vip14` TEXT,
  `vip15` TEXT,
  `vip2` TEXT,
  `vip3` TEXT,
  `vip4` TEXT,
  `vip5` TEXT,
  `vip6` TEXT,
  `vip7` TEXT,
  `vip8` TEXT,
  `vip9` TEXT,
  `vipLimit` TEXT,
  `weekdayInfo` TEXT
);

CREATE TABLE IF NOT EXISTS `shop_discount_save` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `discount_Id` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `shop_mystery` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `exvalue` TEXT,
  `item` TEXT,
  `num` TEXT,
  `price` TEXT,
  `rate1` TEXT,
  `rate2` TEXT,
  `rate3` TEXT,
  `rate4` TEXT,
  `rate5` TEXT,
  `rate6` TEXT,
  `rate7` TEXT,
  `rate8` TEXT,
  `rate9` TEXT
);

CREATE TABLE IF NOT EXISTS `shop_yaoshi` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `item` TEXT,
  `num` TEXT,
  `price` TEXT,
  `rate1` TEXT,
  `rate10` TEXT,
  `rate11` TEXT,
  `rate12` TEXT,
  `rate2` TEXT,
  `rate3` TEXT,
  `rate4` TEXT,
  `rate5` TEXT,
  `rate6` TEXT,
  `rate7` TEXT,
  `rate8` TEXT,
  `rate9` TEXT
);

CREATE TABLE IF NOT EXISTS `sig_log` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `skill` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `CD` TEXT,
  `des` TEXT,
  `learnLevel` TEXT,
  `name` TEXT,
  `xiang` TEXT
);

CREATE TABLE IF NOT EXISTS `skill_levelup` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `money` TEXT,
  `QianNeng` TEXT,
  `skillId` TEXT,
  `skillLevel` TEXT
);

CREATE TABLE IF NOT EXISTS `source` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `start` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `stream` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `strtoddiyfp` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `taohuageng_config` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `material_id` INTEGER NOT NULL DEFAULT '0',
  `material_per_num` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `template` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `text` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `that` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `tongtianta` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `_1` TEXT,
  `roleId` TEXT
);

CREATE TABLE IF NOT EXISTS `transform` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `attr_type1` TEXT,
  `attr_type2` TEXT,
  `attr_type3` TEXT,
  `attr_type4` TEXT,
  `attr_type5` TEXT,
  `attr_type6` TEXT,
  `attr_type7` TEXT,
  `attr_type8` TEXT,
  `attr_value1` TEXT,
  `attr_value2` TEXT,
  `attr_value3` TEXT,
  `attr_value4` TEXT,
  `attr_value5` TEXT,
  `attr_value6` TEXT,
  `attr_value7` TEXT,
  `attr_value8` TEXT,
  `item_id` TEXT,
  `last_time` TEXT,
  `monster_id` TEXT,
  `monster_name` TEXT,
  `name` TEXT,
  `quality` TEXT,
  `target_type` TEXT
);

CREATE TABLE IF NOT EXISTS `user_award` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `user_info` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bd_money` TEXT,
  `binding` TEXT,
  `del_test_award` TEXT,
  `money` TEXT,
  `name` TEXT,
  `password` TEXT,
  `personal_id` TEXT,
  `personal_name` TEXT,
  `phone_state` TEXT,
  `role0` TEXT,
  `role1` TEXT,
  `role2` TEXT,
  `role3` TEXT
);

CREATE TABLE IF NOT EXISTS `user_info1` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `bd_money` TEXT,
  `binding` TEXT,
  `del_test_award` TEXT,
  `money` TEXT,
  `name` TEXT,
  `password` TEXT,
  `personal_id` TEXT,
  `personal_name` TEXT,
  `phone_state` TEXT,
  `role0` TEXT,
  `role1` TEXT,
  `role2` TEXT,
  `role3` TEXT,
  `ad` INTEGER NOT NULL DEFAULT '0',
  `del_time0` INTEGER NOT NULL DEFAULT '0',
  `type` INTEGER NOT NULL DEFAULT '0',
  `reg_time` INTEGER NOT NULL DEFAULT '0',
  `mobile_type` TEXT NOT NULL DEFAULT '',
  `mobile_info` TEXT NOT NULL DEFAULT '',
  `new_user` INTEGER NOT NULL DEFAULT '0'
);

CREATE TABLE IF NOT EXISTS `user_record_log` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `value` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE IF NOT EXISTS `vip_def` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `arenabuy` TEXT,
  `arenatz` TEXT,
  `awardn1` TEXT,
  `awardn2` TEXT,
  `awardn3` TEXT,
  `awardt1` TEXT,
  `awardt2` TEXT,
  `awardt3` TEXT,
  `bossbuy` TEXT,
  `bosstz` TEXT,
  `fengshen_shilian` TEXT,
  `fxdown` TEXT,
  `fxexp` TEXT,
  `jingbi_tree` TEXT,
  `jingyan_tree` TEXT,
  `lingqi` TEXT,
  `neidan_tree` TEXT,
  `offline` TEXT,
  `openshop` TEXT,
  `sweep_copy` TEXT,
  `vip` TEXT,
  `yaoqianshu` TEXT,
  `yaoqianshu2` TEXT,
  `yuanbao` TEXT,
  `yuanbao_tree` TEXT,
  `zhongzhi` TEXT
);

CREATE TABLE IF NOT EXISTS `white_ip` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `comment` TEXT,
  `ip` TEXT
);

CREATE TABLE IF NOT EXISTS `xianyuan_card` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `chapter_info` TEXT,
  `des` TEXT,
  `isnotice` TEXT,
  `item_id` TEXT,
  `name` TEXT,
  `pic` TEXT,
  `quality` TEXT,
  `single_odds` TEXT,
  `ten_odds` TEXT,
  `xy_value` TEXT
);

CREATE TABLE IF NOT EXISTS `xianyuan_chapter` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `attr_type1` TEXT,
  `attr_type2` TEXT,
  `attr_type3` TEXT,
  `attr_type4` TEXT,
  `attr_value1` TEXT,
  `attr_value2` TEXT,
  `attr_value3` TEXT,
  `attr_value4` TEXT,
  `des` TEXT,
  `name` TEXT,
  `need_card1` TEXT,
  `need_card2` TEXT,
  `need_card3` TEXT,
  `need_card4` TEXT,
  `need_card5` TEXT
);

CREATE TABLE IF NOT EXISTS `xin_shi` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `money` INTEGER NOT NULL DEFAULT '0',
  `YB` INTEGER NOT NULL DEFAULT '0',
  `bdYB` INTEGER NOT NULL DEFAULT '0',
  `attachment` TEXT,
  `from_id` INTEGER NOT NULL DEFAULT '0',
  `to_id` INTEGER NOT NULL DEFAULT '0',
  `gmtime` INTEGER NOT NULL DEFAULT '0',
  `time` TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `shenhun` INTEGER NOT NULL DEFAULT '0',
  `deleted` INTEGER NOT NULL DEFAULT '0',
  `from_name` TEXT NOT NULL DEFAULT '',
  `message` TEXT
);

CREATE TABLE IF NOT EXISTS `zha_dan_info` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `type` INTEGER NOT NULL DEFAULT '0',
  `award` INTEGER NOT NULL DEFAULT '0',
  `num` INTEGER NOT NULL DEFAULT '0',
  `petQt` INTEGER NOT NULL DEFAULT '0',
  `petQtLv` INTEGER NOT NULL DEFAULT '0',
  `rate` INTEGER NOT NULL DEFAULT '0',
  `isJinPin` INTEGER NOT NULL DEFAULT '0',
  `isShow` INTEGER NOT NULL DEFAULT '0',
  `notice` TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS `zha_dan_log` (
  `id` INTEGER PRIMARY KEY AUTOINCREMENT,
  `data` TEXT,
  `time` TEXT NULL DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS `schema_version` (
  `version` INTEGER PRIMARY KEY,
  `name` TEXT NOT NULL,
  `source_sha256` TEXT NOT NULL,
  `applied_utc` TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT OR IGNORE INTO `schema_version` (`version`,`name`,`source_sha256`)
VALUES (1,'initial-schema','91C71452B603940A96DD35C98EE3B14F383C50A09405BB9871AAD903C311F022');

-- Local-only first-charge UI fallback. Do not treat these as production rewards.
INSERT INTO `hd_peizhi_info`
  (`type`,`yb`,`count`,`lv`,`idx`,`cdTime`,`price`,`count_ext8`,`lastTime_ext32`,`zhenying1_name`,`zhenying2_name`,`water_cz`,`bug_cz`,`step1_cz`,`step2_cz`)
SELECT 29,60,1,0,1,0,6,0,0,'','',0,0,0,0
WHERE NOT EXISTS (SELECT 1 FROM `hd_peizhi_info` WHERE `type`=29);

INSERT INTO `huodong_award`
  (`type`,`idx`,`YB`,`award1`,`num1`,`petQt1`,`petQtLv1`,`award2`,`num2`,`petQt2`,`petQtLv2`,`award3`,`num3`,`petQt3`,`petQtLv3`,`award4`,`num4`,`petQt4`,`petQtLv4`,`award5`,`num5`,`petQt5`,`petQtLv5`,`award6`,`num6`,`petQt6`,`petQtLv6`,`idx2`,`idx3`)
SELECT 29,1,0,60002,19,5,1,1001,10,0,0,837,10,0,0,60000,100000,0,0,60001,500,0,0,0,0,0,0,0,0
WHERE NOT EXISTS (SELECT 1 FROM `huodong_award` WHERE `type`=29 AND `idx`=1);

-- Trading-house initialization requires one baseline exchange-rate row.
INSERT INTO `jiaoyi_gold_yuzhi` (`id`,`gold`,`time`)
SELECT 1,30000,CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM `jiaoyi_gold_yuzhi`);

-- Keep the local trading-house feature in its legacy default state.
INSERT INTO `function_switch` (`id`,`function_type`,`switch_state`)
SELECT 1,1,1
WHERE NOT EXISTS (SELECT 1 FROM `function_switch` WHERE `function_type`=1);

COMMIT;
