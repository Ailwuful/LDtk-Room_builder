// feather ignore all
#macro LDtk_struct global.LDTKstruct
#macro Dir global.project_path
global.build_IntGrid = 1;
global.LDTKstruct = -1;
global.project_path = "";
global.LDtk_path = "";
global.pause = false;
global.selected_levels = [];
draw_set_font(Font1);

ini_open("data.ini");

var LD_path = ini_read_string("Paths","LDtk","");
if (LD_path != "") global.LDtk_path = LD_path;

var path = ini_read_string("Paths","Project","");
if (path != "") Dir = path;

var levels = ini_read_string("Paths","Levels","");
if (levels != "") global.selected_levels = json_parse(levels);

global.build_IntGrid = ini_read_real("Paths","IntGrid",1);

ini_close();

function LDtk_parse() {
	//var file = file_text_open_read(global.LDtk_path);
			
	//var json_string = "";
	//while (!file_text_eof(file)) {
	//	json_string += file_text_read_string(file);
	//	file_text_readln(file);
	//}
	//file_text_close(file);
		
	//LDtk_struct = json_parse(json_string);
	
	var buffer = buffer_load(global.LDtk_path);
	var json = buffer_read(buffer, buffer_string);
	LDtk_struct = json_parse(json);
	buffer_delete(buffer);
}

