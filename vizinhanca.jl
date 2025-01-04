const global LIMITE_TENT_PRN_ISOLADA = 1000
const global LIMITE_TENT_GPU_COM_TIPO = 1000
const global LIMITE_TENT_CAPACIDADE = 1000

const global LIMITE_TENT_TROCA = 1000

const global LIMITE_TENT_MOV = 1000

const global NOT_FOUND = -1


function buscaPRNIsolada(listaPRN, contTipoGPU, limiteHeuristPRN)
    local prn
    local tipoPRN
    local gpuOrigemID

    tentativasPRN = 0
    
    while (tentativasPRN < limiteHeuristPRN)
        prn = PRNAleatoria(listaPRN)
        tipoPRN = prn.tipo
        gpuOrigemID = prn.gpuID

        # Escolhe a PRN aleatória para fazer a troca se está 'isolada' em relação ao seu tipo.
        if (contTipoGPU[gpuOrigemID, tipoPRN] == 1)
            return prn
        end
        tentativasPRN += 1
    end

    return NOT_FOUND
end

function PRNAleatoria(listaPRN)
    global NUM_PRNs

    return listaPRN[rand(1:NUM_PRNs)]
end


function escolhePRN(listaPRN, contTipoGPU, limiteHeuristPRN)
    prn_isolada = buscaPRNIsolada(listaPRN, contTipoGPU, limiteHeuristPRN)

    if prn_isolada == NOT_FOUND
        return PRNAleatoria(listaPRN)
    else
        return prn_isolada
    end
end


function GPUAleatoria(listaGPU)
    global NUM_GPUs

    return listaGPU[rand(1:NUM_GPUs)].id
end

function buscaGPUComTipo(listaGPU, prn, contTipoGPU)
    global NUM_GPUs
    local gpuDestinoID
    local temTipo
    local temEspaco
    local gpuOrigemID = prn.gpuID

    tentativasGPU = 0
    while (tentativasGPU < LIMITE_TENT_GPU_COM_TIPO)
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [gpuOrigemID]))
        
        temTipo = contTipoGPU[gpuDestinoID, prn.tipo] > 0
        temEspaco = listaGPU[gpuDestinoID].capacidadeRestante >= prn.custo

        if (temTipo && temEspaco)
            return gpuDestinoID
        end
        
        tentativasGPU += 1
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

    tentativasGPU = 0
    while (tentativasGPU < LIMITE_TENT_CAPACIDADE)
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [prn.gpuID]))
        temEspaco = listaGPU[gpuDestinoID].capacidadeRestante >= prn.custo

        if (temEspaco)
            return gpuDestinoID
        else
            tentativasGPU += 1
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

function escolheGPUTroca(prn, listaGPU, contTipoGPU)
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

function buscaPRNTroca(prn1, listaGPU, listaPRN, contTipoGPU)
    global NUM_GPUs
    local prn2
    local tentativasTroca = 0

    while (tentativasTroca < LIMITE_TENT_TROCA)
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [prn1.gpuID]))
        #gpuDestinoID = escolheGPUDestino(prn1, listaGPU, contTipoGPU)
        for prn2Id in listaGPU[gpuDestinoID].listaIDsPRN
            prn2 = listaPRN[prn2Id]
            
            if (prn2.tipo != prn1.tipo)
                espacoGPUOrigem = listaGPU[prn1.gpuID].capacidadeRestante + prn1.custo >= prn2.custo
                espacoGPUDestino = listaGPU[gpuDestinoID].capacidadeRestante + prn2.custo >= prn1.custo

                if espacoGPUOrigem && espacoGPUDestino
                    return prn2
                end
            end
        end

        tentativasTroca += 1
    end

    return NOT_FOUND
end

