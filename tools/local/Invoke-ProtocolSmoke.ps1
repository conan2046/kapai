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
  [switch]$InvalidRisky
)

$autoCreateRoleText = if ($AutoCreateRole) { "true" } else { "false" }
if ($AutoCreateRole -and [string]::IsNullOrWhiteSpace($RoleName)) {
  $RoleName = "T" + (Get-Random -Minimum 10000 -Maximum 99999)
}
$extendedText = if ($Extended) { "true" } else { "false" }
$actionsText = if ($Actions) { "true" } else { "false" }
$mutationsText = if ($Mutations) { "true" } else { "false" }
$positiveText = if ($Positive) { "true" } else { "false" }
$invalidRiskyText = if ($InvalidRisky) { "true" } else { "false" }
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
INVALID_RISKY = "$invalidRiskyText"

def u8(v): return struct.pack('<B', v)
def u16(v): return struct.pack('<H', v)
def u32(v): return struct.pack('<I', v)
def s(v):
    data = (v or '').encode('utf-16le')
    return u16(len(data)) + data
def pkt(t, body=b''):
    return u32(len(body)) + u16(t) + body

recv_types = []
created_role_id = {'id': None}
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
                recv_types.append(msg_type)
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
        ('pet_all', 24, u8(1)),
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
        ('stage_award_1', 223, u8(2) + u8(1)),
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
        ('pet_equip_wear_bad', 319, u8(2) + u32(0) + u16(0)),
        ('pet_equip_takeoff_bad', 319, u8(3) + u32(0)),
        ('pet_equip_strong_bad', 319, u8(4) + u32(0)),
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
            raise RuntimeError('auto create role failed or timed out')
        role_to_select = created_role_id['id']
        print('created_role_id=' + str(role_to_select))
    sock.sendall(pkt(1004, u32(role_to_select)))
    if EXTENDED == 'true':
        smokes.append(('player_info_self', 34, u32(role_to_select)))
        smokes.append(('role_query_self', 248, u8(1) + s(str(role_to_select))))
    time.sleep(6.0 if AUTO_CREATE_ROLE == 'true' else 2.0)
    for name, t, body in smokes:
        sock.sendall(pkt(t, body))
        print(f'sent {name} type={t} body={len(body)}')
        time.sleep(0.2)
    time.sleep(4)
    stop_flag['stop'] = True
    time.sleep(0.2)

print('recv_count=' + str(len(recv_types)))
print('recv_types=' + ','.join(map(str, recv_types[:200])))
"@

$python | python -