function room_create(all_levels = false) {
	/*
	output_string = "";
	if (LDtk_struct == -1 or !file_exists(global.LDtk_path)) {
		output_string += "LDtk file not selected or found.\n";
		exit;
	}
	if (Dir == "" or !directory_exists(Dir)) {
		output_string += "Project file not selected or found.\n";
		exit;
	}*/
	
	LDtk_parse();
	
	tileset_names = {};
	var tilesets = LDtk_struct.defs.tilesets;
	for (var n = 0; n < array_length(tilesets); n++) {
		tileset_names[$ tilesets[n].uid] = tilesets[n].identifier;
	}
	
	var levels = LDtk_struct.levels;
	if (all_levels) {
		var level_number = array_length(levels);
	}else {
		var level_number = array_length(global.selected_levels);
	}
	
	var inst_number = 0;
	var output_string = "";
	
	for (var n = 0; n < level_number; n++) {
		if (all_levels)	var level = levels[n];
		else			var level = levels[global.selected_levels[n]];
		var level_name = level.identifier;
		var level_path = Dir+"/rooms/"+level_name+"/"+level_name+".yy";
		
		//If file doesn't already exist with the same name, it moves to the next level
		if (!file_exists(level_path)) {
			output_string += "Couldn't find room asset with name "+level_name+".\n";
			continue;
		}
		var _depth = 0; //depth is increased by 100 everytime a layer is inserted in the string
		
		var buffer = buffer_load(level_path);
		var level_json = buffer_read(buffer, buffer_string);
		level_json = json_parse(level_json);
		buffer_delete(buffer);
		
		//var level_file = file_text_open_read(level_path);
		//var level_json = "";
		//while (!file_text_eof(level_file)) {
		//	level_json += file_text_read_string(level_file);
		//	file_text_readln(level_file);
		//}
		//level_json = json_parse(level_json);
		//file_text_close(level_file);
		
		rm = {
			name : level_name,
			width : level.pxWid, //div LDtk_struct.defaultGridSize * LDtk_struct.defaultGridSize,
			height : level.pxHei, //div LDtk_struct.defaultGridSize * LDtk_struct.defaultGridSize,
			bg_color : color_to_decimal(level.__bgColor),
			room_string : room_string_build_first(),
			parent : {
				name : level_json.parent.name,
				path : level_json.parent.path,
			},
			instanceCreationOrder : "",
			path : "rooms/"+level_name+"/"+level_name+".yy"
		}
			
		var LDtk_layers = level.layerInstances;
		var LDtk_layers_number = array_length(LDtk_layers);
		
		for (var i = 0; i < LDtk_layers_number; i++) {
			var l = LDtk_layers[i];
			var o = 0;
			
			if (l.__type == "Entities") {
				var e = l.entityInstances;
				var e_number = array_length(e);
				
				if (e_number > 0) {
					
					var gridSize = string(l.__gridSize);
					rm.room_string += "{\"instances\":[\n";
					
					while (o < e_number) {
						var obj_name = e[o].__identifier;
						if (!file_exists(Dir+"/objects/"+obj_name+"/"+obj_name+".yy")) {o++; output_string += "Object of name "+obj_name+" not found.\n"; continue;}
						
						var entity_index = array_find_index(LDtk_struct.defs.entities,method({obj : obj_name}, function(_val, _ind) {
							return _val.identifier == obj;
						}));
						var obj_color = "4294967295",
							obj_scaleX = string(e[o].width / LDtk_struct.defs.entities[entity_index].width),
							obj_scaleY = string(e[o].height / LDtk_struct.defs.entities[entity_index].height),
							obj_image_speed = "1.0",
							obj_image_index = "0",
							obj_image_angle = "0.0",
							obj_properties = "[";
						
						if (array_length(e[o].fieldInstances) > 0) { //Add fields to instance parameters if any
							var fields = e[o].fieldInstances;
							var f_number = array_length(fields);
							var _n = 0;
							repeat(f_number) {
								if (fields[_n].__type == "Color") obj_color = string(color_to_decimal(fields[_n].__value));
								else if (fields[_n].__type == "Float" or fields[_n].__type == "Integer") {
									if (fields[_n].__identifier == "image_angle") obj_image_angle = string(fields[_n].__value);
									else if (fields[_n].__identifier == "image_index") obj_image_index = string(fields[_n].__value);
									else if (fields[_n].__identifier == "image_speed") obj_image_speed = string(fields[_n].__value);
									else {
										var _field_name = string(fields[_n].__identifier),
											_field_value = string(fields[_n].__value);
										obj_properties += "\n{\"resourceType\":\"GMOverriddenProperty\",\"resourceVersion\":\"1.0\",\"name\":\"\",\"propertyId\":{\"name\":\""+_field_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"value\":\""+_field_value+"\",},\n";
									}
								}
								_n++;
							}
						}
						obj_properties += "]";
						//show_debug_message([obj_image_angle,obj_image_index,obj_image_speed,obj_scaleX,obj_scaleY,obj_color]);
						rm.room_string += "{\"resourceType\":\"GMRInstance\",\"resourceVersion\":\"1.0\",\"name\":\""+"inst_"+obj_name+"_"+string(++inst_number)+"\",\"properties\":"+obj_properties+",\"isDnd\":false,\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"inheritCode\":false,\"hasCreationCode\":false,\"colour\":"+obj_color+",\"rotation\":"+obj_image_angle+",\"scaleX\":"+obj_scaleX+",\"scaleY\":"+obj_scaleY+",\"imageIndex\":"+obj_image_index+",\"imageSpeed\":"+obj_image_speed+",\"inheritedItemId\":null,\"frozen\":false,\"ignore\":false,\"inheritItemSettings\":false,\"x\":"+string(e[o].px[0])+",\"y\":"+string(e[o].px[1])+",},\n";
						rm.instanceCreationOrder += "{\"name\":\""+"inst_"+obj_name+"_"+string(inst_number)+"\",\"path\":\""+rm.path+"\",},\n";
						
						o++;
					}
					
					rm.room_string += "],\"visible\":true,\"depth\":"+string(_depth)+",\"userdefinedDepth\":false,\"inheritLayerDepth\":false,\"inheritLayerSettings\":false,\"gridX\":"+gridSize+",\"gridY\":"+gridSize+",\"layers\":[],\"hierarchyFrozen\":false,\"effectEnabled\":true,\"effectType\":null,\"properties\":[],\"resourceVersion\":\"1.0\",\"name\":\""+l.__identifier+"\",\"tags\":[],\"resourceType\":\"GMRInstanceLayer\",},\n";
					_depth += 100;
				}
			}			
			else { //If Layer type is IntGrid, AutoLayer or Tiles
				if (l.__type == "Tiles") var tiles = l.gridTiles;
				else var tiles = l.autoLayerTiles;
				
				var tiles_number = array_length(tiles);
				if (tiles_number > 0) {
					
					var gridSize = l.__gridSize;
					var tileset_name = tileset_names[$ l.__tilesetDefUid];
					var tiles_struct = {};
					var layer_name = l.__identifier;
					var vis = l.visible;
					tiles_struct[$ layer_name+"_1"] = array_create((rm.width/gridSize)*(rm.height/gridSize));
					
					var tile_index = 0;
					while (o < tiles_number) {
						tile_index = (tiles[o].px[0]/gridSize) + (tiles[o].px[1]/gridSize * l.__cWid);
						var layer_n = 1;
						while (tiles_struct[$ layer_name+"_"+string(layer_n)][tile_index] != 0) {
							layer_n++;
							if (!variable_struct_exists(tiles_struct,layer_name+"_"+string(layer_n))) {
								tiles_struct[$ layer_name+"_"+string(layer_n)] = array_create((rm.width/gridSize)*(rm.height/gridSize));
							}
						}
						tiles_struct[$ layer_name+"_"+string(layer_n)][tile_index] = int64(tiles[o].t);
						if (tiles[o].f > 0) {//Checking if the tile is mirrored or flipped
							var f = string(tiles[o].f * 10000000);
							var t = tiles_struct[$ layer_name+"_"+string(layer_n)][tile_index];
							t = dec_to_hex(t);
							t = string_copy(f, 1, string_length(f) - string_length(t)) + t;
							tiles_struct[$ layer_name+"_"+string(layer_n)][tile_index] = int64(ptr(t));
						}
						
						o++;
					}
					//Build the whole data for the layer here, using the struct arrays for TileSerialiseData, already turned into a string preferably
					
					var layer_struct = {
						tilesetId : {
							name : tileset_name,
							path : "tilesets/"+tileset_name+"/"+tileset_name+".yy",
						},
						tiles : {
							SerialiseWidth : string(rm.width/gridSize),
							SerialiseHeight : string(rm.height/gridSize),
							TileSerialiseData : "", //grabbing array from tiles_struct value
						},
						gridX : string(gridSize),
						gridY : string(gridSize),
						name : "", //grabbing name from tiles_struct variable name
						resourceType : "GMRTileLayer",
					}
					
					//Turning the tiles struct arrays to strings
					var tiles_struct_number = variable_struct_names_count(tiles_struct);
					var s = tiles_struct_number;
					repeat (tiles_struct_number) {
						tiles_struct[$ layer_name+"_"+string(s)] = json_stringify(tiles_struct[$ layer_name+"_"+string(s)]);
						rm.room_string += "\n{\"tilesetId\":{\"name\":\""+layer_struct.tilesetId.name+"\",\"path\":\""+layer_struct.tilesetId.path+"\",},\"x\":0,\"y\":0,\"tiles\":{\"SerialiseWidth\":"+layer_struct.tiles.SerialiseWidth+",\"SerialiseHeight\":"+layer_struct.tiles.SerialiseHeight+",\"TileSerialiseData\":\n"+
									tiles_struct[$ layer_name+"_"+string(s)] +
									"\n,},\"visible\":"+string(vis)+",\"depth\":"+string(_depth)+",\"userdefinedDepth\":false,\"inheritLayerDepth\":false,\"inheritLayerSettings\":false,\"gridX\":"+layer_struct.gridX+",\"gridY\":"+layer_struct.gridY+",\"layers\":[],\"hierarchyFrozen\":false,\"effectEnabled\":true,\"effectType\":null,\"properties\":[],\"resourceVersion\":\"1.0\",\"name\":\""+layer_name+"_"+string(s)+"\",\"tags\":[],\"resourceType\":\"GMRTileLayer\",},";
						s--;
						_depth += 100;
					}
					
					// Creating a Tile layer for reference on types of tiles
					if (global.build_IntGrid and l.__type == "IntGrid") {
						var g = l.intGridCsv;
						rm.room_string += "\n{\"tilesetId\":{\"name\":\""+layer_struct.tilesetId.name+"\",\"path\":\""+layer_struct.tilesetId.path+"\",},\"x\":0,\"y\":0,\"tiles\":{\"SerialiseWidth\":"+layer_struct.tiles.SerialiseWidth+",\"SerialiseHeight\":"+layer_struct.tiles.SerialiseHeight+",\"TileSerialiseData\":\n"+
											string(g) +
											"\n,},\"visible\":false,\"depth\":0,\"userdefinedDepth\":true,\"inheritLayerDepth\":false,\"inheritLayerSettings\":false,\"gridX\":"+layer_struct.gridX+",\"gridY\":"+layer_struct.gridY+",\"layers\":[],\"hierarchyFrozen\":false,\"effectEnabled\":true,\"effectType\":null,\"properties\":[],\"resourceVersion\":\"1.0\",\"name\":\""+layer_name+"\",\"tags\":[],\"resourceType\":\"GMRTileLayer\",},";
					}
				}
			}
		}
		//Creating the Background Layer
		rm.room_string += "\n{\"spriteId\":null,\"colour\":"+string(rm.bg_color)+",\"x\":0,\"y\":0,\"htiled\":false,\"vtiled\":false,\"hspeed\":0.0,\"vspeed\":0.0,\"stretch\":false,\"animationFPS\":15.0,\"animationSpeedType\":0,\"userdefinedAnimFPS\":false,\"visible\":true,\"depth\":"+string(_depth)+",\"userdefinedDepth\":false,\"inheritLayerDepth\":false,\"inheritLayerSettings\":false,\"gridX\":32,\"gridY\":32,\"layers\":[],\"hierarchyFrozen\":false,\"effectEnabled\":true,\"effectType\":null,\"properties\":[],\"resourceVersion\":\"1.0\",\"name\":\"Background\",\"tags\":[],\"resourceType\":\"GMRBackgroundLayer\",},";
		
		rm.room_string += room_string_build_last();
		var room_file = file_text_open_write(level_path);
		file_text_write_string(room_file,rm.room_string);
		file_text_close(room_file);
	}
	
	output_string += "Finished.";
	oMenu._string = output_string;
}

