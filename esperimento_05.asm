; ESPERIMENTO DI RASTER #5: Crea uno schermo in modalità ECM ed usa un raster stabile per evidenziare la linea #13 cambiando la palette di colori

; PROVA TEMPORANEA: once sospeso (LIB-01).
!source "config_esperimento_05.asm"

!source <c64/symbols.asm>
!source <c64/kernal.asm>
!source <chip/vic_ii.asm>
!source <chip/cia.asm>
!source <system/standard.asm>

BASIC_START         = BASTXT

*= BASIC_START
+m_BASIC_Preamble 10,START,"ESPERIMENTO DI RASTER #5"

PTR     = ZP_1

RASTER_LINE = 51+12*8-1         ; Il cambio di colore deve avvenire in corrispondenza della 13 riga dello schermo (linea 146)

START:
  lda SCROLY                    ; Abilita ECM
  ora #%01000000
  sta SCROLY

  lda #<VICSCN
  sta PTR
  lda #>VICSCN
  sta PTR+1

  lda #VIC_PURPLE               ; Colore del bordo
  sta EXTCOL

  lda #VIC_YELLOW               ; Colore dell'area messaggi
  sta BGCOL0

  lda #VIC_BLACK                ; Colore dell'area etichette
  sta BGCOL1

  lda #VIC_BLUE                 ; Colore dell'area opcode
  sta BGCOL2

  lda #VIC_GREEN                ; Colore dell'area operandi
  sta BGCOL3

  lda #VIC_WHITE                ; Colore dei caratteri
  sta COLOR

  jsr CLRSCR

  ldx #23

.LoopScreen:
  ldy #$00                      ; Indice alla colonna

.LoopRow:
  lda #(32 or %01000000)        ; Carattere dell'area etichette
  cpy #8
  bcc .PlotField

  lda #(32 or %10000000)        ; Carattere dell'area opcode
  cpy #13
  bcc .PlotField

  lda #(32 or %11000000)        ; Carattere dell'area operandi

.PlotField:
  sta (PTR),y
  iny
  cpy #40
  bcc .LoopRow

  tya
  clc
  adc PTR
  sta PTR
  bcc .NextRow
  inc PTR+1

.NextRow:
  dex
  bne .LoopScreen

.SetIRQ:
  sei
  lda #<.IRQ_1
  sta CINV
  lda #>.IRQ_1
  sta CINV+1

  lda #%00000001
  sta CIAICR
  lda #(RASTER_LINE-3)
  sta RASTER
  lda SCROLY
  and #%01111111
  sta SCROLY
  lda #%00000001
  sta IRQMSK
  cli

.Idle:
  jsr GETIN
  beq .Idle

  rts

.IRQ_1:                         ; Linea 143   cicli 38-44
  lda #<.IRQ_2                  ; Linea 143   cicli 40-46
  sta CINV                      ; Linea 143   cicli 44-50
  lda #>.IRQ_2                  ; Linea 143   cicli 46-52
  sta CINV+1                    ; Linea 143   cicli 50-56
  lda #(RASTER_LINE-1)          ; Linea 143   cicli 52-58
  sta RASTER                    ; Linea 143   cicli 56-62
  inc VICIRQ                    ; Linea 143   cicli 62-68 - Il raster potrebbe gia' essere sulla linea video 144 (per questo e' settato l'IRQ alla linea 145)

  cli                           ; Linea 144   cicli 1-7 (riattiva la modalita' IRQ)
  inc UNUSE2                    ; Linea 144   cicli 7-13
  dec UNUSE2                    ; Linea 144   cicli 13-19
  inc UNUSE2                    ; Linea 144   cicli 19-25
  dec UNUSE2                    ; Linea 144   cicli 25-31
  inc UNUSE2                    ; Linea 144   cicli 31-37
  dec UNUSE2                    ; Linea 144   cicli 37-43
  inc UNUSE2                    ; Linea 144   cicli 43-49
  dec UNUSE2                    ; Linea 144   cicli 49-55
  inc UNUSE2                    ; Linea 144   cicli 55-61
  nop                           ; Linea 144   cicli 57-63
  nop                           ;  - Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;  - Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;  - Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;  - Possibile IRQ (il passaggio ad .IRQ_2 avverrà dopo 2+7+29=38 cicli oppure dopo 1+2+7+29=39 cicli)
  nop                           ;  "nop" di margine

  jmp IRQHND                    ;  Permette al C64 le operazioni di routine

.IRQ_2:                         ; Quando si arriva qui si sa per certo che sono passati 38 oppure 39 cicli dall'inizio della linea video 145
  ldy #VIC_BLACK                ; Linea 145   cicli 40-41
  sty COLOR                     ; Linea 145   cicli 44-45
  ldy #VIC_LIGHT_GREY           ; Linea 145   cicli 46-47
  sty BGCOL1                    ; Linea 145   cicli 50-51
  dey                           ; Linea 145   cicli 52-53
  sty BGCOL2                    ; Linea 145   cicli 56-57
  dey                           ; Linea 145   cicli 58-59
  sty BGCOL3                    ; Linea 145   cicli 62-63

  sei
  lda #<.IRQ_3
  sta CINV
  lda #>.IRQ_3
  sta CINV+1
  lda #(RASTER_LINE+8)
  sta RASTER
  inc VICIRQ
  cli
  jmp IRQMIN

.IRQ_3:
  ldy #VIC_WHITE
  sty COLOR
  ldy #VIC_BLACK
  sty BGCOL1
  ldy #VIC_BLUE
  sty BGCOL2
  ldy #VIC_GREEN
  sty BGCOL3

.Ret:
  sei
  lda #<.IRQ_1                  ; Ripristina il primo gestore delle interruzioni
  sta CINV
  lda #>.IRQ_1
  sta CINV+1
  lda #(RASTER_LINE-3)          ; Ripristina la linea video di attivazione del primo gestore delle interruzioni
  sta RASTER
  inc VICIRQ                    ; Permette le interruzioni successive
  cli
  jmp IRQMIN                    ; e termina il gestore di interruzioni ripristinando i registri dallo stack