function movePRN(prn, gpuDestino, listaGPU, contTipoGPU)
    local tipoPRN = prn.tipo
    local gpuOrigemID = prn.gpuID
    local gpuDestinoID = gpuDestino.id

    # Ensure gpuID is never set to zero
    if gpuOrigemID == 0 || gpuDestinoID == 0
        throw(ErrorException("Invalid GPU ID"))
    end

    # Muda GPU onde PRN está alocada
    prn.gpuID = gpuDestinoID

    # Adiciona PRN a lista de PRNs da GPU destino
    push!(listaGPU[gpuDestinoID].listaIDsPRN, prn.id)

    # Remove PRN da GPU origem
    indexPRN = findfirst(x -> x == prn.id, listaGPU[gpuOrigemID].listaIDsPRN)
    if isnothing(indexPRN)
        throw(ErrorException("Erro: PRN " * string(prn.id) * " não encontrada na GPU de origem " * string(gpuOrigemID)))
    end
    deleteat!(listaGPU[gpuOrigemID].listaIDsPRN, indexPRN)

    # Atualiza numero de tipos da GPU origem
    prnIsoladaOrigem = contTipoGPU[gpuOrigemID, tipoPRN] == 1
    if prnIsoladaOrigem
        listaGPU[gpuOrigemID].numTipos -= 1
    end

    # Atualiza numero de tipos da GPU destino
    prnIsoladaDestino = contTipoGPU[gpuDestinoID, tipoPRN] == 0
    if prnIsoladaDestino
        listaGPU[gpuDestinoID].numTipos += 1
    end

    # Atualiza na matriz nova quantidade de PRNs com tipoPRN na GPU
    contTipoGPU[gpuOrigemID, tipoPRN] -= 1
    contTipoGPU[gpuDestinoID, tipoPRN] += 1

    # Atualiza capacidades restantes das GPUs
    listaGPU[gpuOrigemID].capacidadeRestante += prn.custo
    listaGPU[gpuDestinoID].capacidadeRestante -= prn.custo
end


function trocaPRNs(prn1, prn2, listaGPU, contTipoGPU)
    local gpu1 = listaGPU[prn1.gpuID]
    local gpu2 = listaGPU[prn2.gpuID]

    if prn1 == prn2
        throw(ErrorException("Erro: PRNs iguais"))
    end

    movePRN(prn1, gpu2, listaGPU, contTipoGPU)
    movePRN(prn2, gpu1, listaGPU, contTipoGPU)
end

function vizinhancaTroca(solucao, limiteHeuristPRN)
    local prn1
    local prn2
    local gpuDestinoID

    local listaPRN = deepcopy(solucao.listaPRN)
    local listaGPU = deepcopy(solucao.listaGPU)
    local contTipoGPU = deepcopy(solucao.contTipoGPU)

    tentativasMov = 0
    while true
        # Tentativa de inserção de PRN em GPU de destino
        prn1 = escolhePRN(listaPRN, contTipoGPU, limiteHeuristPRN)

        if (prn1 == NOT_FOUND)
            throw(ErrorException("Não foi possível encontrar uma PRN"))
        end

        # Tentativa de troca de PRNs
        prn2 = buscaPRNTroca(prn1, listaGPU, listaPRN, contTipoGPU)

        if prn2 != NOT_FOUND
            #println("Foi possível fazer a troca da ", prn1.id)
            trocaPRNs(prn1, prn2, listaGPU, contTipoGPU)
            break
        else
            #println("Não foi possível fazer a troca da ", prn1.id)
            continue
        end

        tentativasMov += 1
        
        # Não conseguiu encontrar uma troca válida, dentro do limite de tentativas.
        if (tentativasMov > LIMITE_TENT_MOV)
            println("Não foi possível trocar a PRN ", prn1.id)
            return solucao
        end
        
    end

    valorFO = sum(gpu.numTipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end


function print_solucao(solucao)
    println("PRNs:")
    for prn in solucao.listaPRN
        println("PRN ID: $(prn.id), Tipo: $(prn.tipo), GPU ID: $(prn.gpuID), Custo: $(prn.custo)")
    end
    println("\nGPUs:")
    for gpu in solucao.listaGPU
        println("GPU ID: $(gpu.id), Num Tipos: $(gpu.numTipos), Capacidade: $(gpu.capacidadeRestante)")
    end
    println("\nMatriz contTipoGPU:")
    println(solucao.contTipoGPU)
    println("\nValor da Função Objetivo: $(solucao.valorFO)")
end
