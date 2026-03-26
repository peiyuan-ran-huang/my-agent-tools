# Audit Pitfalls

This file is a calibration and onboarding aid.

It is **not** a canonical runtime authority.

Use it to spot common execution mistakes quickly, then jump to the real rule owner.

The bullets below are navigation cues, not authoritative rule text.

## How To Use This File

For each pitfall below:
- identify the failure pattern
- fix the behaviour by following the linked canonical file
- do not copy rules back into this file as a second truth source

---

## 1. Discovery Mistaken For Verification

**Failure pattern**

- `Verification Source` is effectively "I read it and it seems wrong"

**Why it is dangerous**

- that is still discovery, not independent verification

**Navigation cue**

- open the linked canonical file and confirm that verification still requires an independent source or tool path rather than reusing raw discovery prose

**Primary canonical owner(s)**

- [SKILL.md](SKILL.md)
- [templates/subagent-template.md](templates/subagent-template.md)

---

## 2. Severity Inflation On Small Targets

**Failure pattern**

- minor style or clarity issues get upgraded to `Major` just because the target is short

**Why it is dangerous**

- it distorts prioritisation and teaches the wrong severity scale

**Navigation cue**

- open the linked canonical file and re-check whether the severity reasoning still matches the documented audit standard rather than the target's small size

**Primary canonical owner(s)**

- [SKILL.md](SKILL.md)
