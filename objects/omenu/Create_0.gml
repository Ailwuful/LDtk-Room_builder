container = new EmuCore(20, 20, window_get_width() - 40, window_get_height() - 40, "LDtk Room Builder");

var list = new EmuList(170, 60, 400, 32, "Select levels to build: ", 32, 20, function() {
	
});
list.SetMultiSelect(true, true, true);
list.SetVacantText("Select an LDtk file or reload the room list");
list.SetID("RoomList");
//list.AddEntries(["test1", "test2", "test3"]);
//list.ClearSelection();
//list.Select(1,false);
//list.Select(2,false);
container.AddContent(list);

var reload_button = new EmuButton(380, 40, 180, 40, "Load Level List", function() {
	if (!file_exists(global.LDtk_path)) {
		oMenu._string = "Couldn't load level list.\nLDtk file not found";
	}
	
	LDtk_parse();
	var level_names = [];
	for (var i = 0; i < array_length(LDtk_struct.levels); i++) {
		array_push(level_names,LDtk_struct.levels[i].identifier);
	}
	self.GetSibling("RoomList").Clear().AddEntries(level_names);
	var len = array_length(global.selected_levels);
	if (len > 0) {
		self.GetSibling("RoomList").ClearSelection();
		for (i = 0; i < len; i++) {
			self.GetSibling("RoomList").Select(global.selected_levels[i]);
		}
	}
});
container.AddContent(reload_button);

var button = new EmuButton(20,460,130,100,"Build Rooms", function() {
	if (!file_exists(global.LDtk_path)) {
		oMenu._string = "LDtk file not selected or doesn't exist";
		return;
	}
	if (!directory_exists(Dir)) {
		oMenu._string = "GameMaker project not selected or doesn't exist";
		return;
	}
	oMenu._string = "Building...";
	
	global.selected_levels = self.GetSibling("RoomList").GetAllSelectedIndices();
	if (array_length(global.selected_levels) > 0) {
		ini_open("data.ini");
		var selected_levels_string = json_stringify(global.selected_levels);
		ini_write_string("Paths","Levels",selected_levels_string);
		ini_write_real("Paths","IntGrid",global.build_IntGrid);
		ini_close();
		room_create(false);
	}else {
		room_create(true);
	}
});

container.AddContent(button);

button = new EmuButton(10,150,150,70,"Select LDtk File",function() {
	global.LDtk_path = get_open_filename("LDtk file|*.ldtk", "");
		
	if (global.LDtk_path != "") {
		ini_open("data.ini");
		ini_write_string("Paths","LDtk",global.LDtk_path);
		ini_close();
	}else {
		oMenu._string = "LDtk file not selected.\nSelect the LDtk file."
	}
});
container.AddContent(button);

button = new EmuButton(10,300,150,70,"Select Project File", function() {
	var file_path;
	file_path = get_open_filename("Project file|*.yyp", "");
	if (file_path != "")	{
		Dir = filename_dir(file_path);
			
		ini_open("data.ini");
		ini_write_string("Paths","Project",Dir);
		ini_close();
	}else {
		oMenu._string = "Directory for GameMaker project not selected.\nSelect GameMaker project yyp file.";
	}
});
container.AddContent(button);

button = new EmuButtonImage(1088,32,48,48,spr_emu_help,0,c_white,1,true,function() {
	oMenu._string = "The LDtk to GameMaker room builder requires that "+
"you already have rooms and objects with the same name created in your project.\n\n"+
"Entities names must match the names of your objetcs.\n"+
"Level names must match the names of rooms.\n"+
"Also, LDtk levels sizes must be perfectly divisable by the grid size.\n\n"+
"Click \"Load Level List\" to open a list of levels and select which GameMaker rooms to build.\n\n"+
"Click \"Build Rooms\" to build all selected Levels or all Levels by default."+
"Selecting Minify JSON in LDtk will greatly increase build speed.";
});
container.AddContent(button);

_string = "The LDtk to GameMaker room builder requires that "+
"you already have rooms and objects with the same name created in your project.\n\n"+
"Entities names must match the names of your objetcs.\n"+
"Level names must match the names of rooms.\n"+
"Also, LDtk levels sizes must be perfectly divisable by the grid size.\n\n"+
"Click \"Load Level List\" to open a list of levels and select which GameMaker rooms to build.\n\n"+
"Click \"Build Rooms\" to build all selected Levels or all Levels by default.\n\n"+
"Selecting Minify JSON in LDtk will greatly increase build speed.";
/*
button = new EmuCheckbox(10, 640, 120, 60, "Build\nIntGrid layer",global.build_IntGrid,function() {
	global.build_IntGrid = !global.build_IntGrid;
});
container.AddContent(button);
 */

/*
if (file_exists(global.LDtk_path)) {
		var file = file_text_open_read(global.LDtk_path);
			
		var json_string = "";
		while (!file_text_eof(file)) {
			json_string += file_text_read_string(file);
			file_text_readln(file);
		}
		file_text_close(file);
		
		LDtk_struct = json_parse(json_string);
	}
	*/
/*
var levels = "[2,1,0]";
var jso = json_parse(levels);
show_debug_message(is_array(jso));
show_debug_message(jso[0]);
levels = json_stringify(jso);
show_debug_message(levels);
jso = json_parse(levels);
show_debug_message(jso[1]);*/