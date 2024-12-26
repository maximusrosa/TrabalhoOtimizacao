const global LIMITE_TENT_PRN = 20
const global LIMITE_TENT_GPU = 20
const global LIMITE_TENT_CAPACIDADE = 20

const global ERRO = -1

# Gera PRNs aleatórias e aplica heurística de escolha para troca.
function escolhePRN(listaPRN, contTipoGPU)
    local prn
    local tipoPRN
    local id_gpu_origem

    tentativasPRN = 0
    while (tentativasPRN <= LIMITE_TENT_PRN)
        prn = listaPRN[rand(1:end)]
        tipoPRN = prn.tipo
        id_gpu_origem = prn.gpu_id

        # Escolhe a PRN aleatória para fazer a troca se está 'isolada' em relação ao seu tipo.
        if (contTipoGPU[id_gpu_origem, tipoPRN] == 1)
            break
        end
        tentativasPRN += 1
    end

    return prn, tipoPRN, id_gpu_origem
end

# Gera GPUs de destino aleatórias e tenta escolher uma que já tem o tipo da PRN, para melhorar a função objetivo.
function escolheGPUDestino(gpuOrigemID, prn, listaGPU, contTipoGPU, numGPUs)
    local gpuDestinoID
    local temEspaco

    tentativasGPU = 0
    while (tentativasGPU < LIMITE_TENT_GPU)
        gpuDestinoID = rand(setdiff(1:numGPUs, [gpuOrigemID]))

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
        gpuDestinoID = rand(setdiff(1:numGPUs, [gpuOrigemID]))
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

function vizinhanca(solucao, numGPUs)
    local prn
    local tipoPRN
    local id_gpu_origem
    local gpuDestinoID

    listaPRN = deepcopy(solucao.listaPRN)
    listaGPU = deepcopy(solucao.listaGPU)
    contTipoGPU = deepcopy(solucao.contTipoGPU)

    tentativasMov = 0
    while true
        # Gera PRNs aleatórias e aplica heurística de escolha para troca.
        prn, tipoPRN, id_gpu_origem = escolhePRN(listaPRN, contTipoGPU)

        # Gera GPUs de destino aleatórias e tenta escolher uma que já tem o tipo da PRN, para melhorar a função objetivo.
        gpuDestinoID = escolheGPUDestino(id_gpu_origem, prn, listaGPU, contTipoGPU, numGPUs)
        
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
    prn.gpu_id = gpuDestinoID

    # Adiciona PRN a lista de PRNs da GPU destino
    push!(listaGPU[gpuDestinoID].listaIDsPRN, prn.id)
    
    # Remove PRN da GPU origem
    indexPRN = findfirst(x -> x == prn.id, listaGPU[id_gpu_origem].listaIDsPRN)
    deleteat!(listaGPU[id_gpu_origem].listaIDsPRN, indexPRN)

    # Atualiza numero de tipos da GPU origem
    if contTipoGPU[id_gpu_origem, tipoPRN] == 1
        listaGPU[id_gpu_origem].num_tipos -= 1
    end

    # Atualiza numero de tipos da GPU destino
    if contTipoGPU[gpuDestinoID, tipoPRN] == 0
        listaGPU[gpuDestinoID].num_tipos += 1
    end

    # Atualiza na matriz nova quantidade de PRNs com tipoPRN na GPU
    contTipoGPU[id_gpu_origem, tipoPRN] -= 1
    contTipoGPU[gpuDestinoID, tipoPRN] += 1

    # Atualiza capacidades restantes das GPUs
    listaGPU[id_gpu_origem].capacidadeRestante += prn.custo
    listaGPU[gpuDestinoID].capacidadeRestante -= prn.custo

    #println("PRN: ", prn.id, ", de GPU: ", id_gpu_origem, " para GPU: ", gpuDestinoID)

    valorFO = sum(gpu.num_tipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end


function print_solucao(solucao)
    println("PRNs:")
    for prn in solucao.listaPRN
        println("PRN ID: $(prn.id), Tipo: $(prn.tipo), GPU ID: $(prn.gpu_id), Custo: $(prn.custo)")
    end
    println("\nGPUs:")
    for gpu in solucao.listaGPU
        println("GPU ID: $(gpu.id), Num Tipos: $(gpu.num_tipos), Capacidade: $(gpu.capacidadeRestante)")
    end
    println("\nMatriz contTipoGPU:")
    println(solucao.contTipoGPU)
    println("\nValor da Função Objetivo: $(solucao.valorFO)")
end

export vizinhanca, print_solucao
