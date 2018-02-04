using Gtk;

namespace Diodon.Plugins
{
	public class Filter : Object
	{
		private Gtk.ImageMenuItem item;
		private Gtk.Menu menu;

		private string filter;
		private Label label;
		private Controller controller;
		private PinnedItems pinned_items;

		public Filter (Controller controller, PinnedItems pinned_items)
		{
			this.controller = controller;
			this.pinned_items = pinned_items;
			filter = "";
			label = new Label ("<i>Type to start searching</i>");
			label.use_markup = true;
			label.halign = Align.CENTER;
		}

		public void clear ()
		{
			if (filter == "")
				return;

			filter = "";
			patch.begin (menu);
		}

		/**
		 * Process key presses while menu is open.
		 */
		public bool key_press_event (Gdk.EventKey event)
		{
			switch (event.keyval)
			{
				case 65307: // ESC
					menu.popdown ();
					return true;
				case 65535: // Delete
					filter = "";
					break;
				case 65288: // Backspace
					if (filter != "")
						filter = filter[0:-1];

					break;
				case 65362: // Up
				case 65364: // Down
					return false;
				case 65293: // Enter
					if (menu.get_selected_item () == null)
						((Gtk.MenuItem) menu.get_children ().data).enter_notify_event (null);

					return false;
				default:
					if (event.is_modifier == 1 || !event.str.is_ascii ())
						return false;

					filter += event.str;
					break;
			}

			patch.begin (menu);

			return true;
		}

		/**
		 * Display items matching filter instead of most resent.
		 */
		public async int patch (Gtk.Menu menu)
		{
			this.menu = menu;
			List<Diodon.IClipboardItem> items;

			if (filter == "")
			{
				label.label = "<i>Type to start searching</i>";
				items = yield controller.get_recent_items ();
			} else {
				label.label = "<i>Searching</i> — " + filter;
				items = yield controller.get_items_by_search_query (filter);
			}

			// Replace items
			var max = controller.get_configuration().recent_items_size;
			var menuItems = menu.get_children ();

			var i = 0;
			weak List<Diodon.IClipboardItem> itemNode = items;
			weak List<weak Widget> menuNode = menuItems;
			do
			{
				if (itemNode != null && i < max)
				{
					menu.insert (new ClipboardMenuItem (itemNode.data, controller,  pinned_items), i);
					itemNode = itemNode.next;
				} else {
					itemNode = null;
				}

				if (menuNode != null && menuNode.data != item
					&& !(menuNode.data is SeparatorMenuItem))
				{
					menu.remove (menuNode.data);
					menuNode = menuNode.next;
				} else
				{
					menuNode = null;
				}

				i++;
			} while (itemNode != null || menuNode != null);

			if (item == null)
			{
				item = new Gtk.ImageMenuItem();
				item.sensitive = false;
				item.add (label);
				label.show ();

				menu.insert (item, i - 1);
				i++;
				item.show ();
				menu.key_press_event.connect (this.key_press_event);
				menu.hide.connect (this.clear);
			}

			return i;
		}
	}
}
