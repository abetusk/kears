#include <avr/interrupt.h>

#define DEBOUNCEH 14
#define DEBOUNCEL 166

#define HPW 2
#define LPW 238

/*
//#define LEFTC 17
#define LLEFTC 17
#define LEFTC 25
#define MIDC 55
#define RIGHTC 92
#define RRIGHTC 100
*/

/*
//#define LEFTC 17
#define LLEFTC 25
#define LEFTC 30
#define MIDC 55
#define RIGHTC 86
#define RRIGHTC 92
*/

//#define LEFTC 17
#define LLEFTC 20
#define LEFTC 35
#define MIDC 55
#define RIGHTC 80
#define RRIGHTC 95

#define POS_LEFT 1
#define POS_MID 2
#define POS_RIGHT 3
#define POS_L_LEFT 4
#define POS_R_RIGHT 5

//#define BUTTON_START 1
#define BUTTON_PRESS1 2
#define BUTTON_HOLD1 3
#define BUTTON_RELEASE1 4
#define BUTTON_PRESS2 5
#define BUTTON_HOLD2 6
#define BUTTON_RELEASE2 7
#define BUTTON_PRESS3 8
#define BUTTON_HOLD3 9
#define BUTTON_RELEASE3 10

#define BUTTON_AUX_STATE1 11
#define BUTTON_AUX_STATE2 12
#define BUTTON_AUX_STATE3 13
#define BUTTON_AUX_STATE4 14

#define BUTTON_START 15

#define TIME_BUTTON_H 50
#define TIME_BUTTON_L 255

#define EAR_STATE_IDLE 1
#define EAR_STATE_SURPRISE 2
#define EAR_STATE_ANGRY 3
#define EAR_STATE_DISTRACTED_1 4
#define EAR_STATE_DISTRACTED_2 5
#define EAR_STATE_DISTRACTED_3 6
#define EAR_STATE_DISTRACTED_4 7

// button state counter

volatile unsigned char button_state=BUTTON_START;
volatile unsigned char button_h=0;
volatile unsigned char button_l=0;

unsigned char ear_state=EAR_STATE_IDLE;

// button debounce counter
volatile char hbc=0;
volatile char lbc=0;
volatile char button=0;

// pwm counter
volatile char hcounter=0;
volatile char lcounter=0;

//motor position variables
volatile unsigned char state0=POS_LEFT;
volatile unsigned char state1=POS_LEFT;
volatile unsigned char state2=POS_LEFT;
volatile unsigned char state3=POS_LEFT;

void moto_func(unsigned char state, unsigned char PBX) {

  if (state==POS_LEFT) {
    if ((hcounter==0) && (lcounter == LEFTC)) {
      PORTB &= ~(1<<PBX);
    }
  } else if (state==POS_MID) {
    if ((hcounter==0) && (lcounter == MIDC)) {
      PORTB &= ~(1<<PBX);
    }
  } else if (state==POS_RIGHT) {
    if ((hcounter==0) && (lcounter == RIGHTC)) {
      PORTB &= ~(1<<PBX);
    }
  } else if (state==POS_L_LEFT) {
    if ((hcounter==0) && (lcounter == LLEFTC)) {
      PORTB &= ~(1<<PBX);
    }
  } else if (state==POS_R_RIGHT) {
    if ((hcounter==0) && (lcounter == RRIGHTC)) {
      PORTB &= ~(1<<PBX);
    }
  }

}

#define button_transition(x) button_h = TIME_BUTTON_H ; button_l = TIME_BUTTON_L ; button_state = (x)

