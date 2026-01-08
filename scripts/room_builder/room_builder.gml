// feather ignore all
#macro LDtk_struct global.LDTKstruct
#macro room_struct global.roomstruct
#macro Dir global.project_path
global.build_IntGrid = false;
global.LDTKstruct = -1;
global.project_path = "";
global.LDtk_path = "";
global.pause = false;
global.selected_levels = [];
global.roomstruct = {};
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
	var buffer = buffer_load(global.LDtk_path);
	var json = buffer_read(buffer, buffer_string);
	LDtk_struct = json_parse(json);
	buffer_delete(buffer);
}

// This function is the new method of stringifying a full struct, but this didn't work, so I went back to creating own string
function room_create_new(all_levels = false) {
	var _timer = get_timer();
	
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
		
		global.rm = {
			name : level_name,
			width : level.pxWid, //div LDtk_struct.defaultGridSize * LDtk_struct.defaultGridSize,
			height : level.pxHei, //div LDtk_struct.defaultGridSize * LDtk_struct.defaultGridSize,
			bg_color : color_to_decimal(level.__bgColor),
			room_string : "",
			parent : {
				name : level_json.parent.name,
				path : level_json.parent.path,
			},
			instanceCreationOrder : "",
			path : "rooms/"+level_name+"/"+level_name+".yy"
		}
		
        room_build_template();
			
		var LDtk_layers = level.layerInstances;
		var LDtk_layers_number = array_length(LDtk_layers);
		
		for (var i = 0; i < LDtk_layers_number; i++) {
			var l = LDtk_layers[i];
			var o = 0;
			
			if (l.__type == "Entities") {
				var e = l.entityInstances;
				var e_number = array_length(e);
                
				var gridSize = string(l.__gridSize);	
                var vis = l.visible ? true : false;
                var layer_struct = {
                    depth : int64(_depth),
                    effectEnabled : true,
                    effectType : undefined,
                    gridX : int64(gridSize),
                    gridY : int64(gridSize),
                    hierarchyFrozen : false,
                    inheritLayerDepth : false,
                    inheritLayerSettings : false,
                    inheritSubLayers : true,
                    inheritVisibility : true,
                    instances : [],
                    layers : [],
                    name : l.__identifier,
                    properties : [],
                    resourceType : "GMRInstanceLayer",
                    resourceVersion : "2.0",
                    userdefinedDepth : false,
                    visible : vis,
                }
                layer_struct[$ "$GMRInstanceLayer"] = "";
                layer_struct[$ "%Name"] = l.__identifier;
                
				if (e_number > 0) {
					while (o < e_number) {
						var obj_name = e[o].__identifier;
						if (!file_exists(Dir+"/objects/"+obj_name+"/"+obj_name+".yy")) {o++; output_string += "Object of name "+obj_name+" not found.\n"; continue;}
						
						var entity_index = array_find_index(LDtk_struct.defs.entities,method({obj : obj_name}, function(_val, _ind) {
							return _val.identifier == obj;
						}));
						var obj_color = "4294967295",
							obj_scaleX = e[o].width / LDtk_struct.defs.entities[entity_index].width,
							obj_scaleY = e[o].height / LDtk_struct.defs.entities[entity_index].height,
							obj_image_speed = 1.0,
							obj_image_index = 0,
							obj_image_angle = 0,
							obj_properties = [];
						
						if (array_length(e[o].fieldInstances) > 0) { //Add fields to instance parameters if any
							var fields = e[o].fieldInstances;
							var f_number = array_length(fields);
							var _n = 0;
							repeat(f_number) {
								if (fields[_n].__type == "Color") obj_color = color_to_decimal(fields[_n].__value);
								else if (fields[_n].__type == "Float" or fields[_n].__type == "Int") {
									if (fields[_n].__identifier == "image_angle") obj_image_angle = fields[_n].__value;
									else if (fields[_n].__identifier == "image_index") obj_image_index = fields[_n].__value;
									else if (fields[_n].__identifier == "image_speed") obj_image_speed = fields[_n].__value;
									else {
										var _field_name = string(fields[_n].__identifier),
											_field_value = string(fields[_n].__value);
										array_push(obj_properties, object_build_properties(obj_name, _field_name, _field_value));
									}
								}
								else if (fields[_n].__type == "Point") {
									var _field_name = string(fields[_n].__identifier);
									var _field_value = fields[_n].__value != pointer_null ? string(fields[_n].__value.cx + (fields[_n].__value.cy /100)) : "-1";
									array_push(obj_properties, object_build_properties(obj_name, _field_name, _field_value));
								}
								else if (fields[_n].__type == "Array<Int>" or fields[_n].__type == "Array<Float>") {
									var _field_name = string(fields[_n].__identifier),
										_field_value = string(fields[_n].__value);
									array_push(obj_properties, object_build_properties(obj_name, _field_name, _field_value));
								}
								else if (fields[_n].__type == "String") {
									var _field_name = string(fields[_n].__identifier),
										_field_value = string(fields[_n].__value);
									array_push(obj_properties, object_build_properties(obj_name, _field_name, _field_value));
								}
								else if (fields[_n].__type == "Bool") {
									var _field_name = string(fields[_n].__identifier),
										_field_value = string(fields[_n].__value);
									obj_properties += "\n{\"$GMOverriddenProperty\":\"v1\",\"%Name\":\"\",\"name\":\"\",\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"propertyId\":{\"name\":\""+_field_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"resourceType\":\"GMOverriddenProperty\",\"resourceVersion\":\"2.0\",\"value\":\""+_field_value+"\",},";
								}
								_n++;
							}
						}
                        var inst_name = "inst_"+obj_name+"_"+string(inst_number)+"_"+level_name;
                        var obj_struct = {
                            colour : obj_color,
                            frozen : false,
                            hasCreationCode : false,
                            ignore : false,
                            imageIndex : int64(obj_image_index),
                            imageSpeed : obj_image_speed,
                            inheritCode : false,
                            inheritedItemId : undefined,
                            inheritItemSettings : false,
                            isDnd : false,
                            name : inst_name,
                            objectId : {
                                name : obj_name,
                                path : "objects/"+obj_name+"/"+obj_name+".yy"
                            },
                            properties : obj_properties,
                            resourceType : "GMRInstance",
                            resourceVersion : "2.0",
                            rotation : obj_image_angle,
                            scaleX : obj_scaleX,
                            scaleY : obj_scaleY,
                            x : e[o].px[0],
                            y : e[o].px[1]
                        }
                        obj_struct[$ "$GMRInstance"] = "v2";
                        obj_struct[$ "%Name"] = inst_name;
                        array_push(layer_struct.instances, obj_struct);
                        
                        var instance_createorder_struct = {
                            name : inst_name,
                            path : global.rm.path
                        }
                        array_push(room_struct.instanceCreationOrder, instance_createorder_struct);
						inst_number++;
						o++;
					}
					_depth += 100;
                    array_push(room_struct.layers, layer_struct);
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
					var vis = l.visible ? true : false;
					var tiles_array_size = int64((global.rm.width/gridSize)*(global.rm.height/gridSize));
					tiles_struct[$ layer_name+"_1"] = array_create(tiles_array_size + 1, int64(0));
                    // I put the number of tiles in the first index but that's how the compressed data works
                    // It tells the array that the next numbers are all each an index
					tiles_struct[$ layer_name+"_1"][0] = tiles_array_size;
					var tile_index = 0;
                    // This while puts tile data in the array
					while (o < tiles_number) {
						tile_index = (tiles[o].px[0]/gridSize) + (tiles[o].px[1]/gridSize * l.__cWid) + 1;
						var layer_n = 1;
                        // This while checks if the tile is already painted and changes layers if yes
						while (tiles_struct[$ layer_name+"_"+string(layer_n)][tile_index] != 0) {
							layer_n++;
							if (!variable_struct_exists(tiles_struct,layer_name+"_"+string(layer_n))) {
								tiles_struct[$ layer_name+"_"+string(layer_n)] = array_create(tiles_array_size + 1, int64(0));
								tiles_struct[$ layer_name+"_"+string(layer_n)][0] = tiles_array_size;
							}
						}
                        // Puts tile data in the array, and then changes it if there is mirror or flip data
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
					
					//Turning the tiles struct arrays to strings. The repeat is in case there are multiple layers with tile data.
					var tiles_struct_number = variable_struct_names_count(tiles_struct);
					var s = tiles_struct_number;
					repeat (tiles_struct_number) {
                        var _name = layer_name+"_"+string(s);
                        var layer_struct = {
                            depth : int64(_depth),
                            effectEnabled : true,
                            effectType : undefined,
                            hierarchyFrozen : false,
                            inheritLayerDepth : false,
                            inheritLayerSettings : false,
                            inheritSubLayers : true,
                            inheritVisibility : true,
                            layers : [],
                            properties : [],
                            userdefinedDepth : false,
    						resourceType : "GMRTileLayer",
                            resourceVersion : "2.0",
    						tilesetId : {
    							name : tileset_name,
    							path : "tilesets/"+tileset_name+"/"+tileset_name+".yy",
    						},
    						tiles : {
    							SerialiseWidth : int64(global.rm.width/gridSize),
    							SerialiseHeight : int64(global.rm.height/gridSize),
    							TileCompressedData : tiles_struct[$ _name], //grabbing array from tiles_struct value
                                TileDataFormat : int64(1),
    						},
    						gridX : int64(gridSize),
    						gridY : int64(gridSize),
                            visible : vis,
                            x : int64(0),
                            y : int64(0),
    						name : _name
    					}
                        layer_struct[$ "$GMRTileLayer"] = "";
                        layer_struct[$ "%Name"] = _name;
                        // Push the layer into the room layers
                        array_push(room_struct.layers, layer_struct);
						s--;
						_depth += 100;
					}
					
					// Creating a Tile layer for reference on types of tiles
                    // I'm removing this because I'm lazy and I don't need it?
                    /*
					if (global.build_IntGrid and l.__type == "IntGrid") {
						var g = l.intGridCsv;
                        
						rm.room_string += "\n{\"$GMRTileLayer\":\"\",\"%Name\":\""+layer_name+"\",\"depth\":"+string(_depth)+",\"effectEnabled\":true,\"effectType\":null,\"gridX\":"+layer_struct.gridX+",\"gridY\":"+layer_struct.gridY+",\"hierarchyFrozen\":false,\"inheritLayerDepth\":false,\"inheritLayerSettings\":false,\"inheritSubLayers\":true,\"inheritVisibility\":true,\"layers\":[],\"name\":\""+layer_name+"_"+string(s)+"\",\"properties\":[],\"resourceType\":\"GMRTileLayer\",\"resourceVersion\":\"2.0\",\"tiles\":{\"SerialiseHeight\":"+layer_struct.tiles.SerialiseHeight+",\"SerialiseWidth\":"+layer_struct.tiles.SerialiseWidth+",\"TileSerialiseData\":["+
											string(g) +
											"\n],},\"tilesetId\":{\"name\":\""+layer_struct.tilesetId.name+"\",\"path\":\""+layer_struct.tilesetId.path+"\",},\"userdefinedDepth\":false,\"visible\":"+vis+",\"x\":0,\"y\":0,},";
					}*/
				}
			}
		}
		//Creating the Background Layer
        
        var layer_struct = {
            animationFPS : 15.0,
            animationSpeedType : int64(0),
            colour : global.rm.bg_color,
            depth : int64(_depth),
            effectEnabled : true,
            effectType : undefined,
            gridX : int64(32),
            gridY : int64(32),
            hierarchyFrozen : false,
            hspeed : 0,
            vspeed : 0,
            htiled : false,
            vtiled : false,
            inheritLayerDepth : false,
            inheritLayerSettings : false,
            inheritSubLayers : true,
            inheritVisibility : true,
            layers : [],
            name : "Background",
            properties : [],
            resourceType : "GMRBackgroundLayer",
            resourceVersion : "2.0",
            spriteId : undefined,
            stretch : false,
            userdefinedAnimFPS : false,
            userdefinedDepth : false,
            visible : true,
            x : int64(0),
            y : int64(0)
        }
        layer_struct[$ "$GMRBackgroundLayer"] = "";
        layer_struct[$ "%Name"] = "Background";
		array_push(room_struct.layers, layer_struct);
        
		var _string = json_stringify(room_struct, true);
        // I need to parse the string and get the .0 out of the colour key from the Background Layer
        var color_pos = 0;
        color_pos = string_pos("colour", _string);
        while (color_pos != 0) {
            color_pos = string_pos_ext(".", _string, color_pos);
            _string = string_delete(_string, color_pos, 2);
            color_pos = string_pos_ext("colour", _string, color_pos);
        }
    	var _buffer = buffer_create(string_byte_length(_string) + 1, buffer_fixed, 1);
    	buffer_write(_buffer, buffer_string, _string);
    	buffer_save(_buffer, level_path);
    	buffer_delete(_buffer);
	}
	_timer = string((get_timer() - _timer) / 1000);
	output_string += "Finished in "+ _timer + "ms.";
	oMenu._string = output_string;
}

