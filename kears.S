;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
; to compile and load:
; m4 demo.S > demo.asm
; avr-as -mmcu=attiny13 -o demo.o demo.asm
; avr-ld -o demo.elf demo.o
; avr-objcopy --output-target=ihex demo.elf demo.ihex
; avrdude -c usbtiny -p t13 -U flash:w:demo.ihex
;


.include "kears_equ.S"





























; NOTE, output port mapping to motors is:
; 0 bottom right
; 1 bottom left
; 2 up left
; 3 up right









.equ SREG, 0x3f
.equ TIMSK0, 0x39
.equ TCCR0B, 0x33
.equ PORTB,0x18
.equ DDRB ,0x17
.equ PINB, 0x16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; sets up buttn timer for debounce
;;; and changes state
.macro butt_trans x
  cli
  ldi   r18, TIME_BUTTON_H
  mov   r10, r18
  ldi   r18, TIME_BUTTON_L
  mov   r11, r18
  ldi   r16, \x
  sei
.endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; set up aux timer and transition state
.macro aux_trans x
  cli
  ldi   r18, AUX_COUNTER_H
  mov   r13, r18
  ldi   r18, AUX_COUNTER_L
  mov   r12, r18
  ldi   r16, \x
  sei
.endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; test aux counter for expiration
.macro aux_n_exp skip_label  ; aux not expired, go to skip_label
  tst   r13
  brne  \skip_label
  tst   r12
  brne  \skip_label
.endm

;;;;;;;;;;;;;;;;;;;;;;
;;; set up aux counter
.macro set_aux_cnt
  cli
  ldi   r18, AUX_COUNTER_H
  mov   r13, r18
  ldi   r18, AUX_COUNTER_L
  mov   r12, r18
  sei
.endm

.macro  set_ear_state a, b, c, d
  cli
  ldi   r25, \a
  ldi   r26, \b
  ldi   r27, \c
  ldi   r28, \d
  sei
.endm

.macro no_btn_hld skip_label
  tst   r10
  brne  \skip_label
  tst   r11
  brne  \skip_label
.endm

.macro moto_func state, ppos
  cp    r24, \state
  brne  moto_func_end_macro_\state
  cbi   PORTB, \ppos
moto_func_end_macro_\state:
.endm


.org 0x00
reset:
rjmp main        ; reset
rjmp defaultInt  ; ext_int0
rjmp defaultInt  ; pcint0
rjmp tim0_ovf    ; tim0_ovf
rjmp defaultInt  ; ee_rdy
rjmp defaultInt  ; ana_comp
rjmp defaultInt  ; tim0_compa
rjmp defaultInt  ; tim0_compb
rjmp defaultInt  ; watchdog
rjmp defaultInt  ; adc

defaultInt:
reti

;;;;; TIMER0 ON OVERFLOW
tim0_ovf:

  ;;;;;;;;;;;;;;
  ;;; save state
  ;;; 3
    push  r17
    in    r17, SREG
    push  r17

  ;;;;;;;;;;;;;;;;;;;;
  ;;;;; r22 counter
  ;;; 4-6
    tst   r11
    brne  button_counter_dec_l
    tst   r10
