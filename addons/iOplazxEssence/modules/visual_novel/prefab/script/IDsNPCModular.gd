## [IDsNPCModular] - Solo cosas del pool de NPCs de relleno
class_name IDsNPCModular
extends RefCounted

enum Poses { STAND = 1 }

enum Items {
	MUSTACHE    = 500,
	JACKET_1    = 1001,
	JACKET_2    = 1002,
	JACKET_3    = 1003,
	JACKET_4    = 1004
}

## LA SUB-CONSTANTE DE AGRUPACIÓN:
## Tal como dijiste, es la misma chamarra pero cambia el color.
## Esta lista nos permite agruparlas lógicamente para aleatorizarlas en una sola línea.
const JACKET_COLOR_GROUP = [
	Items.JACKET_1,
	Items.JACKET_2,
	Items.JACKET_3,
	Items.JACKET_4
]