function object_build_properties(obj_name, field_name, field_value) {
    var _struct = {
        name : "",
        objectId : {
            name : obj_name,
            path : "objects/"+obj_name+"/"+obj_name+".yy"
        },
        propertyId : {
            name : field_name,
            path : "objects/"+obj_name+"/"+obj_name+".yy"
        },
        resourceType : "GMOverriddenProperty",
        resourceVersion : "2.0",
        value : field_value
    }
    _struct[$ "$GMOverriddenProperty"] = "v1";
    _struct[$ "%Name"] = "";
    
    return _struct;
}

function room_build_template() {
    room_struct[$ "$GMRoom"] = "v1";
    room_struct[$ "%Name"] = global.rm.name;
    with (room_struct) {
        name = global.rm.name;
        parent = {
            name : global.rm.parent.name,
            path : global.rm.parent.path
        }
        roomSettings = {
            Height : int64(global.rm.height),
            Width : int64(global.rm.width),
            inheritRoomSettings : false,
            persistent : false
        }
        instanceCreationOrder = [];
        layers = [];
        parentRoom = undefined;
        creationCodeFile = "";
        inheritCode = false;
        inheritCreationOrder = false;
        inheritLayers = false;
        isDnd = false;
        physicsSettings = {
            inheritPhysicsSettings : false,
            PhysicsWorld : false,
            PhysicsWorldGravityX : 0.0,
            PhysicsWorldGravityY : 10.0,
            PhysicsWorldPixToMetres : 0.1,
        };
        resourceType = "GMRoom";
        resourceVersion = "2.0";
        sequenceId = undefined;
        views = array_create_ext(8, function() {
            return {hborder:int64(32),hport:int64(1080),hspeed:int64(-1),hview:int64(1080),inherit:false,objectId:undefined,vborder:int64(32),visible:false,vspeed:int64(-1),wport:int64(1920),wview:int64(1920),xport:int64(0),xview:int64(0),yport:int64(0),yview:int64(0),};
        });
        viewSettings = {
            clearDisplayBuffer:true,
            clearViewBackground:false,
            enableViews:false,
            inheritViewSettings:false,
        }
        volume = 1.0;
    }
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
	var _timer = get_timer();
	
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
		
		rm = {
			name : level_name,
			width : level.pxWid, //div LDtk_struct.defaultGridSize * LDtk_struct.defaultGridSize,
			height : level.pxHei, //div LDtk_struct.defaultGridSize * LDtk_struct.defaultGridSize,
			bg_color : color_to_decimal(level.__bgColor),
			room_string : "",
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
					rm.room_string += "\n{\"$GMRInstanceLayer\":\"\",\"%Name\":\""+l.__identifier+"\",\"depth\":"+string(_depth)+",\"effectEnabled\":true,\"effectType\":null,\"gridX\":"+gridSize+",\"gridY\":"+gridSize+",\"hierarchyFrozen\":false,\"inheritLayerDepth\":false,\"inheritLayerSettings\":false,\"inheritSubLayers\":true,\"inheritVisibility\":true,\"instances\":[\n";
					
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
								else if (fields[_n].__type == "Float" or fields[_n].__type == "Int") {
                                    if (fields[_n].__identifier == "image_xscale") obj_scaleX = string(fields[_n].__value);
                                    else if (fields[_n].__identifier == "image_yscale") obj_scaleY = string(fields[_n].__value);
									else if (fields[_n].__identifier == "image_angle") obj_image_angle = string(fields[_n].__value);
									else if (fields[_n].__identifier == "image_index") obj_image_index = string(fields[_n].__value);
									else if (fields[_n].__identifier == "image_speed") obj_image_speed = string(fields[_n].__value);
									else {
										var _field_name = string(fields[_n].__identifier),
											_field_value = string_format(fields[_n].__value, 1, 5);
                                        _field_value = string_trim_end(_field_value, ["0"]);
										obj_properties += "\n{\"$GMOverriddenProperty\":\"v1\",\"%Name\":\"\",\"name\":\"\",\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"propertyId\":{\"name\":\""+_field_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"resourceType\":\"GMOverriddenProperty\",\"resourceVersion\":\"2.0\",\"value\":\""+_field_value+"\",},";
									}
								}
								else if (fields[_n].__type == "Point") {
									var _field_name = string(fields[_n].__identifier);
									var _field_value = fields[_n].__value != pointer_null ? string(fields[_n].__value.cx + (fields[_n].__value.cy /100)) : "-1";
									obj_properties += "\n{\"$GMOverriddenProperty\":\"v1\",\"%Name\":\"\",\"name\":\"\",\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"propertyId\":{\"name\":\""+_field_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"resourceType\":\"GMOverriddenProperty\",\"resourceVersion\":\"2.0\",\"value\":\""+_field_value+"\",},";
								}
								else if (fields[_n].__type == "Array<Int>" or fields[_n].__type == "Array<Float>") {
									var _field_name = string(fields[_n].__identifier),
										_field_value = string(fields[_n].__value);
									obj_properties += "\n{\"$GMOverriddenProperty\":\"v1\",\"%Name\":\"\",\"name\":\"\",\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"propertyId\":{\"name\":\""+_field_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"resourceType\":\"GMOverriddenProperty\",\"resourceVersion\":\"2.0\",\"value\":\""+_field_value+"\",},";
								}
								else if (fields[_n].__type == "String" or string_copy(fields[_n].__type, 1, 9) == "LocalEnum") {
									var _field_name = string(fields[_n].__identifier),
										_field_value = string(fields[_n].__value);
									obj_properties += "\n{\"$GMOverriddenProperty\":\"v1\",\"%Name\":\"\",\"name\":\"\",\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"propertyId\":{\"name\":\""+_field_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"resourceType\":\"GMOverriddenProperty\",\"resourceVersion\":\"2.0\",\"value\":\""+_field_value+"\",},";
								}
								else if (fields[_n].__type == "Bool") {
									var _field_name = string(fields[_n].__identifier),
										_field_value = string(fields[_n].__value);
									obj_properties += "\n{\"$GMOverriddenProperty\":\"v1\",\"%Name\":\"\",\"name\":\"\",\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"propertyId\":{\"name\":\""+_field_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"resourceType\":\"GMOverriddenProperty\",\"resourceVersion\":\"2.0\",\"value\":\""+_field_value+"\",},";
								}
                                else if (fields[_n].__type == "FilePath") {
									var _field_name = string(fields[_n].__identifier),
										_field_value = fields[_n].__value;
                                    if (_field_value != undefined) {
                                        var str_parts = string_split(_field_value, "/");
                                        var resource_name = str_parts[array_length(str_parts)-2];
                                        var resource_type = str_parts[array_length(str_parts)-3];
                                        // I need to parse _field_value so I get the name of the field, and what type it is, like sounds
    									obj_properties += "\n{\"$GMOverriddenProperty\":\"v1\",\"%Name\":\"\",\"name\":\"\",\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"propertyId\":{\"name\":\""+_field_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"resource\":{\"name\":\""+resource_name+"\",\"path\":\""+resource_type+"/"+resource_name+"/"+resource_name+".yy\",},\"resourceType\":\"GMOverriddenProperty\",\"resourceVersion\":\"2.0\",\"value\":\""+resource_name+"\",},";
                                    }
								}
								_n++;
							}
						}
						obj_properties += "]";
						//show_debug_message([obj_image_angle,obj_image_index,obj_image_speed,obj_scaleX,obj_scaleY,obj_color]);
						rm.room_string += "{\"$GMRInstance\":\"v4\",\"%Name\":\""+"inst_"+obj_name+"_"+string(inst_number)+"_"+level_name+"\",\"colour\":"+obj_color+",\"frozen\":false,\"hasCreationCode\":false,\"ignore\":false,\"imageIndex\":"+obj_image_index+",\"imageSpeed\":"+obj_image_speed+",\"inheritCode\":false,\"inheritedItemId\":null,\"inheritItemSettings\":false,\"isDnd\":false,\"name\":\""+"inst_"+obj_name+"_"+string(inst_number)+"_"+level_name+"\",\"objectId\":{\"name\":\""+obj_name+"\",\"path\":\"objects/"+obj_name+"/"+obj_name+".yy\",},\"properties\":"+obj_properties+",\"resourceType\":\"GMRInstance\",\"resourceVersion\":\"2.0\",\"rotation\":"+obj_image_angle+",\"scaleX\":"+obj_scaleX+",\"scaleY\":"+obj_scaleY+",\"x\":"+string(e[o].px[0])+",\"y\":"+string(e[o].px[1])+",},\n";
						rm.instanceCreationOrder += "{\"name\":\""+"inst_"+obj_name+"_"+string(inst_number)+"_"+level_name+"\",\"path\":\""+rm.path+"\",},\n";
						inst_number++;
						o++;
					}
					var vis = l.visible ? "true" : "false";
					rm.room_string += "],\"layers\":[],\"name\":\""+l.__identifier+"\",\"properties\":[],\"resourceType\":\"GMRInstanceLayer\",\"resourceVersion\":\"2.0\",\"userdefinedDepth\":false,\"visible\":"+vis+",},\n";
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
					var vis = l.visible ? "true" : "false";
                    if (rm.width mod gridSize != 0 or rm.height mod gridSize != 0) {
                        output_string += $"The room size for {rm.name} is not perfectly divisible by the grid size. They need to match.\n";
                        continue;
                    }
					var tiles_array_size = int64((rm.width/gridSize)*(rm.height/gridSize));
					tiles_struct[$ layer_name+"_1"] = array_create(tiles_array_size + 1, int64(0));
					tiles_struct[$ layer_name+"_1"][0] = tiles_array_size;
					var tile_index = 0;
					while (o < tiles_number) {
						tile_index = (tiles[o].px[0]/gridSize) + (tiles[o].px[1]/gridSize * l.__cWid) + 1;
						var layer_n = 1;
						while (tiles_struct[$ layer_name+"_"+string(layer_n)][tile_index] != 0) {
							layer_n++;
							if (!variable_struct_exists(tiles_struct,layer_name+"_"+string(layer_n))) {
								tiles_struct[$ layer_name+"_"+string(layer_n)] = array_create(tiles_array_size + 1, int64(0));
								tiles_struct[$ layer_name+"_"+string(layer_n)][0] = tiles_array_size;
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
						rm.room_string += "\n{\"$GMRTileLayer\":\"\",\"%Name\":\""+layer_name+"_"+string(s)+"\",\"depth\":"+string(_depth)+",\"effectEnabled\":true,\"effectType\":null,\"gridX\":"+layer_struct.gridX+",\"gridY\":"+layer_struct.gridY+",\"hierarchyFrozen\":false,\"inheritLayerDepth\":false,\"inheritLayerSettings\":false,\"inheritSubLayers\":true,\"inheritVisibility\":true,\"layers\":[],\"name\":\""+layer_name+"_"+string(s)+"\",\"properties\":[],\"resourceType\":\"GMRTileLayer\",\"resourceVersion\":\"2.0\",\"tiles\":{\"SerialiseHeight\":"+layer_struct.tiles.SerialiseHeight+",\"SerialiseWidth\":"+layer_struct.tiles.SerialiseWidth+",\"TileCompressedData\":"+
									tiles_struct[$ layer_name+"_"+string(s)] +
									"\n,\"TileDataFormat\":1,},\"tilesetId\":{\"name\":\""+layer_struct.tilesetId.name+"\",\"path\":\""+layer_struct.tilesetId.path+"\",},\"userdefinedDepth\":false,\"visible\":"+vis+",\"x\":0,\"y\":0,},";
						s--;
						_depth += 100;
					}
					
					// Creating a Tile layer for reference on types of tiles
					//if (global.build_IntGrid and l.__type == "IntGrid") {
						//var g = l.intGridCsv;
                        //show_message("Shouldn't be here");
						//rm.room_string += "\n{\"$GMRTileLayer\":\"\",\"%Name\":\""+layer_name+"\",\"depth\":"+string(_depth)+",\"effectEnabled\":true,\"effectType\":null,\"gridX\":"+layer_struct.gridX+",\"gridY\":"+layer_struct.gridY+",\"hierarchyFrozen\":false,\"inheritLayerDepth\":false,\"inheritLayerSettings\":false,\"inheritSubLayers\":true,\"inheritVisibility\":true,\"layers\":[],\"name\":\""+layer_name+"\",\"properties\":[],\"resourceType\":\"GMRTileLayer\",\"resourceVersion\":\"2.0\",\"tiles\":{\"SerialiseHeight\":"+layer_struct.tiles.SerialiseHeight+",\"SerialiseWidth\":"+layer_struct.tiles.SerialiseWidth+",\"TileCompressedData\":"+
											//string(g) +
											//"\n,\"TileDataFormat\":1,},\"tilesetId\":{\"name\":\""+layer_struct.tilesetId.name+"\",\"path\":\""+layer_struct.tilesetId.path+"\",},\"userdefinedDepth\":false,\"visible\":"+vis+",\"x\":0,\"y\":0,},";
					//}
				}
			}
		}
		//Creating the Background Layer
		rm.room_string += "\n{\"$GMRBackgroundLayer\":\"\",\"%Name\":\"Background\",\"animationFPS\":15.0,\"animationSpeedType\":0,\"colour\":"+string(rm.bg_color)+",\"depth\":"+string(_depth)+",\"effectEnabled\":true,\"effectType\":null,\"gridX\":32,\"gridY\":32,\"hierarchyFrozen\":false,\"hspeed\":0.0,\"htiled\":false,\"inheritLayerDepth\":false,\"inheritLayerSettings\":false,\"inheritSubLayers\":true,\"inheritVisibility\":true,\"layers\":[],\"name\":\"Background\",\"properties\":[],\"resourceType\":\"GMRBackgroundLayer\",\"resourceVersion\":\"2.0\",\"spriteId\":null,\"stretch\":false,\"userdefinedAnimFPS\":false,\"userdefinedDepth\":false,\"visible\":true,\"vspeed\":0.0,\"vtiled\":false,\"x\":0,\"y\":0,},";
		
		var room_final_string = room_string_build_first() + rm.room_string + room_string_build_last();
		var room_file = file_text_open_write(level_path);
		file_text_write_string(room_file,room_final_string);
		file_text_close(room_file);
	}
	_timer = string(get_timer() - _timer);
	output_string += "Finished in "+ _timer + "ms.";
	oMenu._string = output_string;
}

