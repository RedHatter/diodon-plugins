/*
 * Pop Item a plugin for Diodon
 * Copyright (C) 2017 Timothy Johnson <timothy@idioticdev.com>
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
	 * Pastes and then removes the active clipboard item.
	 *
	 * @author Timothy Johnson <timothy@idioticdev.com>
	 */
	public class PopPlugin : Peas.ExtensionBase, Peas.Activatable, PeasGtk.Configurable
	{
		private Controller controller;

		public static bool should_pop;

		public Object object { get; construct; }

		public PopPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			controller = object as Controller;
			controller.add_command_line_action ("pop",
				"Pastes and then removes the active clipboard item.",
				(args) => pop.begin ());
		}

		public void deactivate () {}

		public void update_state () {}

		private async void pop ()
		{
			var items = yield controller.get_recent_items ();
			yield controller.select_item (items[0]);
			yield controller.remove_item (items[0]);
			yield controller.rebuild_recent_menu ();
		}

		/*
		 * Creates the Preferences window in Diodon's Plugin Preferences.
		 */
		public Gtk.Widget create_configure_widget ()
		{
			var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
			box.margin = 50;
			var label = new Gtk.Label (null);
			label.set_markup ("Please register a custom shortcut with
your desktop environment.
Use <b>/usr/bin/diodon pop</b> as the command.");
			box.add (label);
			box.show_all ();

			return box;
		}
	}
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
	Peas.ObjectModule objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type (
		typeof (Peas.Activatable),
		typeof (Diodon.Plugins.PopPlugin)
	);
	objmodule.register_extension_type (
		typeof (PeasGtk.Configurable),
		typeof (Diodon.Plugins.PopPlugin)
	);
}
