/*
 * Manager a plugin for Diodon
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
	 * Plugin for Diodon that allows deleting, editing, inserting, combining, and searching clipboard items.
	 *
	 * @author RedHatter <_c_@mail.com>
	 */
	public class ManagerPlugin : Peas.ExtensionBase, Peas.Activatable, PeasGtk.Configurable
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
					_settings = new GLib.Settings ("com.diodon.plugins.manager");
				
				return _settings;
			}
		}

		public Object object { get; construct; }

		public ManagerPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			debug ("activate");
			controller = object as Controller;

			// Register keybinding and create menu item
			accelerator = settings.get_string ("accelerator");
			bind_accelerator (accelerator);
			if (settings.get_boolean ("display"))
			{
				item = new Gtk.MenuItem.with_label ("Open Manager");
				item.activate.connect ( () => manager ());
				controller.add_static_recent_menu_item (item);
			}
		}

		/*
		 * Registers the specified keybinding with the Diodon keybinding
		 * manager.
		 */
		private void bind_accelerator (string new_accelerator)
		{
			debug ("bind_accelerator: %s", new_accelerator);
			var keybinding_manager = controller.get_keybinding_manager ();
			if (accelerator != null) {
				keybinding_manager.unbind (accelerator);
				debug ("unbinding %s", accelerator);
			}
			keybinding_manager.bind (new_accelerator, () => manager ());
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
		 * Open manager window.
		 */
		private void manager ()
		{
			debug ("open manager");

			// Create Window
			var window = new Window ();
			window.title = "Diodon";
			window.window_position = WindowPosition.CENTER;
			window.set_keep_above (true);
			var box = new Box (Gtk.Orientation.VERTICAL, 10);
			window.add (box);

			// Create multi-select
			var model = new ListStore (2, typeof (string), typeof (IClipboardItem));

			reset.begin (model);
			controller.on_recent_menu_changed.connect ((menu) => reset.begin(model)); // Update when menu changes

			var select = new TreeView.with_model (model);
			select.headers_visible = false;
			select.enable_search = false;
			select.fixed_height_mode = true;
			select.get_selection().mode = SelectionMode.MULTIPLE;
			select.insert_column_with_attributes (-1, null, new CellRendererText (), "text", 0);
			select.row_activated.connect ( () => // Double-click to set item as active
				{
					select.get_selection ().selected_foreach ( (l_model, path, iter)  =>
					{
						IClipboardItem item = null;
						l_model.get (iter, 1, out item);
						controller.select_item_by_checksum.begin (item.get_checksum ());
					});
				});
			box.add (select);


			// Create buttons
			var buttons = new Box (Gtk.Orientation.HORIZONTAL, 0);
			var button = new Button.with_label ("Select");
			button.margin = 5;
			button.clicked.connect (() =>
				{
					IClipboardItem item = null;

					select.get_selection ().selected_foreach ( (l_model, path, iter)  =>
					{
						l_model.get (iter, 1, out item);
						if (item != null)
							controller.select_item_by_checksum.begin (item.get_checksum ());
					});
				});
			buttons.add (button);

			button = new Button.with_label ("Delete");
			button.margin = 5;
			button.clicked.connect (() =>
				{
					IClipboardItem item = null;

					select.get_selection ().selected_foreach ( (l_model, path, iter)  =>
					{
						l_model.get (iter, 1, out item);
						if (item != null)
							controller.remove_item.begin (item);
					});
				});
			buttons.add (button);

			button = new Button.with_label ("Edit");
			button.margin = 5;
			button.clicked.connect (() => // Code pulled from  the 'Edit' plugin
				{
					IClipboardItem item = null;

					select.get_selection ().selected_foreach ( (l_model, path, iter)  =>
					{
						l_model.get (iter, 1, out item);
						if (item == null)
							return;

						var dialog = new Dialog.with_buttons ("Edit", null, DialogFlags.MODAL, "_OK", ResponseType.ACCEPT, "_Cancel", ResponseType.REJECT, null);
						var text_view = new TextView ();
						text_view.buffer.text = item.get_text ();
						dialog.get_content_area ().add (text_view);
						dialog.response.connect ((id) =>
							{
								switch (id)
								{
									case ResponseType.ACCEPT:
										controller.remove_item.begin (item);
										controller.add_text_item.begin (item.get_clipboard_type (), text_view.buffer.text, item.get_origin ());
										dialog.destroy ();
										break;
									case ResponseType.REJECT:
										dialog.destroy ();
										break;
								}
							});
						dialog.show_all ();
						dialog.run ();
					});
				});
			buttons.add (button);

			// Not very useful, but why not
			button = new Button.with_label ("New");
			button.margin = 5;
			button.clicked.connect (() =>
				{
					var dialog = new Dialog.with_buttons ("New", null, DialogFlags.MODAL, "_OK", ResponseType.ACCEPT, "_Cancel", ResponseType.REJECT, null);
					var text_view = new TextView ();
					dialog.get_content_area ().add (text_view);
					dialog.response.connect ((id) =>
						{
							switch (id)
							{
								case ResponseType.ACCEPT:
									controller.add_text_item.begin (ClipboardType.NONE, text_view.buffer.text, null);
									dialog.destroy ();
									break;
								case ResponseType.REJECT:
									dialog.destroy ();
									break;
							}
						});
					dialog.show_all ();
					dialog.run ();
				});
			buttons.add (button);

			// Works the same as 'Paste All' plugin
			button = new Button.with_label ("Merge");
			button.margin = 5;
			button.clicked.connect (() =>
				{
					IClipboardItem item = null;
					var text = "";

					select.get_selection ().selected_foreach ( (l_model, path, iter)  =>
					{
						l_model.get (iter, 1, out item);
						if (item != null)
							text += item.get_text ();
					});
					controller.add_text_item.begin (ClipboardType.NONE, text, null);
				});
			buttons.add (button);

			box.add (buttons);

			// Create other buttons from menu items
			var menu = controller.get_recent_menu ();
			var widgets = menu.get_children ();
			bool insert = false; // Are we above or below separator?
			foreach (var widget in widgets)
			{
				if (widget is SeparatorMenuItem)
				{
					// Insert separator
					var separator = new Separator (Gtk.Orientation.HORIZONTAL);
					separator.margin_left = 20;
					separator.margin_right = 20;
					box.add (separator);
					insert = true;
				} else if (insert)
				{
					var menu_item = widget as Gtk.MenuItem;
					if (menu_item.label == "Open Manager") // Manager is open, no need to open another
						continue;

					// Create button from item
					button = new Button.with_label (menu_item.label);
					button.margin_left = 10;
					button.margin_right = 10;
					button.relief = ReliefStyle.NONE;
					button.always_show_image = true;
					button.use_stock = true;
					button.xalign = 0.0f;
					button.use_stock = true;
					button.clicked.connect ( () => menu_item.activate ());
					box.add (button);
				}
			}

			// Create search box
			var search = new Entry ();
			search.placeholder_text = "Search";
			search.margin = 10;
			search.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear");
			search.icon_press.connect (() => search.set_text (""));
			search.changed.connect ( () =>
				{
					if (search.text == "")
					{
						reset.begin (model);
						window.resize (1, 1);
					} else
						// Do the search
						controller.get_items_by_search_query.begin (search.text, null, ClipboardTimerange.ALL, null, (obj, res) =>
							{
								TreeIter iter;
								model.clear ();
								var items = controller.get_items_by_search_query.end (res);

								foreach (var item in items)
								{
									model.append (out iter);
									model.set (iter, 0, item.get_label (), 1, item);
								}

								if (items.size < 1)
								{
									model.append (out iter);
									model.set (iter, 0, "<No results>");
								}
								window.resize (1, 1);
							});
				});
			box.add (search);

			window.show_all ();
		}

		/*
		 * Clear select, then populate from reacent items.
		 */
		private async void reset (ListStore model)
		{
			TreeIter iter;
			model.clear ();
			var items = yield controller.get_recent_items ();
			foreach (var item in items)
			{
				model.append (out iter);
				model.set (iter, 0, item.get_label (), 1, item);
			}
		}

		/*
		 * Creates the Preferences window in Diodon's Plugin Preferences.
		 */
		public Gtk.Widget create_configure_widget ()
		{
			accelerator = settings.get_string ("accelerator");

			var box = new Gtk.Grid ();
			box.attach (new Gtk.Label ("Manager Key"), 0, 0, 1, 1);
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
									   typeof (Diodon.Plugins.ManagerPlugin));
	objmodule.register_extension_type (typeof (PeasGtk.Configurable),
									   typeof (Diodon.Plugins.ManagerPlugin));

}
