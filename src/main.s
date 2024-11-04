
;----------------------------------------------------------------------
;			includes cc65
;----------------------------------------------------------------------
.feature string_escapes

.include "telestrat.inc"
.include "fcntl.inc"

;----------------------------------------------------------------------
;			includes SDK
;----------------------------------------------------------------------
.include "SDK.mac"
.include "types.mac"

;----------------------------------------------------------------------
;			include application
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;				imports
;----------------------------------------------------------------------
.import sopt1
.import spar1
.importzp cbp

;----------------------------------------------------------------------
;				exports
;----------------------------------------------------------------------
.export _main

;----------------------------------------------------------------------
;                       Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;			Defines / Constantes
;----------------------------------------------------------------------
VERSION = $20244001
.define PROGNAME "datetime"

typedef .struct ds1501
	.res	$0360

	unsigned char seconds
	unsigned char minutes
	unsigned char hour
	unsigned char day
	unsigned char date
	unsigned char month
	unsigned char year
	unsigned char century

	unsigned char alarm_seconds
	unsigned char alarm_minutes
	unsigned char alarm_hour
	unsigned char alarm_day

	unsigned char wd_ms
	unsigned char wd_s

	unsigned char control_a
	unsigned char control_b

	unsigned char ram_ptr
	unsigned char rsv11
	unsigned char rsv12
	unsigned char ram_data

	unsigned char rsv1x[12]
.endstruct

;----------------------------------------------------------------------
;				Page zéro
;----------------------------------------------------------------------
.pushseg
	.segment "ZEROPAGE"
		unsigned short t1
		unsigned short t2
		unsigned short t3

.popseg

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.pushseg
	.segment "DATA"
		unsigned short _argv
		unsigned char _argc
		unsigned short argn

		unsigned char buffer[128]

.popseg

;----------------------------------------------------------------------
;			Chaines statiques
;----------------------------------------------------------------------
.pushseg
	.segment "RODATA"
		no_ds1501_msg:
			.asciiz "ds1501 not found\r\n"

		month_tbl:
			.byte "Jan."		; 0
			.byte "Feb."		; 4
			.byte "Mar."		; 8
			.byte "Apr."		; 12
			.byte "May."		; 16
			.byte "Jui."		; 20
			.byte "Jul."		; 24
			.byte "Aug."		; 28
			.byte "Sep."		; 32
			.byte "Oct."		; 36
			.byte "Nov."		; 40
			.byte "Dec."		; 44

		error_msg:
			.asciiz "bad argument\r\n"

		help_msg:
			.byte $0a, $0d
			.byte $1b,"C         Date-time utility\r\n\n"
			.byte " ",$1b,"TSyntax:",$1b,"P\r\n"
			.byte "    datetime\r\n"
			.byte "              Display date and time\r\n\r\n"
			.byte "    datetime",$1b,"B-h",$1b,"G\r\n"
			.byte "              Display this help\r\n\r\n"
			.byte "    datetime",$1b,"B-t",$1b,"Ahh,mm,ss\r\n"
			.byte "              Set time\r\n\r\n"
			.byte "    datetime",$1b,"B-d",$1b,"Add,mm,yyyy\r\n"
			.byte "              Set date\r\n"
			.byte "\r\n"
			.byte $00

.popseg

;----------------------------------------------------------------------
;			Programme principal
;----------------------------------------------------------------------
.segment "CODE"



