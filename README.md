# Diodon Plugins
This is a set of plugins for the gnome clipboard manager Diodon.

- **Pop Item**
Pastes and then removes the active clipboard item.

- **Manager**  
A more complex version of Sticky. Opens a window where, in addition to selecting an item to paste, you can create new items, search the entire list, edit or delete existing items, and merge multiple items together.

- **Paste All**  
Simple plugin to paste all recent items at once, optionally appending a string to
the end (defaults to newline).

- **Sticky**  
Opens a window representation of the Diodon menu. The window will stay on top
and reflect changes to the clipboard. Allows searching and deleting clipboard items.

- **Edit**  
Prompts to edit the active item.

## Installing

``` bash
git clone https://github.com/RedHatter/diodon-plugins.git
cd diodon-plugins
./waf configure && ./waf build && ./waf install
```

## Debuging

``` bash
G_MESSAGES_DEBUG=all diodon
```
