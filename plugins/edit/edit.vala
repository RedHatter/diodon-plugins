/*
 * Edit a plugin for Diodon
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
	 * Edit Plugin for Diodon
	 *
	 * @author RedHatter <_c_@mail.com>
	 */
	public class EditPlugin : Peas.ExtensionBase, Peas.Activatable
	{
		private Controller controller;
		private Gtk.MenuItem menuitem;

		public Object object { get; construct; }

		public EditPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			controller = object as Controller;

			menuitem = new Gtk.MenuItem.with_label ("Edit");
			menuitem.activate.connect (() => edit.begin ());
			controller.add_static_recent_menu_item.begin (menuitem);
		}

		public void deactivate () {
			menuitem.destroy();
		}

		public void update_state () {}

		/**
		 * Edit active clipboard item.
		 */
		private async void edit ()
		{
			var item = (yield controller.get_recent_items ())[0];
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
		}
	}
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
	Peas.ObjectModule objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type (typeof (Peas.Activatable),
									   typeof (Diodon.Plugins.EditPlugin));
}
