const global LIMITE_TENT_PRN = 20
const global LIMITE_TENT_GPU = 20
const global LIMITE_TENT_CAPACIDADE = ceil(Int, NUM_GPUs / 2)

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
function escolheGPUDestino(id_gpu_origem, prn, listaGPU, contTipoGPU)
    local id_gpu_destino
    local temEspaco

    tentativasGPU = 0
    while (tentativasGPU < LIMITE_TENT_GPU)
        id_gpu_destino = rand(setdiff(1:NUM_GPUs, [id_gpu_origem]))

        prnIsolada = contTipoGPU[id_gpu_origem, prn.tipo] == 0
        temEspaco = listaGPU[id_gpu_destino].capacidadeRestante >= prn.custo

        if (!prnIsolada && temEspaco)
            break
        end
        tentativasGPU += 1
    end

    # Se não tiver encontrado uma GPU com capacidade para essa PRN, procura outras.
    tentativasGPU = 0
    while (!temEspaco && tentativasGPU < LIMITE_TENT_CAPACIDADE)
        id_gpu_destino = rand(setdiff(1:NUM_GPUs, [id_gpu_origem]))
        temEspaco = listaGPU[id_gpu_destino].capacidadeRestante >= prn.custo
        tentativasGPU += 1
    end

    if (!temEspaco)
        return ERRO
    else
        return id_gpu_destino
    end
end

function vizinhanca(solucao)
    local prn
    local tipoPRN
    local id_gpu_origem
    local id_gpu_destino

    listaPRN = deepcopy(solucao.listaPRN)
    listaGPU = deepcopy(solucao.listaGPU)
    contTipoGPU = deepcopy(solucao.contTipoGPU)

    tentativasMov = 0
    while true
        # Gera PRNs aleatórias e aplica heurística de escolha para troca.
        prn, tipoPRN, id_gpu_origem = escolhePRN(listaPRN, contTipoGPU)

        # Gera GPUs de destino aleatórias e tenta escolher uma que já tem o tipo da PRN, para melhorar a função objetivo.
        id_gpu_destino = escolheGPUDestino(id_gpu_origem, prn, listaGPU, contTipoGPU)
        
        if (id_gpu_destino != ERRO)
            println("Foi possível encontrar uma GPU de destino para a PRN ", prn.id)
            break
        end

        tentativasMov += 1
        # Não achou espaço para a PRN em nenhuma GPU
        if (tentativasMov > LIMITE_TENT_CAPACIDADE)
            #println("===============================================================")
            #println("Não foi possível encontrar uma GPU de destino para a PRN ", prn.id)
            return solucao
        end
    end

    # Muda GPU onde PRN está alocada
    prn.gpu_id = id_gpu_destino

    # Atualiza numero de tipos da GPU origem
    if contTipoGPU[id_gpu_origem, tipoPRN] == 1
        listaGPU[id_gpu_origem].num_tipos -= 1
    end

    # Atualiza numero de tipos da GPU destino
    if contTipoGPU[id_gpu_destino, tipoPRN] == 0
        listaGPU[id_gpu_destino].num_tipos += 1
    end

    # Atualiza na matriz nova quantidade de PRNs com tipoPRN na GPU
    contTipoGPU[id_gpu_origem, tipoPRN] -= 1
    contTipoGPU[id_gpu_destino, tipoPRN] += 1

    # Atualiza capacidades restantes das GPUs
    listaGPU[id_gpu_origem].capacidadeRestante += prn.custo
    listaGPU[id_gpu_destino].capacidadeRestante -= prn.custo

    #println("PRN: ", prn.id, ", de GPU: ", id_gpu_origem, " para GPU: ", id_gpu_destino)

    valorFuncObj = sum(gpu.num_tipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFuncObj)
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
