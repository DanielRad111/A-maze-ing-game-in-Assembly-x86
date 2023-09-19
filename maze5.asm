.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "A-maze-ing game",0
area_width EQU 700
area_height EQU 500
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

ok DD 0
k DD 0

cell_size EQU 50
table_size_horizontal EQU 650
table_size_vertical EQU 500

poz_anterioara_x DD 100
poz_anterioara_y DD 50

matrice dd 1, 2, 0, 1, 2, 1, 2, 1 
		dd 1, 0, 0, 2, 0, 2, 0, 1
		dd 1, 2, 0, 0, 0, 0, 0, 1
		dd 1, 0, 1, 2, 2, 2, 0, 1
		dd 2, 0, 0, 0, 0, 0, 0, 1 
		dd 2, 0, 2, 2, 1, 1, 2, 1
		dd 1, 0, 0, 0, 0, 0, 0, 0
		dd 1, 1, 1, 2, 1, 2, 1, 1
		 
		

coordonate_x dd 0, 50, 100, 150, 200, 250, 300, 350

coordonate_y dd 50, 100, 150, 200, 250, 300, 350, 400

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm
line_horizontal macro x, y, len, color
local bucla_linie
	mov eax, y ; eax = y
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, x ; eax = y * area_width + x
	shl eax, 2 ; eax = (y * area_width + x) * 4
	add eax, area
	mov ecx, len
bucla_linie:
	mov dword ptr[eax], color
	add eax, 4
	loop bucla_linie
endm

line_vertical macro x, y, len, color
local bucla_linie
	mov eax, y ; eax = y
	mov ebx, area_width
	mul ebx ; eax = y * area_width
	add eax, x ; eax = y * area_width + x
	shl eax, 2 ; eax = (y * area_width + x) * 4
	add eax, area
	mov ecx, len
bucla_linie:
	mov dword ptr[eax], color
	add eax, area_width * 4
	loop bucla_linie
endm


deseneaza_patrat macro x, y, len, color
local bucla
	xor edx, edx
	mov edx, 0
	mov ecx, 50
bucla:
	mov edx, y
	add edx, ecx
	push ecx
	
	line_horizontal x, edx, len, color
	pop ecx
	mov edx, 0
	loop bucla
endm

lava macro x, y, z, t
local failed
	cmp x, z
	jne failed
	cmp y, t
	jne failed
	mov poz_anterioara_x, 100
	mov poz_anterioara_y, 50
	deseneaza_patrat poz_anterioara_x, poz_anterioara_y, 50, 0FF0000h
	failed:
endm

perete macro x, y, z, t, a, b
local gasit
	cmp x, z
	jne gasit
	cmp y, t
	jne gasit
	mov poz_anterioara_x, a
	mov poz_anterioara_y, b
	; deseneaza_patrat poz_anterioara_x, poz_anterioara_y, 50, 0FF0000h
gasit:
	deseneaza_patrat poz_anterioara_x, poz_anterioara_y, 50, 0FF0000h
endm

