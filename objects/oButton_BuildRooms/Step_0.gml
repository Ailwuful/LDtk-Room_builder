if (global.pause) exit;

if (file_exists(global.LDtk_path) and directory_exists(Dir)) {
	image_alpha = 1;
	if ((position_meeting(mouse_x,mouse_y,self) and mouse_check_button_pressed(mb_left)) or keyboard_check_released(vk_enter)) {
		var file = file_text_open_read(global.LDtk_path);
			
		var json_string = "";
		while (!file_text_eof(file)) {
			json_string += file_text_read_string(file);
			file_text_readln(file);
		}
		file_text_close(file);
		
		LDtk_struct = json_parse(json_string);
		
		room_create();
	}
}
else {
	image_alpha = 0.5;
}

if (keyboard_check_pressed(ord("Q"))) game_end();
if (keyboard_check_pressed(vk_space)) {
	show_debug_message(Dir);
	if (file_exists(Dir+ "/objects/oLock/oLock" +".yy")) show_debug_message("it exists");
}
/*
if (position_meeting(mouse_x,mouse_y,self)) {
	if (mouse_check_button_pressed(mb_left)) {
		if (global.LDtk_path != "" and file_exists(global.LDtk_path))	{
			var file = file_text_open_read(global.LDtk_path);
			
			var json_string = "";
			while (!file_text_eof(file)) {
				json_string += file_text_read_string(file);
				file_text_readln(file);
			}
			file_text_close(file);
		
			LDtk_struct = json_parse(json_string);
		}
		output_string += room_create();
	}
}

if (keyboard_check_released(vk_enter)) {
	if (global.LDtk_path != "" and file_exists(global.LDtk_path))	{
		var file = file_text_open_read(global.LDtk_path);
			
		var json_string = "";
		while (!file_text_eof(file)) {
			json_string += file_text_read_string(file);
			file_text_readln(file);
		}
		file_text_close(file);
		
		LDtk_struct = json_parse(json_string);
	}
	output_string += room_create();
}*/
