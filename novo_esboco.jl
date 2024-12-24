global NUM_PRNs;
global NUM_GPUs;
global NUM_TIPOS;


struct PRN
    id::Int
    gpu_id::Int
    custo:: Int
    tipo::Int
end

struct GPU
    id::Int
    num_tipos::Int
    capacidade:: Int
end

struct Solucao
    listaPRN :: Vector{PRN}(undef, NUM_PRNs)
    listaGPU :: Vector{GPU}(undef, NUM_GPUs)
    contTipoGPU :: Matrix{UInt8}(undef, NUM_TIPOS, NUM_GPUs) # Matriz que indica quantidade de PRNs de um tipo em cada GPU.
    valorFuncObj ::Int
end

valorObjetivo = 0

function vizinhanca(listaPRN, listaGPU, contTipoGPU, valorObjetivo)
    # Para fazer troca, percorre listaPRN, se achar PRN sozinha troca ela de GPU, se não vai para a próxima GPU da lista.
    for PRN in listaPRN
        i = PRN.indice

        tipoPRN = listaPRN[i].tipo
        id_gpu_origem = listaPRN[i].gpu_id
        id_gpu_destino = novo_gpu_id

        # Faz troca
        if (contTipoGPU[PRN.tipo][PRN.gpu_id] == 0)
            # Muda GPU onde PRN esta alocada
            listaPRN[i].gpu_id = id_gpu_destino

            # Atualiza GPU origem
            # Se PRN que saiu era a única do seu tipo 
            if contTipoGPU[tipoPRN][id_gpu_origem] == 1
                # Diminui o numero de tipos da GPU de origem
                listaGPU[gpu_origem].num_tipos -= 1
            end 
            
            # Atualiza na matriz nova quantidade de tipos na GPU
            contTipoGPU[tipoPRN][id_gpu_origem] -= 1
            
            # ---------------------------------------------------------------------------- #

            # Atualiza GPU destino
            # Se PRN que entrou for de um novo tipo
            if (contTipoGPU[tipoPRN][id_gpu_destino] == 0)
                # Aumenta número de tipos
                listaGPU[id_gpu_destino].num_tipos += 1
            end

            # Atualiza na matriz quantas PRNs do tipo da nova PRN existem na GPU destino.
            contTipoGPU[tipPRN][id_gpu_destino] += 1
            
            # Pra calcular função objetivo, percorre listaGPU e adiciona todos os num_tipos
            for gpu in listaGPU
                valorObjetivo += gpu.num_tipos
            end

            nova_solucao = Solucao(listaPRN, listaGPU, contTipoGPU, valorObjetivo)
            
            return nova_solucao
        end   
    end
end