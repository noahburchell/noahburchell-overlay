# my overlay

## packages

| package | description |
| --- | --- |
| `games-misc/cube-cli` | spinning cube |
| `app-misc/claude-desktop` | ⚠️ PROPRIETARY ⚠️ <br /> repackaged Anthropic's <br /> official .deb | 

## usage

### with `eselect repository`

```sh
emerge --ask app-eselect/eselect-repository
eselect repository add noahburchell git https://github.com/noahburchell/noahburchell-overlay.git
emaint sync --repo noahburchell
```

### manually

create `/etc/portage/repos.conf/noahburchell.conf`:

```ini
[noahburchell]
location = /var/db/repos/noahburchell
sync-type = git
sync-uri = https://github.com/noahburchell/noahburchell-overlay.git
auto-sync = yes
```

then:

```sh
emaint sync --repo noahburchell
```

### installing

```sh
emerge --ask games-misc/cube-cli
```

`app-misc/claude-desktop` is proprietary, so portage will refuse to merge it until you accept the licence:

```sh
echo 'app-misc/claude-desktop all-rights-reserved' >> /etc/portage/package.license
emerge --ask app-misc/claude-desktop
```

## license

GNU General Public License v3.
