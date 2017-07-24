/*
 * Dbus Controller a plugin for Diodon
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
	 * Exposes the Controller api as a DBus service.
	 *
	 * @author Timothy Johnson <timothy@idioticdev.com>
	 */
	public class DBusControllerPlugin : Peas.ExtensionBase, Peas.Activatable
	{
		private Controller controller;
		private uint owner_id;

		public Object object { get; construct; }

		public DBusControllerPlugin ()
		{
			Object ();
		}

		public void activate ()
		{
			controller = object as Controller;
			owner_id = Bus.own_name (BusType.SESSION, "net.launchpad.diodon.Controller", BusNameOwnerFlags.NONE,
				conn => {
					try {
						conn.register_object ("/net/launchpad/diodon/Controller", new DBusController (controller));
					} catch (IOError e) {
						stderr.printf ("Could not register service\n");
					}
				},
				() => {},
				() => stderr.printf ("Could not aquire name\n"));
		}

		public void deactivate ()
		{
			Bus.unown_name(owner_id);
		}

		public void update_state () {}
	}

	[DBus (name = "net.launchpad.diodon.Controller")]
	public class DBusController : Object {
		private Controller controller;

		public signal void on_select_item(GLib.HashTable<string,string> item);

		public signal void on_add_item(GLib.HashTable<string,string> item);

		public signal void on_remove_item(GLib.HashTable<string,string> item);

		public signal void on_clear();

		public DBusController (Controller controller) {
			this.controller = controller;
			controller.on_select_item.connect(item => on_select_item(item_to_dictionary(item)));
			controller.on_add_item.connect(item => on_add_item(item_to_dictionary(item)));
			controller.on_remove_item.connect(item => on_remove_item(item_to_dictionary(item)));
			controller.on_clear.connect(() => on_clear());
		}

		public void execute_paste () {
			controller.execute_paste(
				controller.get_current_item(ClipboardType.CLIPBOARD));
		}

		public async void remove_item_by_checksum (string checksum) {
			yield controller.remove_item(
				yield controller.get_item_by_checksum(checksum));
		}

		public async void add_text_item (string text, string? origin)
		{
			yield controller.add_text_item(ClipboardType.CLIPBOARD, text, origin);
		}

		public async void add_file_item (string paths, string? origin)
		{
			yield controller.add_file_item(ClipboardType.CLIPBOARD, paths, origin);
		}

		public async GLib.HashTable<string,string>[] get_recent_items (string?[] cats, string date_copied)
		{
			var clipboardCategories = new ClipboardCategory[cats.length];
			for (var i = 0; i < cats.length; i++)
				clipboardCategories[i] = ClipboardCategory.from_string(cats[i]);

			var timerange = date_copied != "" ? ClipboardTimerange.from_string(date_copied) : ClipboardTimerange.ALL;

			var recentItems = yield controller.get_recent_items(clipboardCategories, timerange);
			var array = new GLib.HashTable<string,string>[recentItems.size];
			for (var i = 0; i < recentItems.size; i++)
				array[i] = item_to_dictionary(recentItems[i]);

			return array;
		}

		public async GLib.HashTable<string,string>[] get_items_by_search_query (string search_query, string?[] cats, string date_copied)
		{
			var clipboardCategories = new ClipboardCategory[cats.length];
			for (var i = 0; i < cats.length; i++)
				clipboardCategories[i] = ClipboardCategory.from_string(cats[i]);

			var timerange = date_copied != "" ? ClipboardTimerange.from_string(date_copied) : ClipboardTimerange.ALL;

			var recentItems = yield controller.get_items_by_search_query(search_query, clipboardCategories, timerange);
			var array = new GLib.HashTable<string,string>[recentItems.size];
			for (var i = 0; i < recentItems.size; i++)
				array[i] = item_to_dictionary(recentItems[i]);

			return array;
		}

		public async GLib.HashTable<string,string> get_item_by_checksum (string checksum) {
			var item = yield controller.get_item_by_checksum(checksum);
			return item_to_dictionary(item);
		}

		public GLib.HashTable<string,string> get_current_item () {
			var item = controller.get_current_item(ClipboardType.CLIPBOARD);
			return item_to_dictionary(item);
		}

		public async void select_item_by_checksum (string checksum) {
			yield controller.select_item_by_checksum(checksum);
		}

		public async void rebuild_recent_menu () {
			yield controller.rebuild_recent_menu();
		}

		public void show_history () {
			controller.show_history();
		}

		public void show_preferences () {
			controller.show_preferences();
		}

		public void clear () {
			controller.clear();
		}

		public void quit () {
			controller.quit();
		}

		private GLib.HashTable<string,string> item_to_dictionary (IClipboardItem item) {
			var dictionary = new HashTable<string, string> (str_hash, str_equal);
			dictionary.insert("category", item.get_category().to_string());
			dictionary.insert("label", item.get_label());
			dictionary.insert("mime_type", item.get_mime_type());
			dictionary.insert("text", item.get_text());
			dictionary.insert("checksum", item.get_checksum());
			dictionary.insert("origin", item.get_origin());
			return dictionary;
		}
	}
}

[ModuleInit]
public void peas_register_types (GLib.TypeModule module)
{
	Peas.ObjectModule objmodule = module as Peas.ObjectModule;
	objmodule.register_extension_type (typeof (Peas.Activatable),
										 typeof (Diodon.Plugins.DBusControllerPlugin));
}
