/*
 * Paste All a plugin for Diodon
 * Copyright (C) 2017 Timothy Jonson <timothy@idioticdev.com>
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
	 * @author Timothy Jonson <timothy@idioticdev.com>
	 */
	public class PasteAllPlugin : Peas.ExtensionBase, Peas.Activatable, PeasGtk.Configurable
	{
		private Controller controller;
		private string append;
		private Gtk.MenuItem menuitem;

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
			controller = object as Controller;

			append = settings.get_string ("append");
			menuitem = new Gtk.MenuItem.with_label ("Paste All");
			menuitem.activate.connect (() => paste_all.begin ());
			controller.add_static_recent_menu_item.begin (menuitem);

			controller.add_command_line_action ("paste-all",
				"Paste all recent clipboard items.", args => paste_all.begin ());
		}

		public void deactivate () {
			menuitem.destroy();
		}

		public void update_state () {}

		/*
		 * The actual Paste All functionality.
		 */
		private async void paste_all ()
		{
			// Build string of resent items
			var items = yield controller.get_recent_items ();
			var text = "";
			foreach (IClipboardItem item in items)
				text += item.get_text () + append;

			// Create masive item then paste
			var temp = new TextClipboardItem (ClipboardType.NONE, text, null,  new DateTime.now_utc ());
			yield controller.add_item (temp);
			yield controller.select_item (temp);
			controller.execute_paste (temp);
			yield controller.remove_item (temp);

		}

		/*
		 * Creates the Preferences window in Diodon's Plugin Preferences.
		 */
		public Gtk.Widget create_configure_widget ()
		{
			var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
			box.margin = 10;
			box.add (new Gtk.Label ("Append"));
			var append_entry = new Gtk.Entry ();
			settings.bind ("append", append_entry, "text", SettingsBindFlags.DEFAULT);
			box.add (append_entry);
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
