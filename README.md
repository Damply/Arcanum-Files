# ArcanumLand Friends Toolkit

An installer for running ArcanumLand without its locked server-only menu and
for hosting a compatible private Forge server.

## Download

Download `ArcanumLand-Friends-Toolkit-1.2.zip` from the repository's
[Releases](https://github.com/Damply/Arcanum-Files/releases) page.

Do not use GitHub's automatically generated "Source code" archives as the
installer. They do not contain the large server and client payloads.

SHA-256:

```text
71DDFEF7592ED982D4621844CEAECDEC092747743C66007A413CE225CABF0D8B
```

Extract the downloaded ZIP, then run `INSTALL.bat`.

## Installer Options

1. **Client Freedom Patch**: enables Singleplayer and removes the restrictive
   custom menu, loading screen, HUD integration, and remote news feed.
2. **Recovered Dedicated Server**: installs the Forge 1.20.1 / 47.4.13 server.
   An original, unmodified ArcanumLand client can connect.
3. **Both**: installs the optional client patch and recovered server.
4. **Questbook and Artwork Only**: installs recovered quest content without
   changing the original menu.
5. **Restore Newest Client Backup**: reverses the latest toolkit client change.
6. **Check Client Setup**: reports detected UI mods, quests, textures, and
   backups.

Client changes are optional for connecting to the recovered server.

## Backups

Every client operation creates a timestamped backup inside the Minecraft
instance:

```text
_arcanumland_friends_backup_YYYYMMDD-HHMMSSmmm
```

The restore option retains the restored backup and marks it with `_restored`.

## Server Setup

Install Java 17, read `README-SERVER.txt`, accept the Minecraft EULA by setting
`eula=true` in `eula.txt`, then run `start-server.bat`.

The server bundle contains no world, player records, logs, or credentials.

## Repository Contents

This repository tracks the PowerShell installer and documentation. The complete
payload is distributed as a GitHub Release asset because normal Git repositories
do not support files of this size.

This is an independent community interoperability and preservation project. It
is not affiliated with Mojang, Microsoft, CurseForge, or the original modpack
authors.
