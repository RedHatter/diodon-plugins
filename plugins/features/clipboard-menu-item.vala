using Gtk;

namespace Diodon.Plugins
{
	public class ClipboardMenuItem : Gtk.ImageMenuItem
	{
		private static Widget shown;

		private Button pin;
		private string checksum;
		private Controller controller;
		private PinnedItems pinned_items;

		public ClipboardMenuItem (IClipboardItem item, Controller controller, PinnedItems pinned_items)
		{
			this.controller = controller;
			this.pinned_items = pinned_items;
			checksum = item.get_checksum();

			// check if image needs to be shown
			Gtk.Image? image = item.get_image();
			if (image != null)
			{
				set_image(image);
				set_always_show_image(true);
			}

			activate.connect (() =>
				controller.select_item_by_checksum.begin (checksum));

			// Wrap label in box
			var box = new Overlay ();
			add (box);
			box.show ();
			var label = new Label (item.get_label ());
			label.halign = Align.START;
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
				controller.get_recent_menu ().popdown ();
				edit.begin ();
				return true;
			});
			button.get_style_context ().add_class ("icon_button");
			buttons.add (button);

			pin = new Button.from_icon_name (pinned_items.is_pinned(checksum)
				? "diodon-pin-down" : "diodon-pin-up", IconSize.MENU);
			pin.button_release_event.connect ((event) => {
				togglePin ();
				return true;
			});

			pin.get_style_context ().add_class ("icon_button");
			buttons.add (pin);

			button = new Button.from_icon_name ("diodon-delete", IconSize.MENU);
			button.button_release_event.connect ((event) =>
			{
				@remove.begin ();
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
		 * Remove item from controller and menu.
		 */
		public async void remove ()
		{
			// Remove item
			yield controller.remove_item (yield controller.get_item_by_checksum (checksum));
			var menu = controller.get_recent_menu ();
			menu.remove (this);
		}

		/**
		 * Open input dialog to edit clipboard item.
		 */
		public async void edit ()
		{
			var item = yield controller.get_item_by_checksum (checksum);
			var dialog = new Dialog.with_buttons ("Edit", null, DialogFlags.MODAL,
				"_OK", ResponseType.ACCEPT, "_Cancel", ResponseType.REJECT, null);
			var text_view = new TextView ();
			text_view.buffer.text = item.get_text ();
			dialog.get_content_area ().add (text_view);

			var provider = new CssProvider ();
			var css = "textview { padding: 30px; }";
			provider.load_from_data (css, css.length);
			text_view.get_style_context().add_provider (
				provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

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

		/**
		 * Pin clipboard item causing it to 'stick' to the bottom of the menu.
		 */
		public async void togglePin ()
		{
			if (pinned_items.is_pinned(checksum))
				pinned_items.unpin(checksum);
			else
				pinned_items.pin(checksum);

			controller.rebuild_recent_menu();
		}
	}
}
