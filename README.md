# LDtk-Room_builder
Creates GameMaker room files from LDtk's json

The LDtk to GameMaker room builder requires that you already have rooms and objects with the same name created in your project.
Entities names must match the names of your objetcs.
Level names must match the names of rooms.

Entities can have values to change image_index, image_speed and image_angle if you add a float or int value with those identifiers.
They can also have a color value that will be used to blend with the instance's color.
If your object has variable definitions you can also add custom values to Entities if the identifier is the same as the name of the variable.
