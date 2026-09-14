#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
kapai 单机版 GM 后台 —— 本地 Web 控制台。

纯标准库实现(http.server), 无第三方依赖。
功能: 连接本地 LocalServer(默认 127.0.0.1:8711), 复用服务端 MSG_MGR 管理协议,
为指定 roleId 发放资源(通宝/等级/邮件), 并查询当前角色。

运行:
  python gm_web.py
启动后自动打开浏览器(可在 gm_config.ini 设 auto_open=0 关闭),
默认地址 http://127.0.0.1:8081 ; 端口被占用时会按 fallback_ports 自动换端口。
注意: 8080 已被 Unity MCP 占用, 不要改回 8080。

前提: 本地 LocalServer(kapai.exe) 已在运行且 local_test=1。
      进入 Unity Play(或启动 kapai.exe)后 LocalServer 自动监听 8711。
"""

import configparser
import html
import os
import socket
import sys
import webbrowser
from urllib.parse import unquote_plus
from http.server import BaseHTTPRequestHandler, HTTPServer

HERE = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(HERE, "gm_config.ini")

sys.path.insert(0, HERE)
import gm_client as gc  # noqa: E402


def load_cfg():
    cp = configparser.ConfigParser()
    cp.read(CONFIG_PATH, encoding="utf-8")
    return {
        "host": cp.get("server", "host", fallback="127.0.0.1"),
        "port": cp.getint("server", "port", fallback=8711),
        "server_id": cp.getint("server", "server_id", fallback=1),
        "account_id": cp.getint("gm", "account_id", fallback=1),
        "gm_user_id": cp.getint("gm", "gm_user_id", fallback=1),
        "gm_password": cp.get("gm", "gm_password", fallback="gm123456"),
        "listen_host": cp.get("web", "listen_host", fallback="127.0.0.1"),
        "listen_port": cp.getint("web", "listen_port", fallback=8081),
        "fallback_ports": cp.get("web", "fallback_ports", fallback="8088,18080,8899,9000,9527"),
        "auto_open": cp.getint("web", "auto_open", fallback=1),
    }


CFG = load_cfg()


def server_reachable(cfg, timeout=0.4):
    """快速探测 LocalServer(kapai.exe) 是否在监听, 用于页面状态灯。"""
    try:
        with socket.create_connection(
            (cfg.get("host", "127.0.0.1"), int(cfg.get("port", 8711))), timeout=timeout
        ):
            return True
    except Exception:
        return False


# 动作类型 -> (显示名, 风险提示)
ACTIONS = {
    "whoami":  ("查询当前在线存档角色(只读)", ""),
    "tongbao": ("加通宝/元宝(op1)", ""),
    "level":   ("改等级(op5)", ""),
    "mail":    ("发资源邮件(op15)", "本地单机无 server 间通道, 邮件不会真正投递; 仅记录 admin_log。"),
    "item":    ("加物品(op2)", "警告: 该指令会让 LocalServer 停止响应后续请求(需重开游戏), 请最后执行。"),
}

# 最近一次查询到的角色, 用于表单回填
LAST = {"role_id": None, "name": None, "level": None}


def read_int(fields, name, label, minimum, maximum, default=None):
    raw = fields.get(name, "")
    if raw in (None, "") and default is not None:
        raw = default
    try:
        value = int(raw)
    except (TypeError, ValueError):
        raise ValueError("%s 必须是数字" % label)
    if value < minimum or value > maximum:
        raise ValueError("%s 必须在 %s~%s 之间" % (label, minimum, maximum))
    return value


def validate_active_target(role_id):
    active_ok, active_info = gc.do_gm_whoami(CFG)
    active_login = active_info.get("login") or {}
    if not active_ok:
        return "无法校验当前在线存档: " + active_info.get("error", "未知错误")
    active_role_id = active_login.get("role_id")
    if active_role_id != role_id:
        return "已拦截: 目标 roleId=%s 不是当前在线存档角色 roleId=%s(%s)" % (
            role_id, active_role_id, active_login.get("role_name", ""))
    return None


def perform(action, fields):
    """执行一个 GM 动作, 返回 (ok, info_dict)。"""
    try:
        role_id = read_int(fields, "role_id", "role_id", 0, 0xFFFFFFFF, default=0)
    except ValueError as e:
        return False, {"error": str(e)}

    if action == "whoami":
        ok, info = gc.do_gm_whoami(CFG)
        lg = info.get("login") or {}
        if ok and lg.get("role_id"):
            LAST["role_id"] = lg.get("role_id")
            LAST["name"] = lg.get("role_name")
            LAST["level"] = lg.get("role_level")
        return ok, info

    if action == "mail":
        try:
            item_id = read_int(fields, "tmpl_id", "物品模板", 0, 0xFFFF)
            num = read_int(fields, "num", "物品数量", 0, 0x7FFFFFFF)
            money = read_int(fields, "money", "银两", 0, 0x7FFFFFFF)
            yb = read_int(fields, "yb", "元宝", 0, 0x7FFFFFFF)
        except ValueError as e:
            return False, {"error": str(e)}
        message = fields.get("message", "GM 发放") or "GM 发放"
        if role_id == 0:
            return False, {"error": "请先点「查询本机角色」获取 role_id"}
        if (item_id == 0) != (num == 0):
            return False, {"error": "物品模板与物品数量必须同时填写，或同时为 0"}
        if item_id == 0 and money == 0 and yb == 0:
            return False, {"error": "邮件至少需要一项大于 0 的资源"}
        target_error = validate_active_target(role_id)
        if target_error:
            return False, {"error": target_error}
        return gc.do_gm_action(
            CFG,
            lambda: gc.build_send_mail_body(role_id, item_id, num, money, yb, message),
        )

    if action == "tongbao":
        try:
            tongbao = read_int(fields, "tongbao", "通宝数量", 1, 0x7FFFFFFF)
            bangding = read_int(fields, "bangding", "绑定标记", 0, 1)
        except ValueError as e:
            return False, {"error": str(e)}
        if role_id == 0:
            return False, {"error": "请先点「查询本机角色」获取 role_id"}
        target_error = validate_active_target(role_id)
        if target_error:
            return False, {"error": target_error}
        return gc.do_gm_action(
            CFG,
            lambda: gc.build_add_currency_body(role_id, tongbao, bangding),
        )

    if action == "item":
        try:
            tmpl_id = read_int(fields, "tmpl_id", "物品模板", 1, 0xFFFF)
            num = read_int(fields, "num", "物品数量", 1, 0xFF)
            level = read_int(fields, "item_level", "物品等级", 0, 0xFF)
        except ValueError as e:
            return False, {"error": str(e)}
        if role_id == 0 or tmpl_id == 0:
            return False, {"error": "请填写目标 role_id 与物品模板 tmpl_id"}
        target_error = validate_active_target(role_id)
        if target_error:
            return False, {"error": target_error}
        return gc.do_gm_action(
            CFG,
            lambda: gc.build_add_item_body(role_id, tmpl_id, num, level),
        )

    if action == "level":
        try:
            level = read_int(fields, "level", "等级", 1, 0xFF)
        except ValueError as e:
            return False, {"error": str(e)}
        if role_id == 0:
            return False, {"error": "请先点「查询本机角色」获取 role_id"}
        target_error = validate_active_target(role_id)
        if target_error:
            return False, {"error": target_error}
        return gc.do_gm_action(
            CFG,
            lambda: gc.build_set_level_body(role_id, level),
        )

    if action == "selftest":
        return gc.do_gm_selftest(CFG)

    return False, {"error": "未知动作: %s" % action}


def page(current=None, result=None, notice=None):
    """渲染 HTML 页面。"""
    cfg = CFG
    msg_html = ""
    if result is not None:
        ok, info = result
        color = "#2e9e5b" if ok else "#d93434"
        text = info.get("info") or info.get("error") or ("成功" if ok else "失败")
        msg_html += ('<div style="margin:12px 0;padding:10px;border-left:4px solid %s;'
                     'background:#1b1f26;color:%s">%s</div>' % (
                         color, color, html.escape(str(text))))
    if notice:
        msg_html += ('<div style="margin:12px 0;padding:10px;border-left:4px solid #d99a2b;'
                     'background:#1b1f26;color:#e6b955">%s</div>' % html.escape(str(notice)))

    cur = current or "whoami"
    options = "".join(
        '<option value="%s"%s>%s</option>' % (k, " selected" if k == cur else "", v[0])
        for k, v in ACTIONS.items()
    )

    # 当前动作的风险提示
    risk = ACTIONS.get(cur, ("", ""))[1]
    risk_html = ""
    if risk:
        risk_html = ('<div style="margin:0 0 4px;padding:8px 10px;border-radius:6px;'
                     'background:#2a2216;color:#e6b955;font-size:12px">%s</div>'
                     % html.escape(risk))

    # 运行时状态灯
    if server_reachable(cfg):
        dot, scolor = "#2e9e5b", "#2e9e5b"
        stxt = "LocalServer %s:%s 已连接" % (cfg["host"], cfg["port"])
    else:
        dot, scolor = "#d93434", "#d93434"
        stxt = ("LocalServer %s:%s 未连接 — Unity Play 后还需在标题页选择新游戏/继续游戏并进入具体存档"
                % (cfg["host"], cfg["port"]))
    status_html = ('<div id="statuspill" style="display:inline-block;margin-bottom:16px;'
                   'padding:6px 12px;border:1px solid %s;border-radius:20px;font-size:13px;'
                   'color:%s"><span id="statusdot" style="display:inline-block;width:9px;'
                   'height:9px;border-radius:50%%;background:%s;margin-right:8px"></span>'
                   '<span id="statustext">%s</span></div>') % (
        scolor, scolor, dot, html.escape(stxt))
    # 状态灯每 3s 轮询 /status，避免「先开页面、后起服」导致一直显示未连接
    poll_js = """<script>
