if (global.pause) exit;

if (directory_exists(Dir)) {
	image_index = 2;
}else {
	image_index = 1;
}

if (position_meeting(mouse_x,mouse_y,self)) {
	if (mouse_check_button_pressed(mb_left)) {
		var file_path;
		file_path = get_open_filename("Project file|*.yyp", "");
		if (file_path != "")	{
			Dir = filename_dir(file_path);
			
			ini_open("data.ini");
			ini_write_string("Paths","Project",Dir);
			ini_close();
		}
	}
}
