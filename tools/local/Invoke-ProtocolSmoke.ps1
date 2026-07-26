param(
  [string]$HostName = "127.0.0.1",
  [int]$Port = 8711,
  [int]$UserId = 1,
  [int]$RoleId = 1000001,
  [int]$ServerId = 1,
  [string]$Version = "102600",
  [switch]$AutoCreateRole,
  [string]$RoleName = "",
  [switch]$Extended,
  [switch]$Actions,
  [switch]$Mutations,
  [switch]$Positive,
  [switch]$Consumption,
  [switch]$Battle,
  [switch]$BattleListOnly,
  [switch]$UiQueries,
  [switch]$NpcFlow,
  [switch]$InvalidRisky,
  [int]$FriendApplyRoleId = 0,
  [int]$TeamPeerAcceptLeaderRoleId = 0,
  [int]$TeamPeerWaitSeconds = 120,
  [switch]$TeamProbe
)

$autoCreateRoleText = if ($AutoCreateRole) { "true" } else { "false" }
if ($AutoCreateRole -and [string]::IsNullOrWhiteSpace($RoleName)) {
  $RoleName = "T" + (Get-Random -Minimum 10000 -Maximum 99999)
}
$extendedText = if ($Extended) { "true" } else { "false" }
$actionsText = if ($Actions) { "true" } else { "false" }
$mutationsText = if ($Mutations) { "true" } else { "false" }
$positiveText = if ($Positive) { "true" } else { "false" }
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
$python = @"
import socket, struct, time, threading

HOST = "$HostName"
PORT = $Port
USER_ID = $UserId
ROLE_ID = $RoleId
SERVER_ID = $ServerId
VERSION = "$Version"
AUTO_CREATE_ROLE = "$autoCreateRoleText"
ROLE_NAME = "$RoleName"
GUILD_NAME = "G" + ROLE_NAME[1:] if len(ROLE_NAME) > 1 else "G10001"
EXTENDED = "$extendedText"
ACTIONS = "$actionsText"
MUTATIONS = "$mutationsText"
POSITIVE = "$positiveText"
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

def u8(v): return struct.pack('<B', v)
def u16(v): return struct.pack('<H', v)
def u32(v): return struct.pack('<I', v)
def s(v):
    data = (v or '').encode('utf-16le')
    return u16(len(data)) + data
def pkt(t, body=b''):
    return u32(len(body)) + u16(t) + body

recv_types = []
recv_bodies = {}
recv_events = []
created_role_id = {'id': None}
create_response = {'body': None}
battle_target = {'value': None}
fengshen_trial = {'value': None}
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
                if BATTLE == 'true' and msg_type == 161 and len(body) >= 4 and body[0:3] == b'\x00\x01\x01':
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

with socket.create_connection((HOST, PORT), timeout=3) as sock:
    th = threading.Thread(target=reader, args=(sock,), daemon=True)
    th.start()
    login_body = (
        u32(USER_ID) + s('local') + s(VERSION) + u32(SERVER_ID) +
        s('local_test') + s('') + s('') + s('')
    )
    sock.sendall(pkt(1001, login_body))
    time.sleep(1.0)
    role_to_select = ROLE_ID
    if AUTO_CREATE_ROLE == 'true':
        create_body = s(ROLE_NAME) + u8(0) + u8(5) + u8(5) + u16(1)
        sock.sendall(pkt(1003, create_body))
        deadline = time.time() + 3.0
        while time.time() < deadline and created_role_id['id'] is None:
            time.sleep(0.05)
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
        if BATTLE == 'true' and name == 'arena_fight_dynamic_robot':
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
        sock.sendall(pkt(t, body))
        print(f'sent {name} type={t} body={len(body)}')
        if BATTLE == 'true' and t == 161:
            time.sleep(1.0)
        else:
            time.sleep(0.5 if CONSUMPTION == 'true' and t in (47, 84, 177, 200, 216, 257, 309, 310, 332) else 0.2)
        if CONSUMPTION == 'true' and name.startswith('use_special_item_'):
            events = recv_events[event_start:]
            print('case_' + name + '=' + ','.join(str(mt) + ':' + mb.hex() for mt, mb in events))
    time.sleep(4)
    stop_flag['stop'] = True
    time.sleep(0.2)

print('recv_count=' + str(len(recv_types)))
print('recv_types=' + ','.join(map(str, recv_types[:200])))
for response_type in (321,):
    bodies = recv_bodies.get(response_type, [])
    print('response_' + str(response_type) + '=' + ','.join(body.hex() for body in bodies))
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
	if '体力丹'.encode('utf-16le') not in all_response_data:
		raise RuntimeError('stamina pill purchase did not return the expected item-name tip')
	print('stamina_pill_tip=ok')
if UI_QUERIES == 'true':
    for response_type in (32, 33, 46, 53, 68, 101, 110, 152, 153, 154, 160, 176, 189, 191, 201, 204, 213, 214, 222, 229, 304, 305, 306):
        bodies = recv_bodies.get(response_type, [])
        print('response_' + str(response_type) + '=' + ','.join(body.hex() for body in bodies))
    # Several entries intentionally use no-op branches and therefore have no response.
    required_ui_response_types = {46, 53, 68, 101, 152, 153, 154, 160, 201, 213, 222, 305}
    missing_ui_response_types = sorted(required_ui_response_types.difference(recv_types))
    if missing_ui_response_types:
        raise RuntimeError('missing required UI query responses: ' + ','.join(map(str, missing_ui_response_types)))
    trial_bodies = [body for body in recv_bodies.get(320, []) if len(body) >= 2 and body[0] == 21]
    if not trial_bodies or trial_bodies[-1][1] < 4:
        raise RuntimeError('fengshen trial response did not contain four tabs')
    print('fengshen_trial_count=' + str(trial_bodies[-1][1]))
if EXTENDED == 'true':
    required_response_types = {15, 40, 49, 51, 69, 100, 117, 178, 190, 199}
    missing_response_types = sorted(required_response_types.difference(recv_types))
    if missing_response_types:
        raise RuntimeError('missing required smoke responses: ' + ','.join(map(str, missing_response_types)))
if NPC_FLOW == 'true':
    required_npc_response_types = {12, 13, 14, 58}
    missing_npc_response_types = sorted(required_npc_response_types.difference(recv_types))
    if missing_npc_response_types:
        raise RuntimeError('missing required NPC flow responses: ' + ','.join(map(str, missing_npc_response_types)))
"@

$python | python -
$pythonExitCode = $LASTEXITCODE
if ($pythonExitCode -ne 0) {
  Write-Error "Protocol smoke Python runner failed with exit code $pythonExitCode"
  exit $pythonExitCode
}
