all: rom180

rom180:	rom180.o
	ldz80 -b rom180.o -o rom180.bin
	dd if=rom180.bin of=rom180 bs=8192 count=1 conv=sync

rom180.o: rom180.s
	asz80 rom180.s -l rom180.lst

clean:
	rm *.o *.bin *.lst *~
