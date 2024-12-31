const global LIMITE_TENT_PRN = 100
const global LIMITE_TENT_GPU = 100
const global LIMITE_TENT_CAPACIDADE = 100
const global ERRO = -1


function prnIsolada(listaPRN, contTipoGPU)
    local prn
    local tipoPRN
    local gpuOrigemID

    tentativasPRN = 0
    while (tentativasPRN <= LIMITE_TENT_PRN)
        prn = listaPRN[rand(1:NUM_PRNs)]
        tipoPRN = prn.tipo
        gpuOrigemID = prn.gpuID

        # Escolhe a PRN aleatória para fazer a troca se está 'isolada' em relação ao seu tipo.
        if (contTipoGPU[gpuOrigemID, tipoPRN] == 1)
            break
        end
        tentativasPRN += 1
    end

    return prn, tipoPRN, gpuOrigemID
end

function prnAleatoria(listaPRN, contTipoGPU)
    local prn
    local tipoPRN
    local gpuOrigemID

    prn = listaPRN[rand(1:NUM_PRNs)]
    tipoPRN = prn.tipo
    gpuOrigemID = prn.gpuID

    return prn, tipoPRN, gpuOrigemID
end


function escolhePRN(listaPRN, contTipoGPU)
    prn, tipoPRN, gpuOrigemID = prnIsolada(listaPRN, contTipoGPU)
    return prn, tipoPRN, gpuOrigemID
end


function gpuAleatoria(listaGPU)
    return listaGPU[rand(1:NUM_GPUs)].id
end

function gpuComTipo(listaGPU, prn)
    local gpuDestinoID
    local temTipo

    tentativasGPU = 0
    while (tentativasGPU < LIMITE_TENT_GPU)
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [prn.gpuID]))
        
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
    
    return ERRO
end


function escolheGPUDestino(gpuOrigemID, prn, listaGPU, contTipoGPU)
    local gpuDestinoID
    local temEspaco

    # Procura uma GPU de destino que já tenha o tipo da PRN
    gpuDestinoID = gpuComTipo(listaGPU, prn)

    if (gpuDestinoID != ERRO)
        return gpuDestinoID
    end
    
    # Se não tiver encontrado uma GPU com capacidade para essa PRN, procura outras.
    tentativasGPU = 0
    while (tentativasGPU < LIMITE_TENT_CAPACIDADE)
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [gpuOrigemID]))
        temEspaco = listaGPU[gpuDestinoID].capacidadeRestante >= prn.custo

        if (temEspaco)
            return gpuDestinoID
        else
            tentativasGPU += 1
        end
    end

    return ERRO
end

