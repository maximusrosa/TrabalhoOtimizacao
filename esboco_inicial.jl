# ------- Representação -------- #

global MAX_STAGNANT_ITER = 1000
global NUM_GPUs = 100
global INITIAL_CAPACITY = 12
global NUM_TIPOS = 81

# Struct de tipo
struct Tipo
    id::Int
    num_gpus::Int
end

# Vetor de tipos
typeList = Vector{Tipo}(undef, NUM_TIPOS)

# Struct de PRN
struct PRN
    id::Int
    gpu_id::Int
    cost:: Int
    type_id::Int
end

# Struct de GPU
struct GPU
    capacity::Int
    prn_list::Vector{PRN}
end

# Cálculo da função objetivo
function funcao_objetivo(tipos)
    sum = 0
    for tipo in tipos
        sum += tipo.num_gpus
    end
    return sum
end

# Criando um vetor de GPUs com capacidade inicial
gpus = [GPU(capacity=INITIAL_CAPACITY, prn_list=Vector{PRN}()) for gpus in 1:NUM_GPUs]

# Solução Inicial
# Iterar item por item e alocar item atual na primeira GPU com espaço suficiente.
function initial_solution(prns, gpus)
    for prn in prns
        for (i, gpu) in enumerate(gpus)
            if gpu.capacity >= prn.cost
                prn.gpu_id = i
                gpus[i].capacity -= prn.cost
                break
            end
        end
    end
end


# Inicializa quantia de GPU's que cada tipo utiliza, para fazer isso adiciona tipos a um conjunto de forma que não há repetições e então adiciona 1 ao num_gpus de cada tipo presente em cada GPU.
function update_typeList(gpus)
    # Cria um conjunto para evitar repetições de tipos presentes em cada GPU
    for gpu in gpus
        tipos_presentes = Set{Int}()
        for prn in gpu.prn_list
            push!(tipos_presentes, prn.type_id)
        end
        for tipo_id in tipos_presentes
            typeList[tipo_id].num_gpus += 1
        end
    end
end


# Atualizando GPU ao retirar PRN
function remove_prn(GPU_ID, prn)
    gpus[GPU_ID].capacity -= prn.cost
    deleteat!(gpus[GPU_ID].prn_list, findfirst(x -> x.id == prn.id, gpus[GPU_ID].prn_list))
    # Tipo não existe mais na GPU de origem, portanto distribuição do tipo diminui.
    typeList[prn.type_id].num_gpus -= 1
end

# Atualizando GPU ao adicionar PRN
function add_prn(GPU_ID, prn)
    gpus[GPU_ID].capacity += prn.cost
    push!(gpus[GPU_ID].prn_list, prn)
end


# ------- Função de vizinhança ------- #
# Trocar PRNs entre GPUs, se a PRN1 for a única daquele tipo na GPU de origem.

function vizinhanca(prns)
    for prn1 in prns
        # Verifica se a PRN1 é o único do seu tipo na GPU atual (gpu_origem)
        tipo_prn1 = prn1.type_id
        gpu_origem = gpus[prn1.gpu_id]
        
        num_tipos_iguais_origem = count(p -> p.type_id == tipo_prn1, gpu_origem.prn_list)

        # Se PRN1 for o único daquele tipo na GPU de origem
        if num_tipos_iguais_origem == 1
            # Executa até encontrar uma PRN2 válida para troca.
            for prn2 in prns
                # Evitar trocar um PRN com outro do mesmo tipo e garantir que eles estejam em GPUs diferentes
                if prn1.gpu_id != prn2.gpu_id
                    gpu_destino = gpus[prn2.gpu_id]
                    
                    # Verificar se há capacidade na GPU de destino para receber o PRN1
                    if gpu_destino.capacity >= prn1.cost && gpu_origem.capacity + prn1.cost >= prn2.cost
                        # Condição satisfeita, realizar a troca

                        # Atualizar capacidades
                        gpus[prn1.gpu_id].capacity += prn1.cost  # Remove PRN1 da GPU de origem
                        gpus[prn2.gpu_id].capacity -= prn1.cost  # Adiciona PRN1 na GPU de destino
                        gpus[prn2.gpu_id].capacity += prn2.cost  # Remove PRN2 da GPU de destino
                        gpus[prn1.gpu_id].capacity -= prn2.cost  # Adiciona PRN2 na GPU de origem

                        # Atualizar as listas de PRNs nas GPUs
                        remove_prn(prn1.gpu_id, prn1)
                        remove_prn(prn2.gpu_id, prn2)
                        add_prn(prn1.gpu_id, prn2)
                        add_prn(prn2.gpu_id, prn1)

                        # Atualizar IDs das GPUs nos PRNs
                        prn1.gpu_id, prn2.gpu_id = prn2.gpu_id, prn1.gpu_id

                        # Realizou a troca, então podemos parar a busca para esses PRNs
                        break
                    end
                end
            end
        end
    end
end


# Função para o Algoritmo de Metropolis
function metropolis(s, T, melhor_sol, gpus)
    count = 0
    while (count <= MAX_STAGNANT_ITER)
        # Seleciona um vizinho s' aleatoriamente da vizinhança N(s)
        s_linha = vizinhanca(s, gpus)
        
        # Calcula a diferença de custo/valor entre a solução vizinha
        delta = funcao_objetivo(s_linha) - funcao_objetivo(s)
        
        # Se a solução vizinha for melhor, ou seja, levar a um valor da função objetivo menor (delta <= 0), atualiza s.
        if delta <= 0
            s = s_linha
            melhor_sol = s
            count = 0
        else
            # Caso contrário, atualiza com uma certa probabilidade
            probabilidade = exp(-delta / T)
            if rand() < probabilidade
                s = s_linha
            end
            count += 1
        end
    end
    
    # Retorna a solução final após certa quantia de iterações (MAX_STAGNANT_ITER) não causarem melhora na função objetivo.
    return melhor_sol
end


function simulated_annealing(s, T, alpha, temperatura_minima)
    melhor_sol = s  # Inicializa melhor_sol com a solução inicial
    while T > temperatura_minima
        melhor_sol = metropolis(s, T, melhor_sol, gpus)
        T = alpha * T
    end
    return melhor_sol  # Retorna a melhor solução encontrada, quando T chegar a uma temperatura minima.
end


