mutable struct PRN
    id::UInt16
    gpuID::UInt16
    custo::UInt8
    tipo::UInt8
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