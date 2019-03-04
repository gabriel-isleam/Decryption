;ISLEAM GABRIEL-MIHAI -> 325CB

extern puts
extern printf
extern strlen

%define BAD_ARG_EXIT_CODE -1

section .data
filename: db "./input0.dat", 0
inputlen: dd 2263

fmtstr:            db "Key: %d",0xa, 0
usage:             db "Usage: %s <task-no> (task-no can be 1,2,3,4,5,6)", 10, 0
error_no_file:     db "Error: No input file %s", 10, 0
error_cannot_read: db "Error: Cannot read input file %s", 10, 0

section .text
global main

xor_strings:
        xor eax, eax
        xor ebx, ebx
        lea edi, [ecx]                      ;starting position of the string is saved
        
length:
        inc ecx
        cmp byte[ecx], 0x00                 ;looking for string terminator
        jne length
        
create_key:
        inc ecx
        lea edx, [ecx]                      ;starting adress of the key is saved
        lea ecx, [edi]                      ;ecx is set to the initial postition of the string
        
xor_todo:        
        mov al, byte [ecx]                  ;it takes one byte from the string and one from the key
        mov bl, byte [edx]
        xor al, bl                          ;it performs xor operation between the two bytes
        mov byte[ecx], al                   ;it puts the modified byte back in the string
        inc edx
        inc ecx
        cmp byte[ecx], 0x00
        jne xor_todo
        
final:
        lea ecx, [edi]
        ret

rolling_xor:
        lea edi, [ecx]                      ;starting position of the string is saved
        mov al, byte[ecx]                   ;first byte of the string is saved
        
roll:
        mov dl, al                          ;a copy of the current crypted byte
        mov bl, byte[ecx + 1]               ;the following crypyted byte is saved
        xor dl, bl                          ;it performs xor operation between previous encrypted byte and the current encrypted byte
        mov al, bl                          
        mov byte [ecx + 1], dl              ;it puts the decrypted byte back in the string
        inc ecx                             ;it goes to the next byte
        cmp byte[ecx + 1], 0x00
        jne roll
        
        lea ecx, [edi]
        ret

bruteforce_singlebyte_xor:
        xor ebx, ebx
        mov eax, 0                          ;first value for the key byte
        lea edi, [ecx]                      ;starting position of the string is saved

string_restore_before_decryption:
        lea ecx, [edi]

decryption:
        mov bl, byte[ecx]                   ;it is extracted one byte from the string
        xor bl, al                          ;it is performed the xor operation between extracted byte and the key byte
        mov byte[ecx], bl                   ;modified byte is introduced back in the string
        inc ecx                             ;it goes to the next byte from the string
        cmp byte[ecx], 0x00
        jne decryption

string_restore:
        lea ecx, [edi]
        dec ecx
        
key_check:
        inc ecx
        cmp byte[ecx], 0x00                 ;if it reaches the string terminator, it means that it didnt't find the right decryption key
        je restore_initial_string
        cmp byte[ecx], 'f'                  ;it checks for letter "f" in the decrypted string
        je next_check                       ;if yes, it continues checking for the other letters
        jne key_check                       ;on the following positions
        
next_check:
        cmp byte[ecx + 1], 'o'
        jne key_check
        cmp byte[ecx + 2], 'r'
        jne key_check
        cmp byte[ecx + 3], 'c'
        jne key_check
        cmp byte[ecx + 4], 'e'
        jne key_check
        jmp key_found
        
restore_initial_string:
        lea ecx, [edi]
        
restoring:
        mov bl, byte[ecx]                   ;in the case of not finding the key, it is applied the same
        xor bl, al                          ;algorithm used for decryption to get back to the initial
        mov byte[ecx], bl                   ;crypted string
        inc ecx
        cmp byte[ecx], 0x00
        jne restoring
        inc eax                             ;key byte value is incremented
        cmp eax, 255                        ;it can take values between 0 and 255
        jle string_restore_before_decryption
        
key_found:
        lea ecx, [edi]
        ret

decode_vigenere:
        lea edi, [ecx]                      ;starting point of the string is saved 
        lea esi, [eax]                      ;starting position of the key is saved
        xor ebx, ebx
        xor edx, edx
        dec ecx
        dec eax
        jmp increase_key

key_restore:
        lea eax, [esi - 1]