(function(){
  var HOST="%s", PORT=%s;
  function apply(ok){
    var pill=document.getElementById('statuspill'),
        dot=document.getElementById('statusdot'),
        txt=document.getElementById('statustext');
    if(!pill) return;
    var c = ok ? '#2e9e5b' : '#d93434';
    dot.style.background=c; pill.style.borderColor=c; pill.style.color=c;
    txt.textContent = ok
      ? ('LocalServer '+HOST+':'+PORT+' 已连接')
      : ('LocalServer '+HOST+':'+PORT+' 未连接 — Unity Play 后还需在标题页选择新游戏/继续游戏并进入具体存档');
  }
  function poll(){
    fetch('/status',{cache:'no-store'})
      .then(function(r){return r.json();})
      .then(function(d){apply(!!d.reachable);})
      .catch(function(){});
  }
  setInterval(poll, 3000); poll();
})();
</script>""" % (html.escape(str(cfg["host"])), int(cfg["port"]))

    role_html = ""
    if LAST["role_id"]:
        role_html = ('<div class="cfg" style="border:0;padding-top:0;margin-top:0">'
                     '已识别角色: roleId=%s · %s · Lv%s</div>' % (
                         LAST["role_id"], html.escape(str(LAST["name"] or "")),
                         LAST["level"]))

    tpl = """<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>kapai GM 后台</title>
