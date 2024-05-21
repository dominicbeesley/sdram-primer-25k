
HW_UART_DAT	:=	$D000		; UART DATA
HW_UART_STAT	:=	$D001		; UART STATUS
HW_DEBUG		:=	$E000		; 2xLED 7 segment display



		.code

reset:		sei
		cld
		ldx	#$FF
		txs

@lp3:		ldx	#0
@lp2:		stx	HW_DEBUG
		lda	str,X
		beq	@lp3	
		inx	
@lp4:		bit	HW_UART_STAT
		bmi	@lp4
		sta	HW_UART_DAT
		jmp	@lp2


str:		.byte	"This is a test",13,10,0


irq:
nmi:
		rti


		.segment "VECS"
		.addr	nmi
		.addr	reset
		.addr	irq

