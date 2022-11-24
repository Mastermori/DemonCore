# SimVision Command Script (Wed Apr 13 10:16:19 CEST 2005)

#
# mmaps
#
mmap new -reuse -name light3 -contents {
{%b=100 -bgcolor #ff0000 -font -*-courier-medium-r-normal--12-* -label R -linecolor #000000 -shape bus -textcolor #000000}
{%b=010 -bgcolor #ffff00 -font -*-courier-medium-r-normal--12-* -label Y -linecolor #000000 -shape bus -textcolor #000000}
{%b=001 -bgcolor #00ff00 -font -*-courier-medium-r-normal--12-* -label G -linecolor #000000 -shape bus -textcolor #000000}
{%b=110 -bgcolor #ff7f00 -font -*-courier-medium-r-normal--12-* -label RY -linecolor #000000 -shape bus -textcolor #000000}
{%b=* -font -*-courier-medium-r-normal--12-* -label %x -shape bus}
}
mmap new -reuse -name light2 -contents {
{%b=10 -bgcolor #ff0000 -font -*-courier-medium-r-normal--12-* -label r -linecolor #000000 -shape bus -textcolor #000000}
{%b=01 -bgcolor #00ff00 -font -*-courier-medium-r-normal--12-* -label g -linecolor #000000 -shape bus -textcolor #000000}
{%b=* -font -*-courier-medium-r-normal--12-* -label %x -shape bus}
}
