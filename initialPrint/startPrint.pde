// consts for printer
ArrayList<String> gcode;
float layer_height = 0.2;

void setup() {
 gcode = new ArrayList<String>();
 startPrint();
 gExport();
 exit();
}


void startPrint() {
    //heating
    gCommand(";start printing");
    gCommand(";Layer height is:" + layer_height);
    gcode("M140 S55"); // Set bed temperature
    gcode("M105"); 
    gcode("M190 S55");
    gcode("M104 S200"); // Set nozzle temperature
    gcode("M105");
    gcode("M109 S200");

    //center
    gcode("M82"); // absolute extrusion mode
    gcode("G92 E0"); // Reset Extruder
    gcode("G28"); //Home all axes

    //draw lines
    gcode("G1 Z2.0 F3000"); //Move Z Axis up little to prevent scratching of Heat Bed
    gcode("G1 X0.1 Y20 Z0.3 F5000.0"); //Move to start position
    gcode("G1 X0.1 Y200.0 Z0.3 F1500.0 E15"); //Draw the first line
    gcode("G1 X0.4 Y200.0 Z0.3 F5000.0"); //Move to side a little
    gcode("G1 X0.4 Y20 Z0.3 F1500.0 E30"); //Draw the second line
    gcode("G92 E0 "); //Reset Extruder
    gcode("G1 Z2.0 F3000"); //Move Z Axis up little to prevent scratching of Heat Bed
    gcode("G1 X5 Y20 Z0.3 F5000.0"); //Move over to prevent blob squish
}


void gCommand(String command) {
 gcode.add(command);
}


void gExport() {
 //Create a unique name for the exported file
 String name_save = "gcode_startPrint.g";
 //Convert from ArrayList to array (required by saveString function)
 String[] arr_gcode = gcode.toArray(new String[gcode.size()]);
 // Export GCODE
 saveStrings(name_save, arr_gcode);
}
