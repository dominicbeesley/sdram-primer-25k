
HW_DEBUG		:=	$E000		; 2xLED 7 segment display



		.code

reset:		sei
		cld
		ldx	#$FF
		txs

		lda	#0
		tay
@lp2:		ldx	#200
@lp:		dey
		bne	@lp
		dex	
		bne	@lp
		clc
		adc	#1
		sta	HW_DEBUG
		jmp	@lp2



irq:
nmi:
		rti


		.segment "VECS"
		.addr	nmi
		.addr	reset
		.addr	irq

