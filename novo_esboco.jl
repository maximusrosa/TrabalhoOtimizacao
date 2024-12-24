module Otimizacao

export PRN, GPU, Solucao, vizinhanca, print_solucao

global const NUM_PRNs = 3
global const NUM_GPUs = 2
global const NUM_TIPOS = 2

mutable struct PRN
    id::Int
    gpu_id::Int
    custo::Int
    tipo::Int
end

mutable struct GPU
    id::Int
    num_tipos::Int
    capacidade::Int
end

struct Solucao
    listaPRN::Vector{PRN}
    listaGPU::Vector{GPU}
    contTipoGPU::Matrix{UInt8} # Matriz que indica quantidade de PRNs de um tipo em cada GPU.
    valorFuncObj::Int
end

function vizinhanca(listaPRN, listaGPU, contTipoGPU)
    for prn in listaPRN
        tipoPRN = prn.tipo
        id_gpu_origem = prn.gpu_id
        id_gpu_destino = (id_gpu_origem % 2) + 1 # Exemplo de novo GPU ID

        # Faz troca
        if contTipoGPU[tipoPRN, id_gpu_origem] == 1
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

            println("id_origem: ", id_gpu_origem)
            println("id_destino: ", id_gpu_destino)

            valorFuncObj = sum(gpu.num_tipos for gpu in listaGPU)
            return Solucao(listaPRN, listaGPU, contTipoGPU, valorFuncObj)
        end
    end
    # Nenhuma solução se aplicou a heurística
    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFuncObj)
end

function print_solucao(solucao::Solucao)
    println("PRNs:")
    for prn in solucao.listaPRN
        println("PRN ID: $(prn.id), Tipo: $(prn.tipo), GPU ID: $(prn.gpu_id), Custo: $(prn.custo)")
    end
    println("\nGPUs:")
    for gpu in solucao.listaGPU
        println("GPU ID: $(gpu.id), Num Tipos: $(gpu.num_tipos), Capacidade: $(gpu.capacidade)")
    end
    println("\nMatriz contTipoGPU:")
    println(solucao.contTipoGPU)
    println("\nValor da Função Objetivo: $(solucao.valorFuncObj)")
end

# Create test data
prn1 = PRN(1, 1, 10, 1)
prn2 = PRN(2, 2, 20, 1)
prn3 = PRN(3, 2, 30, 2)

gpu1 = GPU(1, 1, 100)
gpu2 = GPU(2, 2, 100)

listaPRN = [prn1, prn2, prn3]
listaGPU = [gpu1, gpu2]
contTipoGPU = UInt8[1 0; 1 1]

# Create initial solution
solucao_inicial = Solucao(listaPRN, listaGPU, contTipoGPU, 3)

# Print initial solution
println("Solução Inicial:")
print_solucao(solucao_inicial)

solucao = vizinhanca(listaPRN, listaGPU, contTipoGPU)
# Print solution after vizinhanca
println("\nSolução Após vizinhanca:")
print_solucao(solucao)

end # module