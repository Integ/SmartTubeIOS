@AGENTS.md

## Claude Code specifics
- Use `superpowers:brainstorming` before new features and `superpowers:writing-plans` before multi-step work; plans go to docs/superpowers/plans/.
- For concurrency questions load the `swift-concurrency` skill; for architecture work load `improve-codebase-architecture`.
- Machine-specific paths and simulator names live in CLAUDE.local.md (gitignored), not here.
