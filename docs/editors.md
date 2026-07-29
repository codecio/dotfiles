# Editors

VS Code and Cursor extensions, kept in sync from a set of tracked files.

> **See also:** [brew.md](brew.md) — the same shared/per-target split, applied to Homebrew.

## Why this exists

<details>
<summary>Settings Sync does not bridge VS Code and Cursor</summary>

Signing into VS Code with GitHub enables **Settings Sync**, which syncs settings, keybindings, and extensions — but only between **VS Code installs**. Microsoft restricts the sync service to official VS Code builds, so Cursor cannot join it. Cursor has no equivalent of its own: it ships no Settings Sync feature, so signing into Cursor does not carry your extension list anywhere.

You can confirm the asymmetry locally:

```bash
ls "$HOME/Library/Application Support/Code/User/sync/"    # populated
ls "$HOME/Library/Application Support/Cursor/User/sync/"  # does not exist
```

Importing VS Code settings into Cursor is a **one-time snapshot**. Nothing keeps them together afterwards, so the two lists drift apart every time you install an extension in one editor and not the other.

The `Extfile` set is the source of truth instead, and it lives in git.

</details>

<details>
<summary>Full parity is impossible — two different marketplaces</summary>

VS Code installs from the **Microsoft Marketplace**. Microsoft's terms restrict it to Visual Studio products, so Cursor installs from **OpenVSX** (Eclipse Foundation) instead.

Most extensions are published to both. Microsoft's proprietary ones are not — Pylance, the Remote-SSH stack, C# Dev Kit, C/C++. Anysphere publishes drop-in forks to OpenVSX to cover the gap, under the `anysphere.*` namespace.

So the goal is not one identical list. It is a **shared baseline plus a deliberate per-editor delta**.

</details>

<details>
<summary>Why not Homebrew Bundle's <code>vscode</code> directive?</summary>

Homebrew Bundle does support extensions natively — `vscode "publisher.extension"` in a Brewfile, covered by `dump`, `check`, `install`, and `cleanup`. The gitignored `Brewfile.archive` still contains 28 such lines from an old `brew bundle dump`.

It cannot work here, because it binds to a **single** CLI binary, resolved first-match from `PATH`:

```ruby
which("code") || which("codium") || which("cursor") || which("code-insiders")
```

There is no override environment variable. With both `code` and `cursor` installed, Homebrew always resolves to `code` and never touches Cursor. The archive proves it: those 28 lines were VS Code's entire list at the time, while Cursor had 51.

So `vscode` lines are deliberately absent from every Brewfile here. Adding them would manage one editor and create a second, competing source of truth.

The one capability Homebrew has that this does not is pruning, which `make ext-prune` now covers.

</details>

## The files

| File | Installs into | Contents |
|------|---------------|----------|
| `Extfile` | VS Code **and** Cursor | Everything published to both registries |
| `Extfile.vscode` | VS Code only | Microsoft-proprietary (`ms-vscode-remote.*`, remote explorer, Live Share) |
| `Extfile.cursor` | Cursor only | Anysphere OpenVSX forks (`anysphere.*`) |
| `Extfile.ignore` | nothing | Installed locally but unreproducible — silenced in `make ext-diff` |

Format is one extension ID per line, `#` for comments — the same output `code --list-extensions` produces.

The two per-editor files are deliberately small and pair up one-to-one:

| VS Code | Cursor |
|---------|--------|
| `ms-vscode-remote.remote-ssh` | `anysphere.remote-ssh` |
| `ms-vscode-remote.remote-ssh-edit` | — |
| `ms-vscode.remote-explorer` | — |
| — | `anysphere.remote-containers` |
| — | `anysphere.remote-wsl` |
| Pylance (not installed) | `anysphere.cursorpyright` |
| `ms-vsliveshare.vsliveshare` | — (absent from OpenVSX) |

<details>
<summary>Extfile.ignore — extensions that cannot be reinstalled</summary>

Two extensions are installed in Cursor but have been pulled from **both** registries, so neither editor can install them again:

