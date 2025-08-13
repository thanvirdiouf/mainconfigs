#!/usr/bin/env python3
# ~/.config/waybar/scripts/cpu_info.py
# Outputs JSON with text and tooltip. Text: overall CPU% and average temp.
# Tooltip: per-core usage and per-core temps.
import time, re, subprocess, json

def read_cpu():
    with open('/proc/stat') as f:
        line = f.readline()
    parts = line.split()[1:]
    parts = list(map(int, parts))
    idle = parts[3] + parts[4] if len(parts) > 4 else parts[3]
    total = sum(parts)
    return idle, total

def cpu_percent(interval=0.5):
    idle1, total1 = read_cpu()
    time.sleep(interval)
    idle2, total2 = read_cpu()
    idle = idle2 - idle1
    total = total2 - total1
    usage = (1.0 - idle/total) * 100.0 if total>0 else 0.0
    return usage

def per_core_usage(interval=0.5):
    # read /proc/stat lines for cpuN
    def snapshot():
        stats = {}
        with open('/proc/stat') as f:
            for line in f:
                if line.startswith('cpu') and line[3].isdigit():
                    parts = line.split()
                    cpu = parts[0]
                    vals = list(map(int, parts[1:]))
                    stats[cpu] = (sum(vals), vals[3])  # total, idle
        return stats
    s1 = snapshot()
    time.sleep(interval)
    s2 = snapshot()
    info = {}
    for cpu in s1:
        t1, idle1 = s1[cpu]
        t2, idle2 = s2.get(cpu, (t1, idle1))
        total = t2 - t1
        idle = idle2 - idle1
        percent = (1.0 - idle/total) * 100.0 if total>0 else 0.0
        info[cpu] = percent
    return info

def temps():
    # use sensors output, look for "Core N:  +xx.x°C"
    out = subprocess.run(['sensors'], capture_output=True, text=True).stdout if subprocess.run(['which','sensors'], capture_output=True).returncode==0 else ""
    cores = {}
    for line in out.splitlines():
        m = re.search(r'Core\s*(\d+):\s*\+?([0-9]+\.[0-9])', line)
        if m:
            cores[int(m.group(1))] = float(m.group(2))
    # try average temp
    avg = None
    if cores:
        avg = sum(cores.values())/len(cores)
    return cores, avg

def main():
    overall = cpu_percent()
    cores_usage = per_core_usage()
    cores_temp, avg_temp = temps()
    avg_temp_display = f"{avg_temp:.1f}°C" if avg_temp else "n/a"
    text = f" {overall:.0f}% {avg_temp_display}"
    # Tooltip lines: per-core usage and temp
    lines = []
    for i, (cpu, u) in enumerate(sorted(cores_usage.items(), key=lambda x:x[0])):
        t = cores_temp.get(i)
        tstr = f"{t:.1f}°C" if t else "n/a"
        lines.append(f"{cpu}: {u:.0f}% / {tstr}")
    tooltip = "\n".join(lines) if lines else "No per-core data"
    print(json.dumps({"text": text, "tooltip": tooltip}))

if __name__ == '__main__':
    main()

