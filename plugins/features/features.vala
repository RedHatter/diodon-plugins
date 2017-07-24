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
		public Controller controller;
		public Gee.List<string> pinned_items;

		private GLib.Settings _settings;
		private GLib.Settings settings
		{
			get
			{
				if (_settings == null)
					_settings = new GLib.Settings ("com.diodon.plugins.features");

				return _settings;
			}
		}

		public Object object { get; construct; }

		public FeaturesPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			controller = object as Controller;

			// Load pinned items
			pinned_items = new Gee.ArrayList<string>.wrap (settings.get_strv ("pinned"));

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
			// Find last separator
			var list = menu.get_children ();
			var i = 0;
			for (i = (int) list.length ()-1; i >= 0; i--)
				if (list.nth_data (i) is SeparatorMenuItem)
					break;

			// Remove items
			for (i--; i >= 0; i--)
				menu.remove (list.nth_data (i));

			// Insert pinned menu items
			for (i = 0; i < pinned_items.size; i++)
			{
				var item = yield controller.get_item_by_checksum (pinned_items[i]);
				if (item == null)
				{
					pinned_items.remove_at (i--);
					continue;
				}

				menu.prepend (new ClipboardMenuItem (item, this));
			}

			save_pinned_items ();

			if (pinned_items.size > 0)
			{
				var item = new SeparatorMenuItem ();
				item.show ();
				menu.prepend (item);
			}

			var filter = new Filter (this);
			menu.prepend (filter);
			filter.show ();
			menu.key_press_event.connect (filter.key_press_event);
			menu.hide.connect (filter.clear);

			// Create and insert new menu items
			var items = yield controller.get_recent_items ();
			for (i = items.size-1; i >= 0; i--)
				menu.prepend (new ClipboardMenuItem (items[i], this));
		}

		/**
		 * Save pinned item checksums to settings.
		 */
		public void save_pinned_items ()
		{
			// Collection.to_array () causes seg fault
			var array = new string[pinned_items.size];
			for (var i = 0; i < pinned_items.size; i++)
				array[i] = pinned_items[i];

			settings.set_strv ("pinned", array);
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
	objmodule.register_extension_type (
		typeof (Peas.Activatable),
		typeof (Diodon.Plugins.FeaturesPlugin)
	);
}