;    breq  button_counter_end
    breq   button_counter_end
    dec   r10
  button_counter_dec_l:
    dec   r11
  button_counter_end:

  ;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; incrememnt counter
  ;;; 3
    inc   r24
    brne  skip_hcounter_incr
    inc   r23
  skip_hcounter_incr:


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; reset counter and set portb high
  ;;; 9
    cpi   r23, HPW
    brne  skip_set_moto
    cpi   r24, LPW
    brne  skip_set_moto
    ldi   r23, 0
    ldi   r24, 0

    in    r17, PORTB
    ori   r17, 0x0f
    out   PORTB, r17

  skip_set_moto:

  ;;;;;;;;;;;;;;;;;;;;;
  ;;;;; motor functions
  ;;; 6 + 44
    tst  r23
    brne moto_func_end

    moto_func r25, 0 
    moto_func r26, 1
    moto_func r27, 2 
    moto_func r28, 3 

  moto_func_end:

  ;;;;;;;;;;;;;;;;;;;;
  ;;;;; debounce logic
  ;;; 8-15
    ldi   r22, 0
    in    r17, PINB
    andi  r17, 0x10  ; 1 << 4
    breq   debounce_reset_skip
    ldi   r20, 0
    ldi   r21, 0
    rjmp  debounce_end
  debounce_reset_skip:
    inc   r21
    brne  debounce_carry_skip
    inc   r20
  debounce_carry_skip:
    cpi   r20, DEBOUNCEH
    brlo  debounce_end
    cpi   r21, DEBOUNCEL
    brlo  debounce_end 
    ldi   r20, DEBOUNCEH
    ldi   r21, DEBOUNCEL 
    ldi   r22, 1
  debounce_end:


  ;;;;;;;;;;;;;;;;;
  ;;;;; aux counter
  ;;; 4-6
    tst   r12
    brne  aux_counter_dec_l
    tst   r13
    breq   aux_counter_end
    dec   r13
  aux_counter_dec_l:
    dec   r12
  aux_counter_end:


  ;;;;;;;;;;;
  ;;; restore
  ;;; 3
    pop   r17
    out   SREG, r17
    pop   r17

reti



;;;;;;;;;;;;;;
;;;;
;;;;/* MAIN */
;;;;
;;;;;;;;;;;;;;
main:

  ;;;;;;;;;;;;;;;;
  ;;;;;; init
  ldi   r17, 0x0f
  out   DDRB, r17

  in    r17, TCCR0B
  andi  r17, 0xf8
  ori   r17, 1
  out   TCCR0B, r17

  in    r17, TIMSK0
  ori   r17, 2
  out   TIMSK0, r17

  eor   r8, r8

  eor   r20, r20
  eor   r21, r21

  eor   r22, r22
  eor   r10, r10
  eor   r11, r11

  eor   r23, r23
  eor   r24, r24

  eor   r15, r15
  eor   r13, r13
  eor   r12, r12

  ldi   r16, BUTTON_START

  ldi   r19, EAR_STATE_IDLE
  set_ear_state PWM_POS_c, PWM_POS_2, PWM_POS_4, PWM_POS_a

  eor   r18, r18
  eor   r17, r17

  sei

 
main_while:

;;;;;;;;;;;;;;;
;;;; ear states

  ldi   r31, pm_hi8(ear_state_jt)
  ldi   r30, pm_lo8(ear_state_jt)
  add   r30, r19
  adc   r31, r8
  ijmp

ear_state_jt:
  rjmp  ear_state_idle
  rjmp  ear_state_surprise
  rjmp  ear_state_angry
  rjmp  ear_state_distracted0
  rjmp  ear_state_distracted1
  rjmp  ear_state_distracted2
  rjmp  ear_state_distracted3

ear_state_idle:
  set_ear_state PWM_POS_c, PWM_POS_2, PWM_POS_4, PWM_POS_a
  rjmp  ear_state_end
ear_state_surprise:
  set_ear_state PWM_POS_d, PWM_POS_1, PWM_POS_1, PWM_POS_d
  rjmp  ear_state_end
ear_state_angry:
  set_ear_state PWM_POS_2, PWM_POS_c, PWM_POS_a, PWM_POS_4
  rjmp  ear_state_end
ear_state_distracted0:
  set_ear_state PWM_POS_c, PWM_POS_7, PWM_POS_a, PWM_POS_a
  rjmp  ear_state_end
ear_state_distracted1:
  set_ear_state PWM_POS_c, PWM_POS_7, PWM_POS_4, PWM_POS_a
  rjmp  ear_state_end
ear_state_distracted2:
  set_ear_state PWM_POS_c, PWM_POS_7, PWM_POS_a, PWM_POS_a
  rjmp  ear_state_end
ear_state_distracted3:
;  set_ear_state PWM_POS_c, PWM_POS_7, PWM_POS_4, PWM_POS_a
  ; back to idle
  set_ear_state PWM_POS_c, PWM_POS_2, PWM_POS_4, PWM_POS_a

;;  rjmp  ear_state_end

ear_state_end:

  ;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; state transitions
  ldi   r31, pm_hi8(button_state_jt)
  ldi   r30, pm_lo8(button_state_jt)
  add   r30, r16
  adc   r31, r8
  ijmp