increase_key:
        inc eax                             
        cmp byte[eax], 0x00                 ;in the case of reaching the string terminator for the key
        je key_restore                      ;it goes back to the starting point
        
increase_string:
        inc ecx
        cmp byte[ecx], 0x00                 ;if it reaches the string terminator, decryption is over
        je final_vigenere
        cmp byte[ecx], 'a'                  ;if the current character is not between 'a' and 'z'
        jl increase_string                  ; it will not be modified
        cmp byte[ecx], 'z'
        jg increase_string
        mov bl, byte[ecx]
        mov dl, byte[eax]                   ;it takes the current byte from the key
        sub dl, 'a'                         ;it finds out the relative position towards 'a'
        sub bl, dl                          ;it is performed a left rotation for decryption;
        cmp bl, 'a'                         ;in the case of obtaining an out-of-range ('a' - 'z' range) result, 
        jge increase_string_final           ;it is added 26 to obtain the suitable letter
        add bl, 26                          ;from this range
        
increase_string_final:
        mov byte[ecx], bl                   ;the modified byte is introduced back in the string 
        jmp increase_key
                        
final_vigenere:
        lea ecx, [edi]                
        ret

main:
    mov ebp, esp; for correct debugging
	push ebp
	mov ebp, esp
	sub esp, 2300

	; test argc
	mov eax, [ebp + 8]
	cmp eax, 2
	jne exit_bad_arg

	; get task no
	mov ebx, [ebp + 12]
	mov eax, [ebx + 4]
	xor ebx, ebx
	mov bl, [eax]
	sub ebx, '0'
	push ebx

	; verify if task no is in range
	cmp ebx, 1
	jb exit_bad_arg
	cmp ebx, 6
	ja exit_bad_arg

	; create the filename
	lea ecx, [filename + 7]
	add bl, '0'
	mov byte [ecx], bl

	; fd = open("./input{i}.dat", O_RDONLY):
	mov eax, 5
	mov ebx, filename
	xor ecx, ecx
	xor edx, edx
	int 0x80
	cmp eax, 0
	jl exit_no_input

	; read(fd, ebp - 2300, inputlen):
	mov ebx, eax
	mov eax, 3
	lea ecx, [ebp-2300]
	mov edx, [inputlen]
	int 0x80
	cmp eax, 0
	jl exit_cannot_read

	; close(fd):
	mov eax, 6
	int 0x80

	; all input{i}.dat contents are now in ecx (address on stack)
	pop eax
	cmp eax, 1
	je task1
	cmp eax, 2
	je task2
	cmp eax, 3
	je task3
	cmp eax, 4
	je task4
	cmp eax, 5
	je task5
	cmp eax, 6
	je task6
	jmp task_done

task1:
	; TASK 1: Simple XOR between two byte streams

        call xor_strings

        push ecx
        call puts                   		;print resulting string
        add esp, 4

	jmp task_done

task2:
	; TASK 2: Rolling XOR

        xor eax, eax
        
        call rolling_xor
        lea ecx, [edi]
        push ecx
        call puts
        add esp, 4

	jmp task_done

task5:
	; TASK 5: Find the single-byte key used in a XOR encoding

        call bruteforce_singlebyte_xor

        mov ebx, eax
        
        push ecx                    		;print resulting string
        call puts
        pop ecx

        mov eax, ebx
        push eax                    		;eax = key value
        push fmtstr
        call printf                 		;print key value
        add esp, 8

	jmp task_done

task6:
	; TASK 6: decode Vignere cipher

	push ecx
	call strlen
	pop ecx

	add eax, ecx
	inc eax
        
	;push eax
	;push ecx                   			;ecx = address of input string 
	call decode_vigenere
	;pop ecx
	;add esp, 4

	push ecx
	call puts
	add esp, 4

task_done:

	xor eax, eax
	jmp exit

exit_bad_arg:

	mov ebx, [ebp + 12]
	mov ecx , [ebx]
	push ecx
	push usage
	call printf
	add esp, 8
	jmp exit

exit_no_input:

	push filename
	push error_no_file
	call printf
	add esp, 8
	jmp exit

exit_cannot_read:

	push filename
	push error_cannot_read
	call printf
	add esp, 8
	jmp exit
        

exit:

	mov esp, ebp
	pop ebp
	ret
