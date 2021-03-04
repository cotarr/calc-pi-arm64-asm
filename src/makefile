calc-pi: main.o math.o calc.o parser.o iomodule.o help.o util.o address.o practice.o
	ld -o calc-pi main.o math.o calc.o parser.o iomodule.o help.o util.o address.o practice.o -M=calc-pi.map
main.o: main.s arch-include.s header-include.s
	as -g -o main.o main.s -a=main.lst
math.o: math.s math-subr.s math-output.s math-input.s math-mult.s math-div.s\
	math-rotate.s math-debug.s arch-include.s header-include.s
	as -g -o math.o math.s -a=math.lst
calc.o: calc.s calc-e.s arch-include.s header-include.s
	as -g -o calc.o calc.s -a=calc.lst
parser.o: parser.s arch-include.s header-include.s
	as -g -o parser.o parser.s -a=parser.lst
iomodule.o: iomodule.s arch-include.s header-include.s
	as -g -o iomodule.o iomodule.s -a=iomodule.lst
help.o: help.s arch-include.s header-include.s
	as -g -o help.o help.s -a=help.lst
util.o: util.s arch-include.s header-include.s
	as -g -o util.o util.s -a=util.lst
address.o: address.s arch-include.s header-include.s
	as -g -o address.o address.s -a=address.lst
practice.o: practice.s arch-include.s header-include.s
	as -g -o practice.o practice.s -a=practice.lst

clean:
	rm -v calc-pi *.o *.lst *.map
	echo Clean done
