
HW_PORTA		:=	$C000		; control port
HW_UART_DAT	:=	$D000		; UART DATA
HW_UART_STAT	:=	$D001		; UART STATUS
HW_DEBUG		:=	$E000		; 2xLED 7 segment display

		
		.zeropage
zp_strptr:	.res 	2
zp_phase:	.res	1

		.pc02
		

		.macro DEB	n
		pha
		lda	#n
		sta	HW_DEBUG
		pla
		.endmacro

		.code

str_boo:		.byte	"START",13,10,0
str_badp1:	.byte	"No RAM in page 1",13,10,0
str_badp0:	.byte	"No RAM in page 0",13,10,0


.proc badp1
@lp3:		ldx	#0
@lp2:		lda	str_badp1,X
		beq	@sk3	
		inx	
@lp4:		bit	HW_UART_STAT
		bmi	@lp4
		sta	HW_UART_DAT
		jmp	@lp2
@sk3:		jmp	@sk3

.endproc

.proc badp0
@lp3:		ldx	#0
@lp2:		lda	str_badp0,X
		beq	@sk3	
		inx	
@lp4:		bit	HW_UART_STAT
		bmi	@lp4
		sta	HW_UART_DAT
		jmp	@lp2
@sk3:		jmp	@sk3

.endproc




reset:		sei
		cld
		ldx	#$FF
		txs

		lda	#0
		sta	HW_DEBUG

		ldx	#0
@lp2:		lda	str_boo,X
		beq	@sk3	
		inx	
@lp4:		bit	HW_UART_STAT
		bmi	@lp4
		sta	HW_UART_DAT
		jmp	@lp2
@sk3:		




		; test ram in page 1
		lda	#2
		pha
		lda	#1
		pha
		pla
		cmp	#1
		bne	badp1
		pla
		cmp	#2
		bne	badp1

		lda	#1
		sta	HW_DEBUG
		; we can now use the stack, check page 0

		lda	#2
		sta	0
		lda	#1
		sta	1
		lda	0
		cmp	#2
		bne	badp0
		lda	1
		cmp	#1
		bne	badp0

		lda	#2
		sta	HW_DEBUG
		
		jsr	printI
		.byte	"RAM OK in pages 0,1",13,10,0
		jsr	printI
		.byte	"Lump chips",13,10,0

		lda	#3
		sta	HW_DEBUG


		lda	#0
		sta	zp_phase
outer_loop:	lda	zp_phase
		sta	HW_DEBUG
		jsr	printHexA
		lda	#' '
		jsr	printA

		ldx	#0
@x1:		lda	str_test,X
		sta	$2000,X
		inx
		cpx	#4
		bne	@x1

		ldx	#0
@x2:		lda	$2000,X
		eor	str_test,X
		jsr	printHexA
		inx
		cpx	#4
		bne	@x2

		jsr	printI
		.byte	13,10,0

		; bump phase
		lda	#5		; reset and nudge phase
		sta	HW_PORTA		
		lda	#0
		sta	HW_PORTA		

		ldx	#0
		ldy	#0
@dl1:		dey
		bne	@dl1
		dex
		bne	@dl1


		inc	zp_phase
		bne	outer_loop


h:		jmp	h

str_test:	.byte $A5,$5A,$BE,$EF


	.proc	printI
		pha
		phy
		phx
		tsx
		lda	$104,X
		sta	zp_strptr
		lda	$105,X
		sta	zp_strptr+1
		ldy	#0
@lp:		iny
		lda	(zp_strptr),Y
		beq	@sk
		jsr	printA
		bra	@lp
@sk:		tya
		clc
		adc	zp_strptr
		sta	$104,X
		lda	zp_strptr+1
		adc	#0
		sta	$105,X
		plx
		ply
		pla
		rts
	.endproc

	.proc	printA
@lp4:		bit	HW_UART_STAT
		bmi	@lp4		
		sta	HW_UART_DAT
		rts
	.endproc


	.proc	printHexA
	pha
	lsr	A
	lsr	A
	lsr	A
	lsr	A
	jsr	@nyb
	pla
	pha
	jsr	@nyb
	pla
	rts
@nyb:	and	#$F
	ora	#'0'
	cmp	#$3A
	bcc	@s
	adc	#'A'-$3A-1
@s:	jsr	printA
	rts


	.endproc






irq:
nmi:
		rti


		.segment "VECS"
		.addr	nmi
		.addr	reset
		.addr	irq

