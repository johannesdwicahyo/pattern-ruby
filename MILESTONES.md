# pattern-ruby — Milestones

> **Source of truth:** https://github.com/johannesdwicahyo/pattern-ruby/milestones
> **Last synced:** 2026-04-14

This file mirrors the GitHub milestones for this repo. Edit the milestone or issues on GitHub and re-sync, do not hand-edit.

## v1.0.0 — Production Ready (**open**)

_Performance, documentation, stability, and ecosystem integration_

- [ ] #21 Performance benchmarks and optimization
- [ ] #22 Thread safety audit and fixes
- [ ] #23 ReDoS protection for pattern compilation
- [ ] #24 Comprehensive documentation and guides
- [ ] #25 CI/CD pipeline with GitHub Actions
- [ ] #26 Ecosystem integration with rag-ruby and guardrails-ruby

## v0.4.0 — Rails Integration (**open**)

_ActionController concern, route DSL, webhook handlers, and session-based conversation_

- [ ] #16 ActionController concern for intent routing
- [ ] #17 Route-like DSL for intent matching
- [ ] #18 Session-based conversation state
- [ ] #19 Webhook handlers for Slack, Discord, and Telegram
- [ ] #20 RSpec matchers for intent testing

## v0.3.0 — Advanced Matching (**open**)

_Fuzzy matching, synonyms, negation detection, and smarter entity handling_

- [ ] #8 Add: Fuzzy matching with Levenshtein distance
- [ ] #9 Add: Synonym expansion
- [ ] #10 Add: Negation detection
- [ ] #11 Add: Date entity type with parser
- [ ] #12 Add: Case-sensitive exact phrase matching with quotes
- [ ] #13 Add: Active slot filling — ask for missing entities
- [ ] #14 Add: Entity validation rules
- [ ] #15 Improve: Smarter scoring for ambiguous matches

## v0.2.0 — Bug Fixes & Hardening (**closed**)

_Fix known bugs, edge cases, and add input validation_

- [x] #1 Fix: Optional section at start of pattern fails to match
- [x] #2 Fix: Empty entity name {} silently creates bad captures
- [x] #3 Fix: Unused variable in Conversation#try_slot_fill
- [x] #4 Add: Validate slot fill values against entity type constraints
- [x] #5 Add: Error handling in Pipeline steps
- [x] #6 Add: Malformed pattern validation and error messages
- [x] #7 Add: Test coverage for edge cases