;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc _main
		lda	ds1501::date
		cmp	ds1501::date
		beq	get_args

		print	no_ds1501_msg
		rts

	get_args:
		; Transfert enable
		lda	ds1501::control_b
		ora	#$80
		sta	ds1501::control_b

		; Recupère l'adresse de la ligne de commande
		initmainargs _argv, _argc, 1

		; Pointe vers le premier paramètre
		clc
		adc	#.strlen("datetime")
		tay
		lda	_argv+1
		adc	#$00

		jsr	sopt1
		.asciiz "DTH"
		bcs	error

		cpx	#$00
		bne	main

		; Pas d'argument, affiche la date et l'heure actuelle

		jsr	get_date
		crlf
		jsr	get_time
		crlf

		mfree	(_argv)

		rts

	main:
		cpx	#$80
		bne	time
		jsr	set_date
		jmp	end

	time:
		cpx	#$40
		bne	help
		jsr	set_time
		jmp	end

	help:
		; jsr	cmnd_version
		print	help_msg

	end:
		mfree	(_argv)
		rts

	error:
		print	error_msg
		mfree	(_argv)
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_date
		; Initialise le buffer de sortie
		ldy	#12
		lda	#' '
	loop:
		sta	buffer,y
		dey
		bpl	loop

		; Insère la date dans le buffer
		lda	ds1501::date
		jsr	bcd2str
		stx	buffer
		sta	buffer+1

		lda	ds1501::month
		cmp	#$10
		bcc	*+4
		sbc	#06

		asl
		asl
		tax
		ldy	#$06
	loop_month:
		lda	month_tbl-1,x
		sta	buffer,y
		dex
		dey
		cpy	#$02
		bne	loop_month

	;	jsr	bcd2str
	;	stx	buffer+3
	;	sta	buffer+4

		lda	ds1501::century
		jsr	bcd2str
		stx	buffer+6+2
		sta	buffer+7+2

		lda	ds1501::year
		jsr	bcd2str
		stx	buffer+8+2
		sta	buffer+9+2

		; Ajoute le nul terminal
		lda	#$00
		sta	buffer+10+2

		; Affiche le buffer
		;lda	stdout
		;ldy	stdout+1
		print	buffer

		clc
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc get_time
		; Initialise le buffer de sortie
		ldy	#8
		lda	#':'
	loop:
		sta	buffer,y
		dey
		bpl	loop

		; Insère l'heure dans le buffer
		lda	ds1501::hour
		jsr	bcd2str
		stx	buffer
		sta	buffer+1

		lda	ds1501::minutes
		jsr	bcd2str
		stx	buffer+3
		sta	buffer+4

		lda	ds1501::seconds
		jsr	bcd2str
		stx	buffer+6
		sta	buffer+7

		; Ajoute le nul terminal
		lda	#$00
		sta	buffer+8

		; Affiche le buffer
		;lda	stdout
		;ldy	stdout+1
		print	buffer

		clc
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	- AY: adresse paramètre (A=MSB)
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc set_date

		ldx	#$00
		jsr	spar1
		.byte	t1,t2,t3,0

		lda	t1
		sta	ds1501::date
		lda	t2
		sta	ds1501::month
		lda	t3
		sta	ds1501::year
		lda	t3+1
		sta	ds1501::century

		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	- AY: adresse paramètre (A=MSB)
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc set_time

		ldx	#$00
		jsr	spar1
		.byte	t1,t2,t3,0

		lda	t1
		sta	ds1501::hour
		lda	t2
		sta	ds1501::minutes
		lda	t3
		sta	ds1501::seconds

		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc cmnd_version
		.out   .sprintf("%s version %x.%x - %x.%x", PROGNAME, (::VERSION & $ff0)>>4, (::VERSION & $0f), ::VERSION >> 16, (::VERSION & $f000)>>12)

		prints	.sprintf("%s version %x.%x - %x.%x", PROGNAME, (::VERSION & $ff0)>>4, (::VERSION & $0f), ::VERSION >> 16, (::VERSION & $f000)>>12)
		crlf

		rts
.endproc


;----------------------------------------------------------------------
;	Conversion d'une valeur BCD <= en ASCII
;----------------------------------------------------------------------
;
; Entrée:
;       - A: valeur BCD
;
; Sortie:
;	- A: unités
;	- X: dizaines
;
; Variables:
;       Modifiées:
;               -
;
;       Utilisées:
;               -
;
; Sous-routines:
;       -
;----------------------------------------------------------------------
.proc bcd2str
		cmp	#99+1
		bcc	conv
		rts

	conv:
		pha
		lsr
		lsr
		lsr
		lsr
		ora	#'0'
		tax

		pla
		and	#$0f
		ora	#'0'

		clc
		rts
.endproc
