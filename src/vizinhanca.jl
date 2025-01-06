const global LIMITE_TENT_PRN_ISOLADA = 1000
const global LIMITE_TENT_GPU_COM_TIPO = 1000
const global LIMITE_TENT_CAPACIDADE = 1000

const global LIMITE_TENT_TROCA = 1000

const global LIMITE_TENT_MOV = 1000

const global NOT_FOUND = -1

# ==================== MOVE ==================== #

function limiteTentPRNIsolada(tempAtual)
    #limiteTent = round(limite_max * (tempAtual / TEMP_INCIAL))
    limiteTent = round(LIMITE_TENT_PRN_ISOLADA - tempAtual)

    if limiteTent < 50
        return 0
    else
        return limiteTent
    end
    
end

function buscaPRNIsolada(limiteHeuristPRN)
    global listaPRN
    global contTipoGPU
    local prn
    local tipoPRN
    local gpuOrigemID

    tentativas = 0
    while tentativas < limiteHeuristPRN
        prn = PRNAleatoria()
        tipoPRN = prn.tipo
        gpuOrigemID = prn.gpuID

        # Escolhe a PRN aleatória para fazer a troca se está 'isolada' em relação ao seu tipo.
        prnIsolada = contTipoGPU[gpuOrigemID, tipoPRN] == 1

        if prnIsolada
            return prn
        end

        tentativas += 1
    end

    return NOT_FOUND
end

function escolhePRN(limiteHeuristPRN)
    global listaPRN
    global contTipoGPU

    prnIsolada = buscaPRNIsolada(limiteHeuristPRN)

    if prnIsolada == NOT_FOUND
        return PRNAleatoria()
    else
        return prnIsolada
    end
end

function buscaGPUComTipo(prn)
    global listaGPU
    global contTipoGPU
    global NUM_GPUs
    local gpuDestinoID
    local temTipo
    local temEspaco
    local gpuOrigemID = prn.gpuID

    tentativas = 0
    while tentativas < LIMITE_TENT_GPU_COM_TIPO
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [gpuOrigemID]))
        
        temTipo = contTipoGPU[gpuDestinoID, prn.tipo] > 0
        temEspaco = listaGPU[gpuDestinoID].capacidadeRestante >= prn.custo

        if (temTipo && temEspaco)
            return gpuDestinoID
        end
        
        tentativas += 1
    end

    if (gpuDestinoID == prn.gpuID)
        throw(ErrorException("GPU de destino é a mesma da origem"))
    end  

    return NOT_FOUND
end

function buscaGPUComCapacidade(prn)
    global NUM_GPUs
    global listaGPU
    local gpuDestinoID
    local temEspaco

    tentativas = 0
    while tentativas < LIMITE_TENT_CAPACIDADE
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [prn.gpuID]))
        temEspaco = listaGPU[gpuDestinoID].capacidadeRestante >= prn.custo

        if temEspaco
            return gpuDestinoID
        else
            tentativas += 1
        end
    end

    return NOT_FOUND
end

function escolheGPUDestino(prn)
    global listaGPU
    global contTipoGPU

    gpuComTipoID = buscaGPUComTipo(prn)

    if gpuComTipoID == NOT_FOUND
         return buscaGPUComCapacidade(prn)
    else
        return gpuComTipoID
    end
end

function vizinhancaMove(solucao, limiteHeuristPRN)
    local prn
    local tipoPRN
    local gpuOrigemID
    local gpuDestinoID

    global listaPRN
    global listaGPU
    global contTipoGPU

    tentativasMov = 0
    while true
        tentativasMov += 1

        # Gera PRNs aleatórias e aplica heurística de escolha para troca.
        prn = escolhePRN(limiteHeuristPRN)
        tipoPRN = prn.tipo
        gpuOrigemID = prn.gpuID

        # Gera GPUs de destino aleatórias e tenta escolher uma que já tem o tipo da PRN, para diminuir o valor da função objetivo.
        gpuDestinoID = escolheGPUDestino(prn)

        if (gpuDestinoID != NOT_FOUND)
            break
        end

        # Não achou espaço para a PRN em nenhuma GPU
        if (tentativasMov > LIMITE_TENT_CAPACIDADE)
            println("Não foi possível encontrar uma GPU de destino para a PRN ", prn.id)
            return solucao
        end
    end

    gpuDestino = listaGPU[gpuDestinoID]
    
    movePRN(prn, gpuDestino)

    valorFO = sum(gpu.numTipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

# ==================== TROCA ==================== #

function escolheGPU2(prn)
    global listaGPU
    global contTipoGPU

    gpuComTipoID = buscaGPUComTipo(listaGPU, prn, contTipoGPU)

    if gpuComTipoID == NOT_FOUND
         return buscaGPUComCapacidade(prn)
    else
        return gpuComTipoID
    end
end

function buscaPRNTroca(prn1)
    global NUM_GPUs
    global listaGPU
    global listaPRN
    global contTipoGPU
    local prn2
    local tentativas = 0

    while tentativas < LIMITE_TENT_TROCA
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [prn1.gpuID]))
        #gpuDestinoID = escolheGPUDestino2(prn1)
        for prn2ID in listaGPU[gpuDestinoID].listaIDsPRN
            prn2 = listaPRN[prn2ID]
            
            if (prn2.tipo != prn1.tipo)
                espacoGPUOrigem = listaGPU[prn1.gpuID].capacidadeRestante + prn1.custo >= prn2.custo
                espacoGPUDestino = listaGPU[gpuDestinoID].capacidadeRestante + prn2.custo >= prn1.custo

                if espacoGPUOrigem && espacoGPUDestino
                    return prn2
                end
            end
        end

        tentativas += 1
    end

    return NOT_FOUND
end

function vizinhancaTroca(solucao, limiteHeuristPRN)
    local prn1
    local prn2
    local gpuDestinoID
    global listaPRN
    global listaGPU
    global contTipoGPU 

    tentativas = 0
    while true
        # Tentativa de inserção de PRN em GPU de destino
        prn1 = escolhePRN(limiteHeuristPRN)

        if (prn1 == NOT_FOUND)
            throw(ErrorException("Não foi possível encontrar uma PRN"))
        end

        # Tentativa de troca de PRNs
        prn2 = buscaPRNTroca(prn1)

        if prn2 != NOT_FOUND
            #println("Foi possível fazer a troca da ", prn1.id)
            trocaPRNs(prn1, prn2)
            break
        else
            #println("Não foi possível fazer a troca da ", prn1.id)
            continue
        end

        tentativas += 1
        
        # Não conseguiu encontrar uma troca válida, dentro do limite de tentativas.
        if (tentativas > LIMITE_TENT_TROCA)
            println("Não foi possível trocar a PRN ", prn1.id)
            return solucao
        end
        
    end

    valorFO = sum(gpu.numTipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end