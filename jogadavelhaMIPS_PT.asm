.data
    novaLinha:       .asciiz "\n"
    tabuleiro:       .asciiz "   |   |      (1|2|3)\n---+---+---\n   |   |      (4|5|6)\n---+---+---\n   |   |      (7|8|9)\n"
    msgTurnoX:        .asciiz "Jogador X, insira sua jogada (1-9): "
    msgTurnoO:        .asciiz "Jogador O, insira sua jogada (1-9): "
    msgErro:         .asciiz "*Jogada inválida ou espaço ocupado, tente novamente*\n"
    msgXVenceu:         .asciiz "Jogador X venceu!\n"
    msgOVenceu:         .asciiz "Jogador O venceu!\n"
    msgEmpate:       .asciiz "Velha!\n"

    # Array com os deslocamentos no 'tabuleiro' onde os símbolos serão inseridos.
    deslocamentos:   .word 1,5,9,35,39,43,69,73,77

    # Combinações vencedoras (8 combinações, cada uma com 3 índices 0-based)
    vencedor:        .word 0,1,2,   3,4,5,   6,7,8,   0,3,6,   1,4,7,   2,5,8,   0,4,8,   2,4,6

    # Estado do jogo: 9 bytes; 0 = vazio, 1 = X, 2 = O.
    estado:          .space 9

.text
.globl main
main:
    jal inicializaTabuleiro      # Inicializa o estado do tabuleiro e reseta a string "tabuleiro"
    li   $s0, 0                 # Contador de jogadas = 0

loopJogo:
    jal imprimeTabuleiro        # Exibe o tabuleiro atualizado
    jal verificaVitoria         # Verifica se há um vencedor; resultado em $v0
    bnez $v0, fimJogo           # Se $v0 ? 0, houve vitória
    li   $t0, 9
    beq  $s0, $t0, empateJogo   # Se 9 jogadas foram realizadas, é empate

    # Define de quem é a vez: se ($s0 mod 2 == 0) é o jogador X; caso contrário, O.
    andi $t1, $s0, 1
    beq  $t1, 0, promptX
    li   $v0, 4
    la   $a0, msgTurnoO
    syscall
    j    obterJogada
promptX:
    li   $v0, 4
    la   $a0, msgTurnoX
    syscall
obterJogada:
    li   $v0, 5               # Lê um inteiro (posição 1-9)
    syscall
    move $t2, $v0             # $t2 ? jogada (1 a 9)
    blt  $t2, 1, jogadaInvalida
    bgt  $t2, 9, jogadaInvalida
    addi $t2, $t2, -1         # Converte para índice 0-based

    la   $t3, estado
    add  $t4, $t3, $t2        # Endereço de estado[t2]
    lb   $t5, 0($t4)
    bnez $t5, jogadaInvalida  # Se não estiver vazio, movimento inválido

    # Define o símbolo e valor do jogador: se ($s0 mod 2 == 0) então X, senão O.
    andi $t1, $s0, 1
    beq  $t1, 0, definirJogadaX
definirJogadaO:
    li   $t6, 2              # Estado 2 para O
    li   $t7, 'O'
    j    armazenarJogada
definirJogadaX:
    li   $t6, 1              # Estado 1 para X
    li   $t7, 'X'
armazenarJogada:
    sb   $t6, 0($t4)         # Atualiza o array estado
    # Atualiza a string do tabuleiro no deslocamento correspondente:
    la   $t8, deslocamentos
    sll  $t9, $t2, 2         # Multiplica índice por 4 (tamanho de uma palavra)
    add  $t8, $t8, $t9
    lw   $t8, 0($t8)         # Deslocamento dentro da string "tabuleiro"
    la   $t3, tabuleiro
    add  $t8, $t3, $t8
    sb   $t7, 0($t8)         # Insere 'X' ou 'O'
    addi $s0, $s0, 1         # Incrementa o contador de jogadas
    j    loopJogo

jogadaInvalida:
    li   $v0, 4
    la   $a0, msgErro
    syscall
    j    loopJogo

inicializaTabuleiro:
    la   $t0, estado
    li   $t1, 9
initLoop:
    beqz $t1, initTabDone
    li   $t2, 0
    sb   $t2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, -1
    j    initLoop
initTabDone:
    la   $t0, tabuleiro
    la   $t1, deslocamentos
    li   $t2, 9
initLoop2:
    beqz $t2, initTabEnd
    lw   $t3, 0($t1)
    add  $t4, $t0, $t3
    li   $t5, ' '           # Coloca espaço vazio
    sb   $t5, 0($t4)
    addi $t1, $t1, 4
    addi $t2, $t2, -1
    j    initLoop2
initTabEnd:
    jr   $ra

imprimeTabuleiro:
    li   $v0, 4
    la   $a0, tabuleiro
    syscall
    jr   $ra

verificaVitoria:
    la   $t0, estado        # Base do array estado
    la   $t1, vencedor      # Base do array de combinações
    li   $t2, 8            # Número de combinações
vitoriaLoop:
    beqz $t2, nenhumVencedor
    lw   $a0, 0($t1)       # Primeiro índice
    lw   $a1, 4($t1)       # Segundo índice
    lw   $a2, 8($t1)       # Terceiro índice
    add  $t3, $t0, $a0
    lb   $t3, 0($t3)
    add  $t4, $t0, $a1
    lb   $t4, 0($t4)
    add  $t5, $t0, $a2
    lb   $t5, 0($t5)
    beqz $t3, proximaComb
    bne  $t3, $t4, proximaComb
    bne  $t3, $t5, proximaComb
    move $v0, $t3         # Retorna o vencedor (1 ou 2)
    jr   $ra
proximaComb:
    addi $t1, $t1, 12     # Próxima combinação (3 palavras = 12 bytes)
    addi $t2, $t2, -1
    j    vitoriaLoop
nenhumVencedor:
    li   $v0, 0
    jr   $ra

fimJogo:
    jal imprimeTabuleiro
    li   $v0, 4
    la   $a0, novaLinha
    syscall
    jal verificaVitoria    # Recalcula o vencedor (resultado em $v0)
    beq  $v0, 1, vitoriaX
    beq  $v0, 2, vitoriaO
    j    sair
vitoriaX:
    li   $v0, 4
    la   $a0, msgXVenceu
    syscall
    j    sair
vitoriaO:
    li   $v0, 4
    la   $a0, msgOVenceu
    syscall
    j    sair

empateJogo:
    li   $v0, 4
    la   $a0, msgEmpate
    syscall
    j    sair

sair:
    li   $v0, 10
    syscall
