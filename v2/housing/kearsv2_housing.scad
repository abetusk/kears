// kears v2 electronic housing
//
// Licensed under CC0
//

MAIN_BOARD_HOLE_DH = 89;
MAIN_BOARD_HOLE_DW = 38;

PWM_HOLE_DH = 56;
PWM_HOLE_DW = 18;

SWITCH_HOLE_DS = 20;

JOYSTICK_HOLE_DH = 19;
JOYSTICK_HOLE_DW = 24;

TUBE_R = 30;
TUBE_RECT_W = 2*tan(22.5)*TUBE_R;

MATERIAL_THICKNESS = 3;
SLOT_W = TUBE_RECT_W - 6;
SLOT_H = MATERIAL_THICKNESS;

SCREW_R = 2/2;

FN=32;

module hexagon(r) {
  dh = 2*r;
  dw = 2*tan(22.5)*r;
  union() {
    square([dh,dw], center=true);
    rotate(45, [0,0,1]) square([dh,dw], center=true);
    rotate(90, [0,0,1]) square([dh,dw], center=true);
    rotate(-45, [0,0,1]) square([dh,dw], center=true);
  };
}

module head_plate() {
  m = MATERIAL_THICKNESS;
  difference() {
    
    hexagon(TUBE_R);
    
    translate([0, TUBE_R - m*2])
      square([SLOT_W, SLOT_H], center=true);
    translate([0, -(TUBE_R - m*2)])
      square([SLOT_W, SLOT_H], center=true);
    
    translate([TUBE_RECT_W/2 + m, 0])
      square([SLOT_H, SLOT_W], center=true);
    translate([-(TUBE_RECT_W/2 + m), 0])
      square([SLOT_H, SLOT_W], center=true);

    translate([-(TUBE_R-1.5*SLOT_H),0])
      square([SLOT_H, SLOT_W], center=true);
    translate([ (TUBE_R-1.5*SLOT_H),0])
      square([SLOT_H, SLOT_W], center=true);
    
    translate([0,TUBE_R/4]) circle(TUBE_R/3, $fn=FN);
  };
}

module back_plate() {
  m = MATERIAL_THICKNESS;
  difference() {
    
    hexagon(TUBE_R);
    
    translate([0, TUBE_R - m*2])
      square([SLOT_W, SLOT_H], center=true);
    translate([0, -(TUBE_R - m*2)])
      square([SLOT_W, SLOT_H], center=true);
    
    translate([TUBE_RECT_W/2 + m, 0])
      square([SLOT_H, SLOT_W], center=true);
    translate([-(TUBE_RECT_W/2 + m), 0])
      square([SLOT_H, SLOT_W], center=true);

    translate([-(TUBE_R-1.5*SLOT_H),0])
      square([SLOT_H, SLOT_W], center=true);
    translate([ (TUBE_R-1.5*SLOT_H),0])
      square([SLOT_H, SLOT_W], center=true);

    square([10,6], center=true);

  };
}

module side_inner_plate() {
  dh = TUBE_R*2 - 2*MATERIAL_THICKNESS;
  dl = MAIN_BOARD_HOLE_DH + 4*MATERIAL_THICKNESS;
  m = MATERIAL_THICKNESS;
  
  cut_l = MAIN_BOARD_HOLE_DH - 4*m;
  cut_h = MAIN_BOARD_HOLE_DW - 4*m;
  
  h_l = MAIN_BOARD_HOLE_DH;
  h_h = MAIN_BOARD_HOLE_DW;
  
  difference() {
    union() {
      square([dl,dh], center=true);
      translate([dl/2 + SLOT_H/2,0])
        square([SLOT_H, SLOT_W], center=true);
      translate([-(dl/2 + SLOT_H/2),0])
        square([SLOT_H, SLOT_W], center=true);
    };
    
    translate([0,dh/2-m-SLOT_H/2])
      square([SLOT_W, SLOT_H],center=true);
    translate([0,-(dh/2-m-SLOT_H/2)])
      square([SLOT_W, SLOT_H],center=true);
    
    hull() {
      translate([-cut_l/2, -cut_h/2])
        circle(m);
      translate([ cut_l/2, -cut_h/2])
        circle(m);
      translate([ cut_l/2,  cut_h/2])
        circle(m);
      translate([-cut_l/2,  cut_h/2])
        circle(m);
    };
    
    translate([-h_l/2, -h_h/2])
      circle(SCREW_R, $fn=FN);
    translate([ h_l/2, -h_h/2])
      circle(SCREW_R, $fn=FN);
    translate([ h_l/2,  h_h/2])
      circle(SCREW_R, $fn=FN);
    translate([-h_l/2,  h_h/2])
      circle(SCREW_R, $fn=FN);

  };
}

