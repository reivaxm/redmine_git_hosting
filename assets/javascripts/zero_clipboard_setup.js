var zero_clipboard_source_input_control_id = "git_url_text";
var clipboard = null

function reset_zero_clipboard()
{
	var clip_container = $('#clipboard_container');
	if (clip_container) {
		clip_container.show();
		clip_container.css('font-family','serif');

		$.each(clip_container.children(),function(i,o){if(o.id != "clipboard_button"){clip_container.remove(o);}});

		clipboard = new ZeroClipboard.Client();

		clipboard.setHandCursor(true);
		clipboard.glue('clipboard_button', 'clipboard_container');

		$(clipboard).mouseover(function(client){
			clipboard.setText($(zero_clipboard_source_input_control_id).value);
		});
	}
}

function setZeroClipboardInputSource(id)
{
	zero_clipboard_source_input_control_id = id;
}

$(document).on('ready', function() { reset_zero_clipboard(); } )
