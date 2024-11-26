.data
slist: .word 0
cclist: .word 0
wclist: .word 0
schedv: .space 32
menu: .ascii "Colecciones de objetos categorizados\n"
.ascii "====================================\n"
.ascii "1-Nueva categoria\n"
.ascii "2-Siguiente categoria\n"
.ascii "3-Categoria anterior\n"
.ascii "4-Listar categorias\n"
.ascii "5-Borrar categoria actual\n"
.ascii "6-Anexar objeto a la categoria actual\n"
.ascii "7-Listar objetos de la categoria\n"
.ascii "8-Borrar objeto de la categoria\n"
.ascii "0-Salir\n"
.asciiz "Ingrese la opcion deseada: "
error: .asciiz "Error: "
return: .asciiz "\n"
catName: .asciiz "\nIngrese el nombre de una categoria: "
selCat: .asciiz "\nSe ha seleccionado la categoria:"
idObj: .asciiz "\nIngrese el ID del objeto a eliminar: "
objName: .asciiz "\nIngrese el nombre de un objeto: "
success: .asciiz "La operación se realizo con exito\n\n"
nccategory: .asciiz " No existe categoria en curso, cree una categoria nueva por favor"
quest: .ascii "\nA que categoria deseas ir?\n"
.ascii "0-Anterior\n"
.ascii "1-Siguiente\n"
.asciiz "Ingrese la opcion deseada: "


.text
main:	
	mostrarmenu:
  		# Mostrar menú
        	li $v0, 4
        	la $a0, menu
        	syscall

        	# Leer la opción seleccionada
        	li $v0, 5
        	syscall
        	move $t2, $v0      # Guardar la opción en $t0
        
        beq $t2, 0, endprogram #Si $t0 es igual a 0 salta a endprogram
        
        # SCHEDULER
        la $t0, schedv      # Cargar la base de la tabla de direcciones
	la $t1, newcategory
	sw $t1, 0($t0)
	la $t1, nextcategory
	sw $t1, 4($t0)
	la $t1, listcategories
	sw $t1, 8($t0)
	
	#UNA VEZ INGRESADO EL VALOR POR TECLADO SE BUSCA CUAL ES LAFUNCION SELECCIONADA EN EL SCHVEC
	subu $t2, $t2, 1    # Ajustar índice a base 0
    	sll $t2, $t2, 2     # Multiplicar índice por 4 (tamaño de palabra)
    	add $t0, $t0, $t2   # Calcular la dirección en la tabla
    	lw $t1, 0($t0)      # Cargar la dirección de la función
    	jalr $t1            # Llamar a la función correspondiente
    	
    	# Volver al inicio
    	j main
    	
    	sbrk:	
		li $a0, 16 # node size fixed 4 words
		li $v0, 9
		syscall # return node address in v0
		jr $ra
	
	smalloc:
		lw $t0, slist
		beqz $t0, sbrk #Si $t0(alamacena slis) es igual a 0 (NULL) salta a sbrk
		move $v0, $t0
		lw $t0, 12($t0)
		sw $t0, slist
		jr $ra
	
	getblock:
		addi $sp, $sp, -4
		sw $ra, 4($sp)
		li $v0, 4
		syscall
		jal smalloc
		move $a0, $v0
		li $a1, 16
		li $v0, 8
		syscall
		move $v0, $a0
		lw $ra, 4($sp)
		addi $sp, $sp, 4
		jr $ra
	addnode:
		addi $sp, $sp, -8
		sw $ra, 8($sp)
		sw $a0, 4($sp)
		jal smalloc
		sw $a1, 4($v0) # set node content
		sw $a2, 8($v0)
		lw $a0, 4($sp)
		lw $t0, ($a0) # first node address
		beqz $t0, addnode_empty_list
		
	addnode_to_end:
		lw $t1, ($t0) # last node address
		# update prev and next pointers of new node
		sw $t1, 0($v0)
		sw $t0, 12($v0)
		# update prev and first node to new node
		sw $v0, 12($t1)
		sw $v0, 0($t0)
		j addnode_exit
		
	addnode_empty_list:
		sw $v0, ($a0)
		sw $v0, 0($v0)
		sw $v0, 12($v0)
	
    	addnode_exit:
		lw $ra, 8($sp)
		addi $sp, $sp, 8
		jr $ra
		
	newcategory_end:
		li $v0, 0 # return success
		lw $ra, 4($sp)
		addiu $sp, $sp, 4
		jr $ra
	
	newcategory:
		addiu $sp, $sp, -4
		sw $ra, 4($sp)
		la $a0, catName # input nombre de la categoria
		jal getblock
		move $a2, $v0 # $a2 = *char to category name
		la $a0, cclist # $a0 = list
		li $a1, 0 # $a1 = NULL
		jal addnode
		lw $t0, wclist
		bnez $t0, newcategory_end
		sw $v0, wclist # update working list if was NULL
		j mostrarmenu
		
###### ACA COMIENZAN TODAS LAS FUNCIONES RELACIONADAS CON LA OPCION 2 DEL MENU ####### 
        error201:
        	li $v0, 4
        	la $a0, error
        	syscall
        	li $v0, 1            # Código de syscall para imprimir entero
		li $a0, 201          # Cargar el número a imprimir
		syscall
		li $v0, 4
        	la $a0, nccategory
        	syscall
        	j endprogram
        
        backcategory:
        	la $t3, wclist
        	lw $t0, 0($t3)
        	Imprimo el nodo
        	lw $a0, 0($t0)
		beqz $t1, error201
        	li $v0, 34
        	#la $a0, anterior  #Continuar a partir de aca
        	syscall
        	
        	#Falta terminar esta funcion
        	
        	j endprogram
        	
        	
         nextcategory:
        	la $t3, wclist
        	lw $t0, 0($t3)
		beqz $t0, error201
        	li $v0, 4
        	la $a0, quest
        	syscall
        	li $v0, 5
        	syscall
        	move $t0, $v0
        	beqz $t0, backcategory
        	j endprogram
        
###### ACA COMIENZAN TODAS LAS FUNCIONES RELACIONADAS CON LA OPCION 3 DEL MENU #######
	 error301:
        	li $v0, 4
        	la $a0, error
        	syscall
        	li $v0, 1            # Código de syscall para imprimir entero
		li $a0, 301          # Cargar el número a imprimir
		syscall
		li $v0, 4
        	la $a0, nccategory
        	syscall
        	j endprogram
        	
        looplist:
        	addiu $sp, $sp, -4
        	sw $ra, 4($sp)
        	move $a1, $a0
        	lw $a0, 8($a1)
        	li $v0, 4
        	syscall
        	lw $a0, 12($a1)
        	bnez $a0, looplist  #Aca tengo el problema que el loop nunca corta, eso se debe a que el puntero al siguiente nodo no es NULL, pero estoy pudiendo correjirlo
         	lw $ra, 4($sp)
		addiu $sp, $sp, 4
        	jr $ra
        	
     	listcategories:
                la $t3, wclist
        	lw $t0, 0($t3)
		beqz $t0, error301
		move $a0, $t0
		jal looplist            
        	j endprogram
        	
        #Fin del programa
        endprogram:
		li $v0 , 10
        	syscall
        	
         
        
        
       
        	
	
    	
	
	
