# noahburchell overlay

A personal overlay.

## Packages

| Package | Description |
| --- | --- |
| `games-misc/cube-cli` | spinning cube |

## Usage

### With `eselect repository`

```sh
emerge --ask app-eselect/eselect-repository
eselect repository add noahburchell git https://github.com/noahburchell/noahburchell-overlay.git
emaint sync --repo noahburchell
```

### Manually

Create `/etc/portage/repos.conf/noahburchell.conf`:

```ini
[noahburchell]
location = /var/db/repos/noahburchell
sync-type = git
sync-uri = https://github.com/noahburchell/noahburchell-overlay.git
auto-sync = yes
```

Then:

```sh
emaint sync --repo noahburchell
```

### Installing

```sh
emerge --ask games-misc/cube-cli
```

The `-9999` ebuild builds from git `main` and needs to be unmasked first:

```sh
echo '=games-misc/cube-cli-9999 **' >> /etc/portage/package.accept_keywords/cube-cli
```

## License

Ebuilds are distributed under the GNU General Public License v3.
