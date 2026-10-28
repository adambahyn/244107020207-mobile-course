import json
import subprocess
import urllib.request

REPO = "adambahyn/244107020207-mobile-course"
API = f"https://api.github.com/repos/{REPO}"
tok = [l.split("=", 1)[1].strip() for l in subprocess.run(
    ["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n",
    capture_output=True, text=True).stdout.splitlines() if l.startswith("password=")][0]


def get(path):
    req = urllib.request.Request(API + path,
                                headers={"Authorization": f"Bearer {tok}",
                                         "Accept": "application/vnd.github+json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read())


runs = get("/actions/runs?per_page=10")["workflow_runs"]
lines = ["# Bukti CI (GitHub Actions)", ""]
for r in runs:
    lines.append(f"- {r['name']} · event `{r['event']}` · branch `{r['head_branch']}` "
                 f"· status `{r['status']}` · hasil `{r['conclusion']}` · {r['html_url']}")
r = runs[0]
jobs = get(f"/actions/runs/{r['id']}/jobs")["jobs"]
for j in jobs:
    lines.append(f"- job `{j['name']}`: `{j['conclusion']}` "
                 f"({j['steps'][-1]['name']})")
open("docs/ci-run.txt", "w", encoding="utf-8").write("\n".join(lines) + "\n")
print("\n".join(lines))