/*
 * Paste All a plugin for Diodon
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

namespace Diodon.Plugins
{

	/*
	 * Plugin for Diodon tht allows you to paste all resent items at once.
	 *
	 * @author RedHatter <_c_@mail.com>
	 */
	public class PasteAllPlugin : Peas.ExtensionBase, Peas.Activatable, PeasGtk.Configurable
	{
		private Controller controller;
		private Gtk.MenuItem item;
		private string accelerator;
		private string append;
		private Settings _settings;
		private Settings settings
		{
			get
			{
				if (_settings == null)
					_settings = new Settings ("com.diodon.plugins.paste-all");
				
				return _settings;
			}
		}

		public Object object { get; construct; }

		public PasteAllPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			debug ("activate");
			controller = object as Controller;
			
			// Register keybinding and set append
			accelerator = settings.get_string ("accelerator");
			bind_accelerator (accelerator);
			append = settings.get_string ("append");
			if (settings.get_boolean ("display"))
			{
				item = new Gtk.MenuItem.with_label ("Paste All");
				item.activate.connect ( () => paste_all.begin ());
				controller.add_static_recent_menu_item (item);
			}
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
		 * The actual Paste All functionality.
		 */
		private async void paste_all ()
		{
			debug ("paste_all");

			// Build string of resent items
			var items = yield controller.get_recent_items ();
			var text = "";
			foreach (IClipboardItem item in items)
				text += item.get_text ()+append;

			// Create masive item then paste
			var temp = new TextClipboardItem (ClipboardType.NONE, text, null,  new DateTime.now_utc ());
			yield controller.add_item (temp);
			yield controller.select_item_by_checksum (temp.get_checksum ());
			controller.execute_paste (temp);
			yield controller.remove_item (temp);

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
				debug ("paste-all unbinding %s", accelerator);
			}
			keybinding_manager.bind (new_accelerator, () => paste_all.begin ());
			accelerator = new_accelerator;
		}

		/*
		 * Creates the Preferences window in Diodon's Plugin Preferences.
		 */
		public Gtk.Widget create_configure_widget ()
		{
			accelerator = settings.get_string ("accelerator");

			var box = new Gtk.Grid ();
			box.attach (new Gtk.Label ("Paste All Key"), 0, 0, 1, 1);
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

			box.attach (new Gtk.Label ("Append"), 0, 1, 1, 1);
			var append_entry = new Gtk.Entry ();
			append_entry.set_text (settings.get_string ("append"));
			append_entry.focus_out_event.connect ( () => {
				var text = append_entry.get_text ();
				if (text != null) {
					settings.set_string ("append", text);
				}
				return false;
			});
			box.attach (append_entry, 1, 1, 1, 1);

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
									   typeof (Diodon.Plugins.PasteAllPlugin));
	objmodule.register_extension_type (typeof (PeasGtk.Configurable),
									   typeof (Diodon.Plugins.PasteAllPlugin));
}
