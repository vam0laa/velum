#!/usr/bin/env python3
"""Runs one stretch of the engine build and stops it in good order.

It stops ninja with SIGINT (never by force while the result is to be kept) when the time for
this stretch is over or when memory or disk come close to running out, and writes down why,
how far the build got and what it used.  Linux only, standard library only.
"""
import argparse
import glob
import json
import os
import re
import signal
import subprocess
import sys
import time

GIB = 1024 ** 3
TARGETS = ["QtWebEngineCore", "convert_dict", "webenginedriver_group"]


def meminfo():
    values = {}
    with open("/proc/meminfo") as f:
        for line in f:
            key, rest = line.split(":", 1)
            values[key] = int(rest.split()[0]) * 1024
    return values


def pressure():
    """Share of the last minute in which every task waited for memory, in percent."""
    try:
        with open("/proc/pressure/memory") as f:
            for line in f:
                if line.startswith("full"):
                    return float(re.search(r"avg60=([\d.]+)", line).group(1))
    except (OSError, AttributeError):
        pass
    return 0.0


def sample(path):
    m = meminfo()
    st = os.statvfs(path)
    return {
        "time": time.time(),
        "mem_total": m["MemTotal"],
        "mem_used": m["MemTotal"] - m["MemAvailable"],
        "mem_available": m["MemAvailable"],
        "swap_used": m["SwapTotal"] - m["SwapFree"],
        "swap_free": m["SwapFree"],
        "pressure": pressure(),
        "disk_free": st.f_bavail * st.f_frsize,
        "disk_used": (st.f_blocks - st.f_bfree) * st.f_frsize,
    }


def danger(s, limits, low_streak):
    if s["disk_free"] < limits["min_free_disk"]:
        return "disk", "free disk %.1f GiB under %.1f" % (s["disk_free"] / GIB, limits["min_free_disk"] / GIB)
    if s["mem_available"] + s["swap_free"] < limits["min_headroom"]:
        return "memory", "free RAM and swap together %.1f GiB" % ((s["mem_available"] + s["swap_free"]) / GIB)
    if s["swap_used"] > limits["max_swap_used"]:
        return "memory", "swap in use %.1f GiB" % (s["swap_used"] / GIB)
    if s["pressure"] > limits["max_pressure"]:
        return "memory", "stalled on memory %.0f%% of the last minute" % s["pressure"]
    if low_streak >= 6:
        return "memory", "RAM available under 1 GiB for a minute"
    return None


def inner_dir(build):
    """The folder in which the engine's own ninja works, once gn has written it."""
    for args in sorted(glob.glob(os.path.join(build, "src", "core", "*", "*", "args.gn"))):
        d = os.path.dirname(args)
        if os.path.exists(os.path.join(d, "build.ninja")):
            return d
    return None


def remaining(directory, targets):
    """How many steps ninja would still run, or -1 when that cannot be told."""
    if not directory:
        return -1
    env = dict(os.environ, NINJA_STATUS="[%f/%t] ")
    wanted = list(targets)
    while True:
        r = subprocess.run(["ninja", "-C", directory, "-n"] + wanted, capture_output=True, text=True, env=env)
        if r.returncode == 0:
            break
        unknown = re.search(r"unknown target '([^']+)'", r.stderr)
        if unknown and unknown.group(1) in wanted and len(wanted) > 1:
            wanted.remove(unknown.group(1))
            continue
        sys.stderr.write(r.stdout[-2000:] + r.stderr[-2000:])
        return -1
    if "no work to do" in r.stdout:
        return 0
    total = re.search(r"^\[\d+/(\d+)\] ", r.stdout, re.M)
    return int(total.group(1)) if total else -1


def session_members(sid):
    found = []
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        try:
            with open("/proc/%s/stat" % entry) as f:
                fields = f.read().rsplit(")", 1)[1].split()
        except OSError:
            continue
        if fields[0] != "Z" and int(fields[3]) == sid:
            found.append(int(entry))
    return found


