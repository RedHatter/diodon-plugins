/*
 * Sticky a plugin for Diodon
 * Copyright (C) 2014 Christian Timothy Johnson <_c_@mail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
 * License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;

namespace Diodon.Plugins
{

	/*
	 * Plugin for Diodon that opens a windowed view of the Diodon menu.
	 *
	 * @author RedHatter <_c_@mail.com>
	 */
	public class StickyPlugin : Peas.ExtensionBase, Peas.Activatable, PeasGtk.Configurable
	{
		private Controller controller;
		private Gtk.MenuItem item;
		private string accelerator;
		private GLib.Settings _settings;
		private GLib.Settings settings
		{
			get
			{
				if (_settings == null)
					_settings = new GLib.Settings ("com.diodon.plugins.sticky");
				
				return _settings;
			}
		}

		public Object object { get; construct; }

		public StickyPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			debug ("activate");
			controller = object as Controller;

			// Register keybinding and create menu item
			bind_accelerator (settings.get_string ("accelerator"));
			if (settings.get_boolean ("display"))
			{
				item = new Gtk.MenuItem.with_label ("Open Sticky");
				item.activate.connect ( () => sticky.begin ());
				controller.add_static_recent_menu_item (item);
			}
		}

		/*
		 * Registers the specified keybinding with the Diodon keybinding
		 * manager.
		 */
		private void bind_accelerator (string new_accelerator)
		{
			debug ("binding %s", new_accelerator);
			var keybinding_manager = controller.get_keybinding_manager ();
			if (accelerator != null) {
				keybinding_manager.unbind (accelerator);
				debug ("unbinding %s", accelerator);
			}
			keybinding_manager.bind (new_accelerator, () => sticky.begin ());
			accelerator = new_accelerator;
		}

		public void deactivate ()
		{
			debug ("deactivate");
			
			controller.get_keybinding_manager ().unbind (accelerator);
			if (item != null)
				controller.remove_static_recent_menu_item (item);
		}

		public void update_state () {}

		/*
		 * Creates and opens the sticky window.
		 */
		private async void sticky ()
		{
			debug ("open sticky");

			var window = new Window ();
			window.title = "Diodon";
			window.window_position = WindowPosition.CENTER;
			window.set_keep_above (true);
			var box = new Grid ();
			window.add (box);
			build (box, window);
			controller.on_recent_menu_changed.connect ( (menu) =>
				{
					// Remove all widgets, then rebuild menu
					var widgets = box.get_children ();
					foreach (var widget in widgets)
						box.remove (widget);
					build (box, window);
					box.show_all ();
				});
			window.show_all ();
		}

		/*
		 * Insert items from recent menu as buttons.
		 */
		private void build (Grid box, Window window)
		{
			debug ("build menu");
			var menu = controller.get_recent_menu ();
			var widgets = menu.get_children ();
			bool stock = false; // Are we above or below separator?
			var n = 0;
			foreach (var widget in widgets)
			{
				if (widget is SeparatorMenuItem)
				{
					// Insert separator
					var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
					separator.margin_left = 5;
					separator.margin_right = 5;
					box.attach (separator, 0, n, 1, 1);
					stock = true;
				} else
				{
					var item = widget as Gtk.MenuItem;
					if (item.label == "Open Sticky") // Sticky is open, no need to open another
						continue;

					// Create button from item
					var button = new Button.with_label (item.label);
					button.margin_left = 10;
					button.margin_right = 10;
					button.image = (item as ImageMenuItem).image;
					button.always_show_image = !stock;
					button.relief = ReliefStyle.NONE;
					button.xalign = 0.0f;
					button.use_stock = stock;
					button.clicked.connect ( () => item.activate ());
					box.attach (button, 0, n, 1, 1);
				}
				n++;
			}

			// Insert search box
			var search = new Gtk.Entry ();
			search.placeholder_text = "Search";
			search.margin = 10;
			search.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear");
			search.icon_press.connect ((pos, event) => search.set_text (""));
			search.changed.connect ( () =>
				{
					debug ("change");
					if (search.text == "")
						build (box, window);
					else
						// Do the search
						controller.get_items_by_search_query.begin (search.text, null, ClipboardTimerange.ALL, null, (obj, res) =>
							{
								var widget = box.get_children ();
								var items = controller.get_items_by_search_query.end (res);
								var size = controller.get_configuration ().recent_items_size;

								// Remove clipboard items
								for (var i = 0; i < size; i++)
								{
									box.remove (box.get_child_at (0, i));
									var x = box.get_child_at (1, i);
									if (x != null)
										box.remove (x);
								}

								// Insert results
								for (var i = 0; i < size; i++)
								{
									var j = i;
									Button button;
									if (i < items.size)
									{
										button = new Button.with_label (items[i].get_label ());
										button.image = items[i].get_image ();
										button.always_show_image = true;
										button.clicked.connect ( () =>
											{
												controller.select_item_by_checksum.begin (items[j].get_checksum());
												build (box, window);
											});

										var del = new Button.with_label (" ");
										del.relief = ReliefStyle.NONE;
										del.clicked.connect ( () => controller.remove_item.begin (items[j]));
										del.enter_notify_event.connect ((event) =>
											{
												del.label = "x";
												return false;
											});
										del.leave_notify_event.connect ((event) =>
											{
												del.label = " ";
												return false;
											});
										box.attach (del, 1, i, 1, 1);
										button.enter_notify_event.connect ((event) =>
											{
												del.label = "x";
												return false;
											});
										button.leave_notify_event.connect ((event) =>
											{
												del.label = " ";
												return false;
											});
									} else
										button = new Button.with_label (" "); // Pad with empty buttons

									button.margin_left = 10;
									button.margin_right = 0;
									button.relief = ReliefStyle.NONE;
									button.xalign = 0.0f;
									box.attach (button, 0, i, 1, 1);
//									box.reorder_child (button, i);
								}
								box.show_all ();
							});
				});
			box.attach (search, 0, n+1, 1, 1);
		}

		/*
		 * Creates the Preferences window in Diodon's Plugin Preferences.
		 */
		public Gtk.Widget create_configure_widget ()
		{
			accelerator = settings.get_string ("accelerator");

			var box = new Gtk.Grid ();
			box.attach (new Gtk.Label ("Sticky Key"), 0, 0, 1, 1);
			var accel_entry = new Gtk.Entry ();
			accel_entry.set_text (accelerator);
			accel_entry.focus_out_event.connect ( () => {
				var text = accel_entry.get_text ();
				if (text != null) {
					settings.set_string ("accelerator", text);
				}
				return false;
			});
			box.attach (accel_entry, 1, 0, 1, 1);

			var check = new Gtk.CheckButton.with_label ("Display in menu");
			check.active = settings.get_boolean ("display");
			check.toggled.connect ( () => settings.set_boolean ("display", check.active));
			box.attach (check, 0, 2, 2, 1);
			box.show_all ();

			return box;
		}

	}
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
	Peas.ObjectModule objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type (typeof (Peas.Activatable),
									   typeof (Diodon.Plugins.StickyPlugin));
	objmodule.register_extension_type (typeof (PeasGtk.Configurable),
									   typeof (Diodon.Plugins.StickyPlugin));

}
