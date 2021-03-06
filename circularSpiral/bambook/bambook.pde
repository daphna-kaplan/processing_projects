// consts for printer
ArrayList<String> gcode;
float width_table = 235; //mm
float height_table = 250; //mm
float height_printer = 165; //mm
float x_center_table = width_table / 2.0f;
float y_center_table = height_table / 2.0f;
float path_width = 0.4;
float layer_height = 0.2;
float filament_diameter = 1.75;
float extruded_path_section = path_width * layer_height;
float filament_section = PI * sq(1.75/2.0f);
float outerRadius = 0.0f;
float extrusion = 0;
PVector previous_point = new PVector();
float extrusion_multiplier = 1;
float angle_increment = TWO_PI /40.0f; // the number of edges on the circle polygon
float circleRadius = 18;
float newCenter_x = x_center_table;
float newCenter_y = y_center_table;
float current_z = 0;

void setup() {
  gcode = new ArrayList<String>();
  startPrint();
  float factor = 1;
  for (int layer = 0; layer<=50; layer++) {
    current_z += layer_height;
    gCommand("G1 Z" + current_z);
    if (layer == 0) {
      // Slow speed and thick extrusion at the beginning of the print
      setSpeed(400);
      extrusion_multiplier = 2;
    } else if (layer == 2) {
      extrusion_multiplier = 1;
    } else if (layer == 3) {
      // Increase the speed
      setSpeed(800);
      enableFan();
    }
    drawCirlce();
    factor -= 0.02;
    circleRadius -= 0.3 * factor;
  }

  drawCircleOnLayers(51, 550) ;
  spiralizeCircle(250.0f, 0.1, 0, 0);
  spiralizeCircle(250.0f, -0.1, -0.03, 0.2);
  drawCircleOnLayers(401, 490);


 endPrint();
 gExport();
 exit();
}


float extrude(PVector p1, PVector p2) {
 float points_distance = dist(p1.x, p1.y, p2.x, p2.y);
 float volume_extruded_path = extruded_path_section * points_distance;
 float length_extruded_path = volume_extruded_path / filament_section;
 return length_extruded_path;
}

void spiralizeCircle(float numberOfPoints, float largeRadiusIncreaseFactor, float smallRadiusIncreaseFactor, float centerMovement){
  for (float outerangle = 0; outerangle<=TWO_PI; outerangle+=TWO_PI /numberOfPoints) {
    current_z += layer_height;
    gCommand("G1 Z" + current_z);
    float outer_x_1 = cos(outerangle) * outerRadius;
    float outer_y_1 = sin(outerangle) * outerRadius;
    float outer_x = x_center_table + outer_x_1;
    float outer_y = y_center_table + outer_y_1;
    newCenter_x = outer_x;
    newCenter_y = outer_y;
    drawCirlce();
    outerRadius += largeRadiusIncreaseFactor;
    circleRadius += smallRadiusIncreaseFactor;
    x_center_table += centerMovement;
 }

}

void setSpeed(float speed) {
 gCommand("G1 F" + speed);
}

void drawCircleOnLayers(int startLayer, int endLayer) {
  for (int layer = startLayer; layer<endLayer; layer++) {
    current_z += layer_height;
    gCommand("G1 Z" + current_z);
    drawCirlce();
  }
}

void drawCirlce(){
  for (float angle = 0; angle<=TWO_PI; angle+=angle_increment) {
    float x_1 = cos(angle) * circleRadius;
    float y_1 = sin(angle) * circleRadius;
    float x = newCenter_x + x_1;
    float y = newCenter_y + y_1;

    PVector next_point = new PVector(x, y);
    if (current_z == layer_height && angle==0) {
    // Go to starting position
      gCommand("G1 X" + x + " Y" + x);
    } else {
      extrusion += (extrude(previous_point, next_point) * extrusion_multiplier);
      gCommand("G1 X" + x + " Y" + y + " E" + extrusion);
    }
    previous_point = next_point;
  }
} 

void enableFan() {
 gCommand("M 106");
}


void disableFan() {
 gCommand("M 107");
}


void startPrint() {
  gCommand("start printing");
  gCommand("Layer height is:" + layer_height);
  gCommand("M140 S55"); // Set bed temperature
  gCommand("M105"); 
  gCommand("M190 S55");
  gCommand("M104 S200"); // Set nozzle temperature
  gCommand("M105");
  gCommand("M109 S200");

  //center
  gCommand("M82"); // absolute extrusion mode
  gCommand("G92 E0"); // Reset Extruder
  gCommand("G28"); //Home all axes

  //draw lines
  gCommand("G1 Z2.0 F3000"); //Move Z Axis up little to prevent scratching of Heat Bed
  gCommand("G1 X0.1 Y20 Z0.3 F5000.0"); //Move to start position
  gCommand("G1 X0.1 Y200.0 Z0.3 F1500.0 E15"); //Draw the first line
  gCommand("G1 X0.4 Y200.0 Z0.3 F5000.0"); //Move to side a little
  gCommand("G1 X0.4 Y20 Z0.3 F1500.0 E30"); //Draw the second line
  gCommand("G92 E0 "); //Reset Extruder
  gCommand("G1 Z2.0 F3000"); //Move Z Axis up little to prevent scratching of Heat Bed
  gCommand("G1 X5 Y20 Z0.3 F5000.0"); //Move over to prevent blob squish

  gCommand("G91"); //Relative mode
  gCommand("G1 Z1"); //Up one millimeter
  gCommand("G28 X0 Y0"); //Home X and Y axes
  gCommand("G90"); //Absolute mode
  gCommand("G1 X" + x_center_table + " Y" + y_center_table + " F8000"); //Go to the center
  gCommand("G28 Z0"); //Home Z axis
  gCommand("G1 Z0"); //Go to height 0
  gCommand("G92 E0"); //Reset extruder position to 0
}


void endPrint() {
  gCommand("G91"); //Relative mode
  gCommand("G1 E-4 F3000"); //Retract filament to avoid filament drop on last layer
  gCommand("G1 X0 Y100 Z20"); //Facilitate object removal
  gCommand("G1 E4"); //Restore filament position
  gCommand("M 107"); //Turn fans off
}


void gCommand(String command) {
  gcode.add(command);
}


void gExport() {
  //Create a unique name for the exported file
  String name_save = "gcode_"+day()+""+hour()+""+minute()+"_"+second()+".g";
  //Convert from ArrayList to array (required by saveString function)
  String[] arr_gcode = gcode.toArray(new String[gcode.size()]);
  // Export GCODE
  saveStrings(name_save, arr_gcode);
}
