mutable struct PRN
    id::Int
    gpuID::Int
    custo::Int
    tipo::UInt8
end


mutable struct GPU
    id::Int
    numTipos::Int
    capacidadeRestante::Int
    listaIDsPRN::Vector{Int}
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
    valorFO::Int
end

function printSolucao(solucao::Solucao)
    println("Valor da Função Objetivo: ", solucao.valorFO)
    
    println("\nLista de GPUs:")
    for gpu in solucao.listaGPU
        println("GPU ID: $(gpu.id), Num Tipos: $(gpu.numTipos), Capacidade Restante: $(gpu.capacidadeRestante)")
    end
    
    println("\nLista de PRNs:")
    for prn in solucao.listaPRN
        println("PRN ID: $(prn.id), GPU ID: $(prn.gpuID), Custo: $(prn.custo), Tipo: $(prn.tipo)")
    end
    
    #println("\nMatriz contTipoGPU:")
    #println(solucao.contTipoGPU)
end