verificare macro x, y
local scrieA
local scrieS
local scrieD
local press_fail
local next
local sfarsit
local failed
	cmp k, 0
	jne failed
	mov eax, [ebp+arg2]
	cmp eax, 'W'
	jne scrieA
	deseneaza_patrat x, y, 50, 0FFFFFFh
	sub y, 50
	deseneaza_patrat x, y, 50, 0FF0000h
	jmp sfarsit
	
	scrieA:
	cmp eax, 'A'
	jne scrieS
	deseneaza_patrat x, y, 50, 0FFFFFFh
	sub x, 50
	deseneaza_patrat x, y, 50, 0FF0000h
	jmp sfarsit
	
	scrieS:
	cmp eax, 'S'
	jne scrieD
	deseneaza_patrat x, y, 50, 0FFFFFFh
	add y, 50
	deseneaza_patrat x, y, 50, 0FF0000h
	jmp sfarsit
	
	
	scrieD:
	cmp eax, 'D'
	jne press_fail
	deseneaza_patrat x, y, 50, 0FFFFFFh
	add x, 50
	deseneaza_patrat x, y, 50, 0FF0000h
	jmp sfarsit
	
	press_fail:
	make_text_macro ' ', area, 1, 1
	jmp sfarsit
	
	sfarsit:

	cmp x, 350
	jne failed
	cmp y, 350
	jne failed
	make_text_macro 'F', area, 500, 200
	make_text_macro 'E', area, 510, 200
	make_text_macro 'L', area, 520, 200
	make_text_macro 'I', area, 530, 200
	make_text_macro 'C', area, 540, 200
	make_text_macro 'I', area, 550, 200
	make_text_macro 'T', area, 560, 200
	make_text_macro 'A', area, 570, 200
	make_text_macro 'R', area, 580, 200
	make_text_macro 'I', area, 590, 200
	mov k, 1
	
	failed:

	; perete x, y, 0, 100, 50, 100
	; perete x, y, 150, 50, 100, 50
	; perete x, y, 150, 100, 100, 100
	; perete x, y, 350, 100, 300, 100
	; perete x, y, 100, 200, 100, 150
	; perete x, y, 250, 200, 250, 150
	; perete x, y, 50, 400, 50, 350
	; perete x, y, 100, 400, 100, 350
	; perete x, y, 300, 400, 300, 350
	; perete x, y, 300, 300, 300, 250
	; perete x, y, 100, 300, 100, 250
	lava x, y, 50, 50
	lava x, y, 200, 50
	lava x, y, 300, 50
	lava x, y, 150, 100
	lava x, y, 250, 100
	lava x, y, 50, 150
	lava x, y, 150, 200
	lava x, y, 200, 200
	lava x, y, 250, 200
	lava x, y, 0, 250
	lava x, y, 0, 300
	lava x, y, 100, 300
	lava x, y, 150, 300
	lava x, y, 300, 300
	lava x, y, 150, 400
	lava x, y, 250, 400
	perete x, y, 100, 0, 100, 50
	perete x, y, 0, 100, 50, 100
	perete x, y, 150, 50, 100, 50
	perete x, y, 350, 100, 300, 100
	perete x, y, 350, 150, 300, 150
	perete x, y, 0, 200, 50, 200
	perete x, y, 100, 200, 100, 150
	perete x, y, 350, 200, 300, 200
	perete x, y, 35, 250, 300, 250
	perete x, y, 200, 300, 200, 250
	perete x, y, 250, 300, 250, 250
	perete x, y, 350, 250, 300, 250
	perete x, y, 0, 350, 50, 350
	perete x, y, 50, 400, 50, 350
	perete x, y, 100, 400, 100, 350
	perete x, y, 200, 400, 200, 350
	perete x, y, 300, 400, 300, 350
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	cmp eax, 3
	jz evt_key
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere

evt_key:
	verificare poz_anterioara_x, poz_anterioara_y
	
evt_click:
	; mov edi, area
	; mov ecx, area_height
	; mov ebx, [ebp+arg3]
	; and ebx, 7
	; inc ebx
; bucla_linii:
	; mov eax, [ebp+arg2]
	; and eax, 0FFh
	;provide a new (random) color
	; mul eax
	; mul eax
	; add eax, ecx
	; push ecx
	; mov ecx, area_width
; bucla_coloane:
	; mov [edi], eax
	; add edi, 4
	; add eax, ebx
	; loop bucla_coloane
	; pop ecx
	; loop bucla_linii
	; jmp afisare_litere
	
