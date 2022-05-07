if (global.pause) exit;

if (file_exists(global.LDtk_path)) {
	image_index = 2;
}else {
	image_index = 1;
}

if (position_meeting(mouse_x,mouse_y,self)) {
	if (mouse_check_button_pressed(mb_left)) {
		global.LDtk_path = get_open_filename("LDtk file|*.ldtk", "");
		
		if (global.LDtk_path != "") {
			ini_open("data.ini");
			ini_write_string("Paths","LDtk",global.LDtk_path);
			ini_close();
		}
	}
}


