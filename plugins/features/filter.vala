using Gtk;

namespace Diodon.Plugins
{
	public class Filter : Gtk.ImageMenuItem
	{
		private string filter;
		private Label label;
		private FeaturesPlugin features;

		public Filter (FeaturesPlugin features)
		{
			this.features = features;
			filter = "";
			
			sensitive = false;

			label = new Label ("<i>Type to start searching</i>");
			label.use_markup = true;
			label.halign = Align.CENTER;
			add (label);
			label.show ();
		}

		public void clear ()
		{
			if (filter == "")
				return;

			filter = "";
			filter_menu.begin ();
		}

		/**
		 * Process key presses while menu is open.
		 */
		public bool key_press_event (Gdk.EventKey event)
		{
			switch (event.keyval)
			{
				case 65307: // ESC
					features.controller.get_recent_menu ().popdown ();
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
					var menu = features.controller.get_recent_menu ();
					if (menu.get_selected_item () == null)
						((Gtk.MenuItem) menu.get_children ().nth_data (0)).enter_notify_event (null);

					return false;
				default:
					if (event.is_modifier == 1 || !event.str.is_ascii ())
						return false;

					filter += event.str;
					break;
			}

			filter_menu.begin ();

			return true;
		}

		/**
		 * Display items matching filter instead of most resent.
		 */
		private async void filter_menu ()
		{
			if (filter == "")
			{
				features.process_menu.begin (features.controller.get_recent_menu ());
				return;
			}

			label.label = "<i>Searching</i> — " + filter;

			// Replace items
			var menu = features.controller.get_recent_menu ();
			var list = menu.get_children ();
			var items = yield features.controller.get_items_by_search_query (filter);
			var i = -1;
			for (i = 0; i < list.length (); i++)
			{
				if (list.nth_data (i) == this)
					break;

				if (i < items.size)
					menu.insert (new ClipboardMenuItem (items[i], features), i);

				menu.remove (list.nth_data (i));
			}

			for (; i < items.size && i < 25; i++)
				menu.insert (new ClipboardMenuItem (items[i], features), i);
		}


	}
}
