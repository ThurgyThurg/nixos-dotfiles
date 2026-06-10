"""
bus.py — a tiny message bus over a Unix domain socket.

A Unix domain socket is like a network socket, but instead of an
IP address + port, the "address" is a path on your filesystem.
Only programs on this machine can connect to it, which is exactly
what we want for a toolbar talking to a local timer.

The protocol is deliberately simple:

    client sends:   one JSON object, terminated by a newline
    server replies: one JSON object, terminated by a newline
    connection closes.

That "one request, one reply, hang up" style is easy to reason
about and impossible to get into a weird half-broken state.

There are only two functions you need:

    serve(path, handler)  -> run forever, calling handler(msg) for
                             each incoming message dict. Whatever
                             dict the handler returns is the reply.

    send(path, msg)       -> connect, send msg dict, return reply dict.

Everything else in this file is plumbing.
"""

import json
import os
import socket


def default_socket_path(name="pomo"):
    """
    Pick a sensible place for the socket file.

    XDG_RUNTIME_DIR (usually /run/user/<uid>) is the standard spot
    for per-user runtime files on Linux. It's owned by you and gets
    cleaned up on logout. We fall back to /tmp if it's not set.
    """
    base = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    return os.path.join(base, f"{name}.sock")


def _recv_line(sock):
    """
    Read from a socket until we see a newline (or the other side
    hangs up). Sockets give you bytes in unpredictable chunks, so
    you always need a loop like this — recv(4096) means "give me
    UP TO 4096 bytes", not "give me exactly one message".
    """
    chunks = []
    while True:
        chunk = sock.recv(4096)
        if not chunk:                 # other side closed the connection
            break
        chunks.append(chunk)
        if chunk.endswith(b"\n"):     # got the full message
            break
    return b"".join(chunks)


def _send_line(sock, obj):
    """Serialize a dict to JSON, add the newline, send all of it."""
    sock.sendall(json.dumps(obj).encode("utf-8") + b"\n")


def send(socket_path, message, timeout=2.0):
    """
    Send one message to the server and return its reply (a dict).

    Raises ConnectionRefusedError / FileNotFoundError if the server
    isn't running — callers can catch that to say "timer not running".
    """
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(timeout)         # don't hang forever if server is stuck
        s.connect(socket_path)
        _send_line(s, message)
        data = _recv_line(s)
        if not data:
            raise ConnectionError("server closed connection without replying")
        return json.loads(data)


def serve(socket_path, handler):
    """
    Run the server loop forever.

    `handler` is a function you write: it takes the incoming message
    (a dict) and returns the reply (a dict). If it raises an exception,
    we catch it and send back an error reply instead of crashing —
    a server should survive one bad request.
    """
    # If a previous run crashed, the old socket file is still lying
    # around and bind() would fail. Remove it first.
    if os.path.exists(socket_path):
        os.unlink(socket_path)

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
        server.bind(socket_path)
        os.chmod(socket_path, 0o600)  # only your user can talk to it
        server.listen()
        print(f"listening on {socket_path}")

        while True:
            conn, _addr = server.accept()   # blocks until a client connects
            with conn:
                data = _recv_line(conn)
                if not data:
                    continue                # client connected and bailed
                try:
                    message = json.loads(data)
                    reply = handler(message)
                    if not isinstance(reply, dict):
                        reply = {"ok": False, "error": "handler returned non-dict"}
                except Exception as e:
                    reply = {"ok": False, "error": f"{type(e).__name__}: {e}"}
                try:
                    _send_line(conn, reply)
                except BrokenPipeError:
                    pass                    # client gave up waiting; fine
