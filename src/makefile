calc-pi: main.o math.o parser.o iomodule.o util.o practice.o
	ld -o calc-pi main.o math.o parser.o iomodule.o util.o practice.o -M=calc-pi.map
main.o: main.s arch-include.s header-include.s
	as -g -o main.o main.s -a=main.lst
math.o: math.s arch-include.s header-include.s
	as -g -o math.o math.s -a=math.lst
parser.o: parser.s arch-include.s header-include.s
	as -g -o parser.o parser.s -a=parser.lst
iomodule.o: iomodule.s arch-include.s header-include.s
	as -g -o iomodule.o iomodule.s -a=iomodule.lst
util.o: util.s arch-include.s header-include.s
	as -g -o util.o util.s -a=util.lst
practice.o: practice.s arch-include.s header-include.s
	as -g -o practice.o practice.s -a=practice.lst


clean:
	rm -v calc-pi *.o *.lst *.map
	echo Clean done
