"""
timerd.py — the pomodoro daemon (skeleton).

Run this in the background; it owns the socket and the timer state.
The actual pomodoro logic is yours to build — I've stubbed the
command handling and left TODOs.

The one design idea you get for free, because it makes everything
else easy: DON'T count down with a loop. Just remember the moment
the timer should end (`end_time`). When anyone asks for status,
compute `end_time - now`. The daemon can then spend its whole life
blocked in serve(), doing nothing until a message arrives.

Run it:        python3 timerd.py
Stop it:       Ctrl+C, or send it a {"cmd": "quit"} if you add one.
"""

import datetime
import time

import bus

BREAK_MINUTES = 5

# --- timer state ------------------------------------------------------
state = {
    "end_time": None,       # float unix timestamp when current phase ends
    "phase": "idle",        # "idle" | "work" | "break" | "pause"
    "done_today": 0,        # completed pomodoros today
    "count_date": None,     # which calendar day done_today refers to
    # TODO: persist done_today to a small JSON file so a restart
    # doesn't wipe your count. json.dump on change, json.load at boot.
}


def remaining_seconds():
    """Seconds left, or 0 if idle/expired."""
    if state["end_time"] is None:
        return 0
    return max(0, int(state["end_time"] - time.time()))


def settle():
    """
    Bring the state up to date with reality. Called before answering
    any message.

    This is the heart of the "lazy" design: the daemon does nothing
    between messages, so time passes "unnoticed". Whenever someone
    asks us anything, we first check: did the current phase end while
    we weren't looking? If so, apply the consequences NOW.

    Because your toolbar polls every second, this runs every second
    anyway — but the daemon stays correct even if nobody asks for an
    hour. The state is always derived from timestamps, never from
    counting.
    """
    # Day rolled over? Reset the counter. (Compare dates, not times —
    # this triggers exactly once per calendar day.)
    today = datetime.date.today().isoformat()
    if state["count_date"] != today:
        state["count_date"] = today
        state["done_today"] = 0

    # Phase ended while we were idle-waiting?
    if state["end_time"] is not None and remaining_seconds() == 0:
        if state["phase"] == "work":
            # A pomodoro just completed: count it, roll into a break.
            state["done_today"] += 1
            state["phase"] = "break"
            state["end_time"] = time.time() + BREAK_MINUTES * 60
            # TODO: fire a desktop notification here so you notice
            # even without looking at the bar. Try:
            #   subprocess.run(["notify-send", "Pomodoro done!"])
        elif state["phase"] == "break":
            state["phase"] = "idle"
            state["end_time"] = None


# --- command handlers -------------------------------------------------

def handle(message):
    """
    This is the function the bus calls for every incoming message.
    Messages look like {"cmd": "start", "minutes": 25}.
    Whatever dict we return goes back to the client.
    """
    settle()  # catch up with any phase that ended since the last message
    cmd = message.get("cmd")

    if cmd == "start":
        if state["phase"] == "pause":
            # resume, at moment t2 (any amount later)
            end_time = time.time() + paused_remaining
            paused_remaining = None
        else:
            minutes = message.get("minutes", 25)
            state["end_time"] = time.time() + minutes * 60
            state["phase"] = "work"

    elif cmd == "stop":
        # Note: an abandoned pomodoro is NOT counted — purist rules.
        state["end_time"] = None
        state["phase"] = "idle"

    elif cmd == "pause":
        state["phase"] = "pause"
        # pause, at moment t1
        paused_remaining = end_time - time.time()
        end_time = None



    elif cmd != "status":
        # TODO: more commands? "pause", "skip", "reset_count"...
        return {"ok": False, "error": f"unknown command: {cmd!r}"}


    # Every command answers with the full current state. This keeps
    # the protocol boring: clients never need to ask twice.
    return {
        "ok": True,
        "phase": state["phase"],
        "remaining": remaining_seconds(),
        "done_today": state["done_today"],
    }


if __name__ == "__main__":
    bus.serve(bus.default_socket_path(), handle)
