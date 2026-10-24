# Skill Advisor

`skill-advisor` is a Codex skill that recommends, organizes, and presents installed skills for a user's task.

It helps users avoid manually remembering which skills they have installed. Instead of immediately using or installing extra skills, it acts as a small advisory layer: inspect local skill metadata, recommend useful matches, explain when they fit, and ask before taking further action.

## What It Helps With

- Recommend installed skills that fit a user's current task.
- Organize installed skills into a compact catalog.
- Group skills by category, such as planning, research, frontend, automation, review, or system configuration.
- Explain which broad project phase a skill helps with: discovery, planning, build, review, or operate.
- Ask before invoking skills, searching online with `find-skills`, or installing remote skills.

## Installation

Install with the Skills CLI:

```bash
npx skills add https://github.com/yfdskr/skill-advisor -g -a codex -y
```

You can also specify the skill explicitly:

```bash
npx skills add https://github.com/yfdskr/skill-advisor --skill skill-advisor -g -a codex -y
```

## Usage

After installation, ask Codex naturally:

```text
Use $skill-advisor to recommend which skills fit this task.
```

```text
Use $skill-advisor to organize my installed skills by category and project phase.
```

```text
Use $skill-advisor to check whether I already have a skill for this workflow before searching online.
```

## Classification and tests

Categories use keyword heuristics over the skill name and description. Explicit
frontend terms (such as `frontend`, `UI`, `React`, or `website`) take precedence
over visual terms, so UI design skills stay in Web and Frontend even when they
mention images or visual design. Image design, photography, illustration, video,
and other visual creation skills without frontend context use Visual and Media.
Bare `design` is a fallback after the specific categories.

Keywords match whole words, with explicit compound forms such as `imagegen`,
`nextjs`, and `tailwindcss`. Ordinary `next` and `sites` in descriptions do not
imply frontend work; the `sites` skill name and `Sites plugin` still match.
Other category priorities and project phase rules remain unchanged. Mixed-purpose
descriptions can still need manual interpretation.

Run the dependency-free regression suite from the repository root:

```powershell
pwsh -NoProfile -File ./tests/list-local-skills.Tests.ps1
```

Windows PowerShell 5.1 is also supported:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ./tests/list-local-skills.Tests.ps1
```

The suite covers overlapping keywords, frontend preservation, substring false
positives, category fallbacks, and inventory output. GitHub Actions runs it on
Windows PowerShell 5.1 and PowerShell 7 on Windows and Linux.

## Repository Layout

```text
SKILL.md
agents/
  openai.yaml
scripts/
  list-local-skills.ps1
tests/
  list-local-skills.Tests.ps1
README.md
LICENSE
```

## Safety Model

`skill-advisor` is advisory by design:

- It does not install, update, delete, configure, publish, spend money, or access external services without user confirmation.
- It reads local skill metadata for discovery, but it does not follow another skill's full instructions until that skill is selected for use.
- If no local skill fits, it asks before using `find-skills` to search online.

## Related Skill

The separate Windows cleanup skill lives at:

```text
https://github.com/yfdskr/CDE-clear
```

## License

MIT
