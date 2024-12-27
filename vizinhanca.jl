const global LIMITE_TENT_PRN = 20
const global LIMITE_TENT_GPU = 20
const global LIMITE_TENT_CAPACIDADE = 20
const global ERRO = -1

function escolhePRN(listaPRN, contTipoGPU)
    local prn
    local tipoPRN
    local gpuOrigemID
    global NUM_PRNs

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

function escolheGPUDestino(gpuOrigemID, prn, listaGPU, contTipoGPU)
    local gpuDestinoID
    local destTemTipo
    local temEspaco
    global NUM_GPUs

    tentativasGPU = 0
    while (tentativasGPU < LIMITE_TENT_GPU)
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [gpuOrigemID]))

        destTemTipo = contTipoGPU[gpuDestinoID, prn.tipo] > 0
        temEspaco = listaGPU[gpuDestinoID].capacidadeRestante >= prn.custo

        if (destTemTipo && temEspaco)
            #println("A PRN ", prn.id, " encontrou a GPU: ", gpuDestinoID, " pela heurística")
            break
        end
        tentativasGPU += 1
    end

    # Se não tiver encontrado uma GPU com capacidade para essa PRN, procura outras.
    tentativasGPU = 0
    while (!temEspaco && tentativasGPU < LIMITE_TENT_CAPACIDADE)
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [gpuOrigemID]))
        temEspaco = listaGPU[gpuDestinoID].capacidadeRestante >= prn.custo
        tentativasGPU += 1
    end

    if (!temEspaco)
        return ERRO
    else
        #if (tentativasGPU > 0 && temEspaco)
        #    println("A PRN ", prn.id, " encontrou a GPU: ", gpuDestinoID, " por tentativa de capacidade")
        #end
        return gpuDestinoID
    end
end

function vizinhanca(solucao)
    local prn
    local tipoPRN
    local gpuOrigemID
    local gpuDestinoID
    global NUM_GPUs

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