evt_timer:
	inc counter
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	; mov ebx, 10
	; mov eax, counter
	;cifra unitatilor
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 30, 10
	;cifra zecilor
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 20, 10
	;cifra sutelor
	; mov edx, 0
	; div ebx
	; add edx, '0'
	; make_text_macro edx, area, 10, 10
	
	;scriem un mesaj
	cmp ok, 0
	jne urm
	inc ok
	deseneaza_patrat coordonate_x[8], coordonate_y[0], 50, 0FF0000h
	urm:
	
	
	make_text_macro 'A', area, 500, 20
	make_text_macro '-', area, 510, 20
	make_text_macro 'M', area, 520, 20
	make_text_macro 'A', area, 530, 20
	make_text_macro 'Z', area, 540, 20
	make_text_macro 'E', area, 550, 20
	make_text_macro '-', area, 560, 20
	make_text_macro 'I', area, 570, 20
	make_text_macro 'N', area, 580, 20
	make_text_macro 'G', area, 590, 20
	
	make_text_macro 'G', area, 535, 40
	make_text_macro 'A', area, 545, 40
	make_text_macro 'M', area, 555, 40
	make_text_macro 'E', area, 565, 40
	
	deseneaza_patrat 100, 0, cell_size, 0FFFFFFh
	cmp matrice[0], 0
	jne sari1
	deseneaza_patrat coordonate_x[0], coordonate_y[0], cell_size, 0FFFFFFh
	
	sari1:
	cmp matrice[0], 1
	jne sari2
	deseneaza_patrat coordonate_x[0], coordonate_y[0], cell_size, 0
	
	sari2:
	cmp matrice[0], 2
	jne sari3
	deseneaza_patrat coordonate_x[0], coordonate_y[0], cell_size, 0FFAA50h
	
	sari3:
	
	cmp matrice[4], 0
	jne sari4
	deseneaza_patrat coordonate_x[4], coordonate_y[0], cell_size, 0FFFFFFh
	
	sari4:
	cmp matrice[4], 1
	jne sari5
	deseneaza_patrat coordonate_x[4], coordonate_y[0], cell_size, 0
	
	sari5:
	cmp matrice[4], 2
	jne sari6
	deseneaza_patrat coordonate_x[4], coordonate_y[0], cell_size, 0FFAA50h
	
	sari6:
	
	sari7:
	cmp matrice[8], 1
	jne sari8
	deseneaza_patrat coordonate_x[8], coordonate_y[0], cell_size, 0
	
	sari8:
	cmp matrice[8], 2
	jne sari9
	deseneaza_patrat coordonate_x[8], coordonate_y[0], cell_size, 0FFAA50h
	
	sari9:
	cmp matrice[12], 0
	jne sari10
	deseneaza_patrat coordonate_x[12], coordonate_y[0], cell_size, 0FFFFFFh
	
	sari10:
	cmp matrice[12], 1
	jne sari11
	deseneaza_patrat coordonate_x[12], coordonate_y[0], cell_size, 0
	
	sari11:
	cmp matrice[12], 2
	jne sari12
	deseneaza_patrat coordonate_x[12], coordonate_y[0], cell_size, 0FFAA50h
	
	sari12:
	cmp matrice[16], 0
	jne sari13
	deseneaza_patrat coordonate_x[16], coordonate_y[0], cell_size, 0FFFFFFh
	
	sari13:
	cmp matrice[16], 1
	jne sari14
	deseneaza_patrat coordonate_x[16], coordonate_y[0], cell_size, 0
	
	sari14:
	cmp matrice[16], 2
	jne sari15
	deseneaza_patrat coordonate_x[16], coordonate_y[0], cell_size, 0FFAA50h
	
	sari15:
	cmp matrice[20], 0
	jne sari16
	deseneaza_patrat coordonate_x[20], coordonate_y[0], cell_size, 0FFFFFFh
	
	sari16:
	cmp matrice[20], 1
	jne sari17
	deseneaza_patrat coordonate_x[20], coordonate_y[0], cell_size, 0
	
	sari17:
	cmp matrice[20], 2
	jne sari18
	deseneaza_patrat coordonate_x[20], coordonate_y[0], cell_size, 0FFAA50h
	
	sari18:
	cmp matrice[24], 0
	jne sari19
	deseneaza_patrat coordonate_x[24], coordonate_y[0], cell_size, 0FFFFFFh
	
	sari19:
	cmp matrice[24], 1
	jne sari20
	deseneaza_patrat coordonate_x[24], coordonate_y[0], cell_size, 0
	
	sari20:
	cmp matrice[24], 2
	jne sari21
	deseneaza_patrat coordonate_x[24], coordonate_y[0], cell_size, 0FFAA50h
	
	sari21:
	cmp matrice[28], 0
	jne sari22
	deseneaza_patrat coordonate_x[28], coordonate_y[0], cell_size, 0FFFFFFh
	
	sari22:
	cmp matrice[28], 1
	jne sari23
	deseneaza_patrat coordonate_x[28], coordonate_y[0], cell_size, 0
	
	sari23:
	cmp matrice[28], 2
	jne sari24
	deseneaza_patrat coordonate_x[28], coordonate_y[0], cell_size, 0FFAA50h
	
	sari24:
	cmp matrice[32], 0
	jne sari25
	deseneaza_patrat coordonate_x[0], coordonate_y[4], cell_size, 0FFFFFFh
	
	sari25:
	cmp matrice[32], 1
	jne sari26
	deseneaza_patrat coordonate_x[0], coordonate_y[4], cell_size, 0
	
	sari26:
	cmp matrice[32], 2
	jne sari27
	deseneaza_patrat coordonate_x[0], coordonate_y[4], cell_size, 0FFAA50h
	
	sari27:

	
	sari28:
	cmp matrice[36], 1
	jne sari29
	deseneaza_patrat coordonate_x[4], coordonate_y[4], cell_size, 0
	
	sari29:
	cmp matrice[36], 2
	jne sari30
	deseneaza_patrat coordonate_x[4], coordonate_y[4], cell_size, 0FFAA50h
	
	sari30:

	
	sari31:
	cmp matrice[40], 1
	jne sari32
	deseneaza_patrat coordonate_x[8], coordonate_y[4], cell_size, 0
	
	sari32:
	cmp matrice[40], 2
	jne sari33
	deseneaza_patrat coordonate_x[8], coordonate_y[4], cell_size, 0FFAA50h
	
	sari33:
	cmp matrice[44], 0
	jne sari34
	deseneaza_patrat coordonate_x[12], coordonate_y[4], cell_size, 0FFFFFFh
	
	sari34:
	cmp matrice[44], 1
	jne sari35
	deseneaza_patrat coordonate_x[12], coordonate_y[4], cell_size, 0
	
	sari35:
	cmp matrice[44], 2
	jne sari36
	deseneaza_patrat coordonate_x[12], coordonate_y[4], cell_size, 0FFAA50h
	
	sari36:
	
	sari37:
	cmp matrice[48], 1
	jne sari38
	deseneaza_patrat coordonate_x[16], coordonate_y[4], cell_size, 0
	
	sari38:
	cmp matrice[48], 2
	jne sari39
	deseneaza_patrat coordonate_x[16], coordonate_y[4], cell_size, 0FFAA50h
	
	sari39:
	cmp matrice[52], 0
	jne sari40
	deseneaza_patrat coordonate_x[20], coordonate_y[4], cell_size, 0FFFFFFh
	
	sari40:
	cmp matrice[52], 1
	jne sari41
	deseneaza_patrat coordonate_x[20], coordonate_y[4], cell_size, 0
	
	sari41:
	cmp matrice[52], 2
	jne sari42
	deseneaza_patrat coordonate_x[20], coordonate_y[4], cell_size, 0FFAA50h
	
	sari42:
	
	sari43:
	cmp matrice[56], 1
	jne sari44
	deseneaza_patrat coordonate_x[24], coordonate_y[4], cell_size, 0
	
	sari44:
	cmp matrice[56], 2
	jne sari45
	deseneaza_patrat coordonate_x[24], coordonate_y[4], cell_size, 0FFAA50h
	
	sari45:
	cmp matrice[60], 0
	jne sari46
	deseneaza_patrat coordonate_x[28], coordonate_y[4], cell_size, 0FFFFFFh
	
	sari46:
	cmp matrice[60], 1
	jne sari47
	deseneaza_patrat coordonate_x[28], coordonate_y[4], cell_size, 0
	
	sari47:
	cmp matrice[60], 2
	jne sari48
	deseneaza_patrat coordonate_x[28], coordonate_y[4], cell_size, 0FFAA50h
	
	
	sari48:
	cmp matrice[64], 0
	jne sari49
	deseneaza_patrat coordonate_x[0], coordonate_y[8], cell_size, 0FFFFFFh
	
	sari49:
	cmp matrice[64], 1
	jne sari50
	deseneaza_patrat coordonate_x[0], coordonate_y[8], cell_size, 0
	
	sari50:
	cmp matrice[64], 2
	jne sari51
	deseneaza_patrat coordonate_x[0], coordonate_y[8], cell_size, 0FFAA50h
	
	sari51:
	cmp matrice[68], 0
	jne sari52
	deseneaza_patrat coordonate_x[4], coordonate_y[8], cell_size, 0FFFFFFh
	
	sari52:
	cmp matrice[68], 1
	jne sari53
	deseneaza_patrat coordonate_x[4], coordonate_y[8], cell_size, 0
	
	sari53:
	cmp matrice[68], 2
	jne sari54
	deseneaza_patrat coordonate_x[4], coordonate_y[8], cell_size, 0FFAA50h
	
	sari54:

	
	sari55:
	cmp matrice[72], 1
	jne sari56
	deseneaza_patrat coordonate_x[8], coordonate_y[8], cell_size, 0
	
	sari56:
	cmp matrice[72], 2
	jne sari57
	deseneaza_patrat coordonate_x[8], coordonate_y[8], cell_size, 0FFAA50h
	
	sari57:

	
	sari58:
	cmp matrice[76], 1
	jne sari59
	deseneaza_patrat coordonate_x[12], coordonate_y[8], cell_size, 0
	
	sari59:
	cmp matrice[76], 2
	jne sari60
	deseneaza_patrat coordonate_x[12], coordonate_y[8], cell_size, 0FFAA50h
	
	sari60:

	
	sari61:
	cmp matrice[80], 1
	jne sari62
	deseneaza_patrat coordonate_x[16], coordonate_y[8], cell_size, 0
	
	sari62:
	cmp matrice[80], 2
	jne sari63
	deseneaza_patrat coordonate_x[16], coordonate_y[8], cell_size, 0FFAA50h
	
	sari63:

	
	sari64:
	cmp matrice[84], 1
	jne sari65
	deseneaza_patrat coordonate_x[20], coordonate_y[8], cell_size, 0
	
	sari65:
	cmp matrice[84], 2
	jne sari66
	deseneaza_patrat coordonate_x[20], coordonate_y[8], cell_size, 0FFAA50h
	
	sari66:

	
	sari67:
	cmp matrice[88], 1
	jne sari68
	deseneaza_patrat coordonate_x[24], coordonate_y[8], cell_size, 0
	
	sari68:
	cmp matrice[88], 2
	jne sari69
	deseneaza_patrat coordonate_x[24], coordonate_y[8], cell_size, 0FFAA50h
	
	sari69:
	cmp matrice[92], 0
	jne sari70
	deseneaza_patrat coordonate_x[28], coordonate_y[8], cell_size, 0FFFFFFh
	
	sari70:
	cmp matrice[92], 1
	jne sari71
	deseneaza_patrat coordonate_x[28], coordonate_y[8], cell_size, 0
	
	sari71:
	cmp matrice[92], 2
	jne sari72
	deseneaza_patrat coordonate_x[28], coordonate_y[8], cell_size, 0FFAA50h
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;linia 4
	sari72:
	cmp matrice[96], 0
	jne sari73
	deseneaza_patrat coordonate_x[0], coordonate_y[12], cell_size, 0FFFFFFh
	
	sari73:
	cmp matrice[96], 1
	jne sari74
	deseneaza_patrat coordonate_x[0], coordonate_y[12], cell_size, 0
	
	sari74:
	cmp matrice[96], 2
	jne sari75
	deseneaza_patrat coordonate_x[0], coordonate_y[12], cell_size, 0FFAA50h
	
	sari75:

	
	sari76:
	cmp matrice[100], 1
	jne sari77
	deseneaza_patrat coordonate_x[4], coordonate_y[12], cell_size, 0
	
	sari77:
	cmp matrice[100], 2
	jne sari78
	deseneaza_patrat coordonate_x[4], coordonate_y[12], cell_size, 0FFAA50h
	
	sari78:
	cmp matrice[104], 0
	jne sari79
	deseneaza_patrat coordonate_x[8], coordonate_y[12], cell_size, 0FFFFFFh
	
	sari79:
	cmp matrice[104], 1
	jne sari80
	deseneaza_patrat coordonate_x[8], coordonate_y[12], cell_size, 0
	
	sari80:
	cmp matrice[104], 2
	jne sari81
	deseneaza_patrat coordonate_x[8], coordonate_y[12], cell_size, 0FFAA50h
	
	sari81:
	cmp matrice[108], 0
	jne sari82
	deseneaza_patrat coordonate_x[12], coordonate_y[12], cell_size, 0FFFFFFh
	
	sari82:
	cmp matrice[108], 1
	jne sari83
	deseneaza_patrat coordonate_x[12], coordonate_y[12], cell_size, 0
	
	sari83:
	cmp matrice[108], 2
	jne sari84
	deseneaza_patrat coordonate_x[12], coordonate_y[12], cell_size, 0FFAA50h
	
	sari84:
	cmp matrice[112], 0
	jne sari85
	deseneaza_patrat coordonate_x[16], coordonate_y[12], cell_size, 0FFFFFFh
	
	sari85:
	cmp matrice[112], 1
	jne sari86
	deseneaza_patrat coordonate_x[16], coordonate_y[12], cell_size, 0
	
	sari86:
	cmp matrice[112], 2
	jne sari87
	deseneaza_patrat coordonate_x[16], coordonate_y[12], cell_size, 0FFAA50h
	
	sari87:
	cmp matrice[116], 0
	jne sari88
	deseneaza_patrat coordonate_x[20], coordonate_y[12], cell_size, 0FFFFFFh
	
	sari88:
	cmp matrice[116], 1
	jne sari89
	deseneaza_patrat coordonate_x[20], coordonate_y[12], cell_size, 0
	
	sari89:
	cmp matrice[116], 2
	jne sari90
	deseneaza_patrat coordonate_x[20], coordonate_y[12], cell_size, 0FFAA50h
	
	sari90:
	
	sari91:
	cmp matrice[120], 1
	jne sari92
	deseneaza_patrat coordonate_x[24], coordonate_y[12], cell_size, 0
	
	sari92:
	cmp matrice[120], 2
	jne sari93
	deseneaza_patrat coordonate_x[24], coordonate_y[12], cell_size, 0FFAA50h
	
	sari93:
	cmp matrice[124], 0
	jne sari94
	deseneaza_patrat coordonate_x[28], coordonate_y[12], cell_size, 0FFFFFFh
	
	sari94:
	cmp matrice[124], 1
	jne sari95
	deseneaza_patrat coordonate_x[28], coordonate_y[12], cell_size, 0
	
	sari95:
	cmp matrice[124], 2
	jne sari96
	deseneaza_patrat coordonate_x[28], coordonate_y[12], cell_size, 0FFAA50h
	;;;;;;;;;;;;;;;;;;;;;;;linia5
	sari96:
	cmp matrice[128], 0
	jne sari97
	deseneaza_patrat coordonate_x[0], coordonate_y[16], cell_size, 0FFFFFFh
	
	sari97:
	cmp matrice[128], 1
	jne sari98
	deseneaza_patrat coordonate_x[0], coordonate_y[16], cell_size, 0
	
	sari98:
	cmp matrice[128], 2
	jne sari99
	deseneaza_patrat coordonate_x[0], coordonate_y[16], cell_size, 0FFAA50h
	
	sari99:
	
	sari100:
	cmp matrice[132], 1
	jne sari101
	deseneaza_patrat coordonate_x[4], coordonate_y[16], cell_size, 0
	
	sari101:
	cmp matrice[132], 2
	jne sari102
	deseneaza_patrat coordonate_x[4], coordonate_y[16], cell_size, 0FFAA50h
	
	sari102:
	
	sari103:
	cmp matrice[136], 1
	jne sari104
	deseneaza_patrat coordonate_x[8], coordonate_y[16], cell_size, 0
	
	sari104:
	cmp matrice[136], 2
	jne sari105
	deseneaza_patrat coordonate_x[8], coordonate_y[16], cell_size, 0FFAA50h
	
	sari105:

	
	sari106:
	cmp matrice[140], 1
	jne sari107
	deseneaza_patrat coordonate_x[12], coordonate_y[16], cell_size, 0
	
	sari107:
	cmp matrice[140], 2
	jne sari108
	deseneaza_patrat coordonate_x[12], coordonate_y[16], cell_size, 0FFAA50h
	
	sari108:

	
	sari109:
	cmp matrice[144], 1
	jne sari110
	deseneaza_patrat coordonate_x[16], coordonate_y[16], cell_size, 0
	
	sari110:
	cmp matrice[144], 2
	jne sari111
	deseneaza_patrat coordonate_x[16], coordonate_y[16], cell_size, 0FFAA50h
	
	sari111:

	
	sari112:
	cmp matrice[148], 1
	jne sari113
	deseneaza_patrat coordonate_x[20], coordonate_y[16], cell_size, 0
	
	sari113:
	cmp matrice[148], 2
	jne sari114
	deseneaza_patrat coordonate_x[20], coordonate_y[16], cell_size, 0FFAA50h
	
	sari114:

	
	sari115:
	cmp matrice[152], 1
	jne sari116
	deseneaza_patrat coordonate_x[24], coordonate_y[16], cell_size, 0
	
	sari116:
	cmp matrice[152], 2
	jne sari117
	deseneaza_patrat coordonate_x[24], coordonate_y[16], cell_size, 0FFAA50h
	
	sari117:
	cmp matrice[156], 0
	jne sari118
	deseneaza_patrat coordonate_x[28], coordonate_y[16], cell_size, 0FFFFFFh
	
	sari118:
	cmp matrice[156], 1
	jne sari119
	deseneaza_patrat coordonate_x[28], coordonate_y[16], cell_size, 0
	
	sari119:
	cmp matrice[156], 2
	jne sari120
	deseneaza_patrat coordonate_x[28], coordonate_y[16], cell_size, 0FFAA50h
	;;;;;;;;;;;;;;;linia6
	sari120:
	cmp matrice[160], 0
	jne sari121
	deseneaza_patrat coordonate_x[0], coordonate_y[20], cell_size, 0FFFFFFh
	
	sari121:
	cmp matrice[160], 1
	jne sari122
	deseneaza_patrat coordonate_x[0], coordonate_y[20], cell_size, 0
	
	sari122:
	cmp matrice[160], 2
	jne sari123
	deseneaza_patrat coordonate_x[0], coordonate_y[20], cell_size, 0FFAA50h
	
	sari123:

	
	sari124:
	cmp matrice[164], 1
	jne sari125
	deseneaza_patrat coordonate_x[4], coordonate_y[20], cell_size, 0
	
	sari125:
	cmp matrice[164], 2
	jne sari126
	deseneaza_patrat coordonate_x[4], coordonate_y[20], cell_size, 0FFAA50h
	
	sari126:
	cmp matrice[168], 0
	jne sari127
	deseneaza_patrat coordonate_x[8], coordonate_y[20], cell_size, 0FFFFFFh
	
	sari127:
	cmp matrice[168], 1
	jne sari128
	deseneaza_patrat coordonate_x[8], coordonate_y[20], cell_size, 0
	
	sari128:
	cmp matrice[168], 2
	jne sari129
	deseneaza_patrat coordonate_x[8], coordonate_y[20], cell_size, 0FFAA50h
	
	sari129:
	cmp matrice[172], 0
	jne sari130
	deseneaza_patrat coordonate_x[12], coordonate_y[20], cell_size, 0FFFFFFh
	
	sari130:
	cmp matrice[172], 1
	jne sari131
	deseneaza_patrat coordonate_x[12], coordonate_y[20], cell_size, 0
	
	sari131:
	cmp matrice[172], 2
	jne sari132
	deseneaza_patrat coordonate_x[12], coordonate_y[20], cell_size, 0FFAA50h
	
	sari132:
	cmp matrice[176], 0
	jne sari133
	deseneaza_patrat coordonate_x[16], coordonate_y[20], cell_size, 0FFFFFFh
	
	sari133:
	cmp matrice[176], 1
	jne sari134
	deseneaza_patrat coordonate_x[16], coordonate_y[20], cell_size, 0
	
	sari134:
	cmp matrice[176], 2
	jne sari135
	deseneaza_patrat coordonate_x[16], coordonate_y[20], cell_size, 0FFAA50h
	
	sari135:
	cmp matrice[180], 0
	jne sari136
	deseneaza_patrat coordonate_x[20], coordonate_y[20], cell_size, 0FFFFFFh
	
	sari136:
	cmp matrice[180], 1
	jne sari137
	deseneaza_patrat coordonate_x[20], coordonate_y[20], cell_size, 0
	
	sari137:
	cmp matrice[180], 2
	jne sari138
	deseneaza_patrat coordonate_x[20], coordonate_y[20], cell_size, 0FFAA50h
	
	sari138:
	cmp matrice[184], 0
	jne sari139
	deseneaza_patrat coordonate_x[24], coordonate_y[20], cell_size, 0FFFFFFh
	
	sari139:
	cmp matrice[184], 1
	jne sari140
	deseneaza_patrat coordonate_x[24], coordonate_y[20], cell_size, 0
	
	sari140:
	cmp matrice[184], 2
	jne sari141
	deseneaza_patrat coordonate_x[24], coordonate_y[20], cell_size, 0FFAA50h
	
	sari141:
	cmp matrice[188], 0
	jne sari142
	deseneaza_patrat coordonate_x[28], coordonate_y[20], cell_size, 0FFFFFFh
	
	sari142:
	cmp matrice[188], 1
	jne sari143
	deseneaza_patrat coordonate_x[28], coordonate_y[20], cell_size, 0
	
	sari143:
	cmp matrice[188], 2
	jne sari144
	deseneaza_patrat coordonate_x[28], coordonate_y[20], cell_size, 0FFAA50h
	
	sari144:
	cmp matrice[192], 0
	jne sari145
	deseneaza_patrat coordonate_x[0], coordonate_y[24], cell_size, 0FFFFFFh
	
	sari145:
	cmp matrice[192], 1
	jne sari146
	deseneaza_patrat coordonate_x[0], coordonate_y[24], cell_size, 0
	
	sari146:
	cmp matrice[192], 2
	jne sari147
	deseneaza_patrat coordonate_x[0], coordonate_y[24], cell_size, 0FFAA50h
	
	sari147:

	
	sari148:
	cmp matrice[196], 1
	jne sari149
	deseneaza_patrat coordonate_x[4], coordonate_y[24], cell_size, 0
	
	sari149:
	cmp matrice[196], 2
	jne sari150
	deseneaza_patrat coordonate_x[4], coordonate_y[24], cell_size, 0FFAA50h
	
	sari150:

	
	sari151:
	cmp matrice[200], 1
	jne sari152
	deseneaza_patrat coordonate_x[8], coordonate_y[24], cell_size, 0
	
	sari152:
	cmp matrice[200], 2
	jne sari153
	deseneaza_patrat coordonate_x[8], coordonate_y[24], cell_size, 0FFAA50h
	
	sari153:

	
	sari154:
	cmp matrice[204], 1
	jne sari155
	deseneaza_patrat coordonate_x[12], coordonate_y[24], cell_size, 0
	
	sari155:
	cmp matrice[204], 2
	jne sari156
	deseneaza_patrat coordonate_x[12], coordonate_y[24], cell_size, 0FFAA50h
	
	sari156:

	
	sari157:
	cmp matrice[208], 1
	jne sari158
	deseneaza_patrat coordonate_x[16], coordonate_y[24], cell_size, 0
	
	sari158:
	cmp matrice[208], 2
	jne sari159
	deseneaza_patrat coordonate_x[16], coordonate_y[24], cell_size, 0FFAA50h
	
	sari159:

	
	sari160:
	cmp matrice[212], 1
	jne sari161
	deseneaza_patrat coordonate_x[20], coordonate_y[24], cell_size, 0
	
	sari161:
	cmp matrice[212], 2
	jne sari162
	deseneaza_patrat coordonate_x[20], coordonate_y[24], cell_size, 0FFAA50h
	
	sari162:

	
	sari163:
	cmp matrice[216], 1
	jne sari164
	deseneaza_patrat coordonate_x[24], coordonate_y[24], cell_size, 0
	
	sari164:
	cmp matrice[216], 2
	jne sari165
	deseneaza_patrat coordonate_x[24], coordonate_y[24], cell_size, 0FFAA50h
	
	sari165:

	
	sari166:
	cmp matrice[220], 1
	jne sari167
	deseneaza_patrat coordonate_x[28], coordonate_y[24], cell_size, 0
	
	sari167:
	cmp matrice[220], 2
	jne sari168
	deseneaza_patrat coordonate_x[28], coordonate_y[24], cell_size, 0FFAA50h
	;;;;;;;;;;;linia8
	sari168:
	cmp matrice[224], 0
	jne sari169
	deseneaza_patrat coordonate_x[0], coordonate_y[28], cell_size, 0FFFFFFh
	
	sari169:
	cmp matrice[224], 1
	jne sari170
	deseneaza_patrat coordonate_x[0], coordonate_y[28], cell_size, 0
	
	sari170:
	cmp matrice[224], 2
	jne sari171
	deseneaza_patrat coordonate_x[0], coordonate_y[28], cell_size, 0FFAA50h
	
	sari171:
	cmp matrice[228], 0
	jne sari172
	deseneaza_patrat coordonate_x[4], coordonate_y[28], cell_size, 0FFFFFFh
	
	sari172:
	cmp matrice[228], 1
	jne sari173
	deseneaza_patrat coordonate_x[4], coordonate_y[28], cell_size, 0
	
	sari173:
	cmp matrice[228], 2
	jne sari174
	deseneaza_patrat coordonate_x[4], coordonate_y[28], cell_size, 0FFAA50h
	
	sari174:
	cmp matrice[232], 0
	jne sari175
	deseneaza_patrat coordonate_x[8], coordonate_y[28], cell_size, 0FFFFFFh
	
	sari175:
	cmp matrice[232], 1
	jne sari176
	deseneaza_patrat coordonate_x[8], coordonate_y[28], cell_size, 0
	
	sari176:
	cmp matrice[232], 2
	jne sari177
	deseneaza_patrat coordonate_x[8], coordonate_y[28], cell_size, 0FFAA50h
	
	sari177:
	cmp matrice[236], 0
	jne sari178
	deseneaza_patrat coordonate_x[12], coordonate_y[28], cell_size, 0FFFFFFh
	
	sari178:
	cmp matrice[236], 1
	jne sari179
	deseneaza_patrat coordonate_x[12], coordonate_y[28], cell_size, 0
	
	sari179:
	cmp matrice[236], 2
	jne sari180
	deseneaza_patrat coordonate_x[12], coordonate_y[28], cell_size, 0FFAA50h
	
	sari180:
	cmp matrice[240], 0
	jne sari181
	deseneaza_patrat coordonate_x[16], coordonate_y[28], cell_size, 0FFFFFFh
	
	sari181:
	cmp matrice[240], 1
	jne sari182
	deseneaza_patrat coordonate_x[16], coordonate_y[28], cell_size, 0
	
	sari182:
	cmp matrice[240], 2
	jne sari183
	deseneaza_patrat coordonate_x[16], coordonate_y[28], cell_size, 0FFAA50h
	
	sari183:
	cmp matrice[244], 0
	jne sari184
	deseneaza_patrat coordonate_x[20], coordonate_y[28], cell_size, 0FFFFFFh
	
	sari184:
	cmp matrice[244], 1
	jne sari185
	deseneaza_patrat coordonate_x[20], coordonate_y[28], cell_size, 0
	
	sari185:
	cmp matrice[244], 2
	jne sari186
	deseneaza_patrat coordonate_x[20], coordonate_y[28], cell_size, 0FFAA50h
	
	sari186:
	cmp matrice[248], 0
	jne sari187
	deseneaza_patrat coordonate_x[24], coordonate_y[28], cell_size, 0FFFFFFh
	
	sari187:
	cmp matrice[248], 1
	jne sari188
	deseneaza_patrat coordonate_x[24], coordonate_y[28], cell_size, 0
	
	sari188:
	cmp matrice[248], 2
	jne sari189
	deseneaza_patrat coordonate_x[24], coordonate_y[28], cell_size, 0FFAA50h
	
	sari189:
	cmp matrice[252], 0
	jne sari190
	deseneaza_patrat coordonate_x[28], coordonate_y[28], cell_size, 0FFFFFFh
	
	sari190:
	cmp matrice[252], 1
	jne sari191
	deseneaza_patrat coordonate_x[28], coordonate_y[28], cell_size, 0
	
	sari191:
	cmp matrice[252], 2
	jne sari192
	deseneaza_patrat coordonate_x[28], coordonate_y[28], cell_size, 0FFAA50h
	
	sari192:
	
	
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start

