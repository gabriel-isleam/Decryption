tema2: decryption.asm
	nasm -f elf32 -o decryption.o $<
	gcc -m32 -o $@ decryption.o

clean:
	rm -f decryption decryption.o