<style>
body{font-family:-apple-system,"Microsoft YaHei",sans-serif;background:#0f1115;color:#e6e6e6;margin:0;padding:24px}
h1{font-size:20px;margin:0 0 4px}
.sub{color:#8b95a5;font-size:13px;margin-bottom:18px}
.card{background:#161a21;border:1px solid #232a35;border-radius:8px;padding:18px;max-width:640px}
label{display:block;margin:10px 0 4px;font-size:13px;color:#aab3c0}
input,select{width:100%;box-sizing:border-box;padding:8px;background:#0f1115;border:1px solid #2a3340;border-radius:6px;color:#e6e6e6;font-size:14px}
.row{display:flex;gap:10px}.row>div{flex:1}
button{margin-top:16px;width:100%;padding:10px;background:#2f6df0;border:0;border-radius:6px;color:#fff;font-size:15px;cursor:pointer}
button:hover{background:#2657c4}
.cfg{font-size:12px;color:#8b95a5;margin-top:14px;border-top:1px dashed #232a35;padding-top:10px}
</style></head><body>
<h1>kapai GM 后台(本地)</h1>
<div class="sub">复用服务端 MSG_MGR 协议 · 仅本机(LocalServer)可用 · 不进分发包</div>
__STATUS__
<div class="card">
<form method="post" action="/do">
  <input type="hidden" name="action" value="selftest">
  <button type="submit" style="background:#3a4250">连接自检（登录 + GM登录）</button>
</form>
<form method="post" action="/do" style="margin-top:14px">
  <label>操作类型</label>
  <select name="action">__OPTIONS__</select>
__RISK__
  <label>目标 role_id(角色ID)</label>
  <input name="role_id" value="__ROLE__" placeholder="先点选「查询当前在线存档角色」">
  __ROLEINFO__

  <div class="row">
    <div><label>通宝 tongbao(op1)</label><input name="tongbao" value="1000"></div>
    <div><label>绑定 0/1(op1)</label><input name="bangding" value="0"></div>
  </div>
  <div class="row">
    <div><label>等级 level(op5)</label><input name="level" value="100"></div>
    <div><label>物品模板 tmpl_id(op2/邮件)</label><input name="tmpl_id" value="0"></div>
  </div>
  <div class="row">
    <div><label>银两 money(邮件)</label><input name="money" value="0"></div>
    <div><label>元宝 yb(邮件)</label><input name="yb" value="0"></div>
  </div>
  <div class="row">
    <div><label>数量 num(邮件/物品)</label><input name="num" value="0"></div>
    <div><label>物品等级(op2)</label><input name="item_level" value="0"></div>
  </div>
  <label>邮件说明 message(邮件)</label>
  <input name="message" value="GM 发放">

  <button type="submit">执行 GM 指令</button>
</form>
__MSG__
</div>
<div class="cfg">
  连接: __CFGHOST__:__CFGPORT__ · server_id=__SERVERID__ · 登录账号id=__ACCT__ · GM账号id=__GMID__<br>
  op1 加通宝 → user_info1.money(游戏内元宝) ; op5 改等级 → role_info.level ; 两者都会写 admin_log。
</div>
__POLLJS__
</body></html>"""
    return (tpl
            .replace("__OPTIONS__", options)
            .replace("__RISK__", risk_html)
            .replace("__ROLE__", str(LAST["role_id"] or ""))
            .replace("__ROLEINFO__", role_html)
            .replace("__MSG__", msg_html)
            .replace("__STATUS__", status_html)
            .replace("__POLLJS__", poll_js)
            .replace("__CFGHOST__", html.escape(str(cfg["host"])))
            .replace("__CFGPORT__", str(cfg["port"]))
            .replace("__SERVERID__", str(cfg["server_id"]))
            .replace("__ACCT__", str(cfg["account_id"]))
            .replace("__GMID__", str(cfg["gm_user_id"])))


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # 静默

    def _send_html(self, text):
        data = text.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _render(self, current=None, result=None):
        try:
            return page(current=current, result=result)
        except Exception as e:
            return "<pre style='color:#ff6b6b'>GM 后台渲染错误: %s</pre>" % html.escape(str(e))

    def do_GET(self):
        if self.path.split("?")[0].rstrip("/") in ("/status", "/ping"):
            reach = server_reachable(CFG)
            data = ('{"reachable": %s, "host": "%s", "port": %d}'
                    % ("true" if reach else "false",
                       CFG["host"], int(CFG["port"]))).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        self._send_html(self._render())

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length).decode("utf-8", "replace")
        fields = {}
        for pair in raw.split("&"):
            if not pair:
                continue
            kv = pair.split("=", 1)
            k = unquote_plus(kv[0])
            v = unquote_plus(kv[1]) if len(kv) > 1 else ""
            fields[k] = v

        action = fields.get("action", "whoami")
        try:
            result = perform(action, fields)
        except Exception as e:
            result = (False, {"error": "执行异常: %s" % e})
        self._send_html(self._render(current=action, result=result))


def main():
    host = CFG["listen_host"]
    cands = [CFG["listen_port"]]
    for p in str(CFG.get("fallback_ports", "")).split(","):
        p = p.strip()
        if p.isdigit() and int(p) not in cands:
            cands.append(int(p))

    srv = None
    for p in cands:
        try:
            srv = HTTPServer((host, p), Handler)
            CFG["listen_port"] = p
            if p != cands[0]:
                print("端口 %s 不可用, 已自动改用 %s" % (cands[0], p))
            break
        except OSError as e:
            print("端口 %s 绑定失败: %s" % (p, e))
    if srv is None:
        print("所有候选端口均被占用, 请修改 gm_config.ini 的 listen_port / fallback_ports")
        return

    url = "http://%s:%s" % (host, CFG["listen_port"])
    print("kapai GM 后台已启动: %s" % url)
    print("LocalServer 目标: %s:%s  server_id=%s" % (CFG["host"], CFG["port"], CFG["server_id"]))
    if server_reachable(CFG):
        print("[OK] LocalServer 已在监听, 可直接执行 GM 指令。")
    else:
        print("[!] LocalServer 未监听 %s:%s —— Unity Play 后还需在标题页选择新游戏/继续游戏并进入具体存档。"
              % (CFG["host"], CFG["port"]))
    print("按 Ctrl+C 停止。")

    if CFG.get("auto_open"):
        try:
            webbrowser.open(url)
        except Exception as e:
            print("自动打开浏览器失败(可手动访问上面的地址): %s" % e)

    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\n已停止。")


if __name__ == "__main__":
    main()
