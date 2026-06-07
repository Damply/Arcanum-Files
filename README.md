# Arcanum-Files
ARCANUMLAND TOOLKIT

Run INSTALL.bat and choose:

1. Client Freedom Patch
   - Enables Minecraft's normal Singleplayer and Multiplayer menus.
   - Disables FancyMenu, Drippy Loading Screen, SpiffyHUD, Spiffy x Gnetum,
     and the remote BetterNews feed.
   - Backs up the bundled server list instead of deleting it permanently.
   - Installs the recovered questbook, artwork, and supporting assets.

2. Recovered dedicated server
   - Extracts the current Forge 1.20.1 / 47.4.13 server.
   - Works with an original, unmodified ArcanumLand client.
   - Includes the recovered questbook and matching server configuration.
   - Does not include a world, player records, logs, or credentials.

3. Both
   - Applies the optional Client Freedom Patch and installs the server.

4. Questbook and artwork only
   - Adds the recovered quest content without changing the original UI.

5. Restore newest client backup
   - Reverses the newest toolkit client installation.

6. Check client setup
   - Reports quest files, textures, backups, and restrictive UI mods.

BACKUPS

Every client operation creates a timestamped folder inside the instance:

_arcanumland_friends_backup_YYYYMMDD-HHMMSSmmm

The restore option keeps restored backups and marks them with "_restored".
gnetum-2.4.3.jar remains installed because the pack uses it independently.

SERVER FIRST START

Read README-SERVER.txt, install Java 17, accept the Minecraft EULA in
eula.txt, then run start-server.bat.
