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

define(brz, breq)
define(brnz, brne)
define(bron, brne)

define(zero, r8)

define(button_h, r10)
define(button_l, r11)

define(aux_counter_l, r12)
define(aux_counter_h, r13)

define(aux_pos, r15)

define(button_state, r16)

define(tmp, r17)
define(t, r18)


define(ear_state, r19)
define(hbc, r20)
define(lbc, r21)
define(button, r22)

define(hcounter, r23)
define(lcounter, r24)

; NOTE, output port mapping to motors is:
; 0 bottom right
; 1 bottom left
; 2 up left
; 3 up right
define(moto_pwm_state0, r25)
define(moto_pwm_state1, r26)
define(moto_pwm_state2, r27)
define(moto_pwm_state3, r28)


define(zh, r31)
define(zl, r30)

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
  ldi   t, TIME_BUTTON_H
  mov   button_h, t
  ldi   t, TIME_BUTTON_L
  mov   button_l, t
  ldi   button_state, \x
  sei
.endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; set up aux timer and transition state
.macro aux_trans x
  cli
  ldi   t, AUX_COUNTER_H
  mov   aux_counter_h, t
  ldi   t, AUX_COUNTER_L
  mov   aux_counter_l, t
  ldi   button_state, \x
  sei
.endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; test aux counter for expiration
.macro aux_n_exp skip_label  ; aux not expired, go to skip_label
  tst   aux_counter_h
  brnz  \skip_label
  tst   aux_counter_l
  brnz  \skip_label
.endm

;;;;;;;;;;;;;;;;;;;;;;
;;; set up aux counter
.macro set_aux_cnt
  cli
  ldi   t, AUX_COUNTER_H
  mov   aux_counter_h, t
  ldi   t, AUX_COUNTER_L
  mov   aux_counter_l, t
  sei
.endm

.macro  set_ear_state a, b, c, d
  cli
  ldi   moto_pwm_state0, \a
  ldi   moto_pwm_state1, \b
  ldi   moto_pwm_state2, \c
  ldi   moto_pwm_state3, \d
  sei
.endm

.macro no_btn_hld skip_label
  tst   button_h
  brnz  \skip_label
  tst   button_l
  brnz  \skip_label
.endm

.macro moto_func state, ppos
  cp    lcounter, \state
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
    push  tmp
    in    tmp, SREG
    push  tmp

  ;;;;;;;;;;;;;;;;;;;;
  ;;;;; button counter
  ;;; 4-6
    tst   button_l
    brnz  button_counter_dec_l
    tst   button_h
;    breq  button_counter_end
    brz   button_counter_end
    dec   button_h
  button_counter_dec_l:
    dec   button_l
  button_counter_end:

  ;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; incrememnt counter
  ;;; 3
    inc   lcounter
    brne  skip_hcounter_incr
    inc   hcounter
  skip_hcounter_incr:


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; reset counter and set portb high
  ;;; 9
    cpi   hcounter, HPW
    brne  skip_set_moto
    cpi   lcounter, LPW
    brne  skip_set_moto
    ldi   hcounter, 0
    ldi   lcounter, 0

    in    tmp, PORTB
    ori   tmp, 0x0f
    out   PORTB, tmp

  skip_set_moto:

  ;;;;;;;;;;;;;;;;;;;;;
  ;;;;; motor functions
  ;;; 6 + 44
    tst  hcounter
    brnz moto_func_end

    moto_func moto_pwm_state0, 0 
    moto_func moto_pwm_state1, 1
    moto_func moto_pwm_state2, 2 
    moto_func moto_pwm_state3, 3 

  moto_func_end:

  ;;;;;;;;;;;;;;;;;;;;
  ;;;;; debounce logic
  ;;; 8-15
    ldi   button, 0
    in    tmp, PINB
    andi  tmp, 0x10  ; 1 << 4
    brz   debounce_reset_skip
    ldi   hbc, 0
    ldi   lbc, 0
    rjmp  debounce_end
  debounce_reset_skip:
    inc   lbc
    brnz  debounce_carry_skip
    inc   hbc
  debounce_carry_skip:
    cpi   hbc, DEBOUNCEH
    brlo  debounce_end
    cpi   lbc, DEBOUNCEL
    brlo  debounce_end 
    ldi   hbc, DEBOUNCEH
    ldi   lbc, DEBOUNCEL 
    ldi   button, 1
  debounce_end:


  ;;;;;;;;;;;;;;;;;
  ;;;;; aux counter
  ;;; 4-6
    tst   aux_counter_l
    brnz  aux_counter_dec_l
    tst   aux_counter_h
    brz   aux_counter_end
    dec   aux_counter_h
  aux_counter_dec_l:
    dec   aux_counter_l
  aux_counter_end:


  ;;;;;;;;;;;
  ;;; restore
  ;;; 3
    pop   tmp
    out   SREG, tmp
    pop   tmp

reti



