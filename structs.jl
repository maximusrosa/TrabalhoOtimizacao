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
end

mutable struct Solucao
    listaPRN::Vector{PRN}
    listaGPU::Vector{GPU}
    contTipoGPU::Matrix{UInt8} # Matriz que indica quantidade de PRNs de um tipo em cada GPU.
    valorFO::Int
end