/*
 * Features a plugin for Diodon
 * Copyright (C) 2018 Timothy Johnson <timothy@idioticdev.com>
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
	public class PinnedItems : Object {
		private GenericArray<string> checksums;
		private Controller controller;
		private GLib.Settings settings;

		public PinnedItems (Controller controller) {
			this.controller = controller;

			// Load pinned items
			settings = new GLib.Settings ("com.diodon.plugins.features");
			var array = settings.get_strv ("pinned");
			checksums = new GenericArray<string> (array.length);
			foreach (var item in array)
				checksums.add (item);
		}

		/**
		 * Save pinned item checksums to settings.
		 */
		public void save_pinned_items ()
		{
			settings.set_strv ("pinned", checksums.data);
		}

		public async void patch (Gtk.Menu menu, int n) {
			for (var i = checksums.length - 1; i >= 0; i--) {
				var item = yield controller.get_item_by_checksum (checksums[i]);
				if (item == null)
					checksums.remove_index (i++);
				else
					menu.insert (new ClipboardMenuItem (item, controller, this), n++);
			}

			if (checksums.length > 0)
			{
				var item = new SeparatorMenuItem ();
				item.show ();
				menu.insert (item, n++);
			}
		}

		public void pin (string checksum)
		{
			checksums.add(checksum);
		}

		public void unpin (string checksum)
		{
			for (var i = 0; i < checksums.length; i++)
			{
				if (checksums[i] != checksum)
					continue;

				checksums.remove_index(i);
				return;
			}
		}

		public bool is_pinned (string checksum)
		{
			for (var i = 0; i < checksums.length; i++)
			{
				if (checksums[i] == checksum)
					return true;
			}

			return false;
		}
	}
}