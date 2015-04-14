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
	public class EditPlugin : Peas.ExtensionBase, Peas.Activatable, PeasGtk.Configurable
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
					_settings = new GLib.Settings ("com.diodon.plugins.edit");
				
				return _settings;
			}
		}

		public Object object { get; construct; }

		public EditPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			debug ("activate");
			controller = object as Controller;

			// Register keybinding and menu item
			accelerator = settings.get_string ("accelerator");
			bind_accelerator (accelerator);
			if (settings.get_boolean ("display"))
			{
				item = new Gtk.MenuItem.with_label ("Edit");
				item.activate.connect ( () => edit.begin ());
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
			keybinding_manager.bind (new_accelerator, () => edit.begin ());
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
		 * Edit active clipboard item.
		 */
		private async void edit ()
		{
			debug ("edit");

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

		/*
		 * Creates the Preferences window in Diodon's Plugin Preferences.
		 */
		public Widget create_configure_widget ()
		{
			accelerator = settings.get_string ("accelerator");

			var box = new Grid ();
			box.attach (new Label ("Edit Key"), 0, 0, 1, 1);
			var accel_text_view = new Entry ();
			accel_text_view.set_text (accelerator);
			accel_text_view.focus_out_event.connect ( () => settings.set_string ("accelerator", accel_text_view.get_text ()));
			box.attach (accel_text_view, 1, 0, 1, 1);

			var check = new CheckButton.with_label ("Display in menu");
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
									   typeof (Diodon.Plugins.EditPlugin));
	objmodule.register_extension_type (typeof (PeasGtk.Configurable),
									   typeof (Diodon.Plugins.EditPlugin));

}
