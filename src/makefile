calc-pi: main.o parser.o iomodule.o util.o
	ld -o calc-pi main.o parser.o iomodule.o util.o -M=calc-pi.map
main.o: main.s arch.inc header.inc
	as -g -o main.o main.s -a=main.lst
parser.o: parser.s arch.inc header.inc
	as -g -o parser.o parser.s -a=parser.lst
iomodule.o: iomodule.s arch.inc header.inc
	as -g -o iomodule.o iomodule.s -a=iomodule.lst
util.o: util.s arch.inc header.inc
	as -g -o util.o util.s -a=util.lst

clean:
	rm -v calc-pi *.o *.lst *.map
	echo Clean done
