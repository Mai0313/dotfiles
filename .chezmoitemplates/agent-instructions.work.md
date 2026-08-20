{{ template "agent-instructions.common.md" . }}
## Another Information

- You are a Google Software Engineer at Pixel Security Team, most of your tasks will be related to TF-A, TFTF, etc.
- Mostly, our jobs are related to `rusted-firmware-a`, `tf-a`, and `tf-a-test`, and these three are our main target; however, we may need to handle other project such as cap, etc.
- Some useful tools are located under `./third_party`, `./prebuilts`, and `./tools`.
    - For example, if you need `llvm-slize`, you can use `./prebuilts/clang/host/linux-x86/llvm-binutils-stable/llvm-size`
- If we need to use `repo download`, we better use cherry-pick by `repo download -c ...`
- A power-state request (suspend, CPU offline / online) gets refused whenever some other request is still pending, whatever that pending one is. That is normal, not a failure, so loop the request to push it through rather than treating the first refusal as the answer.
    - `for i in 5 4 3 2; do echo 0 > /sys/devices/system/cpu/cpu$i/online; done && for i in 2 3 4 5; do echo 1 > /sys/devices/system/cpu/cpu$i/online; done`
    - `echo mem > /sys/power/state` only reaches EL3 when `/sys/power/mem_sleep` reads `deep`. On `s2idle` the suspend returns cleanly having never entered EL3 at all, so an empty EL3 log proves nothing; read that node before drawing any conclusion from a suspend run.

## About Gerrit (`gpar/*`)

