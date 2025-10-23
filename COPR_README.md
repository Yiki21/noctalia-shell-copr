## noctalia-shell — COPR post-install quick guide

After installing the package:

```bash
sudo dnf install noctalia-shell
```

Initialize your user config:

- Recommended (symlink so updates flow automatically):
	```bash
	noctalia-shell
	```
- Copy into your home (manual updates later):
	```bash
	noctalia-shell --copy
	```
- Overwrite an existing config:
	```bash
	noctalia-shell --force
	```

Where things live:
- System config (package content): `/usr/share/quickshell/noctalia-shell`
- Your user config: `~/.config/quickshell/noctalia-shell`

Upstream project URL:
- https://github.com/noctalia-dev/noctalia-shell