function room_string_build_first() {
	var room_string = "{"+"\n"+
		"\"isDnd\": false,"+"\n"+
		"\"volume\": 1.0,"+"\n"+
		"\"parentRoom\": null,"+"\n"+
		"\"views\": ["+"\n"+
		"  {\"inherit\":false,\"visible\":false,\"xview\":0,\"yview\":0,\"wview\":1366,\"hview\":768,\"xport\":0,\"yport\":0,\"wport\":1366,\"hport\":768,\"hborder\":32,\"vborder\":32,\"hspeed\":-1,\"vspeed\":-1,\"objectId\":null,},"+"\n"+
		"  {\"inherit\":false,\"visible\":false,\"xview\":0,\"yview\":0,\"wview\":1366,\"hview\":768,\"xport\":0,\"yport\":0,\"wport\":1366,\"hport\":768,\"hborder\":32,\"vborder\":32,\"hspeed\":-1,\"vspeed\":-1,\"objectId\":null,},"+"\n"+
		"  {\"inherit\":false,\"visible\":false,\"xview\":0,\"yview\":0,\"wview\":1366,\"hview\":768,\"xport\":0,\"yport\":0,\"wport\":1366,\"hport\":768,\"hborder\":32,\"vborder\":32,\"hspeed\":-1,\"vspeed\":-1,\"objectId\":null,},"+"\n"+
		"  {\"inherit\":false,\"visible\":false,\"xview\":0,\"yview\":0,\"wview\":1366,\"hview\":768,\"xport\":0,\"yport\":0,\"wport\":1366,\"hport\":768,\"hborder\":32,\"vborder\":32,\"hspeed\":-1,\"vspeed\":-1,\"objectId\":null,},"+"\n"+
		"  {\"inherit\":false,\"visible\":false,\"xview\":0,\"yview\":0,\"wview\":1366,\"hview\":768,\"xport\":0,\"yport\":0,\"wport\":1366,\"hport\":768,\"hborder\":32,\"vborder\":32,\"hspeed\":-1,\"vspeed\":-1,\"objectId\":null,},"+"\n"+
		"  {\"inherit\":false,\"visible\":false,\"xview\":0,\"yview\":0,\"wview\":1366,\"hview\":768,\"xport\":0,\"yport\":0,\"wport\":1366,\"hport\":768,\"hborder\":32,\"vborder\":32,\"hspeed\":-1,\"vspeed\":-1,\"objectId\":null,},"+"\n"+
		"  {\"inherit\":false,\"visible\":false,\"xview\":0,\"yview\":0,\"wview\":1366,\"hview\":768,\"xport\":0,\"yport\":0,\"wport\":1366,\"hport\":768,\"hborder\":32,\"vborder\":32,\"hspeed\":-1,\"vspeed\":-1,\"objectId\":null,},"+"\n"+
		"  {\"inherit\":false,\"visible\":false,\"xview\":0,\"yview\":0,\"wview\":1366,\"hview\":768,\"xport\":0,\"yport\":0,\"wport\":1366,\"hport\":768,\"hborder\":32,\"vborder\":32,\"hspeed\":-1,\"vspeed\":-1,\"objectId\":null,},"+"\n"+
		"],"+"\n"+
		"\"layers\": ["
	return room_string;
}

