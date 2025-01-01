if (!@isdefined(NUM_GPUs) || !@isdefined(NUM_PRNs))
    include("leitura.jl")
    filePath = "dog/dog_7.txt"
    n, V, T, m, listaGPU, listaPRN, contTipoGPU = lerArquivo(filePath)

    global NUM_GPUs = n
    global NUM_PRNs = m
end

const global LIMITE_TENT_PRN_ISOLADA = 100
const global LIMITE_TENT_GPU = 100
const global LIMITE_TENT_CAPACIDADE = 100
const global LIMITE_TENT_TROCA = 100
const global LIMITE_TENT_MOV = 100

const global ERRO = -1
const global NOT_FOUND = -1


function buscaPRNIsolada(listaPRN, contTipoGPU)
    local prn
    local tipoPRN
    local gpuOrigemID

    tentativasPRN = 0
    while (tentativasPRN < LIMITE_TENT_PRN_ISOLADA)
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


function escolhePRN(listaPRN, contTipoGPU)
    prn_isolada = buscaPRNIsolada(listaPRN, contTipoGPU)

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

function buscaGPUComTipo(listaGPU, prn)
    global NUM_GPUs
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

function escolheGPUDestino(prn, listaGPU)
    gpuComTipoID = buscaGPUComTipo(listaGPU, prn)

    if gpuComTipoID == NOT_FOUND
         return buscaGPUComCapacidade(listaGPU, prn)
    else
        return gpuComTipoID
    end
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
        tentativasMov += 1

        # Gera PRNs aleatórias e aplica heurística de escolha para troca.
        prn = escolhePRN(listaPRN, contTipoGPU)
        tipoPRN = prn.tipo
        gpuOrigemID = prn.gpuID

        # Gera GPUs de destino aleatórias e tenta escolher uma que já tem o tipo da PRN, para diminuir o valor da função objetivo.
        gpuDestinoID = escolheGPUDestino(prn, listaGPU)

        if (gpuDestinoID != NOT_FOUND)
            break
        end

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

function buscaPRNTroca(prn1, listaGPU, listaPRN)
    global NUM_GPUs
    local prn2
    local gpuDestinoID
    local tentativasTroca = 0

    while (tentativasTroca < LIMITE_TENT_TROCA)
        gpuDestinoID = rand(setdiff(1:NUM_GPUs, [prn1.gpuID]))

        for prn2Id in listaGPU[gpuDestinoID].listaIDsPRN
            prn2 = listaPRN[prn2Id]
            
            if prn2.tipo != prn1.tipo
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

function trocaPRNs(prn1, prn2, listaGPU, contTipoGPU)
    local tipoPRN1 = prn1.tipo
    local tipoPRN2 = prn2.tipo
    local gpuID1 = prn1.gpuID
    local gpuID2 = prn2.gpuID

    # Ensure gpuID is never set to zero
    if gpuID1 == 0 || gpuID2 == 0
        throw(ErrorException("Invalid GPU ID"))
    end

    # Muda GPU onde PRN está alocada
    prn1.gpuID = gpuID2
    prn2.gpuID = gpuID1
    
    # Adiciona PRN a lista de PRNs da GPU destino
    push!(listaGPU[gpuID2].listaIDsPRN, prn1.id)
    push!(listaGPU[gpuID1].listaIDsPRN, prn2.id)

    # Remove PRN da GPU origem
    indexPRN1 = findfirst(x -> x == prn1.id, listaGPU[gpuID1].listaIDsPRN)
    indexPRN2 = findfirst(x -> x == prn2.id, listaGPU[gpuID2].listaIDsPRN)

    if isnothing(indexPRN1)
        throw(ErrorException("Erro: PRN " * string(prn1.id) * " não encontrada na GPU de origem " * string(gpuID1)))
    end
    deleteat!(listaGPU[gpuID1].listaIDsPRN, indexPRN1)
    
    if isnothing(indexPRN2)
        throw(ErrorException("Erro: PRN " * string(prn2.id) * " não encontrada na GPU de destino " * string(gpuID2)))
    end
    deleteat!(listaGPU[gpuID2].listaIDsPRN, indexPRN2)

    # Atualiza numero de tipos da GPU origem
    if contTipoGPU[gpuID1, tipoPRN1] == 1
        listaGPU[gpuID1].numTipos -= 1
    end

    if contTipoGPU[gpuID1, tipoPRN2] == 0
        listaGPU[gpuID2].numTipos += 1
    end

    if contTipoGPU[gpuID2, tipoPRN2] == 1
        listaGPU[gpuID2].numTipos -= 1
    end

    if contTipoGPU[gpuID2, tipoPRN1] == 0
        listaGPU[gpuID2].numTipos += 1
    end

    # Atualiza na matriz nova quantidade de PRNs com tipoPRN na GPU
    contTipoGPU[gpuID1, tipoPRN1] -= 1
    contTipoGPU[gpuID2, tipoPRN1] += 1
    contTipoGPU[gpuID2, tipoPRN2] -= 1
    contTipoGPU[gpuID1, tipoPRN2] += 1

    # Atualiza capacidades restantes das GPUs
    listaGPU[gpuID1].capacidadeRestante += prn1.custo - prn2.custo
    listaGPU[gpuID2].capacidadeRestante += prn2.custo - prn1.custo

    #println("PRN: ", prn1.id
    
end


function vizinhancaTroca(solucao)
    local prn1
    local prn2
    local gpuDestinoID

    local listaPRN = deepcopy(solucao.listaPRN)
    local listaGPU = deepcopy(solucao.listaGPU)
    local contTipoGPU = deepcopy(solucao.contTipoGPU)

    tentativasMov = 0
    while true
        # Tentativa de inserção de PRN em GPU de destino
        prn1 = escolhePRN(listaPRN, contTipoGPU)

        if (prn1 == NOT_FOUND)
            throw(ErrorException("Não foi possível encontrar uma PRN"))
        end

        #gpuDestinoID = escolheGPUDestino(prn1, listaGPU)

        #if (gpuDestinoID == NOT_FOUND)
            #println("Não foi possível encontrar uma GPU de destino para a PRN ", prn1.id)
            #continue
        #end

        # Tentativa de troca de PRNs
        prn2 = buscaPRNTroca(prn1, listaGPU, listaPRN)

        if prn2 != NOT_FOUND
            trocaPRNs(prn1, prn2, listaGPU, contTipoGPU)
            break
        else
            println("Não foi possível fazer a troca da ", prn1.id)
            continue
        end

        tentativasMov += 1
        
        # Não conseguiu encontrar uma troca válida, dentro do limite de tentativas.
        if (tentativasMov > LIMITE_TENT_MOV)
            println("Não foi possível mover a PRN ", prn1.id)
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