;;;;;;;;;;;;;;
;;;;
;;;;/* MAIN */
;;;;
;;;;;;;;;;;;;;
main:

  ;;;;;;;;;;;;;;;;
  ;;;;;; init
  ldi   tmp, 0x0f
  out   DDRB, tmp

  in    tmp, TCCR0B
  andi  tmp, 0xf8
  ori   tmp, 1
  out   TCCR0B, tmp

  in    tmp, TIMSK0
  ori   tmp, 2
  out   TIMSK0, tmp

  eor   zero, zero

  eor   hbc, hbc
  eor   lbc, lbc

  eor   button, button
  eor   button_h, button_h
  eor   button_l, button_l

  eor   hcounter, hcounter
  eor   lcounter, lcounter

  eor   aux_pos, aux_pos
  eor   aux_counter_h, aux_counter_h
  eor   aux_counter_l, aux_counter_l

  ldi   button_state, BUTTON_START

  ldi   ear_state, EAR_STATE_IDLE
  set_ear_state PWM_POS_c, PWM_POS_2, PWM_POS_4, PWM_POS_a

  eor   t, t
  eor   tmp, tmp

  sei

 
main_while:

;;;;;;;;;;;;;;;
;;;; ear states

  ldi   zh, pm_hi8(ear_state_jt)
  ldi   zl, pm_lo8(ear_state_jt)
  add   zl, ear_state
  adc   zh, zero
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
  ldi   zh, pm_hi8(button_state_jt)
  ldi   zl, pm_lo8(button_state_jt)
  add   zl, button_state
  adc   zh, zero
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

;;;; button state transitions
button_start_state:

  ldi   ear_state, EAR_STATE_IDLE

  tst   button
  brz   button_state_end_bridge

  butt_trans BUTTON_PRESS1
  rjmp button_state_end_bridge

;;;;
button_press_state1:
  no_btn_hld skip_button_press1

  ; button timer expired, go to HOLD1 state
  ldi   button_state, BUTTON_HOLD1
  rjmp button_state_end_bridge

skip_button_press1:

  tst   button
;  brnz  button_state_end_bridge
  bron  button_state_end_bridge

  ; buttom tomer not expired, button released,
  ; go to RELEASE1 state
  ldi   button_state, BUTTON_RELEASE1
  rjmp  button_state_end_bridge

;;;;
button_hold_state1:

  ldi   ear_state, EAR_STATE_SURPRISE

  tst   button
;  brnz  button_state_end_bridge
  bron  button_state_end_bridge

  ; button release, go back to START
  ldi   button_state, BUTTON_START
  rjmp button_state_end_bridge

;;;;
button_release_state1:

  tst   button
  brz   skip_button_release1

  butt_trans    BUTTON_PRESS2
  rjmp button_state_end_bridge

skip_button_release1:
  no_btn_hld button_state_end_bridge

  ldi   button_state, BUTTON_START
  rjmp button_state_end

button_state_end_bridge:
  rjmp button_state_end

;;;;
button_press_state2:
  no_btn_hld skip_button_press2

  ldi   button_state, BUTTON_HOLD2
  rjmp  button_state_end_bridge

skip_button_press2:

  tst   button
;  brnz  button_state_end_bridge
  bron  button_state_end_bridge

;; ??
  butt_trans BUTTON_RELEASE2
  rjmp button_state_end_bridge

;;;;
button_hold_state2:

  ldi   ear_state, EAR_STATE_ANGRY

  tst   button
;  brnz  button_state_end_bridge
  bron  button_state_end_bridge

  ldi   button_state, BUTTON_START
  rjmp button_state_end_bridge

;;;;
button_release_state2:

  tst   button
  brz   skip_button_release2

  butt_trans    BUTTON_PRESS3
  rjmp button_state_end

skip_button_release2:
  no_btn_hld button_state_end_bridge

  ldi   button_state, BUTTON_START
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

  ldi   ear_state, EAR_STATE_DISTRACTED0

  aux_n_exp     button_aux_state0_wait

  aux_trans     BUTTON_AUX_STATE1
button_aux_state0_wait:
  rjmp button_state_end

;;;;
button_aux_state1:

  ldi   ear_state, EAR_STATE_DISTRACTED1

  aux_n_exp     button_aux_state1_wait

  aux_trans     BUTTON_AUX_STATE2
button_aux_state1_wait:
  rjmp button_state_end

;;;;
button_aux_state2:

  ldi   ear_state, EAR_STATE_DISTRACTED2

  aux_n_exp     button_aux_state2_wait

  aux_trans     BUTTON_AUX_STATE3
button_aux_state2_wait:
  rjmp button_state_end

;;;;
button_aux_state3:

  ldi   ear_state, EAR_STATE_DISTRACTED3

  aux_n_exp     button_aux_state3_wait

  ldi           button_state, BUTTON_START
;  aux_trans     BUTTON_START
button_aux_state3_wait:
  rjmp button_state_end


button_state_end:



end:
;rjmp main_bridge
  rjmp  main_while

