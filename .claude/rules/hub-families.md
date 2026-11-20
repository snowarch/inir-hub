---
paths:
  - "families/**"
---

# Families are not contributions

`families/` holds Material (`ii`), iRiS and Waffle: the desktop every iNiR install gets. Only the hub's maintainers change
them, and CI refuses a pull request from anyone else that touches this folder.

- A feature for a family: build a component or a widget worn with it (`hub-components.md`, `hub-widgets.md`). Read the
  family's files to learn how its surfaces are built; never copy one into an item.
- A bug in a family: an issue with what you saw, the steps, and `inir logs --issues`.
- What items may import from a family: `hub-qml.md › Imports`. The rest of a family's folders are its inside.
- A family's look is in its `DESIGN.md`. Read it before any change to how the family looks.

Maintainers: `CONTRIBUTING.md › Changing a family` (one change per pull request, the family's tokens and parts, every
string in every language the family ships, the version raised in `hub.json` and `plugin.json`, its page in `docs/<id>/`).