function vizinhanca(solucao)
    local prn
    local tipoPRN
    local gpuOrigemID
    local gpuDestinoID

    local listaPRN = deepcopy(solucao.listaPRN)
    local listaGPU = deepcopy(solucao.listaGPU)
    local contTipoGPU = deepcopy(solucao.contTipoGPU)

    tentativasMov = 0
    while true
        # Gera PRNs aleatórias e aplica heurística de escolha para troca.
        prn, tipoPRN, gpuOrigemID = escolhePRN(listaPRN, contTipoGPU)

        # Gera GPUs de destino aleatórias e tenta escolher uma que já tem o tipo da PRN, para diminuir o valor da função objetivo.
        gpuDestinoID = escolheGPUDestino(gpuOrigemID, prn, listaGPU, contTipoGPU)

        if (gpuDestinoID != ERRO)
            break
        end

        tentativasMov += 1
        # Não achou espaço para a PRN em nenhuma GPU
        if (tentativasMov > LIMITE_TENT_CAPACIDADE)
            println("Não foi possível encontrar uma GPU de destino para a PRN ", prn.id)
            return solucao
        end
    end

    # Muda GPU onde PRN está alocada
    prn.gpuID = gpuDestinoID

    # Adiciona PRN a lista de PRNs da GPU destino
    push!(listaGPU[gpuDestinoID].listaIDsPRN, prn.id)
    
    # Remove PRN da GPU origem
    indexPRN = findfirst(x -> x == prn.id, listaGPU[gpuOrigemID].listaIDsPRN)
    deleteat!(listaGPU[gpuOrigemID].listaIDsPRN, indexPRN)

    # Atualiza numero de tipos da GPU origem
    if contTipoGPU[gpuOrigemID, tipoPRN] == 1
        listaGPU[gpuOrigemID].numTipos -= 1
    end

    # Atualiza numero de tipos da GPU destino
    if contTipoGPU[gpuDestinoID, tipoPRN] == 0
        listaGPU[gpuDestinoID].numTipos += 1
    end

    # Atualiza na matriz nova quantidade de PRNs com tipoPRN na GPU
    contTipoGPU[gpuOrigemID, tipoPRN] -= 1
    contTipoGPU[gpuDestinoID, tipoPRN] += 1

    # Atualiza capacidades restantes das GPUs
    listaGPU[gpuOrigemID].capacidadeRestante += prn.custo
    listaGPU[gpuDestinoID].capacidadeRestante -= prn.custo

    #println("PRN: ", prn.id, ", de GPU: ", gpuOrigemID, " para GPU: ", gpuDestinoID)

    valorFO = sum(gpu.numTipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

function vizinhancaTroca(solucao)
    local prn1
    local prn2
    local tipoPRN
    local gpuOrigemID
    local gpuDestinoID

    local listaPRN = deepcopy(solucao.listaPRN)
    local listaGPU = deepcopy(solucao.listaGPU)
    local contTipoGPU = deepcopy(solucao.contTipoGPU)

    tentativasMov = 0
    while true
        # Gera PRNs aleatórias e aplica heurística de escolha para troca.
        prn1, tipoPRN, gpuOrigemID = escolhePRN(listaPRN, contTipoGPU)

        # Gera GPUs de destino aleatórias e tenta escolher uma que já tem o tipo da PRN, para diminuir o valor da função objetivo.
        gpuDestinoID = escolheGPUDestino(gpuOrigemID, prn1, listaGPU, contTipoGPU)

        if (gpuDestinoID == ERRO)
            continue;
        end

        prn2 = escolhePRNTroca(prn1, gpuOrigemID, gpuDestinoID)
        
        if (gpuDestinoID != ERRO && prn2 != ERRO)
            break
        end

        tentativasMov += 1
        
        # Não achou espaço para a PRN em nenhuma GPU
        if (tentativasMov > LIMITE_TENT_CAPACIDADE)
            println("Não foi possível encontrar uma troca para a PRN ", prn1.id)
            return solucao
        else
            println("Foi possível encontrar uma troca para a PRN ", prn1.id)
        end
    end

    if gpuDestinoID == ERRO
        throw(ErrorException("Erro ao escolher GPU de destino"))
    end

    if prn2 == ERRO
        throw(ErrorException("Erro ao escolher PRN para troca"))
    end
    
    #println("PRN2: ", prn2.id, " GPU da PRN2: ", prn2.gpuID, " GPU Destino: ", gpuDestinoID)

    #=
    localizada = 0
    for prnId in listaGPU[gpuDestinoID].listaIDsPRN
        if prnId == prn2.id
            println("PRN ", prn2.id, " localizada")
            localizada = 1
            break
        end
    end
    if localizada == 0
        println("PRN ", prn2.id, " não localizada")
    end
    =#

    try (
        indexPRN2 = findfirst(x -> x == prn2.id, listaGPU[gpuDestinoID].listaIDsPRN);
        deleteat!(listaGPU[gpuDestinoID].listaIDsPRN, indexPRN2)
    )
    catch e
        println("========================================================================")
        println("Erro: PRN ", prn2.id, " não encontrada na GPU de destino ", gpuDestinoID)
        println("GPU da PRN: ", prn2.gpuID)
        throw(e)
    end

    # Verificação de depuração
    println("Antes de adicionar: GPU Destino: ", listaGPU[gpuDestinoID].listaIDsPRN)

    # Muda GPU onde PRN está alocada
    listaPRN[prn1.id].gpuID = gpuDestinoID
    listaPRN[prn2.id].gpuID = gpuOrigemID

    # Adiciona PRN a lista de PRNs da GPU origem e destino
    #println("Antes do push! GPU Destino: ", listaGPU[gpuDestinoID].listaIDsPRN)
    push!(listaGPU[gpuDestinoID].listaIDsPRN, prn1.id)
    #println("Depois do push! GPU Destino: ", listaGPU[gpuDestinoID].listaIDsPRN)
    
    push!(listaGPU[gpuOrigemID].listaIDsPRN, prn2.id)

    # Remove PRN da GPU origem
    indexPRN = findfirst(x -> x == prn1.id, listaGPU[gpuOrigemID].listaIDsPRN)
    deleteat!(listaGPU[gpuOrigemID].listaIDsPRN, indexPRN)

    #indexPRN2 = findfirst(x -> x == prn2.id, listaGPU[gpuDestinoID].listaIDsPRN)
    #println("Antes do deleteat! GPU Destino: ", listaGPU[gpuDestinoID].listaIDsPRN)
    #deleteat!(listaGPU[gpuDestinoID].listaIDsPRN, indexPRN2)
    #println("Depois do deleteat! GPU Destino: ", listaGPU[gpuDestinoID].listaIDsPRN)

    # Atualiza numero de tipos da GPU origem
    if contTipoGPU[gpuOrigemID, tipoPRN] == 1
        listaGPU[gpuOrigemID].numTipos -= 1
    end
    
    if contTipoGPU[gpuOrigemID, prn2.tipo] == 0
        listaGPU[gpuOrigemID].numTipos += 1
    end

    
    # Atualiza numero de tipos da GPU destino
    if contTipoGPU[gpuDestinoID, tipoPRN] == 0
        listaGPU[gpuDestinoID].numTipos += 1
    end

    if contTipoGPU[gpuDestinoID, prn2.tipo] == 1
        listaGPU[gpuDestinoID].numTipos -= 1
    end

    # Atualiza na matriz nova quantidade de PRNs com tipoPRN na GPU
    contTipoGPU[gpuOrigemID, tipoPRN] -= 1
    contTipoGPU[gpuDestinoID, prn2.tipo] -= 1
    contTipoGPU[gpuDestinoID, tipoPRN] += 1
    contTipoGPU[gpuOrigemID, prn2.tipo] += 1

    # Atualiza capacidades restantes das GPUs
    listaGPU[gpuOrigemID].capacidadeRestante += prn1.custo
    listaGPU[gpuDestinoID].capacidadeRestante += prn2.custo
    listaGPU[gpuDestinoID].capacidadeRestante -= prn1.custo
    listaGPU[gpuOrigemID].capacidadeRestante -= prn2.custo

    #println("PRN: ", prn.id, ", de GPU: ", gpuOrigemID, " para GPU: ", gpuDestinoID)

    valorFO = sum(gpu.numTipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

function escolhePRNTroca(prn1, gpuOrigemID, gpuDestinoID)
    local prn2
    
    for prn2ID in listaGPU[gpuDestinoID].listaIDsPRN
        # Busca uma PRN de outro tipo para fazer a troca
        if listaPRN[prn2ID].tipo != listaPRN[prn1.id].tipo
            espacoGPUOrigem = listaGPU[gpuOrigemID].capacidadeRestante + prn1.custo >= listaPRN[prn2ID].custo
            # Se tem espaço para a prn2 na gpu destino escolhe prn2 para troca
            if espacoGPUOrigem
                prn2 = listaPRN[prn2ID]
                if (isnothing(findfirst(x -> x == prn2.id, listaGPU[gpuDestinoID].listaIDsPRN)))
                    throw(ErrorException("PRN não encontrada na GPU de destino"))
                end
                return prn2
            end
        end
    end
    
    return ERRO
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
