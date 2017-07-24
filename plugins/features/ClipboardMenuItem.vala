using Gtk;

namespace Diodon.Plugins
{
	public class ClipboardMenuItem : Gtk.ImageMenuItem
	{
		private static Widget shown;

		private string checksum;
		private FeaturesPlugin features;

		public ClipboardMenuItem (IClipboardItem item, FeaturesPlugin features)
		{
			checksum = item.get_checksum();
			this.features = features;

			// check if image needs to be shown
			Gtk.Image? image = item.get_image();
			if (image != null)
			{
				set_image(image);
				set_always_show_image(true);
			}

			activate.connect (() =>
				features.controller.select_item_by_checksum.begin (checksum));

			// Wrap label in box
			var box = new Overlay ();
			add (box);
			box.show ();
			var label = new Label (item.get_label ());
			box.add (label);
			label.show ();

			// Create icon buttons
			var buttons = new Box (Orientation.HORIZONTAL, 0);
			buttons.margin_end = 5;
			buttons.halign = Align.END;
			buttons.valign = Align.CENTER;
			buttons.get_style_context().add_class(Gtk.STYLE_CLASS_LINKED);
			box.add_overlay (buttons);

			var button = new Button.from_icon_name ("diodon-edit", IconSize.MENU);
			button.button_release_event.connect ((event) =>
			{
				features.controller.get_recent_menu ().popdown ();
				edit.begin ();
				return true;
			});
			button.get_style_context ().add_class ("icon_button");
			buttons.add (button);

			if (features.pinned_items.contains (checksum))
			{
				button = new Button.from_icon_name ("diodon-pin-down", IconSize.MENU);
				button.button_release_event.connect ((event) =>
				{
					unpin ();
					return true;
				});
				button.get_style_context ().add_class ("icon_button");
				buttons.add (button);
			} else
			{
				button = new Button.from_icon_name ("diodon-pin-up", IconSize.MENU);
				button.button_release_event.connect ((event) =>
				{
					pin.begin ();
					return true;
				});
				button.get_style_context ().add_class ("icon_button");
				buttons.add (button);
			}

			button = new Button.from_icon_name ("diodon-delete", IconSize.MENU);
			button.button_release_event.connect ((event) =>
			{
				@delete.begin ();
				return true;
			});
			button.get_style_context ().add_class ("icon_button");
			buttons.add (button);

			// Show buttons
			select.connect (() =>
			{
				if (shown != null)
					shown.hide ();

				buttons.show_all ();
				shown = buttons;
			});

			// Keep menu item selected
			leave_notify_event.connect ((event) =>
			{
				var bounds = Gdk.Rectangle ();
				box.get_child_position (buttons, out bounds);
				if (event.x > bounds.x && (int) event.x <= bounds.x + bounds.width + 15)
					return true;

				shown.hide ();
				return false;
			});

			buttons.hide ();
			show ();
		}

		/**
		 * Remove item from features.controller and menu.
		 */
		public async void delete ()
		{
			// Remove item
			yield features.controller.remove_item (yield features.controller.get_item_by_checksum (checksum));
			var menu = features.controller.get_recent_menu ();
			menu.remove (this);

			// Find first separator
			var list = menu.get_children ();
			var i = 0;
			for (i = 0; i < list.length (); i++)
				if (list.nth_data (i) is SeparatorMenuItem)
					break;

			// Create and insert new menu items
			var items = yield features.controller.get_recent_items ();
			for (i--; i < items.size; i++)
			{
				var new_item = new ClipboardMenuItem (items[i], features);
				new_item.show ();
				menu.insert (new_item, i);
			}
		}

		/**
		 * Open input dialog to edit clipboard item.
		 */
		public async void edit ()
		{
			var item = yield features.controller.get_item_by_checksum (checksum);
			var dialog = new Dialog.with_buttons ("Edit", null, DialogFlags.MODAL,
				"_OK", ResponseType.ACCEPT, "_Cancel", ResponseType.REJECT, null);
			var text_view = new TextView ();
			text_view.buffer.text = item.get_text ();
			dialog.get_content_area ().add (text_view);

			var provider = new CssProvider ();
			var css = "textview { padding: 50px; }";
			provider.load_from_data (css, css.length);
			text_view.get_style_context().add_provider (
				provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

			dialog.response.connect ((id) =>
			{
				switch (id)
				{
					case ResponseType.ACCEPT:
						features.controller.remove_item.begin (item);
						features.controller.add_text_item.begin (item.get_clipboard_type (), text_view.buffer.text, item.get_origin ());
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

		/**
		 * Pin clipboard item causing it to 'stick' to the bottom of the menu.
		 */
		public async void pin ()
		{
			features.pinned_items.add (checksum);
			features.save_pinned_items ();

			var menu = features.controller.get_recent_menu ();

			// Find first separator
			var list = menu.get_children ();
			for (var i = 0; i < list.length (); i++)
				if (list.nth_data (i) is SeparatorMenuItem)
				{
					// Add new menu item
					menu.insert (new ClipboardMenuItem (
						yield features.controller.get_item_by_checksum (checksum), features), ++i);

					if (features.pinned_items.size == 1)
					{
						var separator = new SeparatorMenuItem ();
						menu.insert (separator, ++i);
						separator.show ();
					}

					break;
				}
		}

		/**
		 * Unpin clipboard item.
		 */
		public void unpin ()
		{
			// Find first separator
			var menu = features.controller.get_recent_menu ();
			var children = menu.get_children ();
			var position = -1;
			for (var i = 0; i < children.length (); i++)
				if (children.nth_data (i) is SeparatorMenuItem)
				{
					position = features.pinned_items.size - features.pinned_items.index_of (checksum) + i;
					break;
				}

			features.pinned_items.remove (checksum);
			features.save_pinned_items ();

			menu.remove (children.nth_data (position));
			if (features.pinned_items.size < 1)
				menu.remove (children.nth_data (position + 1));
		}
	}
}