- `jeremyrajan.file-script-runner`
- `ms-vsliveshare.vsliveshare-pack` — Microsoft retired the pack; the single `ms-vsliveshare.vsliveshare` survives on the Microsoft Marketplace only, so it lives in `Extfile.vscode`

They still work in the Cursor install that already has them, but they cannot be reproduced on a fresh Mac. Putting them in the `Extfile` set would make `make ext` fail on a new machine, so they go in `Extfile.ignore` instead — not installed, and not reported as drift.

Uninstall them whenever you stop needing them. There is no way to get them back.

</details>

## Commands

```bash
make ext          # install everything from the Extfile set into both editors
make ext-diff     # report drift in both directions
make ext-dump     # capture hand-installed extensions back into the files
make ext-prune    # uninstall extensions no longer in the files (dry-run)
```

Not part of `make bootstrap` — both editors are GUI casks from `Brewfile.apps`, so run `make apps` first on a fresh machine, then `make ext`.

<details>
<summary>make ext — install</summary>

Computes what each editor is missing and installs only that, so re-running is cheap. Both CLIs (`code`, `cursor`) must be on `PATH`; a missing one is skipped with a warning rather than failing the run.

If an install fails, the extension is absent from that editor's registry. Move the line out of `Extfile` into `Extfile.vscode` or `Extfile.cursor` and re-run. If it fails for **both** editors it has been unpublished everywhere — move it to `Extfile.ignore` instead.

</details>

<details>
<summary>make ext-diff — detect drift</summary>

Reports two categories per editor:

- **tracked but not installed** — the files have it, the editor does not. Run `make ext`.
- **installed but not tracked** — you installed it by hand. Run `make ext-dump`.

Anything listed in `Extfile.ignore` is excluded from the second category.

Run this before committing, the same way you run `make status` for dotfiles.

</details>

<details>
<summary>make ext-dump — capture hand-installed extensions</summary>

Appends anything installed but untracked to the right file, under a dated comment header.

Routing is by namespace: `anysphere.*` goes to `Extfile.cursor`, `ms-vscode-remote.*` and `ms-vscode.remote-*` go to `Extfile.vscode`, and **everything else defaults to the shared `Extfile`**. That default is what converges the two editors — install something in Cursor, dump it, and the next `make ext` backfills it into VS Code.

The appended lines have no description comment. Add one before committing to match the surrounding style, and move the line if the default routing guessed wrong.

</details>

<details>
<summary>make ext-prune — remove extensions you have dropped</summary>

The inverse of `ext-dump`. Both act on the same "installed but unmanaged" set: `ext-dump` adopts it into the files, `ext-prune` removes it from the editors.

**Dry-run by default**, following `brew bundle cleanup`. A bare `make ext-prune` only previews; `make ext-prune FORCE=1` actually uninstalls.

`Extfile.ignore` entries are never candidates, so the unreproducible extensions cannot be destroyed by accident.

</details>

## Adding an extension

Install it in whichever editor you happen to be in, then:

```bash
make ext-dump   # adds it to Extfile
make ext        # backfills it into the other editor
```

Or edit `Extfile` directly and run `make ext`. Add the description comment either way.

## Removing an extension

The files are the source of truth, so delete the line first — otherwise the next `make ext` reinstalls it.

```bash
# 1. delete the line from Extfile (or the per-editor file)
make ext-prune            # preview what would be uninstalled
make ext-prune FORCE=1    # actually uninstall from both editors
```

Uninstalling through the editor UI alone is not enough: `make ext-diff` will report it as "tracked but not installed" and `make ext` will put it back.

## Settings

`settings.json` is **not** managed here — the two editors have their own copies at:

```text
~/Library/Application Support/Code/User/settings.json
~/Library/Application Support/Cursor/User/settings.json
```

They are near-identical today, differing only in `git.addAICoAuthor` (VS Code), plus `projectManager.git.baseFolders` and `window.autoDetectColorScheme` (Cursor). Cursor's copy also lost its section comments during the original import. Folding both into one chezmoi template is a future option.
