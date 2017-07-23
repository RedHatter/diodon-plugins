/*
 * Numbers a plugin for Diodon
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

using Gtk;

namespace Diodon.Plugins
{
	/*
	 * Number clipboard menu items.
	 *
	 * @author Timothy Jonson <timothy@idioticdev.com>
	 */
	public class NumbersPlugin : Peas.ExtensionBase, Peas.Activatable
	{
		private Controller controller;

		public Object object { get; construct; }

		public NumbersPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			controller = object as Controller;
			controller.on_recent_menu_changed.connect (number_menu);
			number_menu (controller.get_recent_menu ());
		}

		public void number_menu (Gtk.Menu menu)
		{
			var items = menu.get_children ();
			for (var i = 0; i < items.length (); i++)
			{
				var item = (Gtk.MenuItem) items.nth_data (i);
				if (item is Gtk.SeparatorMenuItem)
					break;

				item.label = "%2d    %s".printf (i + 1, item.label);
			}
		}

		public void deactivate () {
			controller.rebuild_recent_menu();
		}

		public void update_state () {}
	}
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
	Peas.ObjectModule objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type (typeof (Peas.Activatable),
									   typeof (Diodon.Plugins.NumbersPlugin));
}
