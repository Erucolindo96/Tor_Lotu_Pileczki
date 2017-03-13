	
		.eqv PICT_BUF_SIZE 1000000 #milion, docelowo ma byc 1 MB
 		.eqv READ_FLAG 0
		.eqv WRITE_FLAG 1
		
		
		.macro print_str (%str) # str - adres stringa
		la $a0, %str
		li $v0, 4
		syscall
		.end_macro
		
		.macro read_float(%destination_label)
		li $v0, 6
		syscall
		swc1 $f0,  %destination_label
		.end_macro 
		
		.macro print_float(%float_label)
		lwc1 $f12, %float_label
		li $v0, 2
		syscall
		.end_macro 
		
		.macro print_int(%int_reg)
		move $a0, %int_reg
		li $v0, 1
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
		
		
		#operacje na danych z obrazka
		.macro oblicz_szerokosc_i_wysokosc
		la $t0, picture_buffer
		addiu $t0,$t0, 14 #przeskakujemy file header
		addiu $t0,$t0, 4 # przeskakujemy do szerokosci
		lwr  $t1, ($t0) #laduj szerokosc
		sw $t1, picture_width
		addiu $t0,$t0, 4 #przeskakujemy do wysokosci
		lwr $t1, ($t0) #laduj wysokosc
		sw $t1, picture_height
		.end_macro 
		
		
		

		.data
string:		.asciiz "Wprowadz x"

input_file:	.asciiz "CO2_mascot-working.bmp"
output_file:	.asciiz "testowy.bmp"
		.align 2

read_descriptor:.word 0
write_descriptor:.word 0
picture_lenght:	.word 0
picture_buffer:	.space PICT_BUF_SIZE 
		.align 2
picture_height: .word 0		
picture_width:	.word 0
#stale we wzorach parabol
g:		.float 9.81
v0:		.float 1
H0:		.float 10				
alpha:		.float 0.5
gv02:		.float 9.81 #g/v0^2 - czesta stala we wzorach
x1:		.float 0 
const_0_5:	.float 0.5
max_x:		.float 100
max_y:		.float 15
kwant_x:	.float 0.05	
		.text
		
		.globl main
main:
		print_str(string)
		#wczytaj gola bitmape
		open_file_for_reading
		read_file
		close_file_for_reading
		#operacje na obrazku
		oblicz_szerokosc_i_wysokosc
		
		
		
		#zapisz gotowy obrazek
		open_file_for_writing
		save_file
		close_file_for_writing
		
		end_program
	
		
	#procedury		
					
Draw:				
		

		
	

		
rysuj_polparabole:		

		
	
	
	

#float obliczWartoscPolparaboli(float x)
oblicz_war_polparaboli:	 #x- rejestr f12
			lwc1 $f4, const_0_5
			lwc1 $f6, gv02
			lwc1 $f8, H0
			mul.s $f12, $f12, $f12 #x^2
			mul.s $f12, $f12, $f6#x^2 *g/v0
			mul.s $f12, $f12, $f4, #1/2 x^2*g/v0
			sub.s $f8, $f8, $f12 #h0- 1/2 x^2*g/v0
			mov.s $f0, $f8#zwroc wynik
			jr $ra#powrot
#int przeliczNaWspolrzednaX(float x) //+ dane globalne szerokosc i MAX_X
przelicz_x:		#x - f12
			lwc1 $f4, max_x
			lw $t7, picture_width
			c.le.s $f12, $f4 #jesli x > max_x
			bc1f za_duzo_x #zwroc picture_width
			mtc1 $t7, $f6 #width
			cvt.s.w $f6, $f6 #int konwertuje na floata
			mul.s $f12, $f12, $f6 #width *x
			div.s $f12, $f12, $f4#x*W/MAX_x
			cvt.w.s $f12, $f12 #float konwertuje na int
			mfc1 $v0, $f12 #zwroc obliczona wartosc
			jr $ra												
	za_duzo_x:	move $v0, $t7
			jr $ra
	
#int przeliczNaWspolrzednaY(float y)
przelicz_y:		# float y-f12
			lwc1 $f4, max_y
			lw $t7, picture_height
			c.le.s $f12, $f4#jesli y> max_y
			bc1f za_duzo_y#zwroc picture_height			
			mtc1 $t7, $f6 #height
			cvt.s.w $f6, $f6 #int konwertuje na float
			mul.s $f12, $f12, $f6 #height *y
			div.s $f12, $f12, $f4#y*H/max_y
			cvt.w.s $f12, $f12 #float konwertuje na int
			mfc1 $v0, $f12#zwroc obliczona wartosc
			jr $ra
	za_duzo_y:	move $v0, $t7
			jr $ra
	
	
	
	
	
	
		
	
	
	