button_state_jt:
  rjmp  button_start_state
  rjmp  button_press_state1
  rjmp  button_hold_state1
  rjmp  button_release_state1
  rjmp  button_press_state2
  rjmp  button_hold_state2
  rjmp  button_release_state2
  rjmp  button_press_state3
  rjmp  button_hold_state3
  rjmp  button_release_state3
  rjmp  button_aux_state0
  rjmp  button_aux_state1
  rjmp  button_aux_state2
  rjmp  button_aux_state3

;;;; r22 state transitions
button_start_state:

  ldi   r19, EAR_STATE_IDLE

  tst   r22
  breq   button_state_end_bridge

  butt_trans BUTTON_PRESS1
  rjmp button_state_end_bridge

;;;;
button_press_state1:
  no_btn_hld skip_button_press1

  ; r22 timer expired, go to HOLD1 state
  ldi   r16, BUTTON_HOLD1
  rjmp button_state_end_bridge

skip_button_press1:

  tst   r22
;  brne  button_state_end_bridge
  brne  button_state_end_bridge

  ; buttom tomer not expired, r22 released,
  ; go to RELEASE1 state
  ldi   r16, BUTTON_RELEASE1
  rjmp  button_state_end_bridge

;;;;
button_hold_state1:

  ldi   r19, EAR_STATE_SURPRISE

  tst   r22
;  brne  button_state_end_bridge
  brne  button_state_end_bridge

  ; r22 release, go back to START
  ldi   r16, BUTTON_START
  rjmp button_state_end_bridge

;;;;
button_release_state1:

  tst   r22
  breq   skip_button_release1

  butt_trans    BUTTON_PRESS2
  rjmp button_state_end_bridge

skip_button_release1:
  no_btn_hld button_state_end_bridge

  ldi   r16, BUTTON_START
  rjmp button_state_end

button_state_end_bridge:
  rjmp button_state_end

;;;;
button_press_state2:
  no_btn_hld skip_button_press2

  ldi   r16, BUTTON_HOLD2
  rjmp  button_state_end_bridge

skip_button_press2:

  tst   r22
;  brne  button_state_end_bridge
  brne  button_state_end_bridge

;; ??
  butt_trans BUTTON_RELEASE2
  rjmp button_state_end_bridge

;;;;
button_hold_state2:

  ldi   r19, EAR_STATE_ANGRY

  tst   r22
;  brne  button_state_end_bridge
  brne  button_state_end_bridge

  ldi   r16, BUTTON_START
  rjmp button_state_end_bridge

;;;;
button_release_state2:

  tst   r22
  breq   skip_button_release2

  butt_trans    BUTTON_PRESS3
  rjmp button_state_end

skip_button_release2:
  no_btn_hld button_state_end_bridge

  ldi   r16, BUTTON_START
  rjmp button_state_end

;;;;
button_press_state3:

  aux_trans     BUTTON_AUX_STATE0

  rjmp button_state_end 

;;;;
button_hold_state3:
button_release_state3:

;;;;
button_aux_state0:

  ldi   r19, EAR_STATE_DISTRACTED0

  aux_n_exp     button_aux_state0_wait

  aux_trans     BUTTON_AUX_STATE1
button_aux_state0_wait:
  rjmp button_state_end

;;;;
button_aux_state1:

  ldi   r19, EAR_STATE_DISTRACTED1

  aux_n_exp     button_aux_state1_wait

  aux_trans     BUTTON_AUX_STATE2
button_aux_state1_wait:
  rjmp button_state_end

;;;;
button_aux_state2:

  ldi   r19, EAR_STATE_DISTRACTED2

  aux_n_exp     button_aux_state2_wait

  aux_trans     BUTTON_AUX_STATE3
button_aux_state2_wait:
  rjmp button_state_end

;;;;
button_aux_state3:

  ldi   r19, EAR_STATE_DISTRACTED3

  aux_n_exp     button_aux_state3_wait

  ldi           r16, BUTTON_START
;  aux_trans     BUTTON_START
button_aux_state3_wait:
  rjmp button_state_end


button_state_end:



end:
;rjmp main_bridge
  rjmp  main_while


