# ===========================================================
# Identificacao do grupo:  A49
#
# Membros [istID, primeiro + ultimo nome]
# 1. ist1114476, António Cruz
# 2. ist1114249, Frederico Silva
# 3. ist1114295, Carolina Matias
#
# ===========================================================
# Descricao da ISA Implementada
#
#
# == Formato das Instrucoes ==
# O processador 8-bit Spike implementa três formatos distintos de instruções, todos com 8 bits, conforme a seguinte estrutura:
#
# -> Formato 1 — li (load immediate):
#
# Bits: 0 i i i i i i i
#
# Descrição: 1 bit para opcode (0) + 7 bits para o imediato com sinal (complemento para dois).
#
# Justificação: Este formato permite carregar um valor imediato positivo ou negativo diretamente no registrador R1, com alcance de -64 a 63.
#
#
# -> Formato 2 — addi e subi (add immediate e subtract immediate):
#
# Bits: 100 i i i i i (addi), 101 i i i i i (subi)
#
# Descrição: 3 bits para opcode (100 ou 101), seguido de 5 bits para imediato sem sinal (valor positivo entre 0 e 31).
#
# Justificação: Como estas instruções só aceitam imediatos positivos, o imediato é representado em formato unsigned.
#
# Nota: as instruções `addi 0` (0x80) e `subi 0` (0xA0) funcionam como NOPs, pois não alteram o estado de R1.
#
#
# -> Formato 3 — instruções fixas (abs e relu):
#
# Bits: 11000000 (abs), 11000001 (relu)
#
# Descrição: Opcode fixo de 8 bits.
#
# Justificação: Estas instruções não requerem valores imediatos.
#
#
#
# == Sumario dos Estagios do Pipeline ==
# 
# 1. Busca de Instrução (Instruction Fetch - IF):
#    - O Program Counter (PC) fornece o endereço da próxima instrução.
#    - A ROM 256x8 é acessada usando esse endereço para ler a instrução de 8 bits.
#    - Nota: o carry do somador do PC deve estar ativo para que o contador avance para a próxima instrução.
#
# 2. Decodificação e Extensão de Imediato (Instruction Decode - ID):
#    - A instrução é decodificada para identificar o opcode e extrair o imediato.
#    - O imediato de 5 ou 7 bits é estendido para 8 bits.
#    - Para a instrução `li`, o imediato é com sinal (usa complemento para dois).
#    - Para as instruções `addi` e `subi`, o imediato é sempre positivo e, por isso, o sign extend é feito com zeros à esquerda.
#    - Sinais de controlo são usados para selecionar operações e dados.
#
# 3. Execução (Execute - EX):
#    - Unidades operacionais realizam as operações necessárias:
#      - ALU para add/sub com R1 e imediato.
#      - Módulos (blocos de hardware) específicos para calcular abs e relu.
#    - Multiplexeres (MUXes) controlam a seleção das operações e dos dados.
#
# 4. Write Back (WB):
#    - O resultado final da operação é selecionado por um MUX de seleção final (MUX com a etiqueta MSF).
#    - O valor é escrito no registador R1.
#
#
# == Sinais de Controlo ==
# Existem 4 comparadores à saída da ROM que analisam os bits da instrução atual (vinda da ROM) e geram sinais de controlo.
# Esses sinais funcionam como bits de seleção para os 5 MUXes numerados no circuito. 
# O mesmo comparador pode ser usado para mais do que um MUX (MUXes 1 e 2). A correspondência é a seguinte:
#
# MUX 1 — Seleção da instrução `li`
# - Controlado por um comparador que verifica se o bit mais significativo (bit 7) é igual a 0.
# - Se for 0, a instrução é `li` e este MUX seleciona os 7 bits menos significativos da instrução, interpretados como imediato com sinal.
#
# MUX 2 — Seleção entre `li` e `addi/subi`
# - Usa o mesmo comparador do MUX 1.
# - Se o bit 7 for 0, seleciona li; se for 1, a seleção entre addi e subi é feita pelo MUX 3.
#
# MUX 3 — Seleção entre `addi` e `subi`
# - Controlado por um comparador que testa se os 3 bits mais significativos (bits [7:5]) são iguais a `100`.
# - Se sim, seleciona `addi`; senão, seleciona `subi`.
#
# MUX 4 — Seleção entre `abs` e `relu`
# - Controlado por um comparador que verifica se os 8 bits da instrução são `11000000`.
# - Se sim, seleciona `abs`; senão, assume `relu`.
#
# MUX 5 — MUX de Seleção Final (MSF)
# - Controlado por um comparador que testa se os 2 bits mais significativos (bits [7:6]) são iguais a `11`.
# - Se forem `11`, a instrução é `abs` ou `relu`; caso contrário, seleciona entre `li`, `addi` ou `subi` conforme os MUXes anteriores.
#
#
# ===========================================================
# Requisitos do enunciado que *nao* estao corretamente implementados:
# (indicar um por linha, ou responder "nenhum")
# - nenhum
#
# ===========================================================
# Top-3 das otimizacoes que a vossa solucao incorpora:
# (maximo 140 caracteres por cada otimizacao)
#
# 1. Modularização: unidades específicas para abs e relu, simplificando a ALU e melhorando o desempenho.
#
# 2. Minimização do número de portas lógicas, usando apenas o essencial para garantir a funcionalidade completa.
#
# 3. Extensão seletiva de imediato: zero extend (mais simples) para addi/subi, sign extend só quando necessário (li).
#
# ===========================================================
