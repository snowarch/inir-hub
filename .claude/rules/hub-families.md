---
paths:
  - "families/**"
---

# Families are not contributions

`families/` holds Material (`ii`), iRiS and Waffle: the desktop every iNiR install gets. Only the hub's maintainers
change them, and CI refuses a pull request from anyone else that touches this folder.

- Contributing a feature for a family: build a component worn with it (`hub-components.md`). Read the family's files
  here to learn how its surfaces are built; never copy one into your item.
- A bug in a family: open an issue with what you saw, the steps and `inir logs --issues`.
- What a family offers items to import is listed in `AGENTS.md`; the rest of its folders are its inside.

Maintainers: `CONTRIBUTING.md › Changing a family` (one change per pull request, the family's tokens and parts, every
string in all 18 languages, the version raised in `hub.json` and `plugin.json`, its page in `docs/<id>/`).
