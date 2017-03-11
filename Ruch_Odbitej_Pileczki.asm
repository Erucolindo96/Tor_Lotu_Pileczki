		
		.eqv PICT_BUF_SIZE 1000000 #milion, docelowo ma byc 1 MB
 		.eqv READ_FLAG 0
		.eqv WRITE_FLAG 1
		
		.macro print_str (%str) # str - adres stringa
		la $a0, %str
		li $v0, 4
		syscall
		.end_macro
		
		.macro end_program 
		li $v0, 10
		syscall
		.end_macro
		
		#wejscie/wyjscie
		
		#czytanie z pliku
		.macro open_file_for_reading #zapisuje uchwyt w danej statycznej file_descriptor
		la $a0, input_file
		li $a1, READ_FLAG
		li $v0, 13
		syscall
		sw $v0, read_descriptor
		.end_macro
		
		.macro read_file #pobrane dane zapisuje w buforze "picture", ilosc pobranych bajtow w "picture_lenght"
		lw $a0, read_descriptor
		la $a1, picture_buffer
		li $a2, PICT_BUF_SIZE	
		li $v0, 14
		syscall 
		sw $v0, picture_lenght #zapisz ilosc pobranych bajtow
		.end_macro 
		
		.macro close_file_for_reading
		la $a0, read_descriptor
		li $v0, 16
		syscall
		.end_macro
		 
		 #zapisywanie do pliku
		.macro open_file_for_writing#tworzy nowy plik o nazwie output_file
		la $a0, output_file
		li $a1, WRITE_FLAG
		li $a2, 0 
		li $v0, 13
		syscall
		sw $v0, write_descriptor
		.end_macro 
		
		.macro save_file
		lw $a0, write_descriptor
		la $a1, picture_buffer
		lw $a2, picture_lenght
		li $v0, 15
		syscall
		.end_macro 
		
		.macro close_file_for_writing
		la $a0, write_descriptor
		li $v0, 16
		syscall
		.end_macro 
		
		
		
		

		.data
string:		.asciiz "No elo"
input_file:	.asciiz "obrazek2.jpg"
output_file:	.asciiz "testowy.jpg"
		.align 2
read_descriptor:.word 0
write_descriptor:.word 0

picture_lenght:	.word 0
picture_buffer:	.space PICT_BUF_SIZE 
		.align 2
						
		.text
		
		.globl main
main:
		print_str(string)
		
		open_file_for_reading
		read_file
		close_file_for_reading
		
		open_file_for_writing
		save_file
		close_file_for_writing
		
		end_program
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
		
	
	
	
