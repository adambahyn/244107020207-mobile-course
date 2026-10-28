import json
import subprocess
import urllib.request
import zipfile
import io

REPO = "adambahyn/244107020207-mobile-course"
API = f"https://api.github.com/repos/{REPO}"
tok = [l.split("=", 1)[1].strip() for l in subprocess.run(
    ["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n",
    capture_output=True, text=True).stdout.splitlines() if l.startswith("password=")][0]


def get(path, raw=False):
    req = urllib.request.Request(API + path,
                                headers={"Authorization": f"Bearer {tok}",
                                         "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        data = r.read()
        return data if raw else json.loads(data)


runs = get("/actions/runs?per_page=10")["workflow_runs"]
bad = [r for r in runs if r["conclusion"] == "failure"][0]
print("run", bad["id"], bad["head_branch"], bad["head_sha"][:8])
jobs = get(f"/actions/runs/{bad['id']}/jobs")["jobs"]
for j in jobs:
    print("job", j["id"], j["name"], j["conclusion"])
    for s in j["steps"]:
        print("  step", s["number"], s["name"], s["conclusion"])
try:
    raw = get(f"/actions/jobs/{jobs[0]['id']}/logs", raw=True)
    try:
        z = zipfile.ZipFile(io.BytesIO(raw))
        text = "\n".join(z.read(n).decode("utf-8", "replace") for n in z.namelist())
    except zipfile.BadZipFile:
        text = raw.decode("utf-8", "replace")
    tail = [l for l in text.splitlines() if l.strip()][-25:]
    print("---- log tail ----")
    print("\n".join(tail))
except Exception as e:
    print("log error", e)