## [IDsNPCModular] - Only items from the filler NPC pool
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

## THE GROUPING SUB-CONSTANT:
## As you said, it's the same jacket, but the color changes.
## This list allows us to group them logically so we can randomize them in a single line.
const JACKET_COLOR_GROUP = [
	Items.JACKET_1,
	Items.JACKET_2,
	Items.JACKET_3,
	Items.JACKET_4
]
