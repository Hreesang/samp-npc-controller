# samp-npc-controller

[![sampctl](https://img.shields.io/badge/sampctl-samp--npc--controller-2f2f2f.svg?style=for-the-badge)](https://github.com/Hreesang/samp-npc-controller)

<!--
Short description of your library, why it's useful, some examples, pictures or
videos. Link to your forum release thread too.

Remember: You can use "forumfmt" to convert this readme to forum BBCode!

What the sections below should be used for:

`## Installation`: Leave this section un-edited unless you have some specific
additional installation procedure.

`## Testing`: Whether your library is tested with a simple `main()` and `print`,
unit-tested, or demonstrated via prompting the player to connect, you should
include some basic information for users to try out your code in some way.

And finally, maintaining your version number`:

* Follow [Semantic Versioning](https://semver.org/)
* When you release a new version, update `VERSION` and `git tag` it
* Versioning is important for sampctl to use the version control features

Happy Pawning!
-->
This filterscript is used for NPC purposes like spawning, playing playback, recording playback, and such.
Happy NPC-ing, brothers!

## Installation

First you need to pull the branch:
```bash
git pull https://github.com/Hreesang/samp-npc-controller.git
```

Ensure the dependencies using sampctl:
```bash
sampctl package ensure
```

Build the ``npc-controller.pwn`` file:
```bash
sampctl package build
```

Start the ``samp-server.exe`` by simply click on the file or through the command prompt:

Powershell:
```bash
Powershell
./samp-server.exe
```

CMD
```bash
samp-server.exe
```

## Commands

<!--
Write your code documentation or examples here. If your library is documented in
the source code, direct users there. If not, list your API and describe it well
in this section. If your library is passive and has no API, simply omit this
section.
-->
Here are the commands for this filterscript:

**/anim**
> Apply an animation to your player.

**/recording or /rec**
> Show recording options.

**/npc**
> Show NPC Controller options.