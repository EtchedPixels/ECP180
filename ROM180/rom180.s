;
;	A ROM for the minimal RC2014 that lets you use it as a console for
;	CP/M on the Z180
;
	.abs
	.org	0

COPRO	.equ	0x08
COPRORUN .equ	0x0C

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
	in	a,(0x80)
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
	ret	nz
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

	;	Now check the card is present at 0x08
	ld	bc,COPRO
	ld	a,0x55
	out	(c),a
	in	e,(c)
	cp	e
	jr	nz, no_card
	cpl
	out	(c),a
	in	e,(c)
	cp	e
	jr	nz, no_card
	inc	b
	cpl
	out	(c),a
	cpl
	dec	b
	in	e,(c)
	cp	a
	jr	nz, no_card
	;	Ok looks good

	rst	0x20
	.ascii	'ECP180 Present at 0x08'
	.byte	13,10,0

	ld	hl,loader
	ld	bc,COPRO
	; Load 256 bytes
put_loader:
	ld	a,(hl)
	inc	hl
	out	(c),a
	inc	b
	jr	nz, put_loader

	rst	0x20
	.ascii	'Starting coprocessor card'
	.byte	13,10,0

	;	Start coprocessor and poll for it to be ready
	ld	bc,COPRORUN+768		; byte 3
copro_wait:
	in	a,(c)
	cp	0xFF			; wait for the coprocessor to set it
	jr	nz, copro_wait
	;	Coprocessor is live and running the loader

	rst	0x20
	.ascii	'Uploading firmware'
	.byte	0
	.byte	13,10,0

copro_upload:
	ld	hl,firmware
	ld	d,32			; loading 8K
	ld	bc,COPRORUN+512		; byte 2
	out	(c),d			; counter for blocks

	;	We keep writing pages to the chip
	ld	bc,COPRORUN+1		; second page
up_next:
	ld	a,(hl)
	inc	hl
	out	(c),a			; write a byte
	inc	b			; move on
	jr	nz, up_next
	push	bc
	ld	bc,COPRORUN+768
	; CPU set this to FF, write our ready token
	xor	a
	out	(c),a
	ld	a,'.'
	rst	8
upl_wait:
	in	a,(c)
	cp	0xAA			; started ?? oops
	jr	z, copro_run
	inc	a			; FF ?
	jr	nz, upl_wait
	pop	bc
	; Block uploaded correctly
	jr	up_next

copro_run:
	rst	0x20
	.byte	13,10
	.ascii	'Firmware is running'
	.byte	13,10,0

;
;	Now become a glass tty
;
terminal:
	ld	bc,COPRORUN
term_next:
	in	a,(c)
	or	a
	jr	z, no_out
	rst	8
	xor	a
	out	(c),a		; indicate done
no_out:
	inc	b
	in	a,(c)
	or	a
	jr	nz, terminal
	rst	0x18
	inc	a
	jr	z, terminal
	rst	0x10
	out	(c),a		; key to copro
	jr	terminal

no_card:
	rst	0x20
	.ascii	'No ECP180 detected at 0x08'
	.byte	13,10,0
fail:
	ld	a,#0xF0
	out	(0),a
	jp	fail

;
;	This block is loaded at 0 on the coprocessor. Keep relocatable
;
	.z180

loader:
	jr	runld
	.word	0		; control flags
runld:
	;	Map the upper memory to private memory space
	;	CBR 0x38 BBR 0x39 CBAR 0x3A
	ld	a,0x80
	out0	(0x38),a	; 0x8000 up generates 0x80000 + addr
				; ie 0x8000 is "0x8000 in the private RAM
				; This will be fine for uploading stuff like
				; CP/M
	ld	a,0x88		; 0000-7FFF direct mapped
	out0	(0x3A),a	; 8000-FFFF mapped as common area 1
	;	Now do the transfers
	ld	de,0xE000	; Loading to E000-FFFF in SRAM (TODO unhardcode)
	exx
	ld	de,3
	ld	hl,2
nextblock:
	ld	a,0xFF
	ld	(de),a		; indicate ready
waitblock:
	ld	a,(de)
	inc	a
	jr	z, waitblock
	; 0x01xx is a block to upload into main RAM
	exx
	ld	hl,0x0100
	ld	b,h
	ld	c,l
	ldir
	exx
	; Are we there yet ?
	dec	(hl)
	jr	nz, nextblock
	; Indicate we are go
	ld	a,0xAA
	ld	(de),a
	; Run the uploaded code
	jp	0xE000

	.org	0x0300
firmware:
	; Appended here but test code for now
	xor	a
	ld	(0),a
	ld	a,'*'
	ld	(1),a
kwt:
	ld	a,(1)		; char from kbd ?
	or	a
	jr	z,kwt
	ld	c,a
kwto:
	ld	a,(0)		; wait for out buffer
	or	a
	jr	nz,kwto
	ld	a,c
	ld	(0),a		; write it, other end will clear byte when done
	xor	a
	ld	(1),a		; tell the console we ate the char
	jr	kwt

	.org	0x8000
	; RAM (not initialized)
confunc:
	.word	0

