#!/usr/bin/env python3
"""Exercise docs PR updates against disposable Git remotes; gh never uses the network."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("update-supported-kubernetes.sh").resolve()
MANIFEST = "packages/docs/src/data/supported-kubernetes-versions.json"
BRANCH = "automation/supported-kubernetes-versions"


def run(*args, cwd=None, env=None):
    return subprocess.run(args, cwd=cwd, env=env, text=True, capture_output=True, check=True).stdout.strip()


class DocsUpdates(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.remote = self.root / "remote.git"
        self.main = self.root / "main"
        run("git", "init", "--bare", str(self.remote))
        run("git", "init", "-b", "main", str(self.main))
        run("git", "config", "user.name", "Maintainer", cwd=self.main)
        run("git", "config", "user.email", "maintainer@example.test", cwd=self.main)
        self.write(self.main, ["1.36", "1.35", "1.34"])
        run("git", "add", ".", cwd=self.main)
        run("git", "commit", "-m", "Initial docs", cwd=self.main)
        run("git", "remote", "add", "origin", str(self.remote), cwd=self.main)
        run("git", "push", "origin", "main", cwd=self.main)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        gh = self.bin / "gh"
        gh.write_text("""#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
with open(os.environ["GH_LOG"], "a") as log:
    log.write(json.dumps(args) + "\\n")
if args[:2] == ["label", "list"]:
    if os.environ.get("LABEL_LOOKUP_FAIL"):
        sys.exit(1)
    print(os.environ.get("LABELS", "version-bump"))
elif args[:2] == ["pr", "list"]:
    print(os.environ.get("EXISTING_PR", ""))
elif args[:2] == ["pr", "create"]:
    print("https://github.com/kedify/marketing/pull/123")
if "--body-file" in args:
    Path(os.environ["BODY_LOG"]).write_text(Path(args[args.index("--body-file") + 1]).read_text())
""")
        gh.chmod(0o755)
        self.log = self.root / "gh.log"
        self.summary = self.root / "summary.md"
        self.invocations = 0

    def write(self, repo, minors):
        path = repo / MANIFEST
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(minors, indent=2) + "\n")

    def update(self, minors=None, existing="", check=True, **extra_env):
        work = self.root / f"writer-{self.invocations}"
        self.invocations += 1
        run("git", "clone", "--branch", "main", str(self.remote), str(work))
        self.log.write_text("")
        self.summary.write_text("")
        env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                   GH_LOG=str(self.log), BODY_LOG=str(self.root / "body.md"),
                   EXISTING_PR=existing, RUNNER_TEMP=str(self.root),
                   GITHUB_STEP_SUMMARY=str(self.summary), CHART_VERSION="v0.8.3",
                   SOURCE_SHA="a" * 40, RUN_URL="https://github.com/kedify/charts/actions/runs/123",
                   SUPPORTED_KUBERNETES_VERSIONS=json.dumps(minors or ["1.37", "1.36", "1.35"]))
        env.update(extra_env)
        result = subprocess.run(["bash", str(SCRIPT), str(work)], env=env, text=True, capture_output=True)
        if check:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def tip(self):
        return run("git", "rev-parse", f"refs/heads/{BRANCH}", cwd=self.remote)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def pending(self, minors, human=False):
        run("git", "switch", "-c", BRANCH, cwd=self.main)
        self.write(self.main, minors)
        run("git", "add", MANIFEST, cwd=self.main)
        env = dict(os.environ, GIT_AUTHOR_NAME="Kedify Bot", GIT_AUTHOR_EMAIL="kedifybot@kedify.io",
                   GIT_COMMITTER_NAME="Kedify Bot",
                   GIT_COMMITTER_EMAIL="human@example.test" if human else "kedifybot@kedify.io")
        run("git", "commit", "-m", "Pending support update", cwd=self.main, env=env)
        run("git", "push", "origin", BRANCH, cwd=self.main)
        run("git", "switch", "main", cwd=self.main)

    def test_creates_minor_only_labeled_pr(self):
        self.update()
        values = json.loads(run("git", "show", f"{BRANCH}:{MANIFEST}", cwd=self.remote))
        self.assertEqual(values, ["1.37", "1.36", "1.35"])
        create = next(call for call in self.calls() if call[:2] == ["pr", "create"])
        self.assertEqual(create[create.index("--label") + 1], "version-bump")
        self.assertIn("Signed-off-by: Kedify Bot <kedifybot@kedify.io>",
                      run("git", "log", "-1", "--format=%B", BRANCH, cwd=self.remote))
        self.assertIn("v0.8.3", (self.root / "body.md").read_text())
        self.assertIn("/pull/123", self.summary.read_text())

    def test_creates_missing_label(self):
        self.update(LABELS="")
        self.assertTrue(any(call[:2] == ["label", "create"] for call in self.calls()))

    def test_label_lookup_failure_stops_pr_writes(self):
        result = self.update(check=False, LABEL_LOOKUP_FAIL="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual([call[:2] for call in self.calls()], [["label", "list"]])

    def test_retry_updates_existing_pr_without_duplicate_commit(self):
        self.update()
        tip = self.tip()
        self.update(existing="https://github.com/kedify/marketing/pull/123")
        self.assertEqual(self.tip(), tip)
        self.assertTrue(any(call[:2] == ["pr", "edit"] for call in self.calls()))
        self.assertFalse(any(call[:2] == ["pr", "create"] for call in self.calls()))

    def test_refreshes_after_base_changes(self):
        self.update()
        (self.main / "other.md").write_text("New main commit\n")
        run("git", "add", ".", cwd=self.main)
        run("git", "commit", "-m", "Advance main", cwd=self.main)
        run("git", "push", "origin", "main", cwd=self.main)
        self.update(existing="https://github.com/kedify/marketing/pull/123")
        run("git", "merge-base", "--is-ancestor", "main", BRANCH, cwd=self.remote)

    def test_does_not_downgrade_main(self):
        self.update(["1.35", "1.34", "1.33"])
        self.assertEqual(self.calls(), [])
        self.assertIn("already current", self.summary.read_text())

    def test_does_not_downgrade_pending_pr(self):
        self.pending(["1.38", "1.37", "1.36"])
        tip = self.tip()
        self.update()
        self.assertEqual(self.tip(), tip)
        self.assertEqual(self.calls(), [])
        self.assertIn("newer", self.summary.read_text())

    def test_rejects_human_committer(self):
        self.pending(["1.37", "1.36", "1.35"], human=True)
        tip = self.tip()
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.tip(), tip)
        self.assertEqual(self.calls(), [])
        self.assertIn("other edits", result.stderr)

    def test_rejects_other_file_edits(self):
        self.pending(["1.37", "1.36", "1.35"])
        run("git", "switch", BRANCH, cwd=self.main)
        (self.main / "human.md").write_text("Preserve me\n")
        run("git", "add", ".", cwd=self.main)
        env = dict(os.environ, GIT_AUTHOR_EMAIL="kedifybot@kedify.io", GIT_COMMITTER_EMAIL="kedifybot@kedify.io")
        run("git", "commit", "-m", "Other edits", cwd=self.main, env=env)
        run("git", "push", "origin", BRANCH, cwd=self.main)
        result = self.update(check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_rejects_patch_or_nonconsecutive_versions(self):
        for values in [["1.37.0", "1.36", "1.35"], ["1.37", "1.35", "1.34"], ["1.37"]]:
            with self.subTest(values=values):
                result = self.update(values, check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.calls(), [])


if __name__ == "__main__":
    unittest.main()