def signal_session(sid, sig):
    for pid in session_members(sid):
        try:
            os.kill(pid, sig)
        except ProcessLookupError:
            pass


def make_expendable():
    # if the kernel has to kill something, it should be a compiler, not the runner's agent
    try:
        with open("/proc/self/oom_score_adj", "w") as f:
            f.write("800")
    except OSError:
        pass
    os.nice(5)


def announce(context, state, text):
    """A commit status can be read while the job runs, and survives the loss of the machine."""
    if not (context and os.environ.get("GH_TOKEN") and os.environ.get("GITHUB_SHA")):
        return
    try:
        subprocess.run(["gh", "api", "repos/%s/statuses/%s" % (os.environ["GITHUB_REPOSITORY"], os.environ["GITHUB_SHA"]),
                        "-f", "state=" + state, "-f", "context=" + context, "-f", "description=" + text[:140]],
                       capture_output=True, timeout=30)
    except (OSError, subprocess.TimeoutExpired):
        pass


def brief(s, steps):
    return "%s UTC, step %s, disk free %.0fG, RAM %.1fG, swap %.1fG" % (
        time.strftime("%H:%M", time.gmtime(s["time"])), steps or "-",
        s["disk_free"] / GIB, s["mem_used"] / GIB, s["swap_used"] / GIB)


