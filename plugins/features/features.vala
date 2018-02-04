/*
 * Features a plugin for Diodon
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
	 * Features Plugin for Diodon providing item filtering, editing, deletion,
	 * and pinning.
	 *
	 * @author RedHatter <_c_@mail.com>
	 */
	public class FeaturesPlugin : Peas.ExtensionBase, Peas.Activatable
	{
		private PinnedItems pinned_items;
		private Filter filter;

		public Controller controller;

		public Object object { get; construct; }

		public FeaturesPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			controller = object as Controller;

			pinned_items = new PinnedItems(controller);
			filter = new Filter(controller, pinned_items);

			// Rebuild the menu
			process_menu.begin (controller.get_recent_menu ());
			controller.on_recent_menu_changed.connect (process_menu);
		}

		/**
		 * Replace all items with custom ones. Also adds the filter label and
		 * pinned items.
		 *
		 * @param menu menu containing items.
		 */
		public async void process_menu (Gtk.Menu menu)
		{
			var i = yield filter.patch(menu);
			yield pinned_items.patch(menu, i);
		}

		public void deactivate () {
			controller.rebuild_recent_menu.begin();
		}

		public void update_state () {}
	}
}


[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
	Peas.ObjectModule objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type (
		typeof (Peas.Activatable),
		typeof (Diodon.Plugins.FeaturesPlugin)
	);
}
