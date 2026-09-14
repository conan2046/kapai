#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
kapai 单机版 GM 后台 —— 服务端管理协议(MsgMgr) 客户端。

协议来源(已在服务端源码逐行核实):
  server/src/gyu/g_net_msg.h / g_net_msg.cpp     -> CNetMessage 二进制报文
  server/src/gyu/g_socket_server.cpp:184-250    -> 收包/粘包解析
  server/src/main.cpp:702-703                   -> 编码与头长设置
  server/src/pack_deal.cpp:780  UserLogin       -> 登录
  server/src/pack_deal.cpp:11394 ServerMgr      -> GM 管理协议(op 1/2/5/11/15/16/...)

线格式
------
帧头 6 字节(main.cpp:703 `SetMsgMaxLenSize(MMS_4Byte)` -> headLen=6, typeBegin=4):
    [uint32 LE bodyLen][uint16 LE msgType][body...]      bodyLen = len(body)
字符串(main.cpp:702 `SetNetMsgEncodeType(MET_Unicode)` -> g_net_msg.cpp:299-352):
    [uint16 LE 字节数][UTF-16LE 字节]                    长度是字节数, 不是字符数
整数一律小端。

登录流程(local_test=1 无需口令):
  1) PRO_USER_LOGIN(1001): 服务端据 id/serverId 建号或取号, 返回 userId/roleId/角色简表
  2) MSG_MGR(0xfffe) op 11: `select userId,pwd from admin where userId=? and pwd=MD5(?)`
     成功后 pUser->SetAdminLevel(ADMIN_LEVEL); op 1/2/5 均要求该权限
     登录失败只返回错误，不会自动修改 admin 表或 GM 口令。
     旧槽位必须显式执行 docs/gm-backend/migrate_admin.py 后再登录。
  3) MSG_MGR(0xfffe) op 21: 查询当前在线存档角色
  4) MSG_MGR(0xfffe) op 15/1/2/5: 发资源(邮件/通宝/道具/等级)

响应格式
--------
  op 11 : [uint8 2][uint8 1=成功|2=失败][string 失败原因]
  其他   : [uint16 op][string retMsg]   (op 15/16 的 retMsg 为空串)

