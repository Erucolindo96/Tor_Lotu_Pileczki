	
		.eqv PICT_BUF_SIZE 2097152 #milion, docelowo ma byc 2 MB
 		.eqv READ_FLAG 0
		.eqv WRITE_FLAG 1
		.eqv PIXEL_MAP_OFFSET 138
		.eqv BLUE_COL 0x0
		.eqv RED_COL 0x0
		.eqv GREEN_COL 0x0
		
		.eqv MIN_Y 0x00000FFF #najmniejsza mozliwa wartosc y,sprawdzana w fcjach rysujacych parabole
					#nie chcemy doprowadzić, by liczba w konwencji int_float była mnijsza od zera, bo cholera wie co sie stanie
		
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
		
		
		#makra wykorzystywane w obliczeniach i rysowaniu
		.macro iloczyn(%reg_1, %reg_2) #wynik w rejestrze_1 (UWAGA - muszą to być dwa różnie rejestry
		multu %reg_1, %reg_2
		mfhi %reg_2 #czesc calkowita
		mflo %reg_1 #mantysa
		srl %reg_1, %reg_1, 16 
		sll %reg_2, %reg_2, 16
		addu %reg_1, %reg_1, %reg_2
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
g:		.word 0x0009CD00 #9,81 (int_float)
v0:		.word 0x000A0000 #10(int_float)
H0:		.word 0x00FF0000#255(int_float)				
alpha:		.word 0x00008000#0,5(int_float)
gv02:		.word 0x00001900 #g/v0^2(int_float) - czesta stala we wzorach 
x1:		.word 0 
const_0_5:	.word 0x00008000
#max_x:		.word 0x
#max_y:		.float 15
kwant_x:	.word 0x000000FF	

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
		
		
		jal rysuj_polparabole
		
		#zapisz gotowy obrazek
		open_file_for_writing
		save_file
		close_file_for_writing
		
		end_program
	
		
	#procedury		
					
Draw:				
		

		
	
#opis działania:
#Liczby w postaci int_float
#Wyliczamy współrzędne punktu za pomoca tego formatu
#nastepne ucinamy czesc ułamkową - i dostajemy współrzędną piksela
#trzeba więc, aby poczatkowy y0 byl odpowiednio duzy
#void rysujPolparabole()
rysuj_polparabole:	
#wersja nowa(w stałym przecinku)
			#prolog
			sw $s0, ($sp)#int_float x
			sw $s1, -4($sp)#int_float y
			sw $s2, -8($sp)#int_float kwant_x
			sw $s3, -12($sp)#int_float MIN_Y
			sw $s4, -16($sp)#int Picture_height
			sw $s5, -20($sp)#int picture_width
			sw $ra, -24($sp)
			addiu $sp, $sp, -28
			#cialo fcji
			lw $s2, kwant_x
			lw $s1, H0 #y=H0
			li $s3, MIN_Y #potrzebne do sprawdzania, czy juz nie
			lw $s4, picture_height#potrzebne do sprawdzania, czy wartosc y jest w porzadku
			lw $s5, picture_width #potrzebna do sprawdzania, czy x nie jest wiekszy niz szerokosc
			move $s0, $zero#x=0
	petla_while:	ble $s1, $s3, zapisz_x1#jesli y<=MIIN_Y wyskocz z petli
			move $a0, $s0 #x - argument fcji
			
			jal oblicz_war_polparaboli#oblicz_war_polparaboli(x)
			
			move $s1, $v0 #zapisz y
			
			move $t0, $s0 
			srl $t0, $t0, 16 #konwersja x na wartosc piksela(int)
			move $t1, $s1
			srl $t1, $t1, 16 #konwersja y na wartosci piksela(int)
			
			bge $t0, $s5, zapisz_x1 #wyskocz z petli jest wspolrzedna x pikselu jest wieksza lub rowna szerokosci obrazka
			
			blt $t1, $s4, y_jest_dobry#jesli y jest dobry to kontynuujemy
			move $t1, $s4 #jesli nie, to ładujemy wysokosc obrazka
			addiu $t1, $t1, -1#i zmniejszamy o jeden - wtedy jest to najwieksza mozliwa wartosc y 
y_jest_dobry:		
			
			move $a0,$t0
			move $a1, $t1
			jal rysuj_punkt# void narysuj_punkt(int x, int y)
			
			add $s0, $s0, $s2 #zwieksz x o kwant
			b  petla_while
	zapisz_x1:	sw $s0, x1#zapisz wartosc x, dla ktorej y sie zeruje lub jest ciutke wiekszy niz 0
			#epilog
			addiu $sp,$sp, 28
			lw $ra, -24($sp)
			lw $s5, -20($sp)
			lw $s4, -16($sp)
			lw $s3, -12($sp)
			lw $s2, -8($sp)
			lw $s1, -4($sp)
			lw $s0, ($sp)
			jr $ra
			
#int_float obliczWartoscPolparaboli(int_float x)
oblicz_war_polparaboli:	 
			lw $t0, H0
			lw $t1, gv02
			lw $t2, const_0_5 
			move $t3, $a0
			iloczyn($t3, $a0) #x^2
			iloczyn($t3, $t1)#x^2 *g/v0
			iloczyn($t3, $t2) #1/2 x^2*g/v0
			sub $v0, $t0, $t3 #h0- 1/2 x^2*g/v0
			jr $ra#powrot


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
	
	
	
	
		
	
	
	