function room_string_build_first() {
	var room_string = "{\n"+
		  "\"$GMRoom\":\"v1\",\n"+
		  "\"%Name\":\""+rm.name+"\",\n"+
		  "\"creationCodeFile\":\"\",\n"+
		  "\"inheritCode\":false,\n"+
		  "\"inheritCreationOrder\":false,\n"+
		  "\"inheritLayers\":false,\n"+
		  "\"instanceCreationOrder\":[\n"+rm.instanceCreationOrder+"],\n"+
		  "\"isDnd\":false,\n"+
		  "\"layers\":[";
	return room_string;
}

function room_string_build_last() {
    var room_string = "],\n"+
	  "\"name\":\""+rm.name+"\",\n"+
	  "\"parent\":{\n"+
	  "  \"name\":\""+rm.parent.name+"\",\n"+
	  "  \"path\":\""+rm.parent.path+"\",\n"+
	  "},\n"+
	  "\"parentRoom\":null,\n"+
	  "\"physicsSettings\":{\n"+
	  "  \"inheritPhysicsSettings\":false,\n"+
	  "  \"PhysicsWorld\":false,\n"+
	  "  \"PhysicsWorldGravityX\":0.0,\n"+
	  "  \"PhysicsWorldGravityY\":10.0,\n"+
	  "  \"PhysicsWorldPixToMetres\":0.1,\n"+
	  "},\n"+
	  "\"resourceType\":\"GMRoom\",\n"+
	  "\"resourceVersion\":\"2.0\",\n"+
	  "\"roomSettings\":{\n"+
	  "  \"Height\":"+ string(rm.height) + ",\n"+
	  "  \"inheritRoomSettings\":false,\n"+
	  "  \"persistent\":false,\n"+
	  "  \"Width\":"+ string(rm.width) + ",\n"+
	  "},\n"+
	  "\"sequenceId\":null,\n"+
	  "\"views\":[\n"+
	  "  {\"hborder\":32,\"hport\":1080,\"hspeed\":-1,\"hview\":1080,\"inherit\":false,\"objectId\":null,\"vborder\":32,\"visible\":false,\"vspeed\":-1,\"wport\":1920,\"wview\":1920,\"xport\":0,\"xview\":0,\"yport\":0,\"yview\":0,},\n"+
	  "  {\"hborder\":32,\"hport\":1080,\"hspeed\":-1,\"hview\":1080,\"inherit\":false,\"objectId\":null,\"vborder\":32,\"visible\":false,\"vspeed\":-1,\"wport\":1920,\"wview\":1920,\"xport\":0,\"xview\":0,\"yport\":0,\"yview\":0,},\n"+
	  "  {\"hborder\":32,\"hport\":1080,\"hspeed\":-1,\"hview\":1080,\"inherit\":false,\"objectId\":null,\"vborder\":32,\"visible\":false,\"vspeed\":-1,\"wport\":1920,\"wview\":1920,\"xport\":0,\"xview\":0,\"yport\":0,\"yview\":0,},\n"+
	  "  {\"hborder\":32,\"hport\":1080,\"hspeed\":-1,\"hview\":1080,\"inherit\":false,\"objectId\":null,\"vborder\":32,\"visible\":false,\"vspeed\":-1,\"wport\":1920,\"wview\":1920,\"xport\":0,\"xview\":0,\"yport\":0,\"yview\":0,},\n"+
	  "  {\"hborder\":32,\"hport\":1080,\"hspeed\":-1,\"hview\":1080,\"inherit\":false,\"objectId\":null,\"vborder\":32,\"visible\":false,\"vspeed\":-1,\"wport\":1920,\"wview\":1920,\"xport\":0,\"xview\":0,\"yport\":0,\"yview\":0,},\n"+
	  "  {\"hborder\":32,\"hport\":1080,\"hspeed\":-1,\"hview\":1080,\"inherit\":false,\"objectId\":null,\"vborder\":32,\"visible\":false,\"vspeed\":-1,\"wport\":1920,\"wview\":1920,\"xport\":0,\"xview\":0,\"yport\":0,\"yview\":0,},\n"+
	  "  {\"hborder\":32,\"hport\":1080,\"hspeed\":-1,\"hview\":1080,\"inherit\":false,\"objectId\":null,\"vborder\":32,\"visible\":false,\"vspeed\":-1,\"wport\":1920,\"wview\":1920,\"xport\":0,\"xview\":0,\"yport\":0,\"yview\":0,},\n"+
	  "  {\"hborder\":32,\"hport\":1080,\"hspeed\":-1,\"hview\":1080,\"inherit\":false,\"objectId\":null,\"vborder\":32,\"visible\":false,\"vspeed\":-1,\"wport\":1920,\"wview\":1920,\"xport\":0,\"xview\":0,\"yport\":0,\"yview\":0,},\n"+
	  "],\n"+
	  "\"viewSettings\":{\n"+
	  "  \"clearDisplayBuffer\":true,\n"+
	  "  \"clearViewBackground\":false,\n"+
	  "  \"enableViews\":false,\n"+
	  "  \"inheritViewSettings\":false,\n"+
	  "},\n"+
	  "\"volume\":1.0,\n"+
	"}";
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
