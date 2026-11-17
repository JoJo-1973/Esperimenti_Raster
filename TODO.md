# TODO - Esperimenti Raster

Versione attuale: nessuna (raccolta di esperimenti sul raster del VIC-II).

## In corso

## Da fare

- [stile] Adeguare lo stile di tutti i programmi: `esperimento_01.asm` … `esperimento_05.asm` e `ready64_01.asm` … `ready64_06.asm` (intestazioni, contratti, commenti), un file alla volta.
- [stile] Usare `__DISABLE_KERNAL` al posto di `__KERNAL_STATUS` in `esperimento_01.asm` … `esperimento_04.asm`.
- [idea] Riscrivere `esperimento_05.asm` in modo che utilizzi il modulo `raster_tools.asm`.
- [da verificare] Il file di progetto `Esperimenti_Raster.c64` porta ancora al suo interno il nome `Raster_Experiments` e non fa riferimento ai gruppi di libreria `io` e `math`: controllarlo in C64Studio.

## Fatto

- 2026-11-17 Resi compilabili tutti i programmi (`ready64_01.asm` … `ready64_06.asm`, `esperimento_01.asm` … `esperimento_05.asm`): nomi delle macro con il prefisso `m_`, inclusione del proprio `config_<programma>.asm`, `BASIC_START` e `*= BASIC_START`; in `esperimento_05.asm` `UNUSED` sostituito da `UNUSE2` (locazione in RAM, 6 cicli).
- 2026-11-17 Creati i file di configurazione `config_esperimento_01.asm` … `config_esperimento_05.asm` e `config_ready64_01.asm` … `config_ready64_06.asm`, copie del template con `__DISABLE_KERNAL = 1` per `esperimento_02.asm` ed `esperimento_03.asm` (P422).
- 2026-11-17 Aggiornati i percorsi delle librerie in `esperimento_01.asm` … `esperimento_05.asm` (`6510_tools` e `raster_tools` ora in `chip/`; gruppo di libreria davanti ai file di `esperimento_05.asm`).
- 2026-11-17 Cartella rinominata da `Raster_Experiments` a `Esperimenti_Raster`; aggiunti `.gitattributes`, `.gitignore` e questo file.