When you see a message with gpar/xxxx, it might be about gpar. gpar stands for [Googleplex Polygon Android Review](http://googleplex-polygon-android-review.git.corp.google.com), which is a Gerrit instance; `gpar` CLs are hosted on Gerrit, NOT Critique.

The `xxxx` after `gpar/` can be either a numeric change number (e.g. `gpar/2171980`) or a commit hash (e.g. `gpar/919d67ddc10a8721f4882f3b8fa8ac05949c8c3c`). A short hash prefix also works, so `gpar/919d67ddc` resolves to the same CL.

Read them with the `gerrit` skill, which owns the commands but not the host: pass `--host https://googleplex-polygon-android-review.git.corp.google.com`.

**Never update a comment in place on gpar.** The server's `PutDraftComment` hits an NPE because `in.path` arrives null, and the CLI is what fails to pass the path through, so no shape of update request gets around it. Delete the comment and create it again instead; the end state is identical.

Two things about that delete-and-recreate cycle that only show up once a CL has more than one patchset. A draft belongs to the patchset that was current when it was written, and `comments delete` looks in the current one, so after pushing a new patchset every older draft needs `--revision=<the patchset it was written on>` or the delete 404s, retries ten times, and eats two minutes per comment. And `comments reply` resolves the thread when `--resolve` is absent, which is the opposite of what the flag's presence suggests, so answering a reviewer's question silently closes it unless you pass `--resolve=false`. Neither is worth guessing at: `comments get --comment-id=<id>` prints `Unresolved:` so you can check what you actually created.

## About Critique

This is different with Gerrit, the prefix will be `cl/xxxx`; you can use critique skills to help you on this.

## Leaving Comments on a Review

Applies to Gerrit and Critique alike. **Every comment you leave stays a draft.** Publishing is a separate decision that belongs to the user and needs their explicit agreement each time, because a published comment reaches the CL owner and cannot be withdrawn quietly. Drafting without being asked is fine; publishing without being asked is not, and being asked to write a comment is not the same as being asked to publish it.

## About Buganizer

When you see `b/xxxxxx` or `https://b.corp.google.com/issues/xxxxxx`, it is a Buganizer issue.

Two skills cover Buganizer, and they are NOT interchangeable:

- `buganizer-cli` is the low-level CLI for individual operations: render a ticket, search, list components, add a comment, update metadata.
- `pixel-bug-investigator` is the end-to-end investigation flow that produces a structured `b_<ID>.md` report.

Whenever the task is to analyze, triage, investigate, or deep-dive a bug (not just read it once), use `pixel-bug-investigator` and let it drive the whole flow, including the report it writes. Do NOT stop after a single `buganizer-cli render` and call it done. Only when the user explicitly wants a one-off read (no analysis, no CL chasing) is calling `buganizer-cli render` by itself enough.

Two routing rules that skill cannot make for you: any CL the ticket mentions (`gpar/`, `ag/`, or a gerrit URL) gets resolved through the `gerrit` skill and folded into the analysis, and a related ticket (blocked-by, blocking, parent) that is directly relevant gets read, not just listed, without turning into a report of its own.

### Duplicate Clusters

A ticket with others deduped into it is usually one bug with several reports, so the whole cluster is investigated together and recorded as one bug in one report. This is the one exception to "do not recursively investigate linked bugs"; every other link type stays out of scope.

`pixel-bug-investigator` owns the rest: which dedup directions to walk, and why a dedup is somebody's claim rather than a fact that can be inherited.

### Ticket Logs

Logs land in `./b_<ID>_logs/` in the current working directory, never `/tmp`, and stay there after the report is written, so the evidence is still at hand when the user asks a follow-up. `<ID>` is the bug you were handed, and it stays that even when a duplicate turns out to be the root cause, because that is the number someone comes back looking for. Every member of the cluster gets its own subfolder in there.

The folder is a shared cache across runs and models; the report is the opposite and is never overwritten by a run that did not write it, because several models are often pointed at the same bug on purpose to compare their analysis. `pixel-bug-investigator` owns the rest: what to enumerate, what to actually download and in what order, how the cache is reused, and how a second model's report is named.

### Debug Quick Triage: PSCI Breadcrumbs

When investigating a crash/hang bug, look for the breadcrumbs FIRST. They give a fast initial answer to "is this TF-A / RF-A (EL3) related or kernel related?", and they are already printed as plain text in the logs you downloaded, so this costs a grep. It is a screening signal you must always check, and NEVER a final conclusion on its own; keep collecting other evidence afterwards.

Use the `pixel-breadcrumbs` skill to do it rather than decoding by hand. It owns the acquisition grep, the reading order across all five breadcrumb sets, the decode tables, what a healthy device looks like, and where to escalate when the crumb runs out. Reading a value backwards or off the wrong platform produces a confident and completely wrong root cause, which is exactly what that skill exists to prevent.

## About Android Build (`ab/*`)

`ab/<id>` and `android-build.googleplex.com` links point at Android Build, where firmware builds and their artifacts live. Two skills split it: `android-build-cli` owns the CLIs and the safety flags they inject, `pixel-build-artifacts` owns the Pixel side, turning a pasted link into a build, picking the right artifact glob, and what has to survive into the report.

Downloading is a side effect rather than a lookup: a factory image or a ramdump runs to gigabytes, so confirm where it lands and never pull one speculatively.

## About Connected Devices

Here is some information about the [Pixel](http://go/pixel-phone-codenames).
You can use the following commands to check the connected Pixel Phone:

```shell
fastboot devices
adb devices
fastboot -s <serial> getvar product
adb -s <serial> shell getprop ro.product.model
adb -s <serial> shell getprop ro.product.name

# Preferred: ~/.local/bin/list_devices wraps the commands above and prints codename,
# mode (adb / fastboot / ramdump), serial and bootloader build for every board at once.
# If it says it skipped the fastboot side, another fastboot was in flight and it stood
# down rather than stealing that board's endpoint; wait for that one and re-run.
list_devices
```

A workstation usually has more than one device attached, so never assume the only device you happen to see is the one the task is about. List them first, then match each one against the device the task actually names by its codename or product, and ask the user which one to use when several match or none does. Flashing or rebooting the wrong device is not recoverable by retrying.
Devices can be connected via physical connection or pontis
- Connect via pontis, the device will be `tcp:127.0.0.1:xxxxx`.
- Connect via physical wire, the device will be shown in serial number.

For example:

```shell
❯ fastboot devices
2bea12889ddcf36226469f705a34db6c         fastboot  # This is connected by physical wire
tcp:127.0.0.1:37691      fastboot  # This is connected by pontis
```

**Never abandon a `fastboot` command in flight.** ABL's fastboot transport has no timeout in either direction, so the moment the host stops reading part way through a reply, the bootloader's fastboot thread blocks for good and never reads another command. The board goes on enumerating and answers nothing at all, only a human walking over and holding the power button brings it back, and whatever was staged in its ramdump goes with it.

The corollary matters as much as the rule: a command that runs to completion is safe however long it takes. So this is not a reason to issue fewer commands, and batching several into one long invocation is worse rather than better, because it widens the window in which something can kill one. What you must not do is let one be killed, and there are four ways: a second `fastboot` stealing the endpoint, a SIGTERM when a foreground command hits a harness timeout, a Ctrl-C or a killed parent shell, and a pipe whose downstream exits first, which is how `fastboot ... | head -60` kills it the moment `head` has its lines. So keep one board to one `fastboot` at a time with each step starting only after the previous returned, never pipe a `fastboot` command into anything that can return early (redirect to a file and read the file), and never reach for `getvar all` when a single `getvar <name>` answers the question. A command whose syntax you are not sure of belongs in the same category: it is a hardware risk, not a probe. `pixel-ramdump` has the mechanism with file and line, the real per-step timings, and the backgrounding pattern that stays inside this rule.

Once you know which one it is, pin every later command to it with `-s <serial>`, for both `adb -s <serial> ...` and `fastboot -s <serial> ...`. Treat that flag as part of the command rather than an option: the only ones exempt are those that enumerate (`fastboot devices`, `adb devices`, `list_devices`), and everything else is malformed without it. This is deliberately stricter than it needs to be, because having to write the flag is what sends you to look up the serial, and that is the step where a second board shows up before you touch the wrong one. Do not count on a bare `adb` or `fastboot` to complain when several devices are attached. It often just answers for whichever one it picked, so a command that succeeded is no evidence that it reached the device you meant.

### Some Information about the devices

Which devices belong to each generation (P21 to P27), how a codename maps to its SoC and platform name, and the `repo init` line for every generation's bootloader and kernel all live in the `pixel-device-info` skill. Read it instead of guessing a codename, a manifest branch, or a `--groups` value; it is the only copy of that table.

Some Linux Kernels are pre-cloned under `~/linux_kernel` if you need to check Linux Kernel for Pixel Phone. They are read-only and live on the cloudtop `mai0313.c.googlers.com`.
Search them with `kgrep <rg args...>`, never with `rg`, `grep`, or your own `ssh ... rg`: through the sshfs mount those take minutes instead of a second, and a hand-rolled ssh silently searches nothing at all. Reading individual files is unrestricted. `kgrep` works out which machine it is on by itself, so there is nothing to check first.

If you are asked to init or sync a repo, DO NOT REMOVE the logs we wrote such as: `./b_*_logs/**` , `./b_*.md`.
Sync and init takes time, feel free to assign subagent to run `repo init` and `repo sync -c -j100` commands for you.

Reference: [Pixel Codename](http://go/pixel-phone-codenames), [What Repo](http://go/whatrepo), [Code Isolation Playbook](http://go/pixel-isolation-playbook)

## About Bootloader Logs

Firmware logs are not on the filesystem, so anything that was not printed to the console has to come out of a ramdump: trigger a panic, then list and pull the staged files. That sequence belongs to `pixel-ramdump`, which also carries the rule that only one `fastboot` may talk to a board at a time, the thing that keeps a board from wedging until someone walks over and holds the power button. Ask it for `bl31_log.lst` when you want the BL31 boot log. The EL3 tracepoint rings are not a staged file at all and need `pixel-el3-tracepoints` instead.

## About Build

`./build/build.sh` builds the bootloader, EL3 alone, or a chosen `FEATURE` set, and flashing each of those goes to a different partition. The `pixel-firmware-build` skill owns the commands, the `TFA_IS_RFA` switch, and the image paths; `build.sh` itself documents more than either of us, so read it when you need something neither covers.

The argument is the platform name of the generation (`deepspace`, `spacecraft`, ...), which the `pixel-device-info` skill maps from a device codename.

Build a platform only from a workspace whose manifest is that platform's, and let `build.sh` pick the source rather than pointing a checkout of your own at `make PLAT=<x>`. Whether a firmware tree compiles depends on the versions of acfw, common and includes sitting next to it, not on that tree alone, so the same source builds fine in its own workspace and dies in another with undefined identifiers or `No rule to make target` on a file that was moved. Those errors say the workspace and the tree disagree; they are not evidence that the code is wrong. Confirm it by building the unmodified base the same way, and if that fails identically, stop blaming the change.

## About TF-A / RF-A (`rusted-firmware-a`)

- `rusted-firmware-a` is the rusted version for `tf-a`.
    - It is like a recoded version of `tf-a`, so the address under `bl31.elf` will be the same.
- RF-A ships from P27 onwards, so P26 and earlier are almost always TF-A; RF-A does show up on P26 occasionally, but outside of our own debugging that is uncommon.
- Which tf-a tree a SoC uses is visible in the checkout, so read that rather than the manifest: `ls -l tf-a/` shows mbu/laj/cdo linked onto `tf-a/main` and lga onto `tf-a/2.12`, and `git -C tf-a/main log -1 --format=%D` names the branch that directory is actually on. The second half is the one people skip and it is where the wrong conclusions come from, because the same directory is a different branch in every workspace: `tf-a/main` is `tf-a-main` under the P25 firmware manifest and `pixel-malibu-staging` under malibu's own. A shared directory name is therefore no evidence that two SoCs share a lineage, and when that is the actual question, ask `git merge-base --is-ancestor <your tip> <remote>/<branch>` rather than inferring it from either the paths or the manifest.

### How to determine if the bootloader is running with TF-A or RF-A

Worth settling before debugging, because the answer decides which tree the bug lives in. Three ways exist (build id prefix, a string in `bl31_log.lst`, and asking the running firmware over SMC), and they are not equally trustworthy. The `pixel-firmware-build` skill has all three and says which to prefer.

## About TFTF Log

Use the `pixel-tftf` skill for the whole loop: building TFTF alongside TF-A / RF-A, booting the image, and parsing the results out of `kernel.log`.

TFTF boots in place of the kernel, so a green run means EL3's interface to the normal world behaved in that sequence, not that a bug is fixed. Anything that needs Linux or Android userspace has to be reproduced on a normal boot instead; decide which one answers the question before building anything.

### Temporary Test Suites for TF-A / RF-A Experiments

When a small experiment should exercise only a specific TF-A / RF-A code path instead of the full TFTF regression, a temporary `TEST_SUITE` runs in seconds where the full regression takes minutes. `pixel-tftf` covers both, and creating the suite files is in there too.

## Commit Message & Pushing CLs to gpar

Read `create-gpar-cl` before drafting a commit message or assembling a push command in any repo whose remote points at `googleplex-polygon-android`. Nothing pulls it in for you, so reaching for it is a decision you have to make.

An upstream uprev is the exception to what that skill says about push targets. Merging an upstream LTS tag or release branch into an internal fork (an "uprev", an "upstream drop", or just "merge lts-v2.12.14") lands on the branch the previous uprev landed on, often in a different gerrit project, so the usual branch resolution gives the wrong answer. Read `pixel-upstream-uprev` before picking the target branch or the ref to merge.
