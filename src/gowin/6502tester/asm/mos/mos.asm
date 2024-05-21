
HW_UART_DAT	:=	$D000		; 2xLED 7 segment display
HW_DEBUG		:=	$E000		; 2xLED 7 segment display



		.code

reset:		sei
		cld
		ldx	#$FF
		txs

@lp3:		lda	#$FF
		ldy	#0


@lp2:		ldx	#200
@lp:		dey
		bne	@lp
		dex	
		bne	@lp
		clc
		adc	#1
		tax
		sta	HW_DEBUG
		lda	str,X
		beq	@lp3		
		sta	HW_UART_DAT
		txa
		jmp	@lp2


str:		.byte	"This is a test",13,10,0


irq:
nmi:
		rti


		.segment "VECS"
		.addr	nmi
		.addr	reset
		.addr	irq

