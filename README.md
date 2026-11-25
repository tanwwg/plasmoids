# Plasma widgets

Chess, Clock, and Quote widgets for KDE Plasma 6.

## Link the widgets

Run this from the repository root. If you don't already have a per-user `plasmoids` directory, link the whole checkout so Plasma can also discover widget folders you add later.

```sh
plasmoid_dir="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids"
mkdir -p "$(dirname "$plasmoid_dir")"
ln -sT "$PWD" "$plasmoid_dir"
```

If you already have a per-user `plasmoids` directory, link the widgets individually to keep your existing widgets alongside them.

```sh
plasmoid_dir="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids"
mkdir -p "$plasmoid_dir"
for widget in com.tjtan.chess com.tjtan.clock com.tjtan.quote; do
    ln -sT "$PWD/$widget" "$plasmoid_dir/$widget"
done
```

Open **Add Widgets** in Plasma and search for the widget by name. If it doesn't appear, restart the Plasma shell as shown below.

## Test one widget

Run a linked widget in its own window by plugin ID.

```sh
plasmawindowed com.tjtan.clock
```

With `plasmoidviewer` from the `plasma-sdk` package, you can also test directly from the repository root before linking.

```sh
plasmoidviewer -a "$PWD/com.tjtan.clock"
```

## Reload Plasma

Run this from a terminal in your Plasma session to restart the desktop shell and reload widgets already on the desktop or panel.

```sh
systemctl --user restart plasma-plasmashell.service
```

If your session doesn't use the systemd user service, run:

```sh
plasmashell --replace
```

See the [KDE widget testing guide](https://develop.kde.org/docs/plasma/widget/testing/) for more preview options.