function room_string_build_last() {
	var room_string = "],"+"\n"+
  "\"inheritLayers\": false,"+"\n"+
  "\"creationCodeFile\": \"\","+"\n"+
  "\"inheritCode\": false,"+"\n"+
  "\"instanceCreationOrder\": [\n"+rm.instanceCreationOrder+"],\n"+
  "\"inheritCreationOrder\": false,"+"\n"+
  "\"sequenceId\": null,"+"\n"+
  "\"roomSettings\": {"+"\n"+
  "  \"inheritRoomSettings\": false,"+"\n"+
  "  \"Width\": " + string(rm.width) + ","+"\n"+
  "  \"Height\": "+ string(rm.height) + ","+"\n"+
  "  \"persistent\": false,"+"\n"+
  "},"+"\n"+
  "\"viewSettings\": {"+"\n"+
  "  \"inheritViewSettings\": false,"+"\n"+
  "  \"enableViews\": false,"+"\n"+
  "  \"clearViewBackground\": false,"+"\n"+
  "  \"clearDisplayBuffer\": true,"+"\n"+
  "},"+"\n"+
  "\"physicsSettings\": {"+"\n"+
  "  \"inheritPhysicsSettings\": false,"+"\n"+
  "  \"PhysicsWorld\": false,"+"\n"+
  "  \"PhysicsWorldGravityX\": 0.0,"+"\n"+
  "  \"PhysicsWorldGravityY\": 10.0,"+"\n"+
  "  \"PhysicsWorldPixToMetres\": 0.1,"+"\n"+
  "},"+"\n"+
  "\"parent\": {"+"\n"+
  "  \"name\": \""+rm.parent.name+"\","+"\n"+
  "  \"path\": \""+rm.parent.path+"\","+"\n"+
  "},"+"\n"+
  "\"resourceVersion\": \"1.0\","+"\n"+
  "\"name\": \""+rm.name+"\","+"\n"+
  "\"tags\": [],"+"\n"+
  "\"resourceType\": \"GMRoom\",\n}"
  
  return room_string;
}


function hex_to_dec(hex) {
    var count = string_length(hex);
    var final = 0;
    
    static __sillies = {
        a: 10, b: 11, c: 12, d: 13, e: 14, f: 15
    }
    
    for (var i = 1; i < string_length(hex) + 1; i += 1) {
        count--;
        var digit = __sillies[$ string_lower(string_char_at(hex, i))] ?? real(string_char_at(hex, i));
        var base = power(16, count);
        final += digit * base;
    }
    return final;
}

function dec_to_hex(dec, len = 1) 
{
    var hex = "";
 
    if (dec < 0) {
        len = max(len, ceil(logn(16, 2 * abs(dec))));
    }
 
    var dig = "0123456789ABCDEF";
    while (len-- || dec) {
        hex = string_char_at(dig, (dec & $F) + 1) + hex;
        dec = dec >> 4;
    }
 
    return hex;
}

///@function color_to_decimal(color as a string)
function color_to_decimal(c) {
	c = "FF" + string_copy(c,6,2) + string_copy(c,4,2) + string_copy(c,2,2);
	c = hex_to_dec(c);
	return c;
}
