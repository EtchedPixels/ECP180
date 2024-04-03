;
;	A ROM for the minimal RC2014 that lets you use it as a console for
;	CP/M on the Z180
;
	.abs
	.org	0

rst0:
	di
	ld	sp,0xFFFF
	jp	start
	nop
rst8:				; print char in A, preserve BC-HL
	push	bc
	push	de
	push	hl
	ld	c,a
	jr	rst8con
	nop
	nop
rst10:				; get a char in A, preserve BC-HL
	push	bc
	push	de
	push	hl
	call	conin
	jr	poppers
rst18:				; test for input ready, preserve BC-HL
	push	bc		; on return A = 255 for yes, 0 for no
	push	de
	push	hl
	call	const
	jr	poppers
rst20:
	jp	strout
	nop
	nop
	nop
	nop
	nop
rst28:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
rst30:
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
rst38:
	reti
rst8con:
	call	conout
poppers:
	pop	hl
	pop	de
	pop	bc
	ret

start:
	ld	a,0xCC
	out	(0x00),a	; Debug LEDS
	; ACIA ?
	in	a,(0xA0)
	and	2
	jr	z, not_an_acia
	;	A is currently 2
	inc	a	; 3
	out	(0xA0),a	; Reset ACIA
	in	a,(0xA0)
	and	2
	jr	nz, not_an_acia
	ld	a,0x02
	out	(0xA0),a
	ld	a,0x96
	out	(0xA0),a
	ld	a,'E'
	out	(0xA1),a	; Show the user something
	ld	hl, aciafunc
	jp	init_ram
not_an_acia:
	in	a,(0xA3)	; Look for a 16x50
	ld	e,a
	or	0x80
	ld	c,a
	out	(0xA3),a
	in	a,(0xA1)
	ld	d,a
	ld	a,0xAA
	out	(0xA1),a
	in	a,(0xA1)
	cp	0xAA
	jr	nz, not_16x50
	ld	a,e
	out	(0xA3),a
	in	a,(0xA1)
	cp	0xAA
	jr	z, not_16x50
	; Set up port
	ld	a,c
	out	(0xA3),a
	xor	a
	out	(0xA0),a
	inc	a
	out	(0xA1),a	; 115200
	ld	a,3
	out	(0xA3),a
	dec	a
	out	(0xA4),a
	ld	a,0x87
	out	(0xA2),a
	ld	a,'E'
	out	(0xA0),a
	ld	hl, ns16x50func
	jr	init_ram

not_16x50:
	; SIO time
	ld	bc,0x0A80
	ld	hl, sio_setup
	otir
	ld	bc,0x0A82
	ld	hl, sio_setup
	otir

	ld	a,'E'
	out	(0x81),a

	ld	hl, siofunc

init_ram:
	;	No work to do as we are on a base system
	jp	main

aciafunc:
	.word	aciaout
	.word	aciain
	.word	aciapoll
	.word	aciaopoll

aciaout:
	ld	b,a
aciaow:
	in	a,(0xA0)
	and	2
	jr	z,aciaow
	ld	a,b
	out	(0xA1),a
	ret
aciain:
	in	a,(0xA1)
	ret
aciapoll:
	in	a,(0xA0)
	and	1
	ret
aciaopoll:
	in	a,(0xA0)
	and	2
	ret

ns16x50func:
	.word	ns16x50out
	.word	ns16x50in
	.word	ns16x50poll
	.word	ns16x50opoll

ns16x50out:
	ld	b,a
ns16x50outw:	
	; Do we need the wait here FIXME
	in	a,(0xA5)
	and	0x20
	jr	z,ns16x50outw
	ld	a,b
	out	(0xA0),a
	ret
ns16x50in:
	in	a,(0xA0)
	ret
ns16x50poll:
	in	a,(0xA5)
	and	1
	ret
ns16x50opoll:
	in	a,(0xA5)
	and	0x20
	ret

sio_setup:
	.byte	0x00
	.byte	0x18
	.byte	0x04
	.byte	0xC4
	.byte	0x01
	.byte	0x18
	.byte	0x03
	.byte	0xE1
	.byte	0x05
	.byte	0xEA

siofunc:
	.word	sioout
	.word	sioin
	.word	siopoll
	.word	sioopoll


sioout:	
	ld b,a
siooutw:
	in	a,(0x80)
	and	4
	jr	z,siooutw
	ld	a,b
	out	(0x81),a
	ret
sioin:
	in	a,(0x81)
	ret
siopoll:
	in	a,(0x80)
	and	1
	ret
sioopoll:
	in	a,(080h)
	and	4
	ret
;
;
;
strout:
	push	hl
	ld	hl,(confunc)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	pop	hl
	ex	(sp),hl
	push	bc
stroutl:
	ld	a,(hl)
	or	a
	jr	z, strout_done
	call	jpde
	inc	hl
	jr	stroutl
strout_done:	pop bc
	ex	(sp),hl
	ret
jpde:
	push de
	ret

;
;	Console helpers. These should avoid destroying DE to keep our BIOS
;	users happy
; 
;	These implement the corresponding CP/M BIOS functions.
;
conout:
	ld	hl,(confunc)
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	a,c
jphl:
	jp	(hl)
conin:
	push	ix
	ld	ix,(confunc)
conin2:
	ld	l,(ix + 4)
	ld	h,(ix + 5)
coninw:		
	call	jphl
	or	a
	jr	z,coninw
	ld	l,(ix + 2)
	ld	h,(ix + 3)
	pop	ix
	jp	(hl)

const:
	push	ix
	ld	ix,(confunc)
conout2:
	ld	l,(ix + 4)
	ld	h,(ix + 5)
const2:
	call	jphl
	pop	ix
	ld	a,0
	ret	z
	dec	a
	ret

conost:
	push	ix
	ld	ix,(confunc)
conost2:
	ld	l,(ix + 6)
	ld	h,(ix + 7)
	jr	const2

main:
	ld	(confunc),hl
	rst	0x20
	.ascii	"tched Pixels ECP180"
	.byte	13,10,13,10,0

moo:	jp	moo



	.org	0x8000
	; RAM (not initialized)
confunc:
	.word	0