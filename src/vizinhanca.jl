const global LIMITE_TENT_PRN_ISOLADA = 1000
const global LIMITE_TENT_GPU_COM_TIPO = 1000
const global LIMITE_TENT_CAPACIDADE = 1000

const global LIMITE_TENT_MOV = 1000

const global NOT_FOUND = -1


function limiteTentPRNIsolada(tempAtual)
    #limiteTent = round(limite_max * (tempAtual / TEMP_INCIAL))
    limiteTent = round(LIMITE_TENT_PRN_ISOLADA - tempAtual)

    if limiteTent < 50
        return 0
    else
        return limiteTent
    end
    
end

function buscaPRNIsolada(listaPRN, contTipoGPU, limiteHeuristPRN)
    local prn
    local tipoPRN
    local gpuOrigemID

    tentativas = 0
    while (tentativas < limiteHeuristPRN)
        prn = PRNAleatoria(listaPRN)
        tipoPRN = prn.tipo
        gpuOrigemID = prn.gpuID

        # Escolhe a PRN aleatória para fazer a troca se está 'isolada' em relação ao seu tipo.
        if (contTipoGPU[gpuOrigemID, tipoPRN] == 1)
            return prn
        end
        tentativas += 1
    end

    return NOT_FOUND
end

function escolhePRN(listaPRN, contTipoGPU, limiteHeuristPRN)
    prnIsolada = buscaPRNIsolada(listaPRN, contTipoGPU, limiteHeuristPRN)

    if prnIsolada == NOT_FOUND
        return PRNAleatoria(listaPRN)
    else
        return prnIsolada
    end
end

function buscaGPUComTipo(listaGPU, prn, contTipoGPU)
    global NUM_GPUs
    local gpuDestinoID
    local temTipo
    local temEspaco
    local gpuOrigemID = prn.gpuID

    tentativas = 0
    while (tentativas < LIMITE_TENT_GPU_COM_TIPO)
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

function buscaGPUComCapacidade(listaGPU, prn)
    global NUM_GPUs
    local gpuDestinoID
    local temEspaco

    tentativas = 0
    while (tentativas < LIMITE_TENT_CAPACIDADE)
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [prn.gpuID]))
        temEspaco = listaGPU[gpuDestinoID].capacidadeRestante >= prn.custo

        if (temEspaco)
            return gpuDestinoID
        else
            tentativas += 1
        end
    end

    return NOT_FOUND
end

function escolheGPUDestino(prn, listaGPU, contTipoGPU)
    gpuComTipoID = buscaGPUComTipo(listaGPU, prn, contTipoGPU)

    if gpuComTipoID == NOT_FOUND
         return buscaGPUComCapacidade(listaGPU, prn)
    else
        return gpuComTipoID
    end
end

function vizinhancaMove(solucao, limiteHeuristPRN)
    local prn
    local tipoPRN
    local gpuOrigemID
    local gpuDestinoID

    local listaPRN = deepcopy(solucao.listaPRN)
    local listaGPU = deepcopy(solucao.listaGPU)
    local contTipoGPU = deepcopy(solucao.contTipoGPU)

    tentativasMov = 0
    while true
        tentativasMov += 1

        # Gera PRNs aleatórias e aplica heurística de escolha para troca.
        prn = escolhePRN(listaPRN, contTipoGPU, limiteHeuristPRN)
        tipoPRN = prn.tipo
        gpuOrigemID = prn.gpuID

        # Gera GPUs de destino aleatórias e tenta escolher uma que já tem o tipo da PRN, para diminuir o valor da função objetivo.
        gpuDestinoID = escolheGPUDestino(prn, listaGPU, contTipoGPU)

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
    
    movePRN(prn, gpuDestino, listaGPU, contTipoGPU)

    valorFO = sum(gpu.numTipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end