def last_step(log):
    try:
        with open(log, "rb") as f:
            f.seek(0, os.SEEK_END)
            f.seek(max(0, f.tell() - 65536))
            found = re.findall(rb"^\[(\d+/\d+)\]", f.read(), re.M)
        return found[-1].decode() if found else ""
    except OSError:
        return ""


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--build", required=True)
    p.add_argument("--count", action="store_true", help="only print how many steps the inner ninja has left")
    p.add_argument("--state", help="folder for report.json, build.log and usage.csv")
    p.add_argument("--minutes", type=float)
    p.add_argument("--status-context", default="")
    p.add_argument("--command", action="append", help="JSON list; given once for each phase, in order")
    p.add_argument("--target", action="append", help="targets counted in the inner folder")
    p.add_argument("--inner", help="inner ninja folder (found under the build folder if left out)")
    p.add_argument("--interval", type=float, default=10)
    p.add_argument("--grace", type=float, default=600)
    p.add_argument("--min-free-disk", type=float, default=25)
    p.add_argument("--min-headroom", type=float, default=3)
    p.add_argument("--max-swap-used", type=float, default=7)
    p.add_argument("--max-pressure", type=float, default=30)
    a = p.parse_args()
    if a.count:
        print(remaining(a.inner or inner_dir(a.build), a.target or TARGETS))
        return 0
    if not (a.state and a.minutes and a.command):
        p.error("--state, --minutes and --command are needed")

    limits = {"min_free_disk": a.min_free_disk * GIB, "min_headroom": a.min_headroom * GIB,
              "max_swap_used": a.max_swap_used * GIB, "max_pressure": a.max_pressure}
    targets = a.target or TARGETS
    os.makedirs(a.state, exist_ok=True)
    log_path = os.path.join(a.state, "build.log")
    child_env = {k: v for k, v in os.environ.items() if k not in ("GH_TOKEN", "GITHUB_TOKEN")}

    started = time.time()
    deadline = started + a.minutes * 60
    first = sample(a.build)
    peak = {"mem_used": 0, "swap_used": 0, "disk_used": 0, "pressure": 0.0}
    min_free = first["disk_free"]
    remaining_before = remaining(a.inner or inner_dir(a.build), targets)
    reason, detail, forced, phases_done = None, "", False, 0
    interrupted_at = None
    low_streak = 0
    next_note = 0

    stop_asked = []
    for sig in (signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, lambda *_: stop_asked.append(True))

    usage = open(os.path.join(a.state, "usage.csv"), "w")
    usage.write("time,mem_used,swap_used,pressure,disk_free,step\n")

    with open(log_path, "ab") as log:
        for raw in a.command:
            if reason:
                break
            proc = subprocess.Popen(json.loads(raw), stdout=log, stderr=subprocess.STDOUT, env=child_env,
                                    start_new_session=True, preexec_fn=make_expendable)
            sid = proc.pid
            while proc.poll() is None or (interrupted_at and session_members(sid)):
                s = sample(a.build)
                for key in peak:
                    peak[key] = max(peak[key], s[key])
                min_free = min(min_free, s["disk_free"])
                low_streak = low_streak + 1 if s["mem_available"] < GIB else 0
                step = last_step(log_path)
                usage.write("%d,%d,%d,%.1f,%d,%s\n" % (s["time"], s["mem_used"], s["swap_used"], s["pressure"], s["disk_free"], step))
                usage.flush()
                if time.time() >= next_note:
                    announce(a.status_context, "pending", brief(s, step))
                    print(brief(s, step), flush=True)
                    next_note = time.time() + 600
                if not interrupted_at:
                    found = danger(s, limits, low_streak)
                    if stop_asked:
                        found = ("cancelled", "the job was asked to stop")
                    elif not found and time.time() >= deadline:
                        found = ("time", "the %g minutes of this stretch are over" % a.minutes)
                    if found:
                        reason, detail = found
                        interrupted_at = time.time()
                        print("stopping: %s (%s)" % (reason, detail), flush=True)
                        announce(a.status_context, "pending", "stopping: %s, %s" % (detail, brief(s, step)))
                        signal_session(sid, signal.SIGINT)
                elif time.time() - interrupted_at > a.grace:
                    forced = True
                    signal_session(sid, signal.SIGKILL)
                time.sleep(a.interval)
            rc = proc.wait()
            if reason:
                break
            if rc != 0:
                reason, detail = "error", "a build command ended with %d" % rc
                oom = subprocess.run("sudo -n dmesg 2>/dev/null | grep -ci 'out of memory'", shell=True,
                                     capture_output=True, text=True).stdout.strip()
                if oom not in ("", "0"):
                    reason, detail = "memory", "the kernel killed a process for lack of memory (%s notes)" % oom
                break
            phases_done += 1
    usage.close()

    if not reason:
        reason, detail = "done", "all commands finished"
    last = sample(a.build)
    for key in peak:
        peak[key] = max(peak[key], last[key])
    directory = a.inner or inner_dir(a.build)
    remaining_after = remaining(directory, targets)
    report = {
        "reason": reason,
        "detail": detail,
        "forced_kill": forced,
        "started": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime(started)),
        "ended": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
        "phases_done": phases_done,
        "phases": len(a.command),
        "last_step": last_step(log_path),
        "inner_dir": directory or "",
        "remaining_before": remaining_before,
        "remaining_after": remaining_after,
        "peak_ram_gib": round(peak["mem_used"] / GIB, 2),
        "ram_total_gib": round(first["mem_total"] / GIB, 2),
        "peak_swap_gib": round(peak["swap_used"] / GIB, 2),
        "peak_memory_stall_pct": peak["pressure"],
        "peak_disk_used_gib": round(peak["disk_used"] / GIB, 1),
        "lowest_disk_free_gib": round(min(min_free, last["disk_free"]) / GIB, 1),
        "end_disk_free_gib": round(last["disk_free"] / GIB, 1),
    }
    with open(os.path.join(a.state, "report.json"), "w") as f:
        json.dump(report, f, indent=1)
    print(json.dumps(report, indent=1))
    announce(a.status_context, "success" if reason in ("time", "done") else "failure",
             "%s, left %s, min disk %.0fG, peak RAM %.1fG swap %.1fG" % (
                 reason, remaining_after, report["lowest_disk_free_gib"], report["peak_ram_gib"], report["peak_swap_gib"]))
    # the caller decides from the report; only a broken supervisor makes this step fail
    return 0


if __name__ == "__main__":
    sys.exit(main())