注意: 这些 GM op 仅在本地 LocalServer(默认 127.0.0.1:8711) 有效, 且为开发者工具,
不进游戏分发包。
"""

import socket
import struct

MSG_MGR = 0xFFFE
PRO_USER_LOGIN = 1001
PRO_SUCCESS = 1

HEADER_LEN = 6
LEN_SIZE = 4
STR_ENCODING = "utf-16-le"
TIMEOUT = 8.0


def require_range(name: str, value: int, minimum: int, maximum: int) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError("%s must be an integer" % name)
    if value < minimum or value > maximum:
        raise ValueError("%s must be between %s and %s" % (name, minimum, maximum))
    return value


# --------------------------------------------------------------------------
# 底层编解码
# --------------------------------------------------------------------------

def pack_string(s: str) -> bytes:
    """[uint16 LE 字节数][UTF-16LE 字节]。"""
    data = (s or "").encode(STR_ENCODING)
    if len(data) > 0xFFFF:
        raise ValueError("string too long for uint16 byte-length prefix")
    return struct.pack("<H", len(data)) + data


def read_string(data: bytes, pos: int):
    """读一个编码字符串, 返回 (str, 新位置)。"""
    if pos + 2 > len(data):
        return "", pos
    slen = struct.unpack("<H", data[pos:pos + 2])[0]
    pos += 2
    raw = data[pos:pos + slen]
    return raw.decode(STR_ENCODING, "replace"), pos + slen


def build_message(msg_type: int, body: bytes) -> bytes:
    """完整报文: 6 字节头(uint32 bodyLen + uint16 msgType) + body。"""
    return struct.pack("<IH", len(body), msg_type & 0xFFFF) + body


def _recv_exact(sock: socket.socket, n: int) -> bytes:
    buf = b""
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise ConnectionError("connection closed by peer before full read")
        buf += chunk
    return buf


def send_recv(sock: socket.socket, msg_type: int, body: bytes,
              expect_reply: bool = True, timeout: float = TIMEOUT):
    """发送一条报文; expect_reply=True 时读取并解析一条完整响应。"""
    sock.settimeout(timeout)
    sock.sendall(build_message(msg_type, body))
    if not expect_reply:
        return None
    header = _recv_exact(sock, HEADER_LEN)
    body_len = struct.unpack("<I", header[:LEN_SIZE])[0]
    msg_type_back = struct.unpack("<H", header[LEN_SIZE:HEADER_LEN])[0]
    body_data = _recv_exact(sock, body_len) if body_len > 0 else b""
    return msg_type_back, body_data


# --------------------------------------------------------------------------
# 请求 body 构造 (字段顺序逐一对齐 pack_deal.cpp)
# --------------------------------------------------------------------------

def build_login_body(account_id: int, server_id: int,
                     signature: str = "", version: str = "0",
                     net_info: str = "", mac: str = "", imei: str = "",
                     idfa: str = "") -> bytes:
    # pack_deal.cpp:789  msg>>id>>signature>>version>>serverId>>netInfo>>mac>>IMEI>>IDFA
    return (
        struct.pack("<I", require_range("account_id", account_id, 1, 0xFFFFFFFF))
        + pack_string(signature)
        + pack_string(version)
        + struct.pack("<i", require_range("server_id", server_id, 1, 0x7FFFFFFF))
        + pack_string(net_info)
        + pack_string(mac)
        + pack_string(imei)
        + pack_string(idfa)
    )


def build_gm_login_body(user_id: int, pwd: str) -> bytes:
    # ServerMgr(op 11): msg>>userId(uint32)>>pwd(string)
    return (struct.pack("<H", 11)
            + struct.pack("<I", require_range("user_id", user_id, 1, 0xFFFFFFFF))
            + pack_string(pwd))


def build_send_mail_body(role_id: int, item_id: int, num: int,
                         money: int, yb: int, message: str) -> bytes:
    # ServerMgr(op 15): roleId(uint32) itemId(uint16) num(int) money(int) YB(int) message(string)
    return (
        struct.pack("<H", 15)
        + struct.pack("<I", require_range("role_id", role_id, 1, 0xFFFFFFFF))
        + struct.pack("<H", require_range("item_id", item_id, 0, 0xFFFF))
        + struct.pack("<i", require_range("num", num, 0, 0x7FFFFFFF))
        + struct.pack("<i", require_range("money", money, 0, 0x7FFFFFFF))
        + struct.pack("<i", require_range("yb", yb, 0, 0x7FFFFFFF))
        + pack_string(message)
    )


def build_add_currency_body(role_id: int, tongbao: int, bangding: int) -> bytes:
    # ServerMgr(op 1): roleId(uint32) tongbao(int) bangDing(uint8)
    return (
        struct.pack("<H", 1)
        + struct.pack("<I", require_range("role_id", role_id, 1, 0xFFFFFFFF))
        + struct.pack("<i", require_range("tongbao", tongbao, 1, 0x7FFFFFFF))
        + struct.pack("<B", require_range("bangding", bangding, 0, 1))
    )


def build_add_item_body(role_id: int, tmpl_id: int, num: int, level: int) -> bytes:
    # ServerMgr(op 2): roleId(uint32) tmplId(uint16) num(uint8) level(uint8)
    return (
        struct.pack("<H", 2)
        + struct.pack("<I", require_range("role_id", role_id, 1, 0xFFFFFFFF))
        + struct.pack("<H", require_range("tmpl_id", tmpl_id, 1, 0xFFFF))
        + struct.pack("<B", require_range("num", num, 1, 0xFF))
        + struct.pack("<B", require_range("level", level, 0, 0xFF))
    )


def build_set_level_body(role_id: int, level: int) -> bytes:
    # ServerMgr(op 5): roleId(uint32) level(uint8)
    return (struct.pack("<H", 5)
            + struct.pack("<I", require_range("role_id", role_id, 1, 0xFFFFFFFF))
            + struct.pack("<B", require_range("level", level, 1, 0xFF)))


def build_active_role_body() -> bytes:
    # ServerMgr(op 21): 无其他字段，返回当前唯一在线存档角色。
    return struct.pack("<H", 21)


# --------------------------------------------------------------------------
# 响应解析
# --------------------------------------------------------------------------

def parse_login_reply(body: bytes):
    """PRO_USER_LOGIN 响应(pack_deal.cpp:1055-1077):
    PRO_SUCCESS(u8) inKuafu(u8) userId(u32)
      roleId>0 时: roleId(int) name(string) head(u8) level(u16) sex(u8)
      roleId==0 时: roleId(u32)=0
    """
    if not body:
        return {"ok": False, "error": "空响应"}
    if body[0] != PRO_SUCCESS:
        err, _ = read_string(body, 1)
        return {"ok": False, "error": err or "登录失败"}
    result = {"ok": True, "user_id": 0, "role_id": 0}
    if len(body) < 6:
        return {"ok": False, "error": "响应截断"}
    result["in_kuafu"] = body[1]
    result["user_id"] = struct.unpack("<I", body[2:6])[0]
    if len(body) < 10:
        return result
    role_id = struct.unpack("<i", body[6:10])[0]
    if role_id <= 0:
        return result
    result["role_id"] = role_id
    name, pos = read_string(body, 10)
    result["role_name"] = name
    if pos + 1 <= len(body):
        result["role_head"] = body[pos]; pos += 1
    if pos + 2 <= len(body):
        result["role_level"] = struct.unpack("<H", body[pos:pos + 2])[0]; pos += 2
    if pos + 1 <= len(body):
        result["role_sex"] = body[pos]
    return result


def parse_gm_login_reply(body: bytes):
    """op 11 响应(pack_deal.cpp:11595-11598):
    [u8 2][u8 1=成功|2=失败][string 失败原因]
    """
    if len(body) < 2:
        return {"ok": False, "error": "空响应"}
    if body[0] == 2 and body[1] == 1:
        return {"ok": True, "info": "GM 登录成功(已获得 ADMIN_LEVEL)"}
    err = ""
    if len(body) > 4:
        err, _ = read_string(body, 2)
    return {"ok": False, "error": err or "GM 登录失败(admin 表账号/口令不匹配)"}


def gm_login_ok(body: bytes) -> bool:
    """兼容旧调用。"""
    return parse_gm_login_reply(body).get("ok", False)


def parse_mgr_reply(body: bytes):
    """通用管理响应(pack_deal.cpp:11790-11793): [uint16 op][string retMsg]。"""
    if len(body) < 2:
        return {"op": None, "msg": ""}
    op = struct.unpack("<H", body[:2])[0]
    msg, _ = read_string(body, 2)
    return {"op": op, "msg": msg}


# --------------------------------------------------------------------------
# 高层封装: 一次动作 = 连接 -> 登录 -> GM登录 -> 执行 op -> 关闭
# --------------------------------------------------------------------------

def _connect(cfg):
    host = cfg.get("host", "127.0.0.1")
    port = int(cfg.get("port", 8711))
    return socket.create_connection((host, port), timeout=TIMEOUT)


def _login_and_gm(sock, cfg):
    """登录 + GM 登录。失败时不修改数据库或口令。"""
    _, body = send_recv(sock, PRO_USER_LOGIN,
                        build_login_body(int(cfg.get("account_id", 1)),
                                         int(cfg.get("server_id", 1))))
    login = parse_login_reply(body)
    if not login.get("ok"):
        return False, "账号登录失败: %s" % login.get("error"), login

    gm_user = int(cfg.get("gm_user_id", 1))
    pwd = cfg.get("gm_password", "gm123456")
    _, gm_body = send_recv(sock, MSG_MGR, build_gm_login_body(gm_user, pwd))
    gm = parse_gm_login_reply(gm_body)
    if not gm.get("ok"):
        return False, ("GM 登录失败: %s。请核对 gm_config.ini，旧存档先显式运行 "
                       "docs/gm-backend/migrate_admin.py" % gm.get("error")), login
    return True, gm.get("info", ""), login


def _prefix(login):
    if login.get("role_id"):
        return "[userId=%s roleId=%s %s Lv%s] " % (
            login.get("user_id"), login.get("role_id"),
            login.get("role_name", ""), login.get("role_level", "?"))
    return "[userId=%s 无角色] " % login.get("user_id")


def do_gm_action(cfg: dict, build_op_body, expect_reply: bool = True):
    """完成一次 GM 操作。返回 (ok, info)。"""
    try:
        sock = _connect(cfg)
    except Exception as e:
        return False, {"error": "无法连接 LocalServer(%s:%s): %s。Unity Play 后还需在标题页选择新游戏/继续游戏并进入具体存档。"
                                % (cfg.get("host"), cfg.get("port"), e)}
    try:
        ok, text, login = _login_and_gm(sock, cfg)
        pre = _prefix(login)
        if not ok:
            return False, {"error": pre + text}

        try:
            request_body = build_op_body()
            if len(request_body) < 2:
                return False, {"error": pre + "GM 请求缺少 op"}
            expected_op = struct.unpack("<H", request_body[:2])[0]
            reply = send_recv(sock, MSG_MGR, request_body,
                              expect_reply=expect_reply)
        except socket.timeout:
            return False, {"error": pre + "服务端未响应该指令(超时) —— 常见原因: "
                                        "GM 权限未生效, 或该 op 无回复"}
        if reply is None:
            return True, {"info": pre + "指令已发送(不等待回复)"}
        msg_type, body = reply
        if msg_type != MSG_MGR:
            return False, {"error": pre + "响应类型不匹配: expected=%s actual=%s"
                                    % (MSG_MGR, msg_type)}
        parsed = parse_mgr_reply(body)
        if parsed["op"] != expected_op:
            return False, {"error": pre + "响应 op 不匹配: expected=%s actual=%s"
                                    % (expected_op, parsed["op"])}
        result_text = parsed["msg"] or ""
        if result_text.startswith("OK|"):
            return True, {"info": pre + result_text[3:]}
        if result_text.startswith("ERR|"):
            return False, {"error": pre + result_text[4:]}
        return False, {"error": pre + "服务端未返回可验证结果(op=%s): %s"
                                % (expected_op, result_text or "空响应")}
    except Exception as e:
        return False, {"error": "通信异常: %s" % e}
    finally:
        try:
            sock.close()
        except Exception:
            pass


def do_gm_whoami(cfg: dict):
    """只读: 返回当前唯一已进入存档的在线角色。"""
    try:
        sock = _connect(cfg)
    except Exception as e:
        return False, {"error": "无法连接 LocalServer(%s:%s): %s。Unity Play 后还需在标题页选择新游戏/继续游戏并进入具体存档。"
                                % (cfg.get("host"), cfg.get("port"), e)}
    try:
        ok, text, _ = _login_and_gm(sock, cfg)
        if not ok:
            return False, {"error": text}
        msg_type, body = send_recv(sock, MSG_MGR, build_active_role_body())
        if msg_type != MSG_MGR:
            return False, {"error": "在线角色查询响应类型错误"}
        parsed = parse_mgr_reply(body)
        if parsed["op"] != 21:
            return False, {"error": "在线角色查询响应 op 错误"}
        result = parsed["msg"] or ""
        if result.startswith("ERR|"):
            return False, {"error": result[4:]}
        fields = result.split("|", 4)
        if len(fields) != 5 or fields[0] != "OK" or fields[1] != "ACTIVE":
            return False, {"error": "服务端未返回可验证的在线角色"}
        try:
            role_id = int(fields[2])
            role_level = int(fields[3])
        except ValueError:
            return False, {"error": "服务端返回的在线角色数据无效"}
        login = {
            "ok": True,
            "role_id": role_id,
            "role_level": role_level,
            "role_name": fields[4],
        }
        info = "当前在线存档 · roleId=%s · %s · Lv%s" % (
            role_id, fields[4], role_level)
        return True, {"info": info, "login": login}
    except Exception as e:
        return False, {"error": "通信异常: %s" % e}
    finally:
        try:
            sock.close()
        except Exception:
            pass


def do_gm_selftest(cfg: dict):
    """仅做 登录 + GM登录, 返回连通性与 GM 账号校验结果(不发任何资源)。"""
    try:
        sock = _connect(cfg)
    except Exception as e:
        return False, {"error": "无法连接 LocalServer(%s:%s): %s。Unity Play 后还需在标题页选择新游戏/继续游戏并进入具体存档。"
                                % (cfg.get("host"), cfg.get("port"), e)}
    try:
        ok, text, login = _login_and_gm(sock, cfg)
        pre = _prefix(login)
        if not ok:
            return False, {"error": pre + text}
        return True, {"info": pre.rstrip() + " · 连通正常 · " + text}
    except Exception as e:
        return False, {"error": "通信异常: %s" % e}
    finally:
        try:
            sock.close()
        except Exception:
            pass


if __name__ == "__main__":
    cfg = {"host": "127.0.0.1", "port": 8711, "server_id": 1,
           "account_id": 1, "gm_user_id": 1, "gm_password": "gm123456"}
    print(do_gm_selftest(cfg))
