	
		.eqv PICT_BUF_SIZE 2097152 #milion, docelowo ma byc 2 MB
 		.eqv READ_FLAG 0
		.eqv WRITE_FLAG 1
		.eqv PIXEL_MAP_OFFSET 138
		.eqv BLUE_COL 0x0
		.eqv RED_COL 0x0
		.eqv GREEN_COL 0x0
		
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
		#li $a2, 0
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
#należy podawać pełne ścieżki, inaczej nie wczyta		
input_file:	.asciiz "/home/erucolindo/Programy/Symulator MARS/gola_bitmapa_32bity.bmp"
output_file:	.asciiz "/home/erucolindo/Programy/Symulator MARS/testowy3.bmp"
		.align 2

read_descriptor:.word 0
write_descriptor:.word 0
picture_lenght:	.word 0
picture_buffer:	.space PICT_BUF_SIZE 
		.align 2
picture_height: .word 0		
picture_width:	.word 0
#stale we wzorach parabol
g:		.float 10
v0:		.float 1
H0:		.float 10				
alpha:		.float 0.5
gv02:		.float 9.81 #g/v0^2 - czesta stala we wzorach
x1:		.float 0 
const_0_5:	.float 0.5
max_x:		.float 100
max_y:		.float 15
kwant_x:	.float 0.05	
const_0:	.float 0		
		.text
		
		.globl main
main:
		#print_str(string)
		#wczytaj gola bitmape
		open_file_for_reading
		read_file
		close_file_for_reading
		#operacje na obrazku
		oblicz_szerokosc_i_wysokosc
		#rysowanie linii
		sw $s0, ($sp)
		subiu $sp, $sp, 4
		li $s0, 400 #ilosc iteracji
	petla:	li $a1,499
		move $a0, $s0
		jal rysuj_punkt
		subiu $s0, $s0, 1
		bne $s0, $zero, petla	
		
		addiu $sp,$sp, 4
		
		
		#zapisz gotowy obrazek
		open_file_for_writing
		save_file
		close_file_for_writing
		
		end_program
	
		
	#procedury		
					
Draw:				
		

		
	

#void rysujPolparabole()
rysuj_polparabole:	#prolog
			swc1 $f20, ($sp)#float x
			swc1 $f22, -4($sp)#float y
			swc1 $f24, -8($sp)#float 0
			swc1 $f26, -12($sp)#float kwant_x
			subiu $sp, $sp, 12
			#cialo fcji
			lwc1 $f26, kwant_x
			lwc1 $f24, const_0
			lwc1 $f22, H0 #y=H0
			mov.s $f20, $f24#x=0
	petla_while:	c.le.s $f22, $f24 #jesli y<=0	
			bc1t zapisz_x1#wyskocz z petli
			mov.s $f12, $f20
			jal oblicz_war_polparaboli#oblicz_war_polparaboli(x)
			mov.s $f22, $f12 #zapisz y
			
			mov.s $f12, $f20#
			jal przelicz_x	#przelicz_x(x)
			move $v0, $t0 #wspolrzedna x pikselu
			mov.s $f12, $f22
			jal przelicz_y #przelicz_y(y)
			move $v0, $t1 #wspolrzedna y pikselu
			lw $t7, picture_width #szserokosc obrazka
			bge $t7, $t0, zapisz_x1 #wyskocz z petli jest wspolrzedna x pikselu jest wieksza lub rowna szerokosci obrazka
			move $a0,$t0
			move $a1, $t1
			jal rysuj_punkt# void narysuj_punkt(int x, int y)
			add.s $f20, $f20, $f26 #zwieksz x o kwant
			j petla_while
	zapisz_x1:	swc1 $f20, x1#zapisz wartosc x, dla ktorej y sie zeruje lub jest ciutke mniejszy niz 0
			#epilog
			addiu $sp,$sp, 12
			lwc1 $f26, -12($sp)
			lwc1 $f24, -8($sp)
			lwc1 $f22, -4($sp)
			lwc1 $f20, ($sp)
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
#void rysuj_punkt(int x, int y)
rysuj_punkt:		la $t0, picture_buffer
			lw $t1, picture_height#wysokosc obrazka
			lw $t2, picture_width#szerokosc obrazka
			li $t4, BLUE_COL#wartosci skladowych koloru
			li $t5, GREEN_COL
			li $t6, RED_COL
			addiu $t0, $t0, PIXEL_MAP_OFFSET#adres poczatku tablicy pixeli
			move $t3, $zero #tu bdziemy liczyc adres piksela
			mul $t3, $t2, $a1 #width * y
			addu $t3, $t3, $a0 #width*y +x
			sll $t3, $t3, 2 #(width*y+x)*sizeof(Pixel)//czyli 4					
			#mul $t3, $t3, 3 #a tu gdy sizeof(Pixel)==3)
			addu $t3, $t3, $t0 #adres pierwszego bajtu w strukturze Pixel
			sb $t4, ($t3) # blue
			sb $t5, 1($t3)# green
			sb $t6, 2($t3)# red
			jr $ra 		 
	
	
	
	
		
	
	
	
