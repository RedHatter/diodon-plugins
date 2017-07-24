# Diodon Plugins
This is a collection of plugins for the gnome clipboard manager Diodon.

- **DBus Controller**  
Exposes Diodon api as a DBus service. Designed primarily for the Diodon [Gnome Shell extension](https://github.com/RedHatter/diodon-gnome-indictator).

- **Features**  
Additional features for the diodon menu.
  - Edit items
  - Delete items
  - "Pin" items
  - Search entire clipboard history

- **Numbers**  
Number clipboard menu items.

- **Pop Item**  
Pastes and then removes the active clipboard item.

- **Paste All**  
Simple plugin to paste all recent items at once, optionally appending a string to
the end (defaults to newline).

- **Edit**  
Prompts to edit the active item.

## Installing

``` bash
git clone https://github.com/RedHatter/diodon-plugins.git
cd diodon-plugins
./waf configure --libdir /usr/lib/x86_64-linux-gnu/
./waf build
sudo ./waf install
sudo update-icon-caches /usr/share/icons/hicolor/
```

## Debuging

``` bash
G_MESSAGES_DEBUG=all diodon
```