// called 37500 a second
ISR(TIM0_OVF_vect) {

  if ((button_h != 0) || (button_l != 0)) {
    if (button_l == 0) {
      if (button_h>0) {
        button_l = 255;
        button_h--;
      }
    } else {
      button_l--;
    }
  }

  // PWM servo motor control

  lcounter++;
  if (lcounter==0) hcounter++;

  if ((hcounter==HPW) && (lcounter==LPW)) {
    lcounter=hcounter=0;
    PORTB |=  (1<<PB3) | (1<<PB2) | (1<<PB1) | (1<<PB0);
  }


  moto_func(state1, PB3);
  moto_func(state2, PB2);
  moto_func(state3, PB1);
  moto_func(state0, PB0);


  button=0;
  if ( PINB & (1<<PB4) ) {
    hbc=lbc=0;
  } else {
    lbc++;
    if (lbc==0) hbc++;
    if ( (hbc >= DEBOUNCEH) && (lbc >= DEBOUNCEL)) {
      button=1;
      hbc=DEBOUNCEH;
      lbc=DEBOUNCEL;
    }
  }


}

                
int main(void) {
  char t;


  DDRB = 0b00001111;

  // prescale timer to every clock tick
  TCCR0B |= (0<<CS02) | (0<<CS01) | (1<<CS00);
                                
  // enable timer overflow interrupt
  TIMSK0 |=1<<TOIE0;
  sei();
                                          
  while(1) {

    /*
    if (button) {
      ear_state = EAR_STATE_ANGRY;
    } else {
      ear_state = EAR_STATE_IDLE;
    }
    */


    // button state control

    if (button_state == BUTTON_START) {
      ear_state=EAR_STATE_IDLE;
      if (button) {
        button_transition(BUTTON_PRESS1);
      }
    } 
    else if (button_state == BUTTON_PRESS1) {
      if ((button_h==0) && (button_l==0)) {
        button_state = BUTTON_HOLD1;
      }
      else if (button==0) {
        button_transition(BUTTON_RELEASE1);
      }
    }
    else if (button_state == BUTTON_HOLD1) {
      ear_state=EAR_STATE_SURPRISE;
      if (button==0) {
        button_state = BUTTON_START;
      }
    }
    else if (button_state == BUTTON_RELEASE1) {
      if (button) {
        button_transition(BUTTON_PRESS2);
      }
      if ((button_h==0) && (button_l==0)) {
        button_state = BUTTON_START;
      }
    }

    else if (button_state == BUTTON_PRESS2) {
      if ((button_h==0) && (button_l==0)) {
        button_state = BUTTON_HOLD2;
      }
      else if (button==0) {
        button_transition(BUTTON_RELEASE2);
      }
    }
    else if (button_state == BUTTON_HOLD2) {
      ear_state=EAR_STATE_ANGRY;
      if (button==0) {
        button_state = BUTTON_START;
      }
    } 
    else if (button_state == BUTTON_RELEASE2) {

      //if (button) {
      //  button_transition(BUTTON_AUX_STATE1);
      //}
      button_state = BUTTON_START;
    }

//    else {
//      char t = ear_state-BUTTON_AUX_STATE1;
//      ear_state = EAR_STATE_DISTRACTED_1 + t;
//      if ( (button_h == 0) && (button_l == 0)) {
//        button_transition(BUTTON_AUX_STATE2+t);
//      }
//      if (button_state>=BUTTON_START) button_state=BUTTON_START;
//    } 


    // logical ear state control

    if (ear_state == EAR_STATE_IDLE) {
      state0=POS_LEFT;
      state1=POS_RIGHT;
      state2=POS_RIGHT;
      state3=POS_LEFT;
    } else if (ear_state == EAR_STATE_SURPRISE) {
      state0=POS_LEFT;
      state1=POS_R_RIGHT;
      state2=POS_RIGHT;
      state3=POS_L_LEFT;
    } else if (ear_state == EAR_STATE_ANGRY) {
      state0=POS_RIGHT;
      state1=POS_LEFT;
      state2=POS_LEFT;
      state3=POS_RIGHT;
    } else if ((ear_state == EAR_STATE_DISTRACTED_1) ||
               (ear_state == EAR_STATE_DISTRACTED_3)) {
      state0=POS_LEFT;
      state1=POS_LEFT;
      state2=POS_RIGHT;
      state3=POS_MID;
    } else if ((ear_state == EAR_STATE_DISTRACTED_2) ||
               (ear_state == EAR_STATE_DISTRACTED_4)) {
      state0=POS_RIGHT;
      state1=POS_RIGHT;
      state2=POS_RIGHT;
      state3=POS_MID;
    }


  }

}

