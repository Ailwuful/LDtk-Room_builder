draw_self();
if (global.pause) exit;

draw_text_ext(192,96,output_string,30,580);

if (position_meeting(mouse_x,mouse_y,self)) {
	var str = "Build Rooms";
	var str_size = string_width(str);
	draw_set_color(c_black);
	draw_rectangle(bbox_right+10,bbox_top-30,bbox_right+20+str_size,bbox_top+5,false);
	draw_set_color(c_white);
	draw_text(bbox_right+15,bbox_top-25,str);
}
