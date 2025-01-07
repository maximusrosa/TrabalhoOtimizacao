mutable struct PRN
    id::UInt16
    gpuID::UInt16
    custo::UInt8
    tipo::UInt8
end

function PRNAleatoria(listaPRN)
    global NUM_PRNs

    return listaPRN[rand(1:NUM_PRNs)]
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

mutable struct GPU
    id::UInt16
    numTipos::UInt8
    capacidadeRestante::UInt16
    listaIDsPRN::Vector{UInt16}
end

function addPRN(gpu::GPU, prn::PRN, contTipoGPU::Matrix{UInt8})
    temTipo = contTipoGPU[gpu.id, prn.tipo] > 0

    prn.gpuID = gpu.id
    push!(gpu.listaIDsPRN, prn.id)
    gpu.capacidadeRestante -= prn.custo

    if (!temTipo)
        gpu.numTipos += 1
    end
    contTipoGPU[gpu.id, prn.tipo] += 1
end


mutable struct Solucao
    listaPRN::Vector{PRN}
    listaGPU::Vector{GPU}
    contTipoGPU::Matrix{UInt8} # Matriz que indica quantidade de PRNs de um tipo em cada GPU.
    valorFO::UInt16
end

function printSolucao(solucao::Solucao)
    println("Valor da Função Objetivo: ", solucao.valorFO)
    
    println("\nLista de GPUs:")
    for gpu in solucao.listaGPU
        println("GPU ID: $(Int(gpu.id)), Num Tipos: $(Int(gpu.numTipos)), Capacidade Restante: $(Int(gpu.capacidadeRestante))")
    end
    
    println("\nLista de PRNs:")
    for prn in solucao.listaPRN
        println("PRN ID: $(Int(prn.id)), GPU ID: $(Int(prn.gpuID)), Custo: $(Int(prn.custo)), Tipo: $(Int(prn.tipo))")
    end
    
    println("\nMatriz contTipoGPU (GPU x Tipo):")
    for i in 1:size(solucao.contTipoGPU, 1)
        println(Int.(solucao.contTipoGPU[i, :]))
    end
end