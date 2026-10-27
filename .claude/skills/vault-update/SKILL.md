---
name: vault-update
description: Document a finished jureczek change in the Obsidian vault (obsidian-vault/jureczek) — version note, ADR, overview roadmap, Backlog, tech notes. Use after implementing and verifying any change, before reporting the work as done.
---

Update the vault in `obsidian-vault/jureczek/`. Everything is written in Polish and uses `[[wikilinks]]`. $ARGUMENTS

1. **Read the current state first:** `00 Jureczek – przegląd.md`, the newest note in `Wersje/` (it is your template) and `Backlog.md`.

2. **Version note.** A new version gets `Wersje/vN – <krótki tytuł>.md` (en dash). A fix inside an existing version gets added to that version's note under `## Poprawki po teście`.
   ```
   ---
   tags: [jureczek, wersja]        # add topic tags, e.g. mapbox
   wersja: vN
   status: zaimplementowana – działa na telefonie
   data: YYYY-MM-DD
   ---
   # vN – <tytuł>
   ## Zakres
   ## Decyzje            (table: | # | Decyzja | Wybór |)
   ## Zależności         (optional: new packages)
   ## Pliki              (path: what changed)
   ## Pułapki
   ## Checklista weryfikacji   (flutter analyze: 0 issues, flutter test: X/X, phone checks)
   ## Poprawki po teście (optional)
   ## Otwarte
   Powiązane: [[...]]
   ```
   Only tick checklist items that were actually verified. Never tick phone checks the user hasn't confirmed.

3. **ADR**, when an architectural or library decision was made: `Decyzje/ADR-00N <Tytuł>.md`, numbered after the highest existing one. Frontmatter: `tags: [jureczek, adr]`, `status: przyjęta`, `data:`. Sections: Kontekst, Rozważane opcje, Decyzja, Konsekwencje, Powiązane. Link it from the overview's stack list.

4. **Overview:** add or update the version's row in the roadmap table (`✅ działa na telefonie – [[vN – …]]` only when phone-verified). Update the stack list when it changes.

5. **Backlog:** check off or remove items that are done, and add newly found ideas or problems under the right heading.

6. **Tech notes:** update `Środowisko dev.md` (commands, toolchain, adb) or `Technologia/*.md` (API pitfalls) when new knowledge came up.

7. Report which notes you created or changed.
