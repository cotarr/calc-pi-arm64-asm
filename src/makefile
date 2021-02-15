calc-pi: main.o iomodule.o
	ld -o calc-pi main.o iomodule.o -M=calc-pi.map
main.o: main.s arch.inc header.inc
	as -g -o main.o main.s -a=main.lst
iomodule.o: iomodule.s arch.inc header.inc
	as -g -o iomodule.o iomodule.s -a=test.lst
clean:
	rm -v calc-pi *.o *.lst *.map
	echo Clean done