module side_inner_plate_1() {
  dh = TUBE_R*2 - 2*MATERIAL_THICKNESS;
  dl = MAIN_BOARD_HOLE_DH + 4*MATERIAL_THICKNESS;
  m = MATERIAL_THICKNESS;
  
  cut_l = PWM_HOLE_DH - 4*m;
  cut_h = PWM_HOLE_DW - 4*m;
  
  h_l = PWM_HOLE_DH;
  h_h = PWM_HOLE_DW;
  

  difference() {
    union() {
      square([dl,dh], center=true);
      translate([dl/2 + SLOT_H/2,0])
        square([SLOT_H, SLOT_W], center=true);
      translate([-(dl/2 + SLOT_H/2),0])
        square([SLOT_H, SLOT_W], center=true);
    };
    
    translate([0,dh/2-m-SLOT_H/2])
      square([SLOT_W, SLOT_H],center=true);
    translate([0,-(dh/2-m-SLOT_H/2)])
      square([SLOT_W, SLOT_H],center=true);
    
    hull() {
      translate([-cut_l/2, -cut_h/2])
        circle(m);
      translate([ cut_l/2, -cut_h/2])
        circle(m);
      translate([ cut_l/2,  cut_h/2])
        circle(m);
      translate([-cut_l/2,  cut_h/2])
        circle(m);
    };
    
    translate([-h_l/2, -h_h/2])
      circle(SCREW_R, $fn=FN);
    translate([ h_l/2, -h_h/2])
      circle(SCREW_R, $fn=FN);
    translate([ h_l/2,  h_h/2])
      circle(SCREW_R, $fn=FN);
    translate([-h_l/2,  h_h/2])
      circle(SCREW_R, $fn=FN);

  };
}

module action_plate() {
  m = MATERIAL_THICKNESS;
  dw = 50;
  dh = 40;
  
  bx = -12;
  by = 0;
  bw = 4*SCREW_R;
  bh = SWITCH_HOLE_DS - 4*SCREW_R;
  
  jsx = 5;
  jsy = 0;
  jsr = JOYSTICK_HOLE_DH/2 - m;
  js_dh = JOYSTICK_HOLE_DH;
  js_dw = JOYSTICK_HOLE_DW;
  difference() {
    square([dw, dh], center=true);
    
    translate([-(dw/2-m-SLOT_H/2),0])
      square([SLOT_H,SLOT_W], center=true);
    translate([ (dw/2-m-SLOT_H/2),0])
      square([SLOT_H,SLOT_W], center=true);

    
    translate([bx,by])
      square([bw,bh], center=true);
    translate([bx,by + SWITCH_HOLE_DS/2])
      circle(SCREW_R, $fn=FN);
    translate([bx,by - SWITCH_HOLE_DS/2])
      circle(SCREW_R, $fn=FN);

    hull() {
      translate([jsx, jsy])
        circle(jsr, $fn=FN);
      translate([jsx, jsy- 20])
        circle(jsr, $fn=FN);
    };
    translate([jsx - js_dh/2,jsy - js_dw/2])
      circle(SCREW_R, $fn=FN);
    translate([jsx + js_dh/2,jsy - js_dw/2])
      circle(SCREW_R, $fn=FN);
    translate([jsx + js_dh/2,jsy + js_dw/2])
      circle(SCREW_R, $fn=FN);
    translate([jsx - js_dh/2,jsy + js_dw/2])
      circle(SCREW_R, $fn=FN);
  };
}

head_plate();
translate([2*TUBE_R + 5,0]) back_plate();
translate([-100,0]) side_inner_plate();
translate([-100,60]) side_inner_plate_1();
translate([160,0]) side_inner_plate_1();

translate([0,60]) action_plate();