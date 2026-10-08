import argparse
import json
import socket
import struct
import time
from pathlib import Path


USER_ID = 7200057
ROLE_ID = 1000003
NOTICE_TITLE = "Unity Login SQLite Notice validation"
NOTICE_MESSAGE = "W8 SQLite /88 authority fixture"


def pack_string(value: str) -> bytes:
    encoded = value.encode("utf-16le")
    return struct.pack("<H", len(encoded)) + encoded


def receive_exact(sock: socket.socket, size: int) -> bytes:
    chunks = bytearray()
    while len(chunks) < size:
        chunk = sock.recv(size - len(chunks))
        if not chunk:
            raise RuntimeError("server closed the socket before a complete frame arrived")
        chunks.extend(chunk)
    return bytes(chunks)


def send_packet(sock: socket.socket, protocol: int, body: bytes = b"") -> None:
    sock.sendall(struct.pack("<IH", len(body), protocol) + body)


def receive_protocol(sock: socket.socket, protocol: int, timeout: float) -> bytes:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        sock.settimeout(max(0.05, deadline - time.monotonic()))
        header = receive_exact(sock, 6)
        body_length, message_type = struct.unpack("<IH", header)
        body = receive_exact(sock, body_length)
        if message_type == protocol:
            return body
    raise TimeoutError(f"timed out waiting for protocol {protocol}")


def parse_notices(body: bytes) -> list[dict]:
    if not body:
        raise RuntimeError("PRO_GONGGAO/88 response body is empty")
    count = body[0]
    cursor = 1
    records = []
    for _ in range(count):
        fields = []
        for _ in range(2):
            if cursor + 2 > len(body):
                raise RuntimeError("PRO_GONGGAO/88 string length is truncated")
            byte_length = struct.unpack_from("<H", body, cursor)[0]
            cursor += 2
            end = cursor + byte_length
            if end > len(body):
                raise RuntimeError("PRO_GONGGAO/88 string data is truncated")
            fields.append(body[cursor:end].decode("utf-16le"))
            cursor = end
        if cursor + 2 > len(body):
            raise RuntimeError("PRO_GONGGAO/88 display flags are truncated")
        records.append({
            "title": fields[0],
            "message": fields[1],
            "showType": body[cursor],
            "jumpType": body[cursor + 1],
        })
        cursor += 2
    if cursor != len(body):
        raise RuntimeError("PRO_GONGGAO/88 response contains unread trailing bytes")
    return records


def run(host: str, port: int) -> dict:
    with socket.create_connection((host, port), timeout=5) as sock:
        login = (
            struct.pack("<I", USER_ID)
            + pack_string("local")
            + pack_string("102600")
            + struct.pack("<I", 1)
            + pack_string("local_test")
            + pack_string("")
            + pack_string("")
            + pack_string("")
        )
        send_packet(sock, 1001, login)
        login_response = receive_protocol(sock, 1001, timeout=5)
        if len(login_response) < 10 or login_response[0] != 1:
            raise RuntimeError(f"PRO_USER_LOGIN/1001 failed: {login_response.hex()}")
        response_user_id, response_role_id = struct.unpack_from("<II", login_response, 2)
        if (response_user_id, response_role_id) != (USER_ID, ROLE_ID):
            raise RuntimeError(
                f"fixed identity mismatch: user={response_user_id}, role={response_role_id}"
            )

        send_packet(sock, 1004, struct.pack("<I", ROLE_ID))
        select_response = receive_protocol(sock, 1004, timeout=5)
        if not select_response or select_response[0] != 1:
            raise RuntimeError(f"PRO_SELECT_ROLE/1004 failed: {select_response.hex()}")

        send_packet(sock, 88)
        notice_response = receive_protocol(sock, 88, timeout=5)
        notices = parse_notices(notice_response)
        matching = [
            notice for notice in notices
            if notice["title"] == NOTICE_TITLE and notice["message"] == NOTICE_MESSAGE
        ]
        if len(matching) != 1:
            raise RuntimeError(
                f"expected one authoritative SQLite notice, found {len(matching)}; "
                f"received_titles={[item['title'] for item in notices]}"
            )
        return {
            "status": "passed",
            "backend": "isolated-sqlite",
            "userId": response_user_id,
            "roleId": response_role_id,
            "requestProtocol": 88,
            "responseProtocol": 88,
            "noticeCount": len(notices),
            "matchingNotice": matching[0],
        }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8711)
    parser.add_argument("--evidence", required=True)
    args = parser.parse_args()
    result = run(args.host, args.port)
    result["checkedUtc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    evidence_path = Path(args.evidence)
    evidence_path.parent.mkdir(parents=True, exist_ok=True)
    evidence_path.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
