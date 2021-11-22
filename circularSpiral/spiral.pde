ArrayList<String> gcode;



float width_table = 235; //mm

float height_table = 250; //mm

float height_printer = 165; //mm

float yFactor = 10;

float x_center_table = width_table / 2.0f;

float y_center_table = height_table / 2.0f;

float phase = 0;

float path_width = 0.4;

float layer_height = 0.2;

float filament_diameter = 1.75;



float extruded_path_section = path_width * layer_height;

float filament_section = PI * sq(1.75/2.0f);



void setup() {

 gcode = new ArrayList<String>();



 startPrint();



 float length_side_cube = 10;



 float tot_layers = 360;

 float current_z = 0;



 float extrusion = 0;

 float extrusion_multiplier = 1;



 float angle_increment = TWO_PI /300.0f;

 PVector previous_point = new PVector();



 for (int layer = 0; layer<tot_layers; layer++) {



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

     setSpeed(1200);

     enableFan();

   }



   for (float angle = 0; angle<=TWO_PI; angle+=angle_increment) {



     float x_1 = cos(angle) * length_side_cube;
     float y_1 = sin(angle) * yFactor;

      float x = x_center_table + x_1 * cos(phase) - y_1 * sin(phase);
      float y = y_center_table + x_1 * sin(phase) + y_1 * cos(phase);
      
    
     PVector next_point = new PVector(x, y);



     if (layer == 0 && angle==0) {

       // Go to starting position

       gCommand("G1 X" + x + " Y" + y);

     } else {

       extrusion += (extrude(previous_point, next_point) * extrusion_multiplier);

       gCommand("G1 X" + x + " Y" + y + " E" + extrusion);

     }

     previous_point = next_point;

   }
    phase+=(PI/180);
    yFactor+=0.05;

 }

 for (int layer2 = 361; layer2<720; layer2++) {

   current_z += layer_height;

   gCommand("G1 Z" + current_z);


   for (float angle2 = 0; angle2<=TWO_PI; angle2+=angle_increment) {
      float x_1 = cos(angle2) * length_side_cube;
     float y_1 = sin(angle2) * yFactor;
      float x = x_center_table + x_1 * cos(phase) - y_1 * sin(phase);
      float y = y_center_table + x_1 * sin(phase) + y_1 * cos(phase);
      
     PVector next_point = new PVector(x, y);

     if (layer2 == 0 && angle2==0) {

       // Go to starting position

       gCommand("G1 X" + x + " Y" + y);

     } else {

       extrusion += (extrude(previous_point, next_point) * extrusion_multiplier);

       gCommand("G1 X" + x + " Y" + y + " E" + extrusion);

     }

     previous_point = next_point;

   }
    phase+=(PI/180);
    yFactor-=0.05;

 }

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



void setSpeed(float speed) {

 gCommand("G1 F" + speed);

}



void enableFan() {

 gCommand("M 106");

}



void disableFan() {

 gCommand("M 107");

}



void startPrint() {

 gCommand("G91"); //Relative mode

 gCommand("G1 Z1"); //Up one millimeter

 gCommand("G28 X0 Y0"); //Home X and Y axes

 gCommand("G90"); //Absolute mode

 gCommand("G1 X" + x_center_table + " Y" + y_center_table + " F8000"); //Go to the center

 gCommand("G28 Z0"); //Home Z axis

 gCommand("G1 Z0"); //Go to height 0

 gCommand("T0"); //Select extruder 1

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
