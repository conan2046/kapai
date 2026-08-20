param(
  [string]$HostName = "127.0.0.1",
  [int]$Port = 8711,
  [int]$UserId = 1,
  [int]$RoleId = 1000001,
  [int]$ServerId = 1,
  [string]$Version = "102600",
  [switch]$AutoCreateRole,
  [switch]$ExpectCreateFailure,
  [string]$RoleName = "",
  [switch]$RoleNameOnly,
  [switch]$Extended,
  [switch]$Actions,
  [switch]$Mutations,
  [switch]$Positive,
  [switch]$SteamIncluded,
  [switch]$BagParity,
  [switch]$TaskParity,
  [switch]$TaskRestartVerify,
  [switch]$PlayerHudParity,
  [switch]$HeroParity,
  [switch]$HeroRestartVerify,
  [switch]$HeroEquipParity,
  [switch]$HeroEquipRestartVerify,
  [switch]$MailParity,
  [switch]$MailRestartVerify,
  [switch]$ShopParity,
  [switch]$ShopRestartVerify,
  [switch]$GameplayShopsParity,
  [switch]$GameplayShopsRestartVerify,
  [switch]$WorldParity,
  [switch]$WorldRestartVerify,
  [switch]$DrawParity,
  [switch]$DrawRestartVerify,
  [switch]$GameplayParity,
  [switch]$GameplayRestartVerify,
  [switch]$YouLiParity,
  [switch]$YouLiRestartVerify,
  [switch]$FengShenStoryParity,
  [switch]$FengShenStoryRestartVerify,
  [switch]$ArenaParity,
  [switch]$ArenaRestartVerify,
  [switch]$XunBaoParity,
  [switch]$XunBaoRestartVerify,
  [switch]$Consumption,
  [switch]$Battle,
  [switch]$BattleListOnly,
  [switch]$UiQueries,
  [switch]$NpcFlow,
  [switch]$InvalidRisky,
  [int]$FriendApplyRoleId = 0,
  [int]$TeamPeerAcceptLeaderRoleId = 0,
  [int]$TeamPeerWaitSeconds = 120,
  [switch]$TeamProbe,
  [string]$ResultPath = "",
  [string]$PythonExecutable = ""
)

if (-not $PythonExecutable) {
  $pythonCommand = Get-Command python -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $pythonCommand) {
    throw "Python executable was not resolved. Pass -PythonExecutable with an absolute path."
  }
  $PythonExecutable = [string]$pythonCommand.Source
}
if (-not (Test-Path -LiteralPath $PythonExecutable -PathType Leaf)) {
  throw "Python executable is missing: $PythonExecutable"
}

$autoCreateRoleText = if ($AutoCreateRole) { "true" } else { "false" }
if ($ExpectCreateFailure -and -not $AutoCreateRole) {
  throw "ExpectCreateFailure requires AutoCreateRole"
}
if ($BagParity -and -not $AutoCreateRole) {
  throw "BagParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($TaskParity -and -not $AutoCreateRole) {
  throw "TaskParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($TaskRestartVerify -and $AutoCreateRole) {
  throw "TaskRestartVerify requires an existing persisted role."
}
if ($PlayerHudParity -and $AutoCreateRole) {
  throw "PlayerHudParity requires an existing role prepared at level 1 with 59 experience."
}
if ($HeroParity -and -not $AutoCreateRole) {
  throw "HeroParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($HeroRestartVerify -and $AutoCreateRole) {
  throw "HeroRestartVerify requires an existing persisted role."
}
if ($HeroEquipParity -and -not $AutoCreateRole) {
  throw "HeroEquipParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($HeroEquipRestartVerify -and $AutoCreateRole) {
  throw "HeroEquipRestartVerify requires an existing persisted role."
}
if ($MailParity -and -not $AutoCreateRole) {
  throw "MailParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($MailRestartVerify -and $AutoCreateRole) {
  throw "MailRestartVerify requires an existing persisted role."
}
if ($ShopParity -and -not $AutoCreateRole) {
  throw "ShopParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($ShopRestartVerify -and $AutoCreateRole) {
  throw "ShopRestartVerify requires an existing persisted role."
}
if ($GameplayShopsParity -and -not $AutoCreateRole) {
  throw "GameplayShopsParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($GameplayShopsRestartVerify -and $AutoCreateRole) {
  throw "GameplayShopsRestartVerify requires an existing persisted role."
}
if ($WorldParity -and -not $AutoCreateRole) {
  throw "WorldParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($WorldRestartVerify -and $AutoCreateRole) {
  throw "WorldRestartVerify requires an existing persisted role."
}
if ($DrawParity -and -not $AutoCreateRole) {
  throw "DrawParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($DrawRestartVerify -and $AutoCreateRole) {
  throw "DrawRestartVerify requires an existing persisted role."
}
if ($GameplayParity -and -not $AutoCreateRole) {
  throw "GameplayParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($GameplayRestartVerify -and $AutoCreateRole) {
  throw "GameplayRestartVerify requires an existing persisted role."
}
if ($YouLiParity -and -not $AutoCreateRole) {
  throw "YouLiParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($YouLiRestartVerify -and $AutoCreateRole) {
  throw "YouLiRestartVerify requires an existing persisted role."
}
if ($FengShenStoryParity -and -not $AutoCreateRole) {
  throw "FengShenStoryParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($FengShenStoryRestartVerify -and $AutoCreateRole) {
  throw "FengShenStoryRestartVerify requires an existing persisted role."
}
if ($ArenaParity -and -not $AutoCreateRole) {
  throw "ArenaParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($ArenaRestartVerify -and $AutoCreateRole) {
  throw "ArenaRestartVerify requires an existing persisted role."
}
if ($XunBaoParity -and -not $AutoCreateRole) {
  throw "XunBaoParity requires AutoCreateRole so both backends start from a disposable role."
}
if ($XunBaoRestartVerify -and $AutoCreateRole) {
  throw "XunBaoRestartVerify requires an existing persisted role."
}
if ((@($BagParity, $TaskParity, $TaskRestartVerify, $PlayerHudParity, $HeroParity, $HeroRestartVerify, $HeroEquipParity, $HeroEquipRestartVerify, $MailParity, $MailRestartVerify, $ShopParity, $ShopRestartVerify, $GameplayShopsParity, $GameplayShopsRestartVerify, $WorldParity, $WorldRestartVerify, $DrawParity, $DrawRestartVerify, $GameplayParity, $GameplayRestartVerify, $YouLiParity, $YouLiRestartVerify, $FengShenStoryParity, $FengShenStoryRestartVerify, $ArenaParity, $ArenaRestartVerify, $XunBaoParity, $XunBaoRestartVerify) | Where-Object { $_ }).Count -gt 1) {
  throw "Module-specific parity and restart modes are mutually exclusive."
}
$expectCreateFailureText = if ($ExpectCreateFailure) { "true" } else { "false" }
if ($AutoCreateRole -and [string]::IsNullOrWhiteSpace($RoleName)) {
  $alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  $value = Get-Random -Minimum 0 -Maximum 60466176
  $suffix = New-Object char[] 5
  for ($i = 4; $i -ge 0; $i--) {
    $suffix[$i] = $alphabet[$value % 36]
    $value = [Math]::Floor($value / 36)
  }
  $RoleName = "T" + (-join $suffix)
}
$extendedText = if ($Extended) { "true" } else { "false" }
$roleNameOnlyText = if ($RoleNameOnly) { "true" } else { "false" }
$actionsText = if ($Actions) { "true" } else { "false" }
$mutationsText = if ($Mutations) { "true" } else { "false" }
$positiveText = if ($Positive) { "true" } else { "false" }
$steamIncludedText = if ($SteamIncluded) { "true" } else { "false" }
$bagParityText = if ($BagParity) { "true" } else { "false" }
$taskParityText = if ($TaskParity) { "true" } else { "false" }
$taskRestartVerifyText = if ($TaskRestartVerify) { "true" } else { "false" }
$playerHudParityText = if ($PlayerHudParity) { "true" } else { "false" }
$heroParityText = if ($HeroParity) { "true" } else { "false" }
$heroRestartVerifyText = if ($HeroRestartVerify) { "true" } else { "false" }
$heroEquipParityText = if ($HeroEquipParity) { "true" } else { "false" }
$heroEquipRestartVerifyText = if ($HeroEquipRestartVerify) { "true" } else { "false" }
$mailParityText = if ($MailParity) { "true" } else { "false" }
$mailRestartVerifyText = if ($MailRestartVerify) { "true" } else { "false" }
$shopParityText = if ($ShopParity) { "true" } else { "false" }
$shopRestartVerifyText = if ($ShopRestartVerify) { "true" } else { "false" }
$gameplayShopsParityText = if ($GameplayShopsParity) { "true" } else { "false" }
$gameplayShopsRestartVerifyText = if ($GameplayShopsRestartVerify) { "true" } else { "false" }
$worldParityText = if ($WorldParity) { "true" } else { "false" }
$worldRestartVerifyText = if ($WorldRestartVerify) { "true" } else { "false" }
$drawParityText = if ($DrawParity) { "true" } else { "false" }
$drawRestartVerifyText = if ($DrawRestartVerify) { "true" } else { "false" }
$gameplayParityText = if ($GameplayParity) { "true" } else { "false" }
$gameplayRestartVerifyText = if ($GameplayRestartVerify) { "true" } else { "false" }
$youLiParityText = if ($YouLiParity) { "true" } else { "false" }
$youLiRestartVerifyText = if ($YouLiRestartVerify) { "true" } else { "false" }
$fengShenStoryParityText = if ($FengShenStoryParity) { "true" } else { "false" }
$fengShenStoryRestartVerifyText = if ($FengShenStoryRestartVerify) { "true" } else { "false" }
$arenaParityText = if ($ArenaParity) { "true" } else { "false" }
$arenaRestartVerifyText = if ($ArenaRestartVerify) { "true" } else { "false" }
$xunBaoParityText = if ($XunBaoParity) { "true" } else { "false" }
$xunBaoRestartVerifyText = if ($XunBaoRestartVerify) { "true" } else { "false" }
$consumptionText = if ($Consumption) { "true" } else { "false" }
$battleText = if ($Battle) { "true" } else { "false" }
$battleListOnlyText = if ($BattleListOnly) { "true" } else { "false" }
$uiQueriesText = if ($UiQueries) { "true" } else { "false" }
$npcFlowText = if ($NpcFlow) { "true" } else { "false" }
$invalidRiskyText = if ($InvalidRisky) { "true" } else { "false" }
$friendApplyRoleIdText = $FriendApplyRoleId
$teamPeerAcceptLeaderRoleIdText = $TeamPeerAcceptLeaderRoleId
$teamPeerWaitSecondsText = $TeamPeerWaitSeconds
$teamProbeText = if ($TeamProbe) { "true" } else { "false" }
$resolvedResultPath = if ([string]::IsNullOrWhiteSpace($ResultPath)) {
  ""
} elseif ([IO.Path]::IsPathRooted($ResultPath)) {
  [IO.Path]::GetFullPath($ResultPath)
} else {
  [IO.Path]::GetFullPath((Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..\..")) $ResultPath))
}
$resultPathBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($resolvedResultPath))
$python = @"
import socket, struct, time, threading, sys, json, base64, os, hashlib

HOST = "$HostName"
PORT = $Port
USER_ID = $UserId
ROLE_ID = $RoleId
SERVER_ID = $ServerId
VERSION = "$Version"
AUTO_CREATE_ROLE = "$autoCreateRoleText"
EXPECT_CREATE_FAILURE = "$expectCreateFailureText"
ROLE_NAME = "$RoleName"
GUILD_NAME = "G" + ROLE_NAME[1:] if len(ROLE_NAME) > 1 else "G10001"
ROLE_NAME_ONLY = "$roleNameOnlyText"
EXTENDED = "$extendedText"
ACTIONS = "$actionsText"
MUTATIONS = "$mutationsText"
POSITIVE = "$positiveText"
STEAM_INCLUDED = "$steamIncludedText"
BAG_PARITY = "$bagParityText"
TASK_PARITY = "$taskParityText"
TASK_RESTART_VERIFY = "$taskRestartVerifyText"
PLAYERHUD_PARITY = "$playerHudParityText"
HERO_PARITY = "$heroParityText"
HERO_RESTART_VERIFY = "$heroRestartVerifyText"
HERO_EQUIP_PARITY = "$heroEquipParityText"
HERO_EQUIP_RESTART_VERIFY = "$heroEquipRestartVerifyText"
MAIL_PARITY = "$mailParityText"
MAIL_RESTART_VERIFY = "$mailRestartVerifyText"
SHOP_PARITY = "$shopParityText"
SHOP_RESTART_VERIFY = "$shopRestartVerifyText"
GAMEPLAY_SHOPS_PARITY = "$gameplayShopsParityText"
GAMEPLAY_SHOPS_RESTART_VERIFY = "$gameplayShopsRestartVerifyText"
WORLD_PARITY = "$worldParityText"
WORLD_RESTART_VERIFY = "$worldRestartVerifyText"
DRAW_PARITY = "$drawParityText"
DRAW_RESTART_VERIFY = "$drawRestartVerifyText"
GAMEPLAY_PARITY = "$gameplayParityText"
GAMEPLAY_RESTART_VERIFY = "$gameplayRestartVerifyText"
YOULI_PARITY = "$youLiParityText"
YOULI_RESTART_VERIFY = "$youLiRestartVerifyText"
FENGSHEN_STORY_PARITY = "$fengShenStoryParityText"
FENGSHEN_STORY_RESTART_VERIFY = "$fengShenStoryRestartVerifyText"
ARENA_PARITY = "$arenaParityText"
ARENA_RESTART_VERIFY = "$arenaRestartVerifyText"
XUNBAO_PARITY = "$xunBaoParityText"
XUNBAO_RESTART_VERIFY = "$xunBaoRestartVerifyText"
CONSUMPTION = "$consumptionText"
BATTLE = "$battleText"
BATTLE_LIST_ONLY = "$battleListOnlyText"
UI_QUERIES = "$uiQueriesText"
NPC_FLOW = "$npcFlowText"
INVALID_RISKY = "$invalidRiskyText"
FRIEND_APPLY_ROLE_ID = $friendApplyRoleIdText
TEAM_PEER_ACCEPT_LEADER_ROLE_ID = $teamPeerAcceptLeaderRoleIdText
TEAM_PEER_WAIT_SECONDS = $teamPeerWaitSecondsText
TEAM_PROBE = "$teamProbeText"
RESULT_PATH = base64.b64decode("$resultPathBase64").decode('utf-8')

def u8(v): return struct.pack('<B', v)
def u16(v): return struct.pack('<H', v)
def u32(v): return struct.pack('<I', v)
def s(v):
    data = (v or '').encode('utf-16le')
    return u16(len(data)) + data
def pkt(t, body=b''):
    return u32(len(body)) + u16(t) + body

def read_wire_string(body, pos):
    if pos + 2 > len(body):
        raise RuntimeError('wire string length is truncated')
    byte_len = struct.unpack('<H', body[pos:pos + 2])[0]
    pos += 2
    if pos + byte_len > len(body):
        raise RuntimeError('wire string body is truncated')
    value = body[pos:pos + byte_len].decode('utf-16le')
    return value, pos + byte_len

def parse_mail_list_body(body):
    if len(body) < 2 or body[0] != 2:
        raise RuntimeError('mail list response header is invalid')
    pos = 2
    records = []
    for _ in range(body[1]):
        if pos + 8 > len(body):
            raise RuntimeError('mail list identity is truncated')
        mail_id = struct.unpack('<I', body[pos:pos + 4])[0]
        from_id = struct.unpack('<I', body[pos + 4:pos + 8])[0]
        pos += 8
        sender, pos = read_wire_string(body, pos)
        if pos + 4 > len(body):
            raise RuntimeError('mail list expiry is truncated')
        expire_at = struct.unpack('<I', body[pos:pos + 4])[0]
        pos += 4
        message, pos = read_wire_string(body, pos)
        if pos >= len(body):
            raise RuntimeError('mail reward count is missing')
        reward_count = body[pos]
        pos += 1
        rewards = []
        for _ in range(reward_count):
            if pos + 10 > len(body):
                raise RuntimeError('mail reward is truncated')
            rewards.append({
                'type': struct.unpack('<H', body[pos:pos + 2])[0],
                'typeId': struct.unpack('<I', body[pos + 2:pos + 6])[0],
                'num': struct.unpack('<I', body[pos + 6:pos + 10])[0]
            })
            pos += 10
        records.append({'id': mail_id, 'fromId': from_id, 'sender': sender, 'expireAt': expire_at, 'message': message, 'rewards': rewards})
    if pos != len(body):
        raise RuntimeError('mail list response has unread bytes')
    return records

recv_types = []
recv_bodies = {}
recv_events = []
sent_case_names = []
case_responses = []
created_role_id = {'id': None}
create_response = {'body': None}
battle_target = {'value': None}
fengshen_trial = {'value': None}
bag_item_slots = {}
hero_equip_uids = {'equip': None, 'fabao': None}
mail_fixture_ids = {'reward': None, 'plain': None}
stop_flag = {'stop': False}

def reader(sock):
    buf = b''
    sock.settimeout(0.2)
    while not stop_flag['stop']:
        try:
            chunk = sock.recv(65536)
            if not chunk:
                break
            buf += chunk
            while len(buf) >= 6:
                body_len = struct.unpack('<I', buf[:4])[0]
                total = 6 + body_len
                if len(buf) < total:
                    break
                msg_type = struct.unpack('<H', buf[4:6])[0]
                body = buf[6:total]
                if msg_type == 1003 and len(body) >= 5 and body[0] == 1:
                    created_role_id['id'] = struct.unpack('<I', body[1:5])[0]
                if msg_type == 1003:
                    create_response['body'] = body
                if (BATTLE == 'true' or ARENA_PARITY == 'true') and msg_type == 161 and len(body) >= 4 and body[0:3] == b'\x00\x01\x01':
                    pos = 4
                    candidate = None
                    for _ in range(body[3]):
                        if pos + 9 > len(body):
                            break
                        rank = struct.unpack('<I', body[pos:pos + 4])[0]
                        unit_type = body[pos + 4]
                        role_id = struct.unpack('<I', body[pos + 5:pos + 9])[0]
                        pos += 9
                        if unit_type != 1:
                            break
                        if rank > 10:
                            candidate = (rank, role_id, unit_type)
                    battle_target['value'] = candidate
                if BATTLE == 'true' and msg_type == 320 and len(body) >= 2 and body[0] == 21:
                    pos = 2
                    for _ in range(body[1]):
                        if pos + 11 > len(body):
                            break
                        trial_id = struct.unpack('<I', body[pos:pos + 4])[0]
                        is_open = body[pos + 5]
                        if is_open and fengshen_trial['value'] is None:
                            fengshen_trial['value'] = trial_id
                        pos += 11
                if BAG_PARITY == 'true' and msg_type == 15 and len(body) >= 7 and body[0] in (1, 2):
                    package_slot = struct.unpack('<H', body[1:3])[0]
                    package_item = struct.unpack('<H', body[3:5])[0]
                    package_num = struct.unpack('<H', body[5:7])[0]
                    if package_item == 0 or package_num == 0:
                        stale_items = [item_id for item_id, slot in bag_item_slots.items() if slot == package_slot]
                        for item_id in stale_items:
                            bag_item_slots.pop(item_id, None)
                    else:
                        bag_item_slots[package_item] = package_slot
                if HERO_EQUIP_PARITY == 'true' and msg_type == 319 and len(body) >= 5:
                    if body[0] == 6:
                        hero_equip_uids['equip'] = struct.unpack('<I', body[1:5])[0]
                    elif body[0] == 22:
                        hero_equip_uids['fabao'] = struct.unpack('<I', body[1:5])[0]
                recv_types.append(msg_type)
                recv_bodies.setdefault(msg_type, []).append(body)
                recv_events.append((msg_type, body))
                buf = buf[total:]
        except socket.timeout:
            pass

smokes = [
    ('package', 8, b''),
    ('sys_time', 206, u8(9)),
    ('save_vals', 146, u8(40) + u8(1)),
    ('client_str_all', 331, u8(2) + u8(0)),
    ('red_point_func', 65, u8(1) + u16(65)),
    ('fuben_map_main', 320, u8(1) + u8(1)),
    ('fuben_achievement', 320, u8(11)),
    ('tili_info', 321, u8(1)),
    ('hero_book', 322, u8(1)),
    ('blood_fight_info', 323, u8(1)),
    ('blood_fight_activity', 323, u8(15)),
    ('youli_info', 335, u8(1)),
    ('world_level', 249, b''),
    ('daily_activity', 209, u8(1)),
    ('vip_info', 220, u8(1)),
    ('pet_draw_info', 224, u8(1)),
    ('pet_copy_info', 243, u8(1)),
    ('treasure_map_info', 244, u8(1)),
    ('shilian_info', 245, u8(1)),
    ('stage_goal', 223, u8(1)),
]

if EXTENDED == 'true':
    smokes.extend([
        ('mount_base', 185, u8(1)),
        ('mount_collect', 185, u8(7)),
        ('wing_base', 180, u8(1)),
        ('mission_main', 37, u8(1)),
        ('mission_daily', 37, u8(4)),
        ('mission_fund', 37, u8(7)),
        ('available_task_list', 89, u8(4)),
        ('mail_list', 128, u8(2)),
        ('title_list', 105, b''),
        ('formation_info', 48, u8(1)),
        ('find_resource', 52, u8(1)),
        ('bangpai_list', 54, u8(2)),
        ('my_bangpai', 80, u8(1)),
        ('client_net_check', 175, u32(1)),
        ('heart_beat', 102, b''),
        ('rank_level', 193, u16(1)),
        ('rank_power', 193, u16(3)),
        ('offline_exp_info', 219, u8(1)),
        ('new_shenqi_base', 307, u8(1)),
        ('new_shenqi_enhance_info', 307, u8(3)),
        ('new_shenqi_current', 307, u8(5)),
        ('transform_card_info', 259, u8(1)),
        ('transform_current', 259, u8(2)),
        ('gonggao_query', 88, b''),
        ('charge_server_id', 233, b''),
        ('mobai_base', 239, u8(1)),
        ('mobai_panel', 239, u8(2)),
        ('feixian_data', 246, u8(2)),
        ('task_track_zero', 182, u16(0)),
        ('answer_question_get', 198, u8(1)),
        ('help_title_list', 208, u8(1)),
        ('daily_boss_info', 225, u8(3)),
        ('fish_room_list', 217, u8(1)),
        ('leitai_score', 228, u8(2)),
        ('friend_list', 27, u8(1)),
        ('friend_apply_list', 27, u8(2)),
        ('friend_gift_list', 27, u8(9)),
        ('friend_black_list', 27, u8(12)),
        ('friend_recommend', 27, u8(15)),
        ('near_player_list', 35, u8(1)),
        ('team_list', 29, u8(3) + u8(0)),
        ('pet_all', 24, u8(1)),
        ('pet_skill_57', 40, u16(57)),
        ('finished_mission', 49, b''),
        ('fuqi', 117, b''),
        ('token_360', 178, b''),
        ('query_scene_map1', 100, u16(1)),
        ('fuben_daily_list', 190, u8(11)),
        ('huodong_state', 199, u16(1)),
        ('role_name_check_smoke', 1002, u8(1) + s('Smoke')),
		('role_name_random_female', 1002, u8(2) + u8(1)),
        ('yaoling_cost', 55, u8(2)),
        ('bangzhan_info', 56, u8(1)),
        ('pk_notice_state', 262, u8(3)),
        ('mianzhanpai_cd', 312, b''),
        ('jiaoyi_buy_panel', 313, u8(1)),
        ('jiaoyi_sell_panel', 313, u8(3)),
        ('jiaoyi_record', 313, u8(6)),
        ('flower_self', 314, u8(3)),
        ('flower_rank', 314, u8(6)),
    ])

if TEAM_PROBE == 'true':
    smokes.extend([
        ('team_create', 29, u8(1)),
        ('team_state', 29, u8(16)),
    ])

if ACTIONS == 'true':
    smokes.extend([
        ('package_item_empty', 194, u8(1) + u8(255)),
        ('mount_hide', 185, u8(4) + u8(255)),
        ('wing_hide', 180, u8(3) + u8(255)),
        ('blood_fight_rank', 323, u8(17)),
        ('blood_fight_box_empty', 323, u8(4) + u16(0)),
        ('tili_free_info', 321, u8(2)),
        ('fuben_fix_empty', 320, u8(3) + u32(0)),
        ('fuben_node_empty', 320, u8(27) + u8(1) + u32(0) + u32(0)),
        ('shop_list', 221, u8(1)),
        ('scene_escape_pos', 90, b''),
        ('query_item_desc_bad', 83, u16(0)),
        ('pet_equip_list', 319, u8(1)),
        ('fabao_list', 319, u8(17)),
        ('pet_equip_master', 319, u8(25)),
        ('pet_equip_search_count', 319, u8(31)),
        ('available_task_bad_detail', 89, u8(5) + u16(0)),
        ('title_show_bad', 106, u8(2) + u16(0) + u8(0)),
        ('client_str_one_empty', 331, u8(2) + u8(1) + u8(0)),
        ('caiquan_invalid', 232, u8(1) + u8(0) + u8(0)),
        ('real_name_empty', 330, u8(1) + s('') + s('')),
        ('role_move_invalid', 9, u16(65535) + u16(65535)),
        ('jump_ack_idle', 10, b''),
        ('nearby_chat', 26, u8(2) + s('local-smoke') + u8(0)),
        ('doption_zero', 168, u32(0)),
        ('interact_local_add_item_4', 13, u8(50) + u32(4) + u16(2)),
        ('hecheng_noop', 192, u8(1)),
        ('user_world_notice_empty', 238, b''),
    ])

if MUTATIONS == 'true':
    smokes.extend([
        ('save_val_set', 145, u8(39) + u32(12345)),
        ('save_val_get_one', 146, u8(39) + u8(0)),
        ('client_str_set', 331, u8(1) + u8(9) + s('local-smoke')),
        ('client_str_get_one', 331, u8(2) + u8(1) + u8(9)),
        ('chat_channel_close_world', 73, u8(1) + u8(0)),
        ('chat_channel_open_world', 73, u8(1) + u8(1)),
        ('switch_info', 74, b''),
        ('mount_hide_mutation', 185, u8(4) + u8(255)),
        ('wing_hide_mutation', 180, u8(3) + u8(255)),
        ('title_hide_invalid', 106, u8(2) + u16(0) + u8(0)),
        ('title_unuse_invalid', 106, u8(3) + u16(0) + u8(0)),
        ('open_interact_invalid', 12, u16(0) + u16(0) + u16(0)),
        ('package_discard_invalid', 15, u8(0) + u8(255) + u8(1)),
        ('ignore_dialog_idle', 20, b''),
        ('npc_state_invalid', 58, u8(1) + u16(0) + u16(0)),
        ('world_transport_invalid', 195, u16(1001)),
        ('ignore_qiecuo_on', 261, u8(1)),
        ('ignore_qiecuo_off', 261, u8(0)),
        ('ignore_vip_on', 263, u8(1) + u8(1)),
        ('ignore_vip_off', 263, u8(1) + u8(0)),
    ])

if POSITIVE == 'true':
    smokes.extend([
        ('bangpai_create_unique', 54, u8(1) + s(GUILD_NAME) + s('local') + u32(0) + u16(0)),
        ('bangpai_info_self', 54, u8(13)),
        ('bangpai_member_list', 54, u8(10)),
        ('bangpai_donate_info', 54, u8(37)),
        ('bangpai_donate_money_1', 54, u8(38) + u8(1)),
        ('bangpai_copy_chapter', 64, u8(1)),
        ('bangpai_copy_buff', 64, u8(6)),
        ('bangpai_copy_huoyue', 64, u8(9)),
        ('tili_free_claim_1', 321, u8(3) + u8(1) + u8(1)),
        ('pet_draw_single_type1', 224, u8(2) + u8(1) + u8(1)),
        ('pet_draw_single_type2', 224, u8(2) + u8(2) + u8(1)),
        ('blood_fight_start', 323, u8(2)),
        ('blood_fight_try_easy', 323, u8(3) + u8(1)),
        ('blood_fight_retry', 323, u8(6)),
        ('youli_start_pet57', 335, u8(2) + u8(1) + u16(57) + u8(1) + u8(1) + u8(1)),
        ('youli_award_1', 335, u8(3) + u8(1) + u8(1)),
        ('shop_refresh_type4', 221, u8(3) + u8(4)),
        ('shop_buy_type4_tid1', 221, u8(2) + u8(4) + u16(1) + u16(1) + u8(0)),
		('shop_buy_stamina_pill_5', 221, u8(2) + u8(1) + u16(1002) + u16(5) + u8(0)),
        ('stage_award_1', 223, u8(2) + u8(1)),
    ])

if CONSUMPTION == 'true':
    smokes.extend([
        # Safe local coverage for payment/consumption entry points. Only the
        # package expansion performs a real deduction, using disposable-role
        # test currency. External payment operations use non-payment branches.
        ('use_special_item_missing_rename_card', 47, u8(1) + s('LocalTest')),
        ('use_special_item_valid_rename', 47, u8(1) + s('R12345')),
        ('charge_non_ios', 84, u16(0) + s('') + s('') + u16(0) + s('') + s('') + s('') + s('')),
        ('client_shop_callback_noop', 177, u8(0)),
        ('open_package_one', 200, u8(1) + u8(1)),
        ('charge_order_non_ios', 216, u16(0)),
        ('korea_money_gift_icon', 257, u8(1)),
        ('chongzhi_to_other_panel', 309, u8(1)),
        ('weixin_share_invalid', 310, u8(255)),
        ('mission_award_invalid', 332, u16(0)),
    ])

if BATTLE == 'true':
    smokes.extend([
		('fengshen_trial_info_for_fight', 320, u8(21)),
		('fengshen_trial_fight_dynamic', 320, b''),
        ('arena_list', 161, u8(0) + u8(1)),
        ('arena_fight_dynamic_robot', 161, b''),
        ('guanzhan_missing_role', 133, u32(99999999)),
        ('leave_guanzhan_idle', 134, b''),
    ])

if BATTLE_LIST_ONLY == 'true':
    smokes.append(('arena_list_only', 161, u8(0) + u8(1)))

if UI_QUERIES == 'true':
    smokes.extend([
        ('player_pk_noop', 32, u8(255)),
        ('player_match_noop', 33, u8(255)),
        ('charge_panel', 46, u8(1)),
        ('fengshen_boss_list', 53, u8(1)),
        ('skill_desc_1', 68, u16(1)),
        ('item_def_475', 101, u16(475)),
        ('bangpai_plant_noop', 110, u8(0)),
        ('huodong_today', 152, u8(0)),
        ('npc_guide_info', 153, b''),
        ('guaji_idle', 154, u8(0)),
        ('xiuxian_lilian_info', 160, u8(1)),
        ('googleplay_noop', 176, b''),
        ('npc_auto_transport_noop', 189, u32(0) + u16(0)),
        ('new_player_guide_noop', 191, u8(0)),
        ('player_detail_self', 201, u32(ROLE_ID) + u8(1)),
        ('meet_monster_noop', 204, u8(255)),
        ('chuangguan_enable_count', 213, u8(14)),
        ('tongtianta_noop', 214, u8(1)),
        ('tmp_huodong_gift_status', 222, u8(1) + u8(1)),
        ('husong_noop', 229, u8(1)),
        ('stop_progressbar_noop', 304, u8(0) + u32(0) + u32(0)),
        ('xianyuan_info', 305, u8(1)),
        ('jingjie_info_noop', 306, u8(1)),
        ('fengshen_shilian_info', 320, u8(21)),
    ])

if NPC_FLOW == 'true':
    smokes.extend([
        # EnterScene marks the role as jumping until the client acknowledges it.
        ('npc_scene_ready', 10, b''),
        ('npc_move_to_501', 9, u16(863) + u16(483)),
        ('npc_state_501', 58, u8(1) + u16(501) + u16(501)),
        ('npc_open_501', 12, u16(501) + u16(501) + u16(0)),
        ('npc_dialog_close', 13, u8(0) + u8(0)),
        ('npc_world_to_scene_11', 195, u16(11)),
        ('npc_scene_11_ready', 10, b''),
        ('npc_move_to_1', 9, u16(1650) + u16(1174)),
        ('npc_open_option_1', 12, u16(1) + u16(1) + u16(0)),
        ('npc_select_option_802', 13, u8(2) + u8(1) + u8(0) + u32(802)),
        ('npc_option_close', 13, u8(0) + u8(0)),
    ])

if INVALID_RISKY == 'true':
    smokes.extend([
        ('shop_buy_bad_type', 221, u8(2) + u8(255) + u16(0) + u16(1) + u8(0)),
        ('shop_refresh_bad_type', 221, u8(3) + u8(255)),
        ('shop_count_bad_type', 221, u8(4) + u8(255) + u16(0)),
        ('stage_award_bad', 223, u8(2) + u8(255)),
        ('hero_book_level_bad', 322, u8(2) + u16(0)),
        ('youli_start_empty', 335, u8(2) + u8(0)),
        ('youli_award_empty', 335, u8(3) + u8(0)),
        ('bangpai_create_short_name', 54, u8(1) + s('a') + s('') + u32(0) + u16(0)),
        ('bangpai_apply_zero', 54, u8(3) + u32(0)),
        ('bangpai_apply_missing', 54, u8(3) + u32(99999999)),
        ('pet_draw_bad_op', 224, u8(255)),
        ('fuben_fight_bad', 320, u8(5) + u8(1) + u32(0) + u32(0)),
        ('fuben_sweep_bad', 320, u8(6) + u8(1) + u32(0) + u32(0)),
        ('fuben_reset_bad', 320, u8(7) + u32(0)),
        ('blood_fight_revive_bad', 323, u8(7) + u8(0)),
        ('pet_equip_wear_bad', 319, u8(2) + u8(0) + u32(0)),
        ('pet_equip_takeoff_bad', 319, u8(3) + u8(0) + u32(0)),
        ('pet_equip_strong_bad', 319, u8(4) + u32(0) + u8(0)),
        ('fabao_wear_bad', 319, u8(18) + u32(0) + u8(0) + u8(0)),
        ('fabao_takeoff_bad', 319, u8(19) + u32(0)),
    ])

if STEAM_INCLUDED == 'true':
    # S5 is deliberately narrower than the generic local-server regression.
    # Keep only Steam-retained single-player, arena-robot, and shared foundation
    # operations; excluded social, guild, welfare, activity, KunLun, and
    # BloodFight requests must not be reintroduced through a broad smoke flag.
    steam_included_names = {
        'package', 'sys_time', 'save_vals', 'client_str_all', 'red_point_func',
        'fuben_map_main', 'fuben_achievement', 'hero_book', 'youli_info',
        'tili_info', 'world_level', 'vip_info', 'pet_draw_info',
        'pet_copy_info', 'treasure_map_info',
        'shilian_info', 'stage_goal', 'mission_main', 'mission_daily',
        'available_task_list', 'mail_list', 'title_list', 'formation_info',
        'client_net_check', 'heart_beat', 'new_shenqi_base',
        'new_shenqi_enhance_info', 'new_shenqi_current', 'pet_all',
        'pet_skill_57', 'finished_mission', 'query_scene_map1',
        'fuben_daily_list', 'gonggao_query',
        'role_name_check_smoke',
        'role_name_random_female', 'package_item_empty', 'fuben_fix_empty',
        'fuben_node_empty', 'shop_list', 'scene_escape_pos',
        'query_item_desc_bad', 'pet_equip_list', 'fabao_list',
        'pet_equip_master', 'pet_equip_search_count',
        'available_task_bad_detail', 'title_show_bad',
        'client_str_one_empty', 'role_move_invalid', 'jump_ack_idle',
        'interact_local_add_item_4', 'hecheng_noop', 'save_val_set',
        'save_val_get_one', 'client_str_set', 'client_str_get_one',
        'switch_info', 'title_hide_invalid', 'title_unuse_invalid',
        'package_discard_invalid', 'world_transport_invalid',
        'pet_draw_single_type1', 'pet_draw_single_type2',
        'youli_start_pet57', 'youli_award_1', 'shop_refresh_type4',
        'shop_buy_type4_tid1', 'shop_buy_stamina_pill_5', 'stage_award_1',
        'fengshen_trial_info_for_fight', 'fengshen_trial_fight_dynamic',
        'arena_list', 'arena_fight_dynamic_robot', 'guanzhan_missing_role',
        'leave_guanzhan_idle', 'arena_list_only', 'fengshen_shilian_info',
        'playerhud_levelup'
    }
    smokes = [entry for entry in smokes if entry[0] in steam_included_names]

if BAG_PARITY == 'true':
    # Deterministic S5 Bag sequence. op=50 is local_test-only and drives the
    # normal AddPackage path; use operations then exercise the production /15
    # handler and its authoritative add/update/delete packets.
    smokes = [
        ('bag_initial', 8, b''),
        ('bag_add_direct_3201', 13, u8(50) + u32(3201) + u16(1)),
        ('bag_sort', 15, u8(6)),
        ('bag_use_direct_3201', 15, b''),
        ('bag_after_direct', 8, b''),
        ('bag_add_choice_1111', 13, u8(50) + u32(1111) + u16(2)),
        ('bag_use_choice_1111', 15, b''),
        ('bag_final', 8, b''),
    ]

if TASK_PARITY == 'true':
    # Deterministic S5 Task sequence. The fixture makes daily task 9 and
    # activity box 144 claimable. op=51 is local_test-only
    # and drives the normal quest update path for task 10 (condition 7).
    smokes = [
        ('task_daily_initial', 37, u8(1) + u8(2)),
        ('task_activity_initial', 37, u8(1) + u8(0)),
        ('task_trigger_10', 13, u8(51) + u16(7) + u16(1)),
        ('task_claim_10', 37, u8(3) + u8(2) + u16(10)),
        ('task_claim_10_repeat', 37, u8(3) + u8(2) + u16(10)),
        ('task_claim_144', 37, u8(3) + u8(0) + u16(144)),
        ('task_claim_144_repeat', 37, u8(3) + u8(0) + u16(144)),
        ('task_daily_final', 37, u8(1) + u8(2)),
        ('task_activity_final', 37, u8(1) + u8(0)),
        ('task_redpoint', 65, u8(1) + u16(101)),
    ]

if TASK_RESTART_VERIFY == 'true':
    smokes = [
        ('task_restart_daily', 37, u8(1) + u8(2)),
        ('task_restart_activity', 37, u8(1) + u8(0)),
        ('task_restart_redpoint', 65, u8(1) + u16(101)),
    ]

if PLAYERHUD_PARITY == 'true':
    # The caller prepares the persisted role at level 1 with 59 experience.
    # local_test op=57 adds one experience through CUser::AddExp, producing the
    # production /18 experience update and /226 level-up push.
    smokes = [
        ('playerhud_levelup', 13, u8(57) + u32(1)),
    ]

if HERO_PARITY == 'true':
    # Deterministic S5 Hero sequence. op=55 is local_test-only but uses the
    # production AddPet award path. /48 op4/op5 remain the real formation
    # mutation handlers, and the final swapped state is persisted for restart.
    smokes = [
        ('hero_initial_pet', 24, u8(1)),
        ('hero_initial_formation', 48, u8(1)),
        ('hero_add_pet_64', 13, u8(55) + u16(64)),
        ('hero_after_add_pet', 24, u8(1)),
        ('hero_put_pet64_pos2', 48, u8(4) + u16(64) + u8(2)),
        ('hero_after_put', 48, u8(1)),
        ('hero_invalid_pet', 48, u8(4) + u16(65535) + u8(2)),
        ('hero_swap_1_2', 48, u8(5) + u8(1) + u8(2)),
        ('hero_final_pet', 24, u8(1)),
        ('hero_final_formation', 48, u8(1)),
    ]

if HERO_RESTART_VERIFY == 'true':
    smokes = [
        ('hero_restart_pet', 24, u8(1)),
        ('hero_restart_formation', 48, u8(1)),
    ]

if HERO_EQUIP_PARITY == 'true':
    # Deterministic S5 HeroEquip lifecycle. local_test op53 adds real manager
    # objects; every mutation below uses production /319 handlers and /70
    # attribute refreshes, then leaves both objects unequipped for restart.
    smokes = [
        ('heroequip_initial_equip', 319, u8(1)),
        ('heroequip_initial_fabao', 319, u8(17)),
        ('heroequip_add_equip1001', 13, u8(53) + u8(1) + u16(1001)),
        ('heroequip_after_add_equip', 319, u8(1)),
        ('heroequip_add_fabao1001', 13, u8(53) + u8(2) + u16(1001)),
        ('heroequip_after_add_fabao', 319, u8(17)),
        ('heroequip_wear_equip', 319, b''),
        ('heroequip_after_wear_equip', 319, u8(1)),
        ('heroequip_invalid_equip', 319, u8(2) + u8(1) + u32(0xffffffff)),
        ('heroequip_strong_equip', 319, b''),
        ('heroequip_after_strong_equip', 319, u8(1)),
        ('heroequip_takeoff_equip', 319, b''),
        ('heroequip_after_takeoff_equip', 319, u8(1)),
        ('heroequip_wear_fabao', 319, b''),
        ('heroequip_after_wear_fabao', 319, u8(17)),
        ('heroequip_repeat_fabao', 319, b''),
        ('heroequip_after_repeat_fabao', 319, u8(17)),
        ('heroequip_takeoff_fabao', 319, b''),
        ('heroequip_final_equip', 319, u8(1)),
        ('heroequip_final_fabao', 319, u8(17)),
    ]

if HERO_EQUIP_RESTART_VERIFY == 'true':
    smokes = [
        ('heroequip_restart_equip', 319, u8(1)),
        ('heroequip_restart_fabao', 319, u8(17)),
    ]

if MAIL_PARITY == 'true':
    # Deterministic S5 Mail lifecycle. op54 inserts the local-only 14-row
    # fixture; op2/op3/op4 are production ownership and persistence paths.
    smokes = [
        ('mail_initial_list', 128, u8(2)),
        ('mail_create_fixture', 13, u8(54)),
        ('mail_fixture_list', 128, u8(2)),
        ('mail_claim_reward', 128, b''),
        ('mail_claim_repeat', 128, b''),
        ('mail_after_claim', 128, u8(2)),
        ('mail_read_plain', 128, b''),
        ('mail_read_repeat', 128, b''),
        ('mail_final_list', 128, u8(2)),
    ]

if MAIL_RESTART_VERIFY == 'true':
    smokes = [
        ('mail_restart_list', 128, u8(2)),
    ]

if SHOP_PARITY == 'true':
    # Deterministic S5 basic Shop/type=1 lifecycle. Type 1 is non-random and
    # non-refreshable in the shipped authoritative configuration.
    smokes = [
        ('shop_initial_list', 221, u8(1) + u8(1)),
        ('shop_initial_count_1001', 221, u8(4) + u8(1) + u16(1001)),
        ('shop_buy_1001_one', 221, u8(2) + u8(1) + u16(1001) + u16(1) + u8(0)),
        ('shop_count_after_buy', 221, u8(4) + u8(1) + u16(1001)),
        ('shop_list_after_buy', 221, u8(1) + u8(1)),
        ('shop_buy_insufficient_1015', 221, u8(2) + u8(1) + u16(1015) + u16(200) + u8(0)),
        ('shop_refresh_disabled', 221, u8(3) + u8(1)),
        ('shop_final_list', 221, u8(1) + u8(1)),
    ]

if SHOP_RESTART_VERIFY == 'true':
    smokes = [
        ('shop_restart_list', 221, u8(1) + u8(1)),
        ('shop_restart_count_1001', 221, u8(4) + u8(1) + u16(1001)),
    ]

if GAMEPLAY_SHOPS_PARITY == 'true':
    gameplay_shop_types = (2, 3, 4, 5, 6, 7, 8, 23, 25, 26, 27, 28)
    smokes = [('gameplay_shop_list_type' + str(shop_type), 221, u8(1) + u8(shop_type)) for shop_type in gameplay_shop_types]
    smokes.extend([
        ('gameplay_shop_refresh_type2', 221, u8(3) + u8(2)),
        ('gameplay_shop_buy_type28_28001_x25', 221, u8(2) + u8(28) + u16(28001) + u16(25) + u8(0)),
        ('gameplay_shop_count_type28_28001', 221, u8(4) + u8(28) + u16(28001)),
        ('gameplay_shop_rebuy_soldout_type28', 221, u8(2) + u8(28) + u16(28001) + u16(1) + u8(0)),
        ('gameplay_shop_buy_insufficient_type3', 221, u8(2) + u8(3) + u16(3001) + u16(1) + u8(0)),
        ('gameplay_shop_final_type28', 221, u8(1) + u8(28)),
    ])

if GAMEPLAY_SHOPS_RESTART_VERIFY == 'true':
    smokes = [
        ('gameplay_shop_restart_type2', 221, u8(1) + u8(2)),
        ('gameplay_shop_restart_type28', 221, u8(1) + u8(28)),
        ('gameplay_shop_restart_count_28001', 221, u8(4) + u8(28) + u16(28001)),
    ]

if WORLD_PARITY == 'true':
    # Deterministic S5 World lifecycle on a fresh disposable role. Every state
    # transition uses the production /320 handlers: two real fast fights open
    # the normal/star chests, sweep exhausts stage 10001, and reset consumes
    # the configured 50 premium currency before restart verification.
    smokes = [
        ('world_initial_map', 320, u8(1) + u8(1)),
        ('world_initial_chapter', 320, u8(2) + u8(1) + u32(1001)),
        ('world_initial_node_10001', 320, u8(27) + u8(1) + u32(1001) + u32(10001)),
        ('world_fight_10001', 320, u8(5) + u8(1) + u32(1001) + u32(10001)),
        ('world_after_fight_node_10001', 320, u8(27) + u8(1) + u32(1001) + u32(10001)),
        ('world_claim_normal_10000', 320, u8(4) + u8(1) + u32(1001) + u32(10000)),
        ('world_reclaim_normal_10000', 320, u8(4) + u8(1) + u32(1001) + u32(10000)),
        ('world_fight_10002', 320, u8(5) + u8(1) + u32(1001) + u32(10002)),
        ('world_claim_star_20011', 320, u8(4) + u8(1) + u32(1001) + u32(20011)),
        ('world_sweep_10001', 320, u8(6) + u8(1) + u32(1001) + u32(10001)),
        ('world_after_sweep_node_10001', 320, u8(27) + u8(1) + u32(1001) + u32(10001)),
        ('world_reset_10001', 320, u8(7) + u32(10001)),
        ('world_final_node_10001', 320, u8(27) + u8(1) + u32(1001) + u32(10001)),
        ('world_final_chapter', 320, u8(2) + u8(1) + u32(1001)),
        ('world_final_map', 320, u8(1) + u8(1)),
    ]

if WORLD_RESTART_VERIFY == 'true':
    smokes = [
        ('world_restart_map', 320, u8(1) + u8(1)),
        ('world_restart_chapter', 320, u8(2) + u8(1) + u32(1001)),
        ('world_restart_node_10001', 320, u8(27) + u8(1) + u32(1001) + u32(10001)),
        ('world_restart_node_10002', 320, u8(27) + u8(1) + u32(1001) + u32(10002)),
    ]

if DRAW_PARITY == 'true':
    # Fresh high-pool first draw is production-deterministic hero 64. The
    # local-only op50 injects only the ten tickets required to exercise the
    # production ten-draw deduction/random ownership path.
    smokes = [
        ('draw_initial_info', 224, u8(1)),
        ('draw_high_free_single', 224, u8(2) + u8(2) + u8(1)),
        ('draw_after_single_info', 224, u8(1)),
        ('draw_add_high_tickets', 13, u8(50) + u32(1001) + u16(10)),
        ('draw_high_ten', 224, u8(2) + u8(2) + u8(2)),
        ('draw_after_ten_info', 224, u8(1)),
        ('draw_high_ten_insufficient', 224, u8(2) + u8(2) + u8(2)),
        ('draw_final_pet', 24, u8(1)),
    ]

if DRAW_RESTART_VERIFY == 'true':
    smokes = [
        ('draw_restart_info', 224, u8(1)),
        ('draw_restart_pet', 24, u8(1)),
    ]

if GAMEPLAY_PARITY == 'true':
    # Steam Gameplay retains arena and treasure-search cards. Their /65 query
    # types are owned by the shared hot-point controller; opening the hall does
    # not mutate state or query the excluded BloodFight type 51.
    smokes = [
        ('gameplay_arena_hotpoint', 65, u8(1) + u16(101)),
        ('gameplay_xunbao_hotpoint', 65, u8(1) + u16(103)),
        ('gameplay_arena_hotpoint_repeat', 65, u8(1) + u16(101)),
        ('gameplay_xunbao_hotpoint_repeat', 65, u8(1) + u16(103)),
    ]

if GAMEPLAY_RESTART_VERIFY == 'true':
    smokes = [
        ('gameplay_restart_arena_hotpoint', 65, u8(1) + u16(101)),
        ('gameplay_restart_xunbao_hotpoint', 65, u8(1) + u16(103)),
    ]

if YOULI_PARITY == 'true':
    smokes = [
        ('youli_initial_info', 335, u8(1)),
        ('youli_repeat_info', 335, u8(1)),
    ]

if YOULI_RESTART_VERIFY == 'true':
    smokes = [
        ('youli_restart_info', 335, u8(1)),
    ]

if FENGSHEN_STORY_PARITY == 'true':
    smokes = [
        ('fengshen_story_raise_pets', 13, u8(58) + u16(100)),
        ('fengshen_story_initial_info', 320, u8(24)),
        ('fengshen_story_challenge', 320, u8(25)),
        ('fengshen_story_final_info', 320, u8(24)),
    ]

if FENGSHEN_STORY_RESTART_VERIFY == 'true':
    smokes = [
        ('fengshen_story_restart_info', 320, u8(24)),
    ]

if ARENA_PARITY == 'true':
    smokes = [
        ('arena_add_pet63', 13, u8(55) + u16(63)),
        ('arena_form_pet63_pos2', 48, u8(4) + u16(63) + u8(2)),
        ('arena_add_pet40', 13, u8(55) + u16(40)),
        ('arena_form_pet40_pos3', 48, u8(4) + u16(40) + u8(3)),
        ('arena_add_pet41', 13, u8(55) + u16(41)),
        ('arena_form_pet41_pos4', 48, u8(4) + u16(41) + u8(4)),
        ('arena_add_pet49', 13, u8(55) + u16(49)),
        ('arena_form_pet49_pos5', 48, u8(4) + u16(49) + u8(5)),
        ('arena_raise_pets', 13, u8(58) + u16(100)),
        ('arena_initial_list', 161, u8(0) + u8(1)),
        ('arena_initial_remaining', 161, u8(13)),
        ('arena_fight_dynamic_robot', 161, b''),
        ('arena_final_list', 161, u8(0) + u8(1)),
        ('arena_final_remaining', 161, u8(13)),
        ('arena_flush_rank_snapshot', 13, u8(59)),
    ]

if ARENA_RESTART_VERIFY == 'true':
    smokes = [
        ('arena_restart_list', 161, u8(0) + u8(1)),
        ('arena_restart_remaining', 161, u8(13)),
    ]

if XUNBAO_PARITY == 'true':
    smokes = [
        ('xunbao_initial_info', 319, u8(31)),
        ('xunbao_repeat_info', 319, u8(31)),
    ]

if XUNBAO_RESTART_VERIFY == 'true':
    smokes = [
        ('xunbao_restart_info', 319, u8(31)),
    ]

with socket.create_connection((HOST, PORT), timeout=3) as sock:
    th = threading.Thread(target=reader, args=(sock,), daemon=True)
    th.start()
    login_body = (
        u32(USER_ID) + s('local') + s(VERSION) + u32(SERVER_ID) +
        s('local_test') + s('') + s('') + s('')
    )
    sock.sendall(pkt(1001, login_body))
    time.sleep(1.0)
    if ROLE_NAME_ONLY == 'true':
        event_start = len(recv_events)
        sock.sendall(pkt(1002, u8(2) + u8(1)))
        deadline = time.time() + 3.0
        response = None
        while time.time() < deadline and response is None:
            for msg_type, body in recv_events[event_start:]:
                if msg_type == 1002 and len(body) >= 5 and body[0] == 2 and body[1] == 1 and body[2] > 0:
                    response = body
                    break
            time.sleep(0.05)
        if response is None:
            raise RuntimeError('role-name-only probe returned no /1002 op=2 female candidate')
        print('role_name_only_response=' + response.hex())
        smokes = []
    role_to_select = ROLE_ID
    if AUTO_CREATE_ROLE == 'true':
        create_body = s(ROLE_NAME) + u8(0) + u8(5) + u8(5) + u16(1)
        sock.sendall(pkt(1003, create_body))
        deadline = time.time() + 3.0
        while time.time() < deadline and created_role_id['id'] is None:
            if create_response['body'] is not None and EXPECT_CREATE_FAILURE == 'true':
                break
            time.sleep(0.05)
        if EXPECT_CREATE_FAILURE == 'true':
            body = create_response['body']
            if body is None:
                raise RuntimeError('expected create-role failure timed out with no /1003 response')
            if len(body) < 1 or body[0] != 0:
                raise RuntimeError('expected create-role failure but received: ' + body.hex())
            print('create_role_expected_failure=' + body.hex())
            stop_flag['stop'] = True
            th.join(timeout=1.0)
            sys.exit(0)
        if created_role_id['id'] is None:
            body = create_response['body']
            raise RuntimeError('auto create role failed or timed out; response=' + (body.hex() if body is not None else 'none'))
        role_to_select = created_role_id['id']
        print('created_role_id=' + str(role_to_select))
    sock.sendall(pkt(1004, u32(role_to_select)))
    if EXTENDED == 'true':
        smokes.append(('item_info_self_slot0', 16, u8(1) + u8(0)))
        smokes.append(('other_item_self_slot0', 19, u8(1) + u32(role_to_select) + u8(0)))
        smokes.append(('query_pet_self_57', 51, u32(role_to_select) + u16(57)))
        smokes.append(('other_pet_self_57', 69, u32(role_to_select) + u16(57)))
        smokes.append(('player_info_self', 34, u32(role_to_select)))
        smokes.append(('role_query_self', 248, u8(1) + s(str(role_to_select))))
    time.sleep(6.0 if AUTO_CREATE_ROLE == 'true' else 2.0)
    if FRIEND_APPLY_ROLE_ID > 0:
        event_start = len(recv_events)
        sock.sendall(pkt(27, u8(3) + u32(FRIEND_APPLY_ROLE_ID)))
        deadline = time.time() + 3.0
        response = None
        while time.time() < deadline and response is None:
            for msg_type, body in recv_events[event_start:]:
                if msg_type == 27 and len(body) >= 6 and body[0] == 3 and struct.unpack('<I', body[1:5])[0] == FRIEND_APPLY_ROLE_ID:
                    response = body
                    break
            time.sleep(0.05)
        if response is None:
            raise RuntimeError('friend apply returned no matching /27 op=3 response')
        print('friend_apply_response=' + response.hex())
        if response[5] != 1:
            raise RuntimeError('friend apply failed: ' + response.hex())
    if TEAM_PEER_ACCEPT_LEADER_ROLE_ID > 0:
        print('team_peer_waiting=' + str(TEAM_PEER_ACCEPT_LEADER_ROLE_ID), flush=True)
        event_start = len(recv_events)
        deadline = time.time() + max(10, TEAM_PEER_WAIT_SECONDS)
        invitation = None
        while time.time() < deadline and invitation is None:
            for msg_type, body in recv_events[event_start:]:
                if msg_type == 29:
                    print('team_peer_event_29=' + body.hex(), flush=True)
                if msg_type == 29 and len(body) >= 5 and body[0] == 6 and struct.unpack('<I', body[1:5])[0] == TEAM_PEER_ACCEPT_LEADER_ROLE_ID:
                    invitation = body
                    break
            event_start = len(recv_events)
            time.sleep(0.05)
        if invitation is None:
            raise RuntimeError('team peer received no /29 op=6 invitation from leader')
        sock.sendall(pkt(29, u8(6) + u8(1) + u32(TEAM_PEER_ACCEPT_LEADER_ROLE_ID)))
        print('team_peer_accepted=' + str(TEAM_PEER_ACCEPT_LEADER_ROLE_ID), flush=True)
        joined = False
        joined_deadline = time.time() + 10.0
        while time.time() < joined_deadline and not joined:
            for msg_type, body in recv_events[event_start:]:
                if msg_type == 29 and len(body) >= 4 and body[0] == 16 and body[1] == 1 and body[2] != 255:
                    joined = True
                    break
            time.sleep(0.05)
        if not joined:
            raise RuntimeError('team peer accepted invitation but received no /29 op=16 team state')
        print('team_peer_joined=1', flush=True)
        while time.time() < deadline and not stop_flag['stop']:
            time.sleep(0.1)
        smokes = []
    for name, t, body in smokes:
        if CONSUMPTION == 'true' and name == 'use_special_item_missing_rename_card':
            time.sleep(1.0)
        event_start = len(recv_events)
        if (BATTLE == 'true' or ARENA_PARITY == 'true') and name == 'arena_fight_dynamic_robot':
            deadline = time.time() + 2.0
            while battle_target['value'] is None and time.time() < deadline:
                time.sleep(0.05)
            if battle_target['value'] is None:
                raise RuntimeError('arena list returned no challengeable robot')
            target_rank, target_role_id, target_type = battle_target['value']
            body = u8(5) + u32(target_rank) + u32(target_role_id) + u8(target_type)
            print(f'arena_target rank={target_rank} role={target_role_id} type={target_type}')
        if BATTLE == 'true' and name == 'fengshen_trial_fight_dynamic':
            deadline = time.time() + 2.0
            while fengshen_trial['value'] is None and time.time() < deadline:
                time.sleep(0.05)
            if fengshen_trial['value'] is None:
                raise RuntimeError('fengshen trial list returned no open trial')
            body = u8(22) + u32(fengshen_trial['value'])
            print('fengshen_trial_id=' + str(fengshen_trial['value']))
        if BAG_PARITY == 'true' and name in ('bag_use_direct_3201', 'bag_use_choice_1111'):
            item_id = 3201 if name == 'bag_use_direct_3201' else 1111
            deadline = time.time() + 3.0
            while item_id not in bag_item_slots and time.time() < deadline:
                time.sleep(0.05)
            if item_id not in bag_item_slots:
                raise RuntimeError('Bag parity did not observe an authoritative /15 slot for item ' + str(item_id))
            target = 0 if item_id == 3201 else 1
            body = u8(1) + u16(bag_item_slots[item_id]) + u8(1) + u8(target) + u8(0) + u8(0)
            print(f'bag_use item={item_id} slot={bag_item_slots[item_id]} target={target}')
        if HERO_EQUIP_PARITY == 'true' and name in (
            'heroequip_wear_equip', 'heroequip_strong_equip', 'heroequip_takeoff_equip',
            'heroequip_wear_fabao', 'heroequip_repeat_fabao', 'heroequip_takeoff_fabao'):
            uid_key = 'equip' if 'equip' in name else 'fabao'
            deadline = time.time() + 3.0
            while hero_equip_uids[uid_key] is None and time.time() < deadline:
                time.sleep(0.05)
            uid = hero_equip_uids[uid_key]
            if uid is None:
                raise RuntimeError('HeroEquip parity did not receive the authoritative ' + uid_key + ' UID')
            if name == 'heroequip_wear_equip':
                body = u8(2) + u8(1) + u32(uid)
            elif name == 'heroequip_strong_equip':
                body = u8(4) + u32(uid) + u8(0)
            elif name == 'heroequip_takeoff_equip':
                body = u8(3) + u8(1) + u32(uid)
            elif name in ('heroequip_wear_fabao', 'heroequip_repeat_fabao'):
                body = u8(18) + u32(uid) + u8(1) + u8(5)
            else:
                body = u8(19) + u32(uid)
            print(f'heroequip_mutation case={name} uid={uid}')
        if MAIL_PARITY == 'true' and name in ('mail_claim_reward', 'mail_claim_repeat', 'mail_read_plain', 'mail_read_repeat'):
            deadline = time.time() + 3.0
            while (mail_fixture_ids['reward'] is None or mail_fixture_ids['plain'] is None) and time.time() < deadline:
                list_body = next((candidate for candidate in reversed(recv_bodies.get(128, [])) if len(candidate) >= 2 and candidate[0] == 2 and candidate[1] == 14), None)
                if list_body is not None:
                    records = parse_mail_list_body(list_body)
                    reward_mail = next((record for record in records if len(record['rewards']) == 9), None)
                    plain_mail = next((record for record in records if len(record['rewards']) == 0), None)
                    if reward_mail is not None: mail_fixture_ids['reward'] = reward_mail['id']
                    if plain_mail is not None: mail_fixture_ids['plain'] = plain_mail['id']
                time.sleep(0.05)
            if mail_fixture_ids['reward'] is None or mail_fixture_ids['plain'] is None:
                raise RuntimeError('Mail parity could not resolve deterministic reward/plain fixture IDs')
            if name in ('mail_claim_reward', 'mail_claim_repeat'):
                body = u8(3) + u32(mail_fixture_ids['reward']) + u8(0)
            else:
                body = u8(4) + u32(mail_fixture_ids['plain']) + u8(0)
            print(f'mail_mutation case={name} rewardId={mail_fixture_ids["reward"]} plainId={mail_fixture_ids["plain"]}')
        sock.sendall(pkt(t, body))
        sent_case_names.append(name)
        print(f'sent {name} type={t} body={len(body)}')
        if BATTLE == 'true' and t == 161:
            time.sleep(1.0)
        elif BAG_PARITY == 'true' or TASK_PARITY == 'true' or TASK_RESTART_VERIFY == 'true' or PLAYERHUD_PARITY == 'true' or HERO_PARITY == 'true' or HERO_RESTART_VERIFY == 'true' or HERO_EQUIP_PARITY == 'true' or HERO_EQUIP_RESTART_VERIFY == 'true' or MAIL_PARITY == 'true' or MAIL_RESTART_VERIFY == 'true' or SHOP_PARITY == 'true' or SHOP_RESTART_VERIFY == 'true' or GAMEPLAY_SHOPS_PARITY == 'true' or GAMEPLAY_SHOPS_RESTART_VERIFY == 'true' or WORLD_PARITY == 'true' or WORLD_RESTART_VERIFY == 'true' or DRAW_PARITY == 'true' or DRAW_RESTART_VERIFY == 'true' or GAMEPLAY_PARITY == 'true' or GAMEPLAY_RESTART_VERIFY == 'true' or YOULI_PARITY == 'true' or YOULI_RESTART_VERIFY == 'true' or FENGSHEN_STORY_PARITY == 'true' or FENGSHEN_STORY_RESTART_VERIFY == 'true' or ARENA_PARITY == 'true' or ARENA_RESTART_VERIFY == 'true' or XUNBAO_PARITY == 'true' or XUNBAO_RESTART_VERIFY == 'true':
            time.sleep(0.5)
        else:
            time.sleep(0.5 if CONSUMPTION == 'true' and t in (47, 84, 177, 200, 216, 257, 309, 310, 332) else 0.2)
        if BAG_PARITY == 'true' or TASK_PARITY == 'true' or TASK_RESTART_VERIFY == 'true' or PLAYERHUD_PARITY == 'true' or HERO_PARITY == 'true' or HERO_RESTART_VERIFY == 'true' or HERO_EQUIP_PARITY == 'true' or HERO_EQUIP_RESTART_VERIFY == 'true' or MAIL_PARITY == 'true' or MAIL_RESTART_VERIFY == 'true' or SHOP_PARITY == 'true' or SHOP_RESTART_VERIFY == 'true' or GAMEPLAY_SHOPS_PARITY == 'true' or GAMEPLAY_SHOPS_RESTART_VERIFY == 'true' or WORLD_PARITY == 'true' or WORLD_RESTART_VERIFY == 'true' or DRAW_PARITY == 'true' or DRAW_RESTART_VERIFY == 'true' or GAMEPLAY_PARITY == 'true' or GAMEPLAY_RESTART_VERIFY == 'true' or YOULI_PARITY == 'true' or YOULI_RESTART_VERIFY == 'true' or FENGSHEN_STORY_PARITY == 'true' or FENGSHEN_STORY_RESTART_VERIFY == 'true' or ARENA_PARITY == 'true' or ARENA_RESTART_VERIFY == 'true' or XUNBAO_PARITY == 'true' or XUNBAO_RESTART_VERIFY == 'true':
            events = recv_events[event_start:]
            case_responses.append({
                'case': name,
                'responses': [
                    {'type': msg_type, 'bodyHex': response_body.hex()}
                    for msg_type, response_body in events
                ]
            })
        if CONSUMPTION == 'true' and name.startswith('use_special_item_'):
            events = recv_events[event_start:]
            print('case_' + name + '=' + ','.join(str(mt) + ':' + mb.hex() for mt, mb in events))
    time.sleep(4)
    stop_flag['stop'] = True
    th.join(timeout=1.0)

print('recv_count=' + str(len(recv_types)))
print('recv_types=' + ','.join(map(str, recv_types[:200])))
for response_type in (321,):
    bodies = recv_bodies.get(response_type, [])
    print('response_' + str(response_type) + '=' + ','.join(body.hex() for body in bodies))
if EXTENDED == 'true' or ROLE_NAME_ONLY == 'true':
    role_name_bodies = recv_bodies.get(1002, [])
    print('response_1002=' + ','.join(body.hex() for body in role_name_bodies))
    random_name_bodies = [body for body in role_name_bodies if len(body) >= 5 and body[0] == 2 and body[1] == 1 and body[2] > 0]
    if not random_name_bodies:
        raise RuntimeError('role-name random request returned no /1002 op=2 female candidate')
if CONSUMPTION == 'true':
    for response_type in (47, 84, 177, 200, 216, 257, 309, 310, 332):
        bodies = recv_bodies.get(response_type, [])
        print('response_' + str(response_type) + '=' + ','.join(body.hex() for body in bodies))
if TEAM_PROBE == 'true':
    bodies = recv_bodies.get(29, [])
    print('response_29=' + ','.join(body.hex() for body in bodies))
if BATTLE == 'true':
    for response_type in (133, 134, 161):
        bodies = recv_bodies.get(response_type, [])
        print('response_' + str(response_type) + '=' + ','.join(body.hex() for body in bodies))
    jump_bodies = recv_bodies.get(38, [])
    if not jump_bodies:
        raise RuntimeError('fengshen trial fight returned no replay packet')
    replay = jump_bodies[0]
    if len(replay) < 3 or replay[0] not in (3, 4, 5):
        raise RuntimeError('invalid replay packet header')
    replay_count = struct.unpack('<H', replay[1:3])[0]
    pos = 3
    parsed_count = 0
    while parsed_count < replay_count and pos + 6 <= len(replay):
        body_len = struct.unpack('<I', replay[pos:pos + 4])[0]
        packet_len = body_len + 6
        if packet_len < 6 or pos + packet_len > len(replay):
            raise RuntimeError('invalid embedded replay packet length')
        pos += packet_len
        parsed_count += 1
    if parsed_count != replay_count or pos != len(replay):
        raise RuntimeError('embedded replay packet framing mismatch')
    print('fengshen_replay_packets=' + str(replay_count))
if POSITIVE == 'true':
	all_response_data = b''.join(body for bodies in recv_bodies.values() for body in bodies)
	if '(nil)'.encode('utf-16le') in all_response_data:
		raise RuntimeError('positive smoke received a nil item-name tip')
	if AUTO_CREATE_ROLE == 'true' and '体力丹'.encode('utf-16le') not in all_response_data:
		raise RuntimeError('stamina pill purchase did not return the expected item-name tip')
	print('stamina_pill_tip=' + ('ok' if AUTO_CREATE_ROLE == 'true' else 'existing-role-authoritative-result'))
if UI_QUERIES == 'true':
    for response_type in (32, 33, 46, 53, 68, 101, 110, 152, 153, 154, 160, 176, 189, 191, 201, 204, 213, 214, 222, 229, 304, 305, 306):
        bodies = recv_bodies.get(response_type, [])
        print('response_' + str(response_type) + '=' + ','.join(body.hex() for body in bodies))
    # Several entries intentionally use no-op branches and therefore have no response.
    if STEAM_INCLUDED == 'true':
        required_ui_response_types = set()
    else:
        required_ui_response_types = {46, 53, 68, 101, 152, 153, 154, 160, 201, 213, 222, 305}
    missing_ui_response_types = sorted(required_ui_response_types.difference(recv_types))
    if missing_ui_response_types:
        raise RuntimeError('missing required UI query responses: ' + ','.join(map(str, missing_ui_response_types)))
    trial_bodies = [body for body in recv_bodies.get(320, []) if len(body) >= 2 and body[0] == 21]
    if not trial_bodies or trial_bodies[-1][1] < 4:
        raise RuntimeError('fengshen trial response did not contain four tabs')
    print('fengshen_trial_count=' + str(trial_bodies[-1][1]))
if EXTENDED == 'true':
    if STEAM_INCLUDED == 'true':
        required_response_types = {40, 49, 51, 69, 100, 190}
    else:
        required_response_types = {40, 49, 51, 69, 100, 117, 178, 190, 199}
    if AUTO_CREATE_ROLE == 'true':
        required_response_types.add(15)
    missing_response_types = sorted(required_response_types.difference(recv_types))
    if missing_response_types:
        raise RuntimeError('missing required smoke responses: ' + ','.join(map(str, missing_response_types)))
if NPC_FLOW == 'true':
    required_npc_response_types = {12, 13, 14, 58}
    missing_npc_response_types = sorted(required_npc_response_types.difference(recv_types))
    if missing_npc_response_types:
        raise RuntimeError('missing required NPC flow responses: ' + ','.join(map(str, missing_npc_response_types)))
bag_semantic_cases = []
if BAG_PARITY == 'true':
    def bag_updates_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None:
            raise RuntimeError('Bag parity response bucket is missing: ' + case_name)
        updates = []
        response_types = []
        for response in case['responses']:
            msg_type = response['type']
            body = bytes.fromhex(response['bodyHex'])
            response_types.append(msg_type)
            if msg_type != 15 or not body:
                continue
            update = {'op': body[0]}
            if body[0] in (1, 2) and len(body) >= 7:
                update.update({
                    'slot': struct.unpack('<H', body[1:3])[0],
                    'itemId': struct.unpack('<H', body[3:5])[0],
                    'num': struct.unpack('<H', body[5:7])[0]
                })
            elif body[0] == 6 and len(body) >= 4:
                update.update({
                    'success': body[1],
                    'packageCount': struct.unpack('<H', body[2:4])[0]
                })
            updates.append(update)
        bag_semantic_cases.append({'case': case_name, 'responseTypes': response_types, 'packageUpdates': updates})
        return response_types, updates

    initial_types, _ = bag_updates_for('bag_initial')
    _, direct_add = bag_updates_for('bag_add_direct_3201')
    _, sorted_updates = bag_updates_for('bag_sort')
    _, direct_use = bag_updates_for('bag_use_direct_3201')
    after_direct_types, _ = bag_updates_for('bag_after_direct')
    _, choice_add = bag_updates_for('bag_add_choice_1111')
    _, choice_use = bag_updates_for('bag_use_choice_1111')
    final_types, _ = bag_updates_for('bag_final')
    if 8 not in initial_types or 8 not in after_direct_types or 8 not in final_types:
        raise RuntimeError('Bag parity did not receive all three authoritative /8 snapshots')
    if not any(update.get('itemId') == 3201 and update.get('num', 0) >= 1 for update in direct_add):
        raise RuntimeError('Bag parity did not observe deterministic item 3201 injection')
    if not any(update.get('op') == 6 and update.get('success') == 1 for update in sorted_updates):
        raise RuntimeError('Bag parity sort did not return /15 op=6 success')
    if not any(update.get('op') == 2 and update.get('itemId') == 0 and update.get('num') == 0 for update in direct_use):
        raise RuntimeError('Bag parity direct use did not emit authoritative deletion')
    if not any(update.get('itemId') == 1111 and update.get('num', 0) >= 2 for update in choice_add):
        raise RuntimeError('Bag parity did not observe deterministic choice item injection')
    if not any(update.get('itemId') == 1111 and update.get('num') == 1 for update in choice_use):
        raise RuntimeError('Bag parity choice use did not decrement item 1111')
    if not any(update.get('itemId') == 4621 and update.get('num', 0) >= 1 for update in choice_use):
        raise RuntimeError('Bag parity choice use did not add deterministic reward item 4621')
    print('bag_parity_semantics=passed')
task_semantic_cases = []
if TASK_PARITY == 'true':
    def task_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None:
            raise RuntimeError('Task parity response bucket is missing: ' + case_name)
        parsed = []
        for response in case['responses']:
            msg_type = response['type']
            body = bytes.fromhex(response['bodyHex'])
            if msg_type == 37 and body:
                value = {'protocol': 37, 'op': body[0]}
                if body[0] == 1 and len(body) >= 4:
                    value['taskType'] = body[1]
                    count = struct.unpack('<H', body[2:4])[0]
                    value['count'] = count
                    entries = []
                    pos = 4
                    for _ in range(count):
                        if pos + 7 > len(body):
                            raise RuntimeError('Task parity list response is truncated: ' + case_name)
                        entries.append({
                            'id': struct.unpack('<H', body[pos:pos + 2])[0],
                            'num': struct.unpack('<I', body[pos + 2:pos + 6])[0],
                            'state': body[pos + 6]
                        })
                        pos += 7
                    value['entries'] = entries
                elif body[0] == 2 and len(body) >= 8:
                    value.update({
                        'id': struct.unpack('<H', body[1:3])[0],
                        'num': struct.unpack('<I', body[3:7])[0],
                        'state': body[7]
                    })
                elif body[0] == 3 and len(body) >= 5:
                    value.update({
                        'taskType': body[1],
                        'id': struct.unpack('<H', body[2:4])[0],
                        'success': body[4]
                    })
                parsed.append(value)
            elif msg_type == 65:
                parsed.append({'protocol': 65, 'bodyHex': body.hex()})
        task_semantic_cases.append({'case': case_name, 'taskResponses': parsed})
        return parsed

    daily_initial = task_responses_for('task_daily_initial')
    activity_initial = task_responses_for('task_activity_initial')
    trigger = task_responses_for('task_trigger_10')
    claim_10 = task_responses_for('task_claim_10')
    claim_10_repeat = task_responses_for('task_claim_10_repeat')
    claim_144 = task_responses_for('task_claim_144')
    claim_144_repeat = task_responses_for('task_claim_144_repeat')
    daily_final = task_responses_for('task_daily_final')
    activity_final = task_responses_for('task_activity_final')
    redpoint = task_responses_for('task_redpoint')

    def find_list_entry(responses, task_id):
        for response in responses:
            for entry in response.get('entries', []):
                if entry['id'] == task_id:
                    return entry
        return None

    if find_list_entry(daily_initial, 9) is None or find_list_entry(daily_initial, 9)['state'] != 1:
        raise RuntimeError('Task parity initial daily task 9 is not claimable')
    if find_list_entry(activity_initial, 144) is None or find_list_entry(activity_initial, 144)['state'] != 1:
        raise RuntimeError('Task parity initial activity box 144 is not claimable')
    if not any(response.get('op') == 2 and response.get('id') == 10 and response.get('num') == 1 and response.get('state') == 1 for response in trigger):
        raise RuntimeError('Task parity did not receive /37 op=2 for task 10')
    if not any(response.get('op') == 3 and response.get('id') == 10 and response.get('success') == 1 for response in claim_10):
        raise RuntimeError('Task parity task 10 claim did not succeed')
    if not any(response.get('op') == 3 and response.get('id') == 10 and response.get('success') == 0 for response in claim_10_repeat):
        raise RuntimeError('Task parity repeated task 10 claim was not rejected')
    if not any(response.get('op') == 3 and response.get('id') == 144 and response.get('success') == 1 for response in claim_144):
        raise RuntimeError('Task parity activity box 144 claim did not succeed')
    if not any(response.get('op') == 3 and response.get('id') == 144 and response.get('success') == 0 for response in claim_144_repeat):
        raise RuntimeError('Task parity repeated activity box 144 claim was not rejected')
    if find_list_entry(daily_final, 10) is None or find_list_entry(daily_final, 10)['state'] != 2:
        raise RuntimeError('Task parity final daily task 10 is not persisted as claimed in memory')
    if find_list_entry(activity_final, 144) is None or find_list_entry(activity_final, 144)['state'] != 2:
        raise RuntimeError('Task parity final activity box 144 is not persisted as claimed in memory')
    if not any(response.get('protocol') == 65 for response in redpoint):
        raise RuntimeError('Task parity red-point query returned no /65 response')
    print('task_parity_semantics=passed')
if TASK_RESTART_VERIFY == 'true':
    def task_restart_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None:
            raise RuntimeError('Task restart response bucket is missing: ' + case_name)
        parsed = []
        for response in case['responses']:
            msg_type = response['type']
            body = bytes.fromhex(response['bodyHex'])
            if msg_type == 37 and len(body) >= 4 and body[0] == 1:
                count = struct.unpack('<H', body[2:4])[0]
                entries = []
                pos = 4
                for _ in range(count):
                    if pos + 7 > len(body):
                        raise RuntimeError('Task restart list response is truncated: ' + case_name)
                    entries.append({
                        'id': struct.unpack('<H', body[pos:pos + 2])[0],
                        'num': struct.unpack('<I', body[pos + 2:pos + 6])[0],
                        'state': body[pos + 6]
                    })
                    pos += 7
                parsed.append({'protocol': 37, 'op': 1, 'taskType': body[1], 'count': count, 'entries': entries})
            elif msg_type == 65:
                parsed.append({'protocol': 65, 'bodyHex': body.hex()})
        task_semantic_cases.append({'case': case_name, 'taskResponses': parsed})
        return parsed

    restart_daily = task_restart_responses_for('task_restart_daily')
    restart_activity = task_restart_responses_for('task_restart_activity')
    restart_redpoint = task_restart_responses_for('task_restart_redpoint')
    restart_task_10 = next((entry for response in restart_daily for entry in response.get('entries', []) if entry['id'] == 10), None)
    restart_task_144 = next((entry for response in restart_activity for entry in response.get('entries', []) if entry['id'] == 144), None)
    if restart_task_10 is None or restart_task_10['state'] != 2:
        raise RuntimeError('Task restart verification did not persist task 10 as claimed')
    if restart_task_144 is None or restart_task_144['state'] != 2:
        raise RuntimeError('Task restart verification did not persist activity box 144 as claimed')
    if not any(response.get('protocol') == 65 for response in restart_redpoint):
        raise RuntimeError('Task restart verification returned no /65 response')
    print('task_restart_semantics=passed')
playerhud_semantic_cases = []
if PLAYERHUD_PARITY == 'true':
    levelup_case = next((entry for entry in case_responses if entry['case'] == 'playerhud_levelup'), None)
    if levelup_case is None:
        raise RuntimeError('PlayerHud parity response bucket is missing')
    parsed_levelups = []
    response_types = []
    for response in levelup_case['responses']:
        msg_type = response['type']
        body = bytes.fromhex(response['bodyHex'])
        response_types.append(msg_type)
        if msg_type != 226:
            continue
        if len(body) < 36:
            raise RuntimeError('PlayerHud /226 response is truncated')
        pet_count = body[35]
        if len(body) != 36 + pet_count * 3:
            raise RuntimeError('PlayerHud /226 pet list framing is invalid')
        parsed_levelups.append({
            'protocol': 226,
            'oldLevel': body[0],
            'oldCombat': struct.unpack('<Q', body[1:9])[0],
            'oldPetCombat': struct.unpack('<Q', body[9:17])[0],
            'newLevel': struct.unpack('<H', body[17:19])[0],
            'newCombat': struct.unpack('<Q', body[19:27])[0],
            'newPetCombat': struct.unpack('<Q', body[27:35])[0],
            'petCount': pet_count,
            'pets': [
                {
                    'id': struct.unpack('<H', body[36 + index * 3:38 + index * 3])[0],
                    'quality': body[38 + index * 3]
                }
                for index in range(pet_count)
            ]
        })
    playerhud_semantic_cases.append({
        'case': 'playerhud_levelup',
        'responseTypes': response_types,
        'levelUps': parsed_levelups
    })
    if 18 not in response_types:
        raise RuntimeError('PlayerHud level-up did not emit authoritative /18 experience update')
    if len(parsed_levelups) != 1:
        raise RuntimeError('PlayerHud level-up did not emit exactly one /226 packet')
    if parsed_levelups[0]['oldLevel'] != 1 or parsed_levelups[0]['newLevel'] != 2:
        raise RuntimeError('PlayerHud /226 did not describe the prepared level 1 to level 2 transition')
    print('playerhud_parity_semantics=passed')
hero_semantic_cases = []
if HERO_PARITY == 'true' or HERO_RESTART_VERIFY == 'true':
    def hero_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None:
            raise RuntimeError('Hero parity response bucket is missing: ' + case_name)
        parsed = []
        response_types = []
        for response in case['responses']:
            msg_type = response['type']
            body = bytes.fromhex(response['bodyHex'])
            if msg_type in (24, 48):
                response_types.append(msg_type)
            if msg_type == 24:
                parsed.append({'protocol': 24, 'bodyLength': len(body), 'bodySha256': hashlib.sha256(body).hexdigest().upper()})
            elif msg_type == 48 and body:
                value = {'protocol': 48, 'op': body[0]}
                if body[0] == 1:
                    if len(body) < 5:
                        raise RuntimeError('Hero formation snapshot is truncated: ' + case_name)
                    pos = 1
                    value['formationId'] = struct.unpack('<H', body[pos:pos + 2])[0]
                    pos += 2
                    formation_count = body[pos]
                    pos += 1
                    formations = []
                    for _ in range(formation_count):
                        if pos + 3 > len(body):
                            raise RuntimeError('Hero formation list is truncated: ' + case_name)
                        formations.append({'id': struct.unpack('<H', body[pos:pos + 2])[0], 'level': body[pos + 2]})
                        pos += 3
                    if pos >= len(body):
                        raise RuntimeError('Hero combat position list is missing: ' + case_name)
                    combat_count = body[pos]
                    pos += 1
                    combat = []
                    for _ in range(combat_count):
                        if pos + 2 > len(body):
                            raise RuntimeError('Hero combat position list is truncated: ' + case_name)
                        combat.append(struct.unpack('<H', body[pos:pos + 2])[0])
                        pos += 2
                    if pos >= len(body):
                        raise RuntimeError('Hero formation member count is missing: ' + case_name)
                    member_count = body[pos]
                    pos += 1
                    members = []
                    for _ in range(member_count):
                        if pos + 2 > len(body):
                            raise RuntimeError('Hero formation members are truncated: ' + case_name)
                        members.append(struct.unpack('<H', body[pos:pos + 2])[0])
                        pos += 2
                    if pos != len(body):
                        raise RuntimeError('Hero formation snapshot has unread bytes: ' + case_name)
                    value.update({'formations': formations, 'combat': combat, 'members': members})
                elif body[0] == 4 and len(body) >= 5:
                    value.update({'petId': struct.unpack('<H', body[1:3])[0], 'position': body[3], 'success': body[4]})
                elif body[0] == 5 and len(body) >= 4:
                    value.update({'source': body[1], 'target': body[2], 'success': body[3]})
                parsed.append(value)
        hero_semantic_cases.append({'case': case_name, 'responseTypes': response_types, 'heroResponses': parsed})
        return parsed

    def formation_snapshot(responses):
        return next((entry for entry in responses if entry.get('protocol') == 48 and entry.get('op') == 1), None)

    if HERO_PARITY == 'true':
        initial_pet = hero_responses_for('hero_initial_pet')
        initial_formation = formation_snapshot(hero_responses_for('hero_initial_formation'))
        hero_responses_for('hero_add_pet_64')
        after_add_pet = hero_responses_for('hero_after_add_pet')
        put_result = hero_responses_for('hero_put_pet64_pos2')
        after_put = formation_snapshot(hero_responses_for('hero_after_put'))
        invalid_result = hero_responses_for('hero_invalid_pet')
        swap_result = hero_responses_for('hero_swap_1_2')
        final_pet = hero_responses_for('hero_final_pet')
        final_formation = formation_snapshot(hero_responses_for('hero_final_formation'))
        if not any(entry.get('protocol') == 24 for entry in initial_pet + after_add_pet + final_pet):
            raise RuntimeError('Hero parity did not receive authoritative /24 snapshots')
        if initial_formation is None or len(initial_formation['combat']) < 2 or initial_formation['combat'][0] != 57 or initial_formation['combat'][1] != 0:
            raise RuntimeError('Hero parity initial formation is not pet57 plus empty position2')
        if not any(entry.get('op') == 4 and entry.get('petId') == 64 and entry.get('position') == 2 and entry.get('success') == 1 for entry in put_result):
            raise RuntimeError('Hero parity pet64 position2 mutation did not succeed')
        if after_put is None or after_put['combat'][0:2] != [57, 64]:
            raise RuntimeError('Hero parity authoritative formation did not show pet64 in position2')
        if not any(entry.get('op') == 4 and entry.get('petId') == 65535 and entry.get('success') == 0 for entry in invalid_result):
            raise RuntimeError('Hero parity invalid pet mutation was not rejected')
        if not any(entry.get('op') == 5 and entry.get('source') == 1 and entry.get('target') == 2 and entry.get('success') == 1 for entry in swap_result):
            raise RuntimeError('Hero parity position swap did not succeed')
        if final_formation is None or final_formation['combat'][0:2] != [57, 64] or final_formation['members'][0:2] != [64, 57]:
            raise RuntimeError('Hero parity final authoritative formation members are not swapped')
        print('hero_parity_semantics=passed')
    else:
        restart_pet = hero_responses_for('hero_restart_pet')
        restart_formation = formation_snapshot(hero_responses_for('hero_restart_formation'))
        if not any(entry.get('protocol') == 24 for entry in restart_pet):
            raise RuntimeError('Hero restart verification returned no /24 snapshot')
        if restart_formation is None or restart_formation['combat'][0:2] != [57, 64] or restart_formation['members'][0:2] != [64, 57]:
            raise RuntimeError('Hero restart verification did not persist the swapped formation')
        print('hero_restart_semantics=passed')
hero_equip_semantic_cases = []
if HERO_EQUIP_PARITY == 'true' or HERO_EQUIP_RESTART_VERIFY == 'true':
    def parse_equip_record(body, pos):
        if pos + 12 > len(body):
            raise RuntimeError('HeroEquip equipment record is truncated')
        uid = struct.unpack('<I', body[pos:pos + 4])[0]; pos += 4
        template_id = struct.unpack('<H', body[pos:pos + 2])[0]; pos += 2
        fpos = body[pos]; pos += 1
        jl_exp = struct.unpack('<I', body[pos:pos + 4])[0]; pos += 4
        cultivate_count = body[pos]; pos += 1
        cultivate = []
        for _ in range(cultivate_count):
            if pos + 3 > len(body): raise RuntimeError('HeroEquip cultivate record is truncated')
            cultivate.append({'type': body[pos], 'level': struct.unpack('<H', body[pos + 1:pos + 3])[0]})
            pos += 3
        if pos + 6 > len(body): raise RuntimeError('HeroEquip base attribute is truncated')
        base_type = struct.unpack('<H', body[pos:pos + 2])[0]
        base_value = struct.unpack('<I', body[pos + 2:pos + 6])[0]
        pos += 6
        for _ in range(4):
            if pos + 2 > len(body): raise RuntimeError('HeroEquip cultivate attribute group is truncated')
            pos += 1
            attr_count = body[pos]; pos += 1
            if pos + attr_count * 6 > len(body): raise RuntimeError('HeroEquip cultivate attributes are truncated')
            pos += attr_count * 6
        return {'uid': uid, 'templateId': template_id, 'fpos': fpos, 'jlExp': jl_exp, 'cultivate': cultivate, 'baseAttrType': base_type, 'baseAttrValue': base_value}, pos

    def parse_fabao_record(body, pos):
        if pos + 13 > len(body): raise RuntimeError('HeroEquip FaBao record is truncated')
        uid = struct.unpack('<I', body[pos:pos + 4])[0]; pos += 4
        template_id = struct.unpack('<H', body[pos:pos + 2])[0]; pos += 2
        fpos = body[pos]; wpos = body[pos + 1]; pos += 2
        exp = struct.unpack('<I', body[pos:pos + 4])[0]; pos += 4
        cultivate_count = body[pos]; pos += 1
        cultivate = []
        for _ in range(cultivate_count):
            if pos + 2 > len(body): raise RuntimeError('HeroEquip FaBao cultivate record is truncated')
            cultivate.append({'type': body[pos], 'level': body[pos + 1]}); pos += 2
        return {'uid': uid, 'templateId': template_id, 'fpos': fpos, 'wpos': wpos, 'exp': exp, 'cultivate': cultivate}, pos

    def hero_equip_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None: raise RuntimeError('HeroEquip parity response bucket is missing: ' + case_name)
        parsed = []
        response_types = []
        for response in case['responses']:
            msg_type = response['type']
            body = bytes.fromhex(response['bodyHex'])
            if msg_type not in (70, 319):
                continue
            response_types.append(msg_type)
            if msg_type == 70:
                parsed.append({'protocol': 70, 'bodyLength': len(body), 'bodySha256': hashlib.sha256(body).hexdigest().upper()})
                continue
            if not body: continue
            value = {'protocol': 319, 'op': body[0]}
            if body[0] in (1, 17):
                if len(body) < 3: raise RuntimeError('HeroEquip list response is truncated: ' + case_name)
                total = struct.unpack('<H', body[1:3])[0]
                value['total'] = total
                records = []
                if total:
                    if len(body) < 6: raise RuntimeError('HeroEquip paged list header is truncated: ' + case_name)
                    value.update({'packetCount': body[3], 'packetIndex': body[4], 'itemCount': body[5]})
                    pos = 6
                    for _ in range(body[5]):
                        record, pos = parse_equip_record(body, pos) if body[0] == 1 else parse_fabao_record(body, pos)
                        records.append(record)
                    if pos != len(body): raise RuntimeError('HeroEquip list response has unread bytes: ' + case_name)
                value['records'] = records
            elif body[0] in (6, 16):
                record, pos = parse_equip_record(body, 1); value['record'] = record
                if pos != len(body): raise RuntimeError('HeroEquip equipment update has unread bytes')
            elif body[0] == 22:
                record, pos = parse_fabao_record(body, 1); value['record'] = record
                if pos != len(body): raise RuntimeError('HeroEquip FaBao update has unread bytes')
            elif body[0] in (2, 3) and len(body) >= 7:
                value.update({'fpos': body[1], 'uid': struct.unpack('<I', body[2:6])[0], 'success': body[6]})
            elif body[0] == 4 and len(body) >= 7:
                value.update({'uid': struct.unpack('<I', body[1:5])[0], 'type': body[5], 'success': body[6]})
                if body[6] and len(body) >= 10:
                    value.update({'crit': body[7], 'addLevel': struct.unpack('<H', body[8:10])[0]})
            elif body[0] == 18 and len(body) >= 8:
                value.update({'uid': struct.unpack('<I', body[1:5])[0], 'fpos': body[5], 'wpos': body[6], 'success': body[7]})
                if body[7] and len(body) >= 12: value['replacedUid'] = struct.unpack('<I', body[8:12])[0]
            elif body[0] == 19 and len(body) >= 6:
                value.update({'uid': struct.unpack('<I', body[1:5])[0], 'success': body[5]})
            parsed.append(value)
        hero_equip_semantic_cases.append({'case': case_name, 'responseTypes': response_types, 'heroEquipResponses': parsed})
        return parsed

    def list_record(responses, op, template_id):
        for response in responses:
            if response.get('protocol') == 319 and response.get('op') == op:
                for record in response.get('records', []):
                    if record.get('templateId') == template_id: return record
        return None

    if HERO_EQUIP_PARITY == 'true':
        initial_equip = hero_equip_responses_for('heroequip_initial_equip')
        initial_fabao = hero_equip_responses_for('heroequip_initial_fabao')
        added_equip = hero_equip_responses_for('heroequip_add_equip1001')
        after_add_equip = hero_equip_responses_for('heroequip_after_add_equip')
        added_fabao = hero_equip_responses_for('heroequip_add_fabao1001')
        after_add_fabao = hero_equip_responses_for('heroequip_after_add_fabao')
        wear_equip = hero_equip_responses_for('heroequip_wear_equip')
        after_wear_equip = hero_equip_responses_for('heroequip_after_wear_equip')
        invalid_equip = hero_equip_responses_for('heroequip_invalid_equip')
        strong_equip = hero_equip_responses_for('heroequip_strong_equip')
        after_strong_equip = hero_equip_responses_for('heroequip_after_strong_equip')
        takeoff_equip = hero_equip_responses_for('heroequip_takeoff_equip')
        after_takeoff_equip = hero_equip_responses_for('heroequip_after_takeoff_equip')
        wear_fabao = hero_equip_responses_for('heroequip_wear_fabao')
        after_wear_fabao = hero_equip_responses_for('heroequip_after_wear_fabao')
        repeat_fabao = hero_equip_responses_for('heroequip_repeat_fabao')
        after_repeat_fabao = hero_equip_responses_for('heroequip_after_repeat_fabao')
        takeoff_fabao = hero_equip_responses_for('heroequip_takeoff_fabao')
        final_equip = hero_equip_responses_for('heroequip_final_equip')
        final_fabao = hero_equip_responses_for('heroequip_final_fabao')
        if any(response.get('total') != 0 for response in initial_equip + initial_fabao if response.get('op') in (1, 17)):
            raise RuntimeError('HeroEquip fresh role did not start with empty equipment and FaBao lists')
        if not any(response.get('op') == 6 and response.get('record', {}).get('templateId') == 1001 for response in added_equip):
            raise RuntimeError('HeroEquip fixture did not add equipment template 1001')
        if not any(response.get('op') == 22 and response.get('record', {}).get('templateId') == 1001 for response in added_fabao):
            raise RuntimeError('HeroEquip fixture did not add FaBao template 1001')
        if list_record(after_add_equip, 1, 1001) is None or list_record(after_add_fabao, 17, 1001) is None:
            raise RuntimeError('HeroEquip authoritative lists did not contain both fixtures')
        if not any(response.get('op') == 2 and response.get('success') == 1 for response in wear_equip):
            raise RuntimeError('HeroEquip equipment wear did not succeed')
        if list_record(after_wear_equip, 1, 1001).get('fpos') != 1:
            raise RuntimeError('HeroEquip equipment wear did not persist in the authoritative list')
        if not any(response.get('op') == 2 and response.get('success') == 0 for response in invalid_equip):
            raise RuntimeError('HeroEquip invalid equipment UID was not rejected')
        if not any(response.get('op') == 4 and response.get('success') == 1 and response.get('addLevel', 0) > 0 for response in strong_equip):
            raise RuntimeError('HeroEquip equipment strengthening did not succeed')
        strengthened = list_record(after_strong_equip, 1, 1001)
        if strengthened is None or not any(level['type'] == 1 and level['level'] > 0 for level in strengthened['cultivate']):
            raise RuntimeError('HeroEquip strengthened level was not authoritative')
        if not any(response.get('op') == 3 and response.get('success') == 1 for response in takeoff_equip) or list_record(after_takeoff_equip, 1, 1001).get('fpos') != 0:
            raise RuntimeError('HeroEquip equipment takeoff did not persist')
        if not any(response.get('op') == 18 and response.get('success') == 1 for response in wear_fabao):
            raise RuntimeError('HeroEquip FaBao wear did not succeed')
        worn_fabao = list_record(after_wear_fabao, 17, 1001)
        if worn_fabao is None or worn_fabao.get('fpos') != 1 or worn_fabao.get('wpos') != 5:
            raise RuntimeError('HeroEquip FaBao wear did not persist')
        if not any(response.get('op') == 18 and response.get('success') == 0 for response in repeat_fabao):
            raise RuntimeError('HeroEquip repeated FaBao wear was not rejected')
        if list_record(after_repeat_fabao, 17, 1001).get('fpos') != 1:
            raise RuntimeError('HeroEquip repeated FaBao rejection changed authoritative state')
        if not any(response.get('op') == 19 and response.get('success') == 1 for response in takeoff_fabao):
            raise RuntimeError('HeroEquip FaBao takeoff did not succeed')
        final_equip_record = list_record(final_equip, 1, 1001)
        final_fabao_record = list_record(final_fabao, 17, 1001)
        if final_equip_record is None or final_equip_record.get('fpos') != 0:
            raise RuntimeError('HeroEquip final equipment state is not unequipped')
        if final_fabao_record is None or final_fabao_record.get('fpos') != 0 or final_fabao_record.get('wpos') != 0:
            raise RuntimeError('HeroEquip final FaBao state is not unequipped')
        owned_responses = [response for case in hero_equip_semantic_cases for response in case['heroEquipResponses']]
        if sum(1 for response in owned_responses if response.get('protocol') == 70) < 5:
            raise RuntimeError('HeroEquip mutations emitted fewer than five authoritative /70 updates')
        print('heroequip_parity_semantics=passed')
    else:
        restart_equip = hero_equip_responses_for('heroequip_restart_equip')
        restart_fabao = hero_equip_responses_for('heroequip_restart_fabao')
        equip_record = list_record(restart_equip, 1, 1001)
        fabao_record = list_record(restart_fabao, 17, 1001)
        if equip_record is None or equip_record.get('fpos') != 0 or not any(level['type'] == 1 and level['level'] > 0 for level in equip_record['cultivate']):
            raise RuntimeError('HeroEquip restart did not persist strengthened unequipped equipment')
        if fabao_record is None or fabao_record.get('fpos') != 0 or fabao_record.get('wpos') != 0:
            raise RuntimeError('HeroEquip restart did not persist unequipped FaBao')
        print('heroequip_restart_semantics=passed')
mail_semantic_cases = []
if MAIL_PARITY == 'true' or MAIL_RESTART_VERIFY == 'true':
    def mail_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None:
            raise RuntimeError('Mail parity response bucket is missing: ' + case_name)
        parsed = []
        response_types = []
        for response in case['responses']:
            if response['type'] != 128:
                continue
            body = bytes.fromhex(response['bodyHex'])
            response_types.append(128)
            if not body:
                continue
            value = {'protocol': 128, 'op': body[0]}
            if body[0] == 2:
                value['mails'] = parse_mail_list_body(body)
                value['count'] = len(value['mails'])
            elif body[0] in (3, 4) and len(body) >= 7:
                value.update({
                    'id': struct.unpack('<I', body[1:5])[0],
                    'clientUse': body[5],
                    'success': body[6]
                })
            parsed.append(value)
        mail_semantic_cases.append({'case': case_name, 'responseTypes': response_types, 'mailResponses': parsed})
        return parsed

    def mail_list_from(responses):
        return next((entry for entry in responses if entry.get('op') == 2), None)

    if MAIL_PARITY == 'true':
        initial_list = mail_list_from(mail_responses_for('mail_initial_list'))
        mail_responses_for('mail_create_fixture')
        fixture_list = mail_list_from(mail_responses_for('mail_fixture_list'))
        claim = mail_responses_for('mail_claim_reward')
        claim_repeat = mail_responses_for('mail_claim_repeat')
        after_claim = mail_list_from(mail_responses_for('mail_after_claim'))
        read_plain = mail_responses_for('mail_read_plain')
        read_repeat = mail_responses_for('mail_read_repeat')
        final_list = mail_list_from(mail_responses_for('mail_final_list'))
        if initial_list is None or initial_list.get('count') != 0:
            raise RuntimeError('Mail fresh role did not start with an empty list')
        if fixture_list is None or fixture_list.get('count') != 14:
            raise RuntimeError('Mail fixture did not return 14 visible rows')
        reward_mail = next((mail for mail in fixture_list['mails'] if len(mail['rewards']) == 9), None)
        plain_mail = next((mail for mail in fixture_list['mails'] if len(mail['rewards']) == 0), None)
        if reward_mail is None or plain_mail is None:
            raise RuntimeError('Mail fixture lacks reward/plain ownership cases')
        if not any(response.get('op') == 3 and response.get('id') == reward_mail['id'] and response.get('success') == 1 for response in claim):
            raise RuntimeError('Mail reward claim did not succeed')
        if not any(response.get('op') == 3 and response.get('id') == reward_mail['id'] and response.get('success') == 0 for response in claim_repeat):
            raise RuntimeError('Mail repeated reward claim was not rejected')
        if after_claim is None or after_claim.get('count') != 13 or any(mail['id'] == reward_mail['id'] for mail in after_claim['mails']):
            raise RuntimeError('Mail claimed row remains in the authoritative list')
        if not any(response.get('op') == 4 and response.get('id') == plain_mail['id'] and response.get('success') == 1 for response in read_plain):
            raise RuntimeError('Mail plain read/delete did not succeed')
        if not any(response.get('op') == 4 and response.get('id') == plain_mail['id'] and response.get('success') == 0 for response in read_repeat):
            raise RuntimeError('Mail repeated plain read/delete was not rejected')
        if final_list is None or final_list.get('count') != 12 or any(mail['id'] in (reward_mail['id'], plain_mail['id']) for mail in final_list['mails']):
            raise RuntimeError('Mail final authoritative list did not persist both removals')
        print('mail_parity_semantics=passed')
    else:
        restart_list = mail_list_from(mail_responses_for('mail_restart_list'))
        if restart_list is None or restart_list.get('count') != 12:
            raise RuntimeError('Mail restart did not persist the 12-row final list')
        if any(len(mail['rewards']) == 9 for mail in restart_list['mails']):
            raise RuntimeError('Mail restart restored the already claimed nine-reward row')
        print('mail_restart_semantics=passed')
shop_semantic_cases = []
gameplay_shops_semantic_cases = []
if SHOP_PARITY == 'true' or SHOP_RESTART_VERIFY == 'true' or GAMEPLAY_SHOPS_PARITY == 'true' or GAMEPLAY_SHOPS_RESTART_VERIFY == 'true':
    shop_semantic_target = gameplay_shops_semantic_cases if GAMEPLAY_SHOPS_PARITY == 'true' or GAMEPLAY_SHOPS_RESTART_VERIFY == 'true' else shop_semantic_cases
    def shop_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None:
            raise RuntimeError('Shop parity response bucket is missing: ' + case_name)
        parsed = []
        for response in case['responses']:
            if response['type'] != 221:
                continue
            body = bytes.fromhex(response['bodyHex'])
            if not body:
                continue
            op = body[0]
            value = {'protocol': 221, 'op': op}
            if op in (1, 3):
                if len(body) < 3:
                    raise RuntimeError('Shop list/refresh response is truncated: ' + case_name)
                value.update({'type': body[1], 'success': body[2]})
                if body[2] == 0:
                    reason, pos = read_wire_string(body, 3)
                    if pos != len(body): raise RuntimeError('Shop rejection has unread bytes: ' + case_name)
                    value['reason'] = reason
                else:
                    if len(body) < 9: raise RuntimeError('Shop list header is truncated: ' + case_name)
                    value.update({
                        'refreshTimes': struct.unpack('<H', body[3:5])[0],
                        'freeTimes': body[5],
                        'refreshRemaining': struct.unpack('<H', body[6:8])[0],
                        'count': body[8]
                    })
                    pos = 9
                    records = []
                    for _ in range(body[8]):
                        if pos + 5 > len(body): raise RuntimeError('Shop list record is truncated: ' + case_name)
                        records.append({
                            'grid': body[pos],
                            'id': struct.unpack('<H', body[pos + 1:pos + 3])[0],
                            'buyCount': struct.unpack('<H', body[pos + 3:pos + 5])[0]
                        })
                        pos += 5
                    if pos != len(body): raise RuntimeError('Shop list has unread bytes: ' + case_name)
                    value['records'] = records
            elif op == 2:
                if len(body) < 8: raise RuntimeError('Shop purchase response is truncated: ' + case_name)
                value.update({
                    'type': body[1],
                    'id': struct.unpack('<H', body[2:4])[0],
                    'quantity': struct.unpack('<H', body[4:6])[0],
                    'use': body[6],
                    'success': body[7]
                })
                if body[7] == 0:
                    reason, pos = read_wire_string(body, 8)
                    if pos != len(body): raise RuntimeError('Shop purchase rejection has unread bytes: ' + case_name)
                    value['reason'] = reason
                else:
                    if len(body) != 16: raise RuntimeError('Shop purchase success framing is invalid: ' + case_name)
                    value.update({
                        'buyCount': struct.unpack('<H', body[8:10])[0],
                        'rewardType': struct.unpack('<H', body[10:12])[0],
                        'rewardAmount': struct.unpack('<I', body[12:16])[0]
                    })
            elif op == 4:
                if len(body) < 5: raise RuntimeError('Shop count response is truncated: ' + case_name)
                value.update({'type': body[1], 'id': struct.unpack('<H', body[2:4])[0], 'success': body[4]})
                if body[4] == 0:
                    reason, pos = read_wire_string(body, 5)
                    if pos != len(body): raise RuntimeError('Shop count rejection has unread bytes: ' + case_name)
                    value['reason'] = reason
                else:
                    if len(body) != 7: raise RuntimeError('Shop count success framing is invalid: ' + case_name)
                    value['buyCount'] = struct.unpack('<H', body[5:7])[0]
            parsed.append(value)
        shop_semantic_target.append({'case': case_name, 'responseTypes': [221] * len(parsed), 'shopResponses': parsed})
        return parsed

    def shop_one(responses, op):
        return next((entry for entry in responses if entry.get('op') == op), None)

    def shop_record(snapshot, item_id):
        return next((entry for entry in snapshot.get('records', []) if entry['id'] == item_id), None) if snapshot else None

    if SHOP_PARITY == 'true':
        initial_list = shop_one(shop_responses_for('shop_initial_list'), 1)
        initial_count = shop_one(shop_responses_for('shop_initial_count_1001'), 4)
        purchase = shop_one(shop_responses_for('shop_buy_1001_one'), 2)
        count_after = shop_one(shop_responses_for('shop_count_after_buy'), 4)
        list_after = shop_one(shop_responses_for('shop_list_after_buy'), 1)
        insufficient = shop_one(shop_responses_for('shop_buy_insufficient_1015'), 2)
        refresh = shop_one(shop_responses_for('shop_refresh_disabled'), 3)
        final_list = shop_one(shop_responses_for('shop_final_list'), 1)
        if initial_list is None or initial_list.get('success') != 1 or initial_list.get('count') != 17 or shop_record(initial_list, 1001) is None:
            raise RuntimeError('Shop type=1 initial authoritative list is incomplete')
        if initial_count is None or initial_count.get('success') != 1 or initial_count.get('buyCount') != 0:
            raise RuntimeError('Shop item 1001 did not start at buy count zero')
        if purchase is None or purchase.get('success') != 1 or purchase.get('buyCount') != 1 or purchase.get('rewardType') != 60000 or purchase.get('rewardAmount') != 100000:
            raise RuntimeError('Shop item 1001 production purchase result is invalid')
        if count_after is None or count_after.get('buyCount') != 1 or shop_record(list_after, 1001).get('buyCount') != 1:
            raise RuntimeError('Shop purchase count is not authoritative after purchase')
        if insufficient is None or insufficient.get('success') != 0:
            raise RuntimeError('Shop insufficient-balance purchase was not rejected')
        if refresh is None or refresh.get('success') != 0:
            raise RuntimeError('Shop type=1 disabled refresh was not rejected')
        if shop_record(final_list, 1001).get('buyCount') != 1 or shop_record(final_list, 1015).get('buyCount') != 0:
            raise RuntimeError('Shop rejected operations changed authoritative final state')
        print('shop_parity_semantics=passed')
    elif SHOP_RESTART_VERIFY == 'true':
        restart_list = shop_one(shop_responses_for('shop_restart_list'), 1)
        restart_count = shop_one(shop_responses_for('shop_restart_count_1001'), 4)
        if shop_record(restart_list, 1001).get('buyCount') != 1 or restart_count is None or restart_count.get('buyCount') != 1:
            raise RuntimeError('Shop restart did not persist item 1001 purchase count')
        print('shop_restart_semantics=passed')
    elif GAMEPLAY_SHOPS_PARITY == 'true':
        expected_counts = {2: 6, 3: 9, 4: 16, 5: 12, 6: 8, 7: 16, 8: 7, 23: 9, 25: 8, 26: 0, 27: 5, 28: 5}
        snapshots = {}
        for shop_type, expected_count in expected_counts.items():
            snapshot = shop_one(shop_responses_for('gameplay_shop_list_type' + str(shop_type)), 1)
            if snapshot is None or snapshot.get('type') != shop_type or snapshot.get('success') != 1 or snapshot.get('count') != expected_count:
                raise RuntimeError('GameplayShops authoritative list mismatch for type=' + str(shop_type) + ' snapshot=' + repr(snapshot))
            snapshots[shop_type] = snapshot
        type2_records = snapshots[2]['records']
        if snapshots[2].get('freeTimes') != 10 or sorted(record['grid'] for record in type2_records) != [1, 2, 3, 4, 5, 6] or len(set(record['id'] for record in type2_records)) != 6:
            raise RuntimeError('GameplayShops random type=2 list is structurally invalid')
        refresh = shop_one(shop_responses_for('gameplay_shop_refresh_type2'), 3)
        if refresh is None or refresh.get('success') != 1 or refresh.get('count') != 6 or refresh.get('freeTimes') != 9 or sorted(record['grid'] for record in refresh.get('records', [])) != [1, 2, 3, 4, 5, 6]:
            raise RuntimeError('GameplayShops type=2 free refresh did not persist authoritative structure')
        purchase = shop_one(shop_responses_for('gameplay_shop_buy_type28_28001_x25'), 2)
        count = shop_one(shop_responses_for('gameplay_shop_count_type28_28001'), 4)
        sold_out = shop_one(shop_responses_for('gameplay_shop_rebuy_soldout_type28'), 2)
        insufficient = shop_one(shop_responses_for('gameplay_shop_buy_insufficient_type3'), 2)
        final_type28 = shop_one(shop_responses_for('gameplay_shop_final_type28'), 1)
        if purchase is None or purchase.get('success') != 1 or purchase.get('buyCount') != 25 or purchase.get('rewardType') != 1120 or purchase.get('rewardAmount') != 1:
            raise RuntimeError('GameplayShops type=28 purchase did not return the configured authoritative result')
        if count is None or count.get('buyCount') != 25 or shop_record(final_type28, 28001).get('buyCount') != 25:
            raise RuntimeError('GameplayShops type=28 purchase count did not persist')
        if sold_out is None or sold_out.get('success') != 0:
            raise RuntimeError('GameplayShops sold-out repeated purchase was not rejected')
        if insufficient is None or insufficient.get('success') != 0:
            raise RuntimeError('GameplayShops zero-arena-currency purchase was not rejected')
        # Random type=2 item ids are valid backend-independent RNG output, so
        # compare their owned shape while retaining every raw packet in evidence.
        for semantic_case in gameplay_shops_semantic_cases:
            for response in semantic_case['shopResponses']:
                if response.get('type') == 2 and response.get('op') in (1, 3) and response.get('success') == 1:
                    response['records'] = [{'grid': record['grid'], 'buyCount': record['buyCount']} for record in response['records']]
                    response['refreshRemainingActive'] = response.get('refreshRemaining', 0) > 0
                    response.pop('refreshRemaining', None)
        print('gameplay_shops_parity_semantics=passed')
    else:
        restart_type2 = shop_one(shop_responses_for('gameplay_shop_restart_type2'), 1)
        restart_type28 = shop_one(shop_responses_for('gameplay_shop_restart_type28'), 1)
        restart_count = shop_one(shop_responses_for('gameplay_shop_restart_count_28001'), 4)
        if restart_type2 is None or restart_type2.get('freeTimes') != 9 or restart_type2.get('count') != 6:
            raise RuntimeError('GameplayShops restart did not persist type=2 refresh state')
        if shop_record(restart_type28, 28001).get('buyCount') != 25 or restart_count is None or restart_count.get('buyCount') != 25:
            raise RuntimeError('GameplayShops restart did not persist type=28 sold-out state')
        for semantic_case in gameplay_shops_semantic_cases:
            for response in semantic_case['shopResponses']:
                if response.get('type') == 2 and response.get('op') == 1 and response.get('success') == 1:
                    response['records'] = [{'grid': record['grid'], 'buyCount': record['buyCount']} for record in response['records']]
                    response['refreshRemainingActive'] = response.get('refreshRemaining', 0) > 0
                    response.pop('refreshRemaining', None)
        print('gameplay_shops_restart_semantics=passed')
world_semantic_cases = []
if WORLD_PARITY == 'true' or WORLD_RESTART_VERIFY == 'true':
    def world_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None:
            raise RuntimeError('World parity response bucket is missing: ' + case_name)
        packets = []
        for response in case['responses']:
            if response['type'] != 320:
                continue
            body = bytes.fromhex(response['bodyHex'])
            if not body:
                continue
            op = body[0]
            value = {'protocol': 320, 'op': op, 'bodyLength': len(body)}
            if op == 8:
                if len(body) < 24:
                    raise RuntimeError('World battle settlement is truncated: ' + case_name)
                reward_count = body[23]
                if len(body) != 24 + reward_count * 10:
                    raise RuntimeError('World battle settlement reward framing is invalid: ' + case_name)
                value.update({
                    'attackCount': body[1],
                    'stageId': struct.unpack('<I', body[2:6])[0],
                    'nextMapId': struct.unpack('<I', body[6:10])[0],
                    'nextNodeId': struct.unpack('<I', body[10:14])[0],
                    'normalBoxId': struct.unpack('<I', body[14:18])[0],
                    'starBoxId': struct.unpack('<I', body[18:22])[0],
                    'star': body[22],
                    'rewardCount': reward_count
                })
            elif op == 27:
                if len(body) != 13:
                    raise RuntimeError('World node detail framing is invalid: ' + case_name)
                value.update({
                    'type': body[1],
                    'mapId': struct.unpack('<I', body[2:6])[0],
                    'nodeId': struct.unpack('<I', body[6:10])[0],
                    'star': body[10],
                    'attackCount': body[11],
                    'resetRemaining': body[12]
                })
            elif op == 4:
                if len(body) < 11:
                    raise RuntimeError('World chest response is truncated: ' + case_name)
                value.update({
                    'type': body[1],
                    'mapId': struct.unpack('<I', body[2:6])[0],
                    'boxId': struct.unpack('<I', body[6:10])[0],
                    'success': body[10]
                })
                if body[10] == 1:
                    if len(body) < 12 or len(body) != 12 + body[11] * 10:
                        raise RuntimeError('World chest reward framing is invalid: ' + case_name)
                    value['rewardCount'] = body[11]
                else:
                    reason, pos = read_wire_string(body, 11)
                    if pos != len(body):
                        raise RuntimeError('World chest rejection has unread bytes: ' + case_name)
                    value['reasonPresent'] = len(reason) > 0
            elif op == 6:
                if len(body) < 12:
                    raise RuntimeError('World sweep response is truncated: ' + case_name)
                value.update({
                    'type': body[1],
                    'mapId': struct.unpack('<I', body[2:6])[0],
                    'nodeId': struct.unpack('<I', body[6:10])[0],
                    'success': body[10]
                })
                if body[10] == 1:
                    sweep_count = body[11]
                    pos = 12
                    rounds = []
                    for _ in range(sweep_count):
                        if pos + 2 > len(body): raise RuntimeError('World sweep round is truncated: ' + case_name)
                        round_index = body[pos]; money_count = body[pos + 1]; pos += 2
                        if pos + money_count * 10 + 1 > len(body): raise RuntimeError('World sweep currency rewards are truncated: ' + case_name)
                        pos += money_count * 10
                        reward_count = body[pos]; pos += 1
                        if pos + reward_count * 10 > len(body): raise RuntimeError('World sweep item rewards are truncated: ' + case_name)
                        pos += reward_count * 10
                        rounds.append({'index': round_index, 'moneyRewardCount': money_count, 'itemRewardCount': reward_count})
                    if pos != len(body): raise RuntimeError('World sweep response has unread bytes: ' + case_name)
                    value.update({'sweepCount': sweep_count, 'rounds': rounds})
            elif op == 7:
                if len(body) < 6:
                    raise RuntimeError('World reset response is truncated: ' + case_name)
                value.update({'nodeId': struct.unpack('<I', body[1:5])[0], 'success': body[5]})
                if body[5] == 1:
                    if len(body) != 9: raise RuntimeError('World reset success framing is invalid: ' + case_name)
                    value.update({'resetCount': body[6], 'cost': struct.unpack('<H', body[7:9])[0]})
            elif op in (1, 2):
                value['bodySha256'] = hashlib.sha256(body).hexdigest().upper()
            elif op == 5:
                if len(body) != 10: raise RuntimeError('World fight acknowledgement framing is invalid: ' + case_name)
                value.update({'type': body[1], 'mapId': struct.unpack('<I', body[2:6])[0], 'nodeId': struct.unpack('<I', body[6:10])[0]})
            packets.append(value)
        world_semantic_cases.append({'case': case_name, 'worldResponses': packets})
        return packets

    def world_one(responses, op):
        return next((entry for entry in responses if entry.get('op') == op), None)

    if WORLD_PARITY == 'true':
        initial_map = world_one(world_responses_for('world_initial_map'), 1)
        initial_chapter = world_one(world_responses_for('world_initial_chapter'), 2)
        initial_node = world_one(world_responses_for('world_initial_node_10001'), 27)
        fight1 = world_responses_for('world_fight_10001')
        after_fight = world_one(world_responses_for('world_after_fight_node_10001'), 27)
        normal_claim = world_one(world_responses_for('world_claim_normal_10000'), 4)
        normal_reclaim = world_one(world_responses_for('world_reclaim_normal_10000'), 4)
        fight2 = world_responses_for('world_fight_10002')
        star_claim = world_one(world_responses_for('world_claim_star_20011'), 4)
        sweep = world_one(world_responses_for('world_sweep_10001'), 6)
        after_sweep = world_one(world_responses_for('world_after_sweep_node_10001'), 27)
        reset = world_one(world_responses_for('world_reset_10001'), 7)
        final_node = world_one(world_responses_for('world_final_node_10001'), 27)
        final_chapter = world_one(world_responses_for('world_final_chapter'), 2)
        final_map = world_one(world_responses_for('world_final_map'), 1)
        settlement1 = world_one(fight1, 8)
        settlement2 = world_one(fight2, 8)
        if initial_map is None or initial_chapter is None or initial_node is None or initial_node.get('star') != 0 or initial_node.get('attackCount') != 0:
            raise RuntimeError('World fresh-role initial authoritative state is invalid')
        if settlement1 is None or settlement1.get('stageId') != 10001 or settlement1.get('star', 0) < 1 or after_fight.get('attackCount') != 1:
            raise RuntimeError('World stage 10001 production fight did not settle and persist')
        if normal_claim is None or normal_claim.get('success') != 1 or normal_reclaim is None or normal_reclaim.get('success') != 0:
            raise RuntimeError('World normal chest claim/rejection lifecycle is invalid')
        if settlement2 is None or settlement2.get('stageId') != 10002 or settlement2.get('star', 0) < 1:
            raise RuntimeError('World stage 10002 production fight did not settle')
        if star_claim is None or star_claim.get('success') != 1:
            raise RuntimeError('World six-star chest was not claimable after two three-star fights')
        if sweep is None or sweep.get('success') != 1 or sweep.get('sweepCount') != 4 or after_sweep.get('attackCount') != 5:
            raise RuntimeError('World sweep did not exhaust the four remaining stage attempts')
        if reset is None or reset.get('success') != 1 or reset.get('resetCount') != 1 or reset.get('cost') != 50:
            raise RuntimeError('World reset did not consume the configured first reset cost')
        if final_node is None or final_node.get('star', 0) < 1 or final_node.get('attackCount') != 0 or final_node.get('resetRemaining') != 4:
            raise RuntimeError('World final node state did not retain stars and clear attempts after reset')
        if final_chapter is None or final_map is None:
            raise RuntimeError('World final authoritative chapter/map snapshots are missing')
        print('world_parity_semantics=passed')
    else:
        restart_map = world_one(world_responses_for('world_restart_map'), 1)
        restart_chapter = world_one(world_responses_for('world_restart_chapter'), 2)
        restart_node1 = world_one(world_responses_for('world_restart_node_10001'), 27)
        restart_node2 = world_one(world_responses_for('world_restart_node_10002'), 27)
        if restart_map is None or restart_chapter is None:
            raise RuntimeError('World restart map/chapter snapshots are missing')
        if restart_node1 is None or restart_node1.get('star', 0) < 1 or restart_node1.get('attackCount') != 0 or restart_node1.get('resetRemaining') != 4:
            raise RuntimeError('World restart did not persist stage 10001 reset state')
        if restart_node2 is None or restart_node2.get('star', 0) < 1 or restart_node2.get('attackCount') != 1:
            raise RuntimeError('World restart did not persist stage 10002 fight state')
        print('world_restart_semantics=passed')
draw_semantic_cases = []
if DRAW_PARITY == 'true' or DRAW_RESTART_VERIFY == 'true':
    def parse_draw_reward(body, pos, case_name):
        if pos + 10 > len(body): raise RuntimeError('Draw reward is truncated: ' + case_name)
        reward = {
            'type': struct.unpack('<H', body[pos:pos + 2])[0],
            'typeId': struct.unpack('<I', body[pos + 2:pos + 6])[0],
            'amount': struct.unpack('<I', body[pos + 6:pos + 10])[0]
        }
        pos += 10
        if reward['type'] == 60002:
            if pos + 6 > len(body): raise RuntimeError('Draw pet transform reward is truncated: ' + case_name)
            reward['transformItemId'] = struct.unpack('<H', body[pos:pos + 2])[0]
            reward['transformAmount'] = struct.unpack('<I', body[pos + 2:pos + 6])[0]
            pos += 6
        return reward, pos

    def draw_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None: raise RuntimeError('Draw parity response bucket is missing: ' + case_name)
        parsed = []
        for response in case['responses']:
            if response['type'] == 24:
                parsed.append({'protocol': 24, 'present': True})
                continue
            if response['type'] != 224:
                continue
            body = bytes.fromhex(response['bodyHex'])
            if not body: continue
            op = body[0]
            value = {'protocol': 224, 'op': op, 'bodyLength': len(body)}
            if op == 1:
                if len(body) < 2: raise RuntimeError('Draw info response is truncated: ' + case_name)
                count = body[1]; pos = 2; pools = []
                for _ in range(count):
                    if pos + 10 > len(body): raise RuntimeError('Draw pool state is truncated: ' + case_name)
                    pools.append({
                        'type': body[pos],
                        'allCount': struct.unpack('<I', body[pos + 1:pos + 5])[0],
                        'freeCooldown': struct.unpack('<I', body[pos + 5:pos + 9])[0],
                        'freeTimes': body[pos + 9]
                    })
                    pos += 10
                if pos != len(body): raise RuntimeError('Draw info response has unread bytes: ' + case_name)
                value.update({'count': count, 'pools': pools})
            elif op == 2:
                if len(body) < 4: raise RuntimeError('Draw result response is truncated: ' + case_name)
                value.update({'type': body[1], 'drawType': body[2], 'success': body[3]})
                if body[3] == 0:
                    reason, pos = read_wire_string(body, 4)
                    if pos != len(body): raise RuntimeError('Draw rejection has unread bytes: ' + case_name)
                    value['reasonPresent'] = len(reason) > 0
                else:
                    if len(body) < 9: raise RuntimeError('Draw success header is truncated: ' + case_name)
                    pos = 4; value['allCount'] = struct.unpack('<I', body[pos:pos + 4])[0]; pos += 4
                    if body[2] == 1:
                        if pos + 5 > len(body): raise RuntimeError('Draw single state is truncated: ' + case_name)
                        value['freeTimes'] = body[pos]; value['freeCooldown'] = struct.unpack('<I', body[pos + 1:pos + 5])[0]; pos += 5
                    guaranteed_count = body[pos]; pos += 1
                    guaranteed = []
                    for _ in range(guaranteed_count):
                        reward, pos = parse_draw_reward(body, pos, case_name); guaranteed.append(reward)
                    result_count = 1 if body[2] == 1 else body[pos]
                    if body[2] != 1: pos += 1
                    results = []
                    for _ in range(result_count):
                        reward, pos = parse_draw_reward(body, pos, case_name); results.append(reward)
                    if pos != len(body): raise RuntimeError('Draw success response has unread bytes: ' + case_name)
                    value.update({'guaranteed': guaranteed, 'resultCount': result_count, 'results': results})
            parsed.append(value)
        draw_semantic_cases.append({'case': case_name, 'drawResponses': parsed})
        return parsed

    def draw_one(responses, protocol, op=None):
        return next((entry for entry in responses if entry.get('protocol') == protocol and (op is None or entry.get('op') == op)), None)

    def draw_pool(snapshot, pool_type):
        return next((entry for entry in snapshot.get('pools', []) if entry['type'] == pool_type), None) if snapshot else None

    if DRAW_PARITY == 'true':
        initial = draw_one(draw_responses_for('draw_initial_info'), 224, 1)
        single = draw_one(draw_responses_for('draw_high_free_single'), 224, 2)
        after_single = draw_one(draw_responses_for('draw_after_single_info'), 224, 1)
        draw_responses_for('draw_add_high_tickets')
        ten = draw_one(draw_responses_for('draw_high_ten'), 224, 2)
        after_ten = draw_one(draw_responses_for('draw_after_ten_info'), 224, 1)
        insufficient = draw_one(draw_responses_for('draw_high_ten_insufficient'), 224, 2)
        final_pet = draw_one(draw_responses_for('draw_final_pet'), 24)
        initial_high = draw_pool(initial, 2); single_high = draw_pool(after_single, 2); final_high = draw_pool(after_ten, 2)
        if initial is None or initial.get('count') != 3 or initial_high is None or initial_high.get('allCount') != 0 or initial_high.get('freeTimes') != 1:
            raise RuntimeError('Draw high pool did not start at deterministic fresh-role state')
        result = single.get('results', [None])[0] if single else None
        if single is None or single.get('success') != 1 or single.get('allCount') != 1 or single.get('freeTimes') != 0 or result is None or result.get('type') != 60002 or result.get('typeId') != 64 or result.get('amount') != 1:
            raise RuntimeError('Draw first high single did not return deterministic hero 64')
        if single_high is None or single_high.get('allCount') != 1 or single_high.get('freeTimes') != 0:
            raise RuntimeError('Draw post-single pool state is invalid')
        if ten is None or ten.get('success') != 1 or ten.get('allCount') != 11 or ten.get('resultCount') != 10 or len(ten.get('results', [])) != 10:
            raise RuntimeError('Draw production high ten-draw did not return ten authoritative results')
        if any(reward.get('amount', 0) <= 0 for reward in ten.get('results', [])):
            raise RuntimeError('Draw production high ten-draw returned a non-positive reward')
        if final_high is None or final_high.get('allCount') != 11 or final_high.get('freeTimes') != 0:
            raise RuntimeError('Draw final high-pool count did not persist in-session')
        if insufficient is None or insufficient.get('success') != 0 or not insufficient.get('reasonPresent'):
            raise RuntimeError('Draw repeated high ten-draw without tickets was not rejected')
        if final_pet is None:
            raise RuntimeError('Draw final authoritative /24 pet snapshot is missing')
        # Ten-draw contents are production RNG. Preserve raw packets but compare
        # ownership/count/positive-result semantics between sequential backends.
        ten['results'] = [{'valid': reward.get('amount', 0) > 0} for reward in ten['results']]
        print('draw_parity_semantics=passed')
    else:
        restart_info = draw_one(draw_responses_for('draw_restart_info'), 224, 1)
        restart_pet = draw_one(draw_responses_for('draw_restart_pet'), 24)
        restart_high = draw_pool(restart_info, 2)
        if restart_high is None or restart_high.get('allCount') != 11 or restart_high.get('freeTimes') != 0:
            raise RuntimeError('Draw restart did not persist high-pool allCount/freeTimes')
        if restart_pet is None:
            raise RuntimeError('Draw restart authoritative /24 pet snapshot is missing')
        print('draw_restart_semantics=passed')
gameplay_semantic_cases = []
if GAMEPLAY_PARITY == 'true' or GAMEPLAY_RESTART_VERIFY == 'true':
    def gameplay_hotpoint_for(case_name, expected_type):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None: raise RuntimeError('Gameplay parity response bucket is missing: ' + case_name)
        parsed = []
        for response in case['responses']:
            if response['type'] != 65: continue
            body = bytes.fromhex(response['bodyHex'])
            if len(body) != 4:
                raise RuntimeError('Gameplay /65 response framing is invalid: ' + case_name)
            parsed.append({
                'protocol': 65,
                'op': body[0],
                'type': struct.unpack('<H', body[1:3])[0],
                'state': body[3],
                'bodyHex': body.hex()
            })
        if len(parsed) != 1 or parsed[0]['op'] != 1 or parsed[0]['type'] != expected_type or parsed[0]['state'] != 0:
            raise RuntimeError('Gameplay local-test hot-point response is not the authoritative hidden state: ' + case_name)
        gameplay_semantic_cases.append({'case': case_name, 'hotPointResponses': parsed})

    if GAMEPLAY_PARITY == 'true':
        gameplay_hotpoint_for('gameplay_arena_hotpoint', 101)
        gameplay_hotpoint_for('gameplay_xunbao_hotpoint', 103)
        gameplay_hotpoint_for('gameplay_arena_hotpoint_repeat', 101)
        gameplay_hotpoint_for('gameplay_xunbao_hotpoint_repeat', 103)
        print('gameplay_parity_semantics=passed')
    else:
        gameplay_hotpoint_for('gameplay_restart_arena_hotpoint', 101)
        gameplay_hotpoint_for('gameplay_restart_xunbao_hotpoint', 103)
        print('gameplay_restart_semantics=passed')
youli_semantic_cases = []
if YOULI_PARITY == 'true' or YOULI_RESTART_VERIFY == 'true':
    def youli_info_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None: raise RuntimeError('YouLi parity response bucket is missing: ' + case_name)
        parsed = []
        for response in case['responses']:
            if response['type'] != 335: continue
            body = bytes.fromhex(response['bodyHex'])
            if len(body) < 2 or body[0] != 1:
                raise RuntimeError('YouLi /335 op=1 response framing is invalid: ' + case_name)
            count = body[1]
            # Fresh isolated roles must remain an authoritative empty state.
            # Non-empty variable reward/dialogue framing belongs to later
            # mutation coverage and is not inferred here.
            if count != 0 or len(body) != 2:
                raise RuntimeError('YouLi fresh-role query is not the expected empty authoritative state: ' + case_name)
            parsed.append({'protocol': 335, 'op': 1, 'count': 0, 'bodyHex': body.hex()})
        if len(parsed) != 1:
            raise RuntimeError('YouLi query did not receive exactly one owned /335 response: ' + case_name)
        youli_semantic_cases.append({'case': case_name, 'youLiResponses': parsed})

    if YOULI_PARITY == 'true':
        youli_info_for('youli_initial_info')
        youli_info_for('youli_repeat_info')
        print('youli_parity_semantics=passed')
    else:
        youli_info_for('youli_restart_info')
        print('youli_restart_semantics=passed')
fengshen_story_semantic_cases = []
if FENGSHEN_STORY_PARITY == 'true' or FENGSHEN_STORY_RESTART_VERIFY == 'true':
    def fengshen_story_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None: raise RuntimeError('FengShenStory parity response bucket is missing: ' + case_name)
        parsed = []
        for response in case['responses']:
            if response['type'] != 320: continue
            body = bytes.fromhex(response['bodyHex'])
            if not body: continue
            op = body[0]
            value = {'protocol': 320, 'op': op, 'bodyLength': len(body), 'bodyHex': body.hex()}
            if op == 24:
                if len(body) != 10: raise RuntimeError('FengShenStory op24 framing is invalid: ' + case_name)
                value.update({
                    'mapIndex': struct.unpack('<I', body[1:5])[0],
                    'nodeId': struct.unpack('<I', body[5:9])[0],
                    'remainingCount': body[9]
                })
            elif op == 25:
                if len(body) != 1: raise RuntimeError('FengShenStory successful op25 acknowledgement is invalid: ' + case_name)
            elif op == 10:
                if len(body) < 20: raise RuntimeError('FengShenStory op10 settlement is truncated: ' + case_name)
                value.update({
                    'oldMapIndex': struct.unpack('<I', body[1:5])[0],
                    'oldNodeId': struct.unpack('<I', body[5:9])[0],
                    'remainingCount': body[9],
                    'newMapIndex': struct.unpack('<I', body[10:14])[0],
                    'newNodeId': struct.unpack('<I', body[14:18])[0],
                    'star': body[18],
                    'awardCount': body[19]
                })
                pos = 20; awards = []
                for _ in range(value['awardCount']):
                    if pos + 10 > len(body): raise RuntimeError('FengShenStory op10 reward is truncated: ' + case_name)
                    awards.append({
                        'type': struct.unpack('<H', body[pos:pos + 2])[0],
                        'typeId': struct.unpack('<I', body[pos + 2:pos + 6])[0],
                        'amount': struct.unpack('<I', body[pos + 6:pos + 10])[0]
                    })
                    pos += 10
                if pos != len(body): raise RuntimeError('FengShenStory op10 settlement has unread bytes: ' + case_name)
                value['awards'] = awards
            elif op == 26:
                if len(body) < 2: raise RuntimeError('FengShenStory op26 fixed reward is truncated: ' + case_name)
                count = body[1]; pos = 2; awards = []
                for _ in range(count):
                    if pos + 10 > len(body): raise RuntimeError('FengShenStory op26 reward is truncated: ' + case_name)
                    awards.append({
                        'type': struct.unpack('<H', body[pos:pos + 2])[0],
                        'typeId': struct.unpack('<I', body[pos + 2:pos + 6])[0],
                        'amount': struct.unpack('<I', body[pos + 6:pos + 10])[0]
                    })
                    pos += 10
                if pos != len(body): raise RuntimeError('FengShenStory op26 fixed reward has unread bytes: ' + case_name)
                value.update({'awardCount': count, 'awards': awards})
            parsed.append(value)
        fengshen_story_semantic_cases.append({'case': case_name, 'fengShenStoryResponses': parsed})
        return parsed

    def fengshen_story_one(responses, op):
        matches = [entry for entry in responses if entry.get('op') == op]
        if len(matches) != 1: raise RuntimeError('FengShenStory expected exactly one op' + str(op))
        return matches[0]

    if FENGSHEN_STORY_PARITY == 'true':
        initial = fengshen_story_one(fengshen_story_responses_for('fengshen_story_initial_info'), 24)
        challenge = fengshen_story_responses_for('fengshen_story_challenge')
        settlement = fengshen_story_one(challenge, 10)
        fengshen_story_one(challenge, 25)
        final = fengshen_story_one(fengshen_story_responses_for('fengshen_story_final_info'), 24)
        if initial['remainingCount'] <= 0 or initial['nodeId'] == 0:
            raise RuntimeError('FengShenStory fresh-role initial state is invalid')
        if settlement['oldMapIndex'] != initial['mapIndex'] or settlement['oldNodeId'] != initial['nodeId']:
            raise RuntimeError('FengShenStory settlement did not start from the authoritative initial node')
        if settlement['remainingCount'] != initial['remainingCount'] - 1 or settlement['newNodeId'] == initial['nodeId']:
            raise RuntimeError('FengShenStory settlement did not consume one count and advance the node')
        if settlement['star'] != 3 or settlement['awardCount'] <= 0 or any(a['amount'] <= 0 for a in settlement['awards']):
            raise RuntimeError('FengShenStory settlement star/reward semantics are invalid')
        if final['mapIndex'] != settlement['newMapIndex'] or final['nodeId'] != settlement['newNodeId'] or final['remainingCount'] != settlement['remainingCount']:
            raise RuntimeError('FengShenStory final op24 did not match the production settlement')
        print('fengshen_story_parity_semantics=passed')
    else:
        restart = fengshen_story_one(fengshen_story_responses_for('fengshen_story_restart_info'), 24)
        if restart['remainingCount'] < 0 or restart['nodeId'] == 0:
            raise RuntimeError('FengShenStory restart state is invalid')
        print('fengshen_story_restart_semantics=passed')
arena_semantic_cases = []
if ARENA_PARITY == 'true' or ARENA_RESTART_VERIFY == 'true':
    def parse_arena_list(body, case_name):
        if len(body) < 4 or body[0:3] != b'\x00\x01\x01':
            raise RuntimeError('Arena op0 type1 response header is invalid: ' + case_name)
        count = body[3]; pos = 4; opponents = []
        for _ in range(count):
            if pos + 9 > len(body): raise RuntimeError('Arena opponent identity is truncated: ' + case_name)
            rank = struct.unpack('<I', body[pos:pos + 4])[0]
            unit_type = body[pos + 4]
            role_id = struct.unpack('<I', body[pos + 5:pos + 9])[0]
            pos += 9
            entry = {'rank': rank, 'unitType': unit_type}
            if unit_type == 0:
                _, pos = read_wire_string(body, pos)
                if pos + 13 > len(body): raise RuntimeError('Arena player opponent is truncated: ' + case_name)
                pos += 13
                entry['identity'] = 'player'
            elif unit_type == 1:
                entry['identity'] = 'robot'
            else:
                raise RuntimeError('Arena opponent type is invalid: ' + case_name)
            opponents.append(entry)
        if pos + 13 != len(body): raise RuntimeError('Arena op0 state tail is invalid: ' + case_name)
        value = {
            'protocol': 161, 'op': 0, 'type': 1, 'success': 1,
            'opponentCount': count,
            'robotCount': len([entry for entry in opponents if entry['unitType'] == 1]),
            'playerCount': len([entry for entry in opponents if entry['unitType'] == 0]),
            'rank': struct.unpack('<I', body[pos:pos + 4])[0],
            'remainingCount': struct.unpack('<H', body[pos + 4:pos + 6])[0],
            'challengedCount': struct.unpack('<H', body[pos + 6:pos + 8])[0],
            'buyCount': body[pos + 8],
            'score': struct.unpack('<i', body[pos + 9:pos + 13])[0]
        }
        return value

    def arena_responses_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None: raise RuntimeError('Arena parity response bucket is missing: ' + case_name)
        parsed = []
        for response in case['responses']:
            body = bytes.fromhex(response['bodyHex'])
            if response['type'] == 161 and body:
                if body[0] == 0:
                    parsed.append(parse_arena_list(body, case_name))
                elif body[0] == 13:
                    if len(body) != 2: raise RuntimeError('Arena op13 response framing is invalid: ' + case_name)
                    parsed.append({'protocol': 161, 'op': 13, 'remainingCount': body[1]})
            elif response['type'] == 38:
                if len(body) < 3 or body[0] not in (3, 4, 5):
                    raise RuntimeError('Arena replay header is invalid: ' + case_name)
                replay_count = struct.unpack('<H', body[1:3])[0]
                pos = 3
                for _ in range(replay_count):
                    if pos + 6 > len(body): raise RuntimeError('Arena replay packet is truncated: ' + case_name)
                    packet_body_len = struct.unpack('<I', body[pos:pos + 4])[0]
                    packet_len = packet_body_len + 6
                    if packet_len < 6 or pos + packet_len > len(body): raise RuntimeError('Arena replay embedded framing is invalid: ' + case_name)
                    pos += packet_len
                if pos != len(body): raise RuntimeError('Arena replay has unread bytes: ' + case_name)
                parsed.append({'protocol': 38, 'replayType': body[0], 'packetCountPositive': replay_count > 0, 'framingValid': True})
        arena_semantic_cases.append({'case': case_name, 'arenaResponses': parsed})
        return parsed

    def arena_one(responses, protocol, op=None):
        matches = [entry for entry in responses if entry.get('protocol') == protocol and (op is None or entry.get('op') == op)]
        if len(matches) != 1: raise RuntimeError('Arena expected exactly one owned response')
        return matches[0]

    if ARENA_PARITY == 'true':
        for fixture_case in ('arena_add_pet63', 'arena_form_pet63_pos2', 'arena_add_pet40', 'arena_form_pet40_pos3', 'arena_add_pet41', 'arena_form_pet41_pos4', 'arena_add_pet49', 'arena_form_pet49_pos5'):
            arena_responses_for(fixture_case)
        arena_responses_for('arena_raise_pets')
        initial = arena_one(arena_responses_for('arena_initial_list'), 161, 0)
        initial_remaining = arena_one(arena_responses_for('arena_initial_remaining'), 161, 13)
        replay = arena_one(arena_responses_for('arena_fight_dynamic_robot'), 38)
        final = arena_one(arena_responses_for('arena_final_list'), 161, 0)
        final_remaining = arena_one(arena_responses_for('arena_final_remaining'), 161, 13)
        arena_responses_for('arena_flush_rank_snapshot')
        if initial['rank'] != 10000 or initial['remainingCount'] <= 0 or initial['challengedCount'] != 0 or initial['opponentCount'] < 10:
            raise RuntimeError('Arena fresh-role initial rank/count/opponent state is invalid')
        if initial_remaining['remainingCount'] != 0:
            raise RuntimeError('Arena fresh-role op13 entry-count state is invalid')
        if not replay['framingValid'] or not replay['packetCountPositive']:
            raise RuntimeError('Arena production fight did not return a valid replay')
        if final['rank'] >= initial['rank'] or final['remainingCount'] != initial['remainingCount'] - 1 or final['challengedCount'] != 1:
            raise RuntimeError('Arena production fight did not win, advance rank, and consume one attempt')
        if final_remaining['remainingCount'] != initial_remaining['remainingCount']:
            raise RuntimeError('Arena op13 entry-count state changed unexpectedly')
        print('arena_parity_semantics=passed')
    else:
        restart = arena_one(arena_responses_for('arena_restart_list'), 161, 0)
        restart_remaining = arena_one(arena_responses_for('arena_restart_remaining'), 161, 13)
        if restart['rank'] >= 10000 or restart['remainingCount'] != 19 or restart['challengedCount'] != 1:
            raise RuntimeError('Arena restart did not persist the successful fight state: rank=' + str(restart['rank']) + ' remaining=' + str(restart['remainingCount']) + ' challenged=' + str(restart['challengedCount']))
        if restart_remaining['remainingCount'] != 0:
            raise RuntimeError('Arena restart op13 entry-count state is invalid')
        print('arena_restart_semantics=passed')
xunbao_semantic_cases = []
if XUNBAO_PARITY == 'true' or XUNBAO_RESTART_VERIFY == 'true':
    def xunbao_info_for(case_name):
        case = next((entry for entry in case_responses if entry['case'] == case_name), None)
        if case is None: raise RuntimeError('XunBao parity response bucket is missing: ' + case_name)
        parsed = []
        for response in case['responses']:
            if response['type'] != 319: continue
            body = bytes.fromhex(response['bodyHex'])
            if len(body) != 7 or body[0] != 31:
                continue
            parsed.append({
                'protocol': 319,
                'op': 31,
                'remainingCount': struct.unpack('<H', body[1:3])[0],
                'recoverySeconds': struct.unpack('<I', body[3:7])[0],
                'bodyHex': body.hex()
            })
        if len(parsed) != 1:
            raise RuntimeError('XunBao query did not receive exactly one owned /319 op31 response: ' + case_name)
        # config.json fabao_counts=[20,30,30]: a new role starts with 20 searches,
        # recovers one search every 30 minutes, and caps at 30.  The raw recovery
        # seconds naturally differ by wall-clock time between backend runs, so
        # validate the production interval and compare the normalized state.
        info = parsed[0]
        if info['remainingCount'] != 20 or info['recoverySeconds'] < 1 or info['recoverySeconds'] > 1800:
            raise RuntimeError(
                'XunBao fresh-role authoritative count/recovery state is invalid: '
                + case_name + ' count=' + str(info['remainingCount'])
                + ' recovery=' + str(info['recoverySeconds'])
                + ' body=' + info['bodyHex'])
        xunbao_semantic_cases.append({
            'case': case_name,
            'xunBaoResponses': [{
                'protocol': 319,
                'op': 31,
                'remainingCount': info['remainingCount'],
                'recoveryActive': True,
                'recoveryIntervalSeconds': 1800
            }]
        })

    if XUNBAO_PARITY == 'true':
        xunbao_info_for('xunbao_initial_info')
        xunbao_info_for('xunbao_repeat_info')
        print('xunbao_parity_semantics=passed')
    else:
        xunbao_info_for('xunbao_restart_info')
        print('xunbao_restart_semantics=passed')
if RESULT_PATH:
    response_counts = {str(t): len(bodies) for t, bodies in sorted(recv_bodies.items())}
    response_lengths = {str(t): [len(body) for body in bodies] for t, bodies in sorted(recv_bodies.items())}
    response_hashes = {}
    for t, bodies in sorted(recv_bodies.items()):
        digest = hashlib.sha256()
        for body in bodies:
            digest.update(struct.pack('<I', len(body)))
            digest.update(body)
        response_hashes[str(t)] = digest.hexdigest().upper()
    report = {
        'schemaVersion': 1,
        'status': 'Passed',
        'endpoint': {'host': HOST, 'port': PORT},
        'identity': {'userId': USER_ID, 'roleId': role_to_select, 'createdRoleId': created_role_id['id']},
        'flags': {
            'steamIncluded': STEAM_INCLUDED == 'true',
            'bagParity': BAG_PARITY == 'true',
            'taskParity': TASK_PARITY == 'true',
            'taskRestartVerify': TASK_RESTART_VERIFY == 'true',
            'playerHudParity': PLAYERHUD_PARITY == 'true',
            'heroParity': HERO_PARITY == 'true',
            'heroRestartVerify': HERO_RESTART_VERIFY == 'true',
            'heroEquipParity': HERO_EQUIP_PARITY == 'true',
            'heroEquipRestartVerify': HERO_EQUIP_RESTART_VERIFY == 'true',
            'mailParity': MAIL_PARITY == 'true',
            'mailRestartVerify': MAIL_RESTART_VERIFY == 'true',
            'shopParity': SHOP_PARITY == 'true',
            'shopRestartVerify': SHOP_RESTART_VERIFY == 'true',
            'gameplayShopsParity': GAMEPLAY_SHOPS_PARITY == 'true',
            'gameplayShopsRestartVerify': GAMEPLAY_SHOPS_RESTART_VERIFY == 'true',
            'worldParity': WORLD_PARITY == 'true',
            'worldRestartVerify': WORLD_RESTART_VERIFY == 'true',
            'drawParity': DRAW_PARITY == 'true',
            'drawRestartVerify': DRAW_RESTART_VERIFY == 'true',
            'gameplayParity': GAMEPLAY_PARITY == 'true',
            'gameplayRestartVerify': GAMEPLAY_RESTART_VERIFY == 'true',
            'youLiParity': YOULI_PARITY == 'true',
            'youLiRestartVerify': YOULI_RESTART_VERIFY == 'true',
            'fengShenStoryParity': FENGSHEN_STORY_PARITY == 'true',
            'fengShenStoryRestartVerify': FENGSHEN_STORY_RESTART_VERIFY == 'true',
            'arenaParity': ARENA_PARITY == 'true',
            'arenaRestartVerify': ARENA_RESTART_VERIFY == 'true',
            'xunBaoParity': XUNBAO_PARITY == 'true',
            'xunBaoRestartVerify': XUNBAO_RESTART_VERIFY == 'true',
            'extended': EXTENDED == 'true',
            'actions': ACTIONS == 'true',
            'mutations': MUTATIONS == 'true',
            'positive': POSITIVE == 'true',
            'battle': BATTLE == 'true',
            'uiQueries': UI_QUERIES == 'true'
        },
        'sentCases': sent_case_names,
        'receivedCount': len(recv_types),
        'receivedTypes': recv_types,
        'responseCountsByType': response_counts,
        'responseBodyLengthsByType': response_lengths,
        'responseBodySha256ByType': response_hashes,
        'caseResponses': case_responses if BAG_PARITY == 'true' or TASK_PARITY == 'true' or TASK_RESTART_VERIFY == 'true' or PLAYERHUD_PARITY == 'true' or HERO_PARITY == 'true' or HERO_RESTART_VERIFY == 'true' or HERO_EQUIP_PARITY == 'true' or HERO_EQUIP_RESTART_VERIFY == 'true' or MAIL_PARITY == 'true' or MAIL_RESTART_VERIFY == 'true' or SHOP_PARITY == 'true' or SHOP_RESTART_VERIFY == 'true' or GAMEPLAY_SHOPS_PARITY == 'true' or GAMEPLAY_SHOPS_RESTART_VERIFY == 'true' or WORLD_PARITY == 'true' or WORLD_RESTART_VERIFY == 'true' or DRAW_PARITY == 'true' or DRAW_RESTART_VERIFY == 'true' or GAMEPLAY_PARITY == 'true' or GAMEPLAY_RESTART_VERIFY == 'true' or YOULI_PARITY == 'true' or YOULI_RESTART_VERIFY == 'true' or FENGSHEN_STORY_PARITY == 'true' or FENGSHEN_STORY_RESTART_VERIFY == 'true' or ARENA_PARITY == 'true' or ARENA_RESTART_VERIFY == 'true' or XUNBAO_PARITY == 'true' or XUNBAO_RESTART_VERIFY == 'true' else [],
        'bagParity': {
            'status': 'Passed',
            'semanticCases': bag_semantic_cases
        } if BAG_PARITY == 'true' else None,
        'taskParity': {
            'status': 'Passed',
            'semanticCases': task_semantic_cases
        } if TASK_PARITY == 'true' or TASK_RESTART_VERIFY == 'true' else None,
        'playerHudParity': {
            'status': 'Passed',
            'semanticCases': playerhud_semantic_cases
        } if PLAYERHUD_PARITY == 'true' else None,
        'heroParity': {
            'status': 'Passed',
            'mode': 'runtime' if HERO_PARITY == 'true' else 'restart',
            'semanticCases': hero_semantic_cases
        } if HERO_PARITY == 'true' or HERO_RESTART_VERIFY == 'true' else None,
        'heroEquipParity': {
            'status': 'Passed',
            'mode': 'runtime' if HERO_EQUIP_PARITY == 'true' else 'restart',
            'semanticCases': hero_equip_semantic_cases
        } if HERO_EQUIP_PARITY == 'true' or HERO_EQUIP_RESTART_VERIFY == 'true' else None,
        'mailParity': {
            'status': 'Passed',
            'mode': 'runtime' if MAIL_PARITY == 'true' else 'restart',
            'semanticCases': mail_semantic_cases
        } if MAIL_PARITY == 'true' or MAIL_RESTART_VERIFY == 'true' else None,
        'shopParity': {
            'status': 'Passed',
            'mode': 'runtime' if SHOP_PARITY == 'true' else 'restart',
            'semanticCases': shop_semantic_cases
        } if SHOP_PARITY == 'true' or SHOP_RESTART_VERIFY == 'true' else None,
        'gameplayShopsParity': {
            'status': 'Passed',
            'mode': 'runtime' if GAMEPLAY_SHOPS_PARITY == 'true' else 'restart',
            'semanticCases': gameplay_shops_semantic_cases
        } if GAMEPLAY_SHOPS_PARITY == 'true' or GAMEPLAY_SHOPS_RESTART_VERIFY == 'true' else None,
        'worldParity': {
            'status': 'Passed',
            'mode': 'runtime' if WORLD_PARITY == 'true' else 'restart',
            'semanticCases': world_semantic_cases
        } if WORLD_PARITY == 'true' or WORLD_RESTART_VERIFY == 'true' else None,
        'drawParity': {
            'status': 'Passed',
            'mode': 'runtime' if DRAW_PARITY == 'true' else 'restart',
            'semanticCases': draw_semantic_cases
        } if DRAW_PARITY == 'true' or DRAW_RESTART_VERIFY == 'true' else None,
        'gameplayParity': {
            'status': 'Passed',
            'mode': 'runtime' if GAMEPLAY_PARITY == 'true' else 'restart',
            'semanticCases': gameplay_semantic_cases
        } if GAMEPLAY_PARITY == 'true' or GAMEPLAY_RESTART_VERIFY == 'true' else None,
        'youLiParity': {
            'status': 'Passed',
            'mode': 'runtime' if YOULI_PARITY == 'true' else 'restart',
            'semanticCases': youli_semantic_cases
        } if YOULI_PARITY == 'true' or YOULI_RESTART_VERIFY == 'true' else None,
        'fengShenStoryParity': {
            'status': 'Passed',
            'mode': 'runtime' if FENGSHEN_STORY_PARITY == 'true' else 'restart',
            'semanticCases': fengshen_story_semantic_cases
        } if FENGSHEN_STORY_PARITY == 'true' or FENGSHEN_STORY_RESTART_VERIFY == 'true' else None,
        'arenaParity': {
            'status': 'Passed',
            'mode': 'runtime' if ARENA_PARITY == 'true' else 'restart',
            'semanticCases': arena_semantic_cases
        } if ARENA_PARITY == 'true' or ARENA_RESTART_VERIFY == 'true' else None,
        'xunBaoParity': {
            'status': 'Passed',
            'mode': 'runtime' if XUNBAO_PARITY == 'true' else 'restart',
            'semanticCases': xunbao_semantic_cases
        } if XUNBAO_PARITY == 'true' or XUNBAO_RESTART_VERIFY == 'true' else None
    }
    parent = os.path.dirname(RESULT_PATH)
    if parent:
        os.makedirs(parent, exist_ok=True)
    temporary = RESULT_PATH + '.tmp'
    with open(temporary, 'w', encoding='utf-8', newline='\n') as output:
        json.dump(report, output, ensure_ascii=False, indent=2)
        output.write('\n')
    os.replace(temporary, RESULT_PATH)
"@

$python | & $PythonExecutable -
$pythonExitCode = $LASTEXITCODE
if ($null -eq $pythonExitCode -or $pythonExitCode -ne 0) {
  Write-Error "Protocol smoke Python runner failed with exit code $pythonExitCode"
  exit $(if ($null -eq $pythonExitCode) { 1 } else { $pythonExitCode })
}
