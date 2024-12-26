mutable struct PRN
    id::Int
    gpu_id::Int
    custo::Int
    tipo::Int
end

mutable struct GPU
    id::Int
    num_tipos::Int
    capacidadeRestante::Int
    listaIDsPRN::Vector{Int}
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
        println("GPU ID: $(gpu.id), Num Tipos: $(gpu.num_tipos), Capacidade Restante: $(gpu.capacidadeRestante)")
    end
    
    println("\nLista de PRNs:")
    for prn in solucao.listaPRN
        println("PRN ID: $(prn.id), GPU ID: $(prn.gpu_id), Custo: $(prn.custo), Tipo: $(prn.tipo)")
    end
    
    #println("\nMatriz contTipoGPU:")
    #println(solucao.contTipoGPU)
end