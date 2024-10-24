# ------- Representação -------- #

# Struct de tipo
struct Tipo
    id::Int
    num_gpus::Int
end

# Vetor de tipos
typeList = []

# Struct de PRN
struct PRN
    gpu_id::Int
    cost::Float64
    type_id::Int
end

# Vetor de PRN
PRNList = []

# Cálculo da função objetivo
function calcular_funcao_objetivo(tipos)
    sum = 0
    for tipo in tipos
        sum += tipo.num_gpus
    end
    return sum
end

# Solução Inicial
# Iterar item por item e alocar item atual na primeira mochila com espaço suficiente.
function solucao_inicial(prns, gpus)
    for prn in prns
        for (i, gpu) in enumerate(gpus)
            if gpu >= prn.cost
                prn.gpu_id = i
                gpus[i] -= prn.cost
                break
            end
        end
    end
end

# Vetor de GPUs que armazena capacidade restante
GPUList = []

# Atualizando GPU ao retirar PRN
function atualizar_gpu_remove(prn, gpus)
    gpus[prn.gpu_id] -= prn.cost
end

# Atualizando GPU ao adicionar PRN
function atualizar_gpu_add(prn, gpus)
    gpus[prn.gpu_id] += prn.cost
end


# ------- Função de vizinhança ------- #

