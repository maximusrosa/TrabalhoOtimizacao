include("leitura.jl")
include("vizinhanca.jl")

using .Structs
using .Vizinhanca

const global MAX_STAGNANT_ITER = 20

# Solução Inicial
# Iterar item por item e alocar item atual na primeira GPU com espaço suficiente.
function solucaoInicial(listaPRN, listaGPU, contTipoGPU)
    for prn in listaPRN
        for gpu in listaGPU
            if gpu.capacidadeRestante >= prn.custo
                listaPRN[prn.id].gpu_id = gpu.id

                # Atualiza a capacidade restante da GPU
                listaGPU[gpu.id].capacidadeRestante -= prn.custo

                # Atualiza a matriz contTipoGPU e num_tipos da GPU
                contTipoGPU[gpu.id, prn.tipo] += 1
                if(contTipoGPU[gpu.id, prn.tipo] == 1)
                    listaGPU[gpu.id].num_tipos += 1
                end
                break
            end
        end
    end

    valorFO = sum(gpu.num_tipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

# Função para o Algoritmo de Metropolis
function metropolis(s, T, melhor_sol)
    count = 0
    while (count <= MAX_STAGNANT_ITER)
        # Seleciona um vizinho s' aleatoriamente da vizinhança N(s)
        sLinha = vizinhanca(s)
        
        # Calcula a diferença de custo/valor entre a solução vizinha
        delta = sLinha.valorFO - s.valorFO
        
        # Se a solução vizinha for melhor, ou seja, levar a um valor da função objetivo menor (delta <= 0), atualiza s.
        if delta <= 0
            s = s_linha
            melhor_sol = s
            count = 0
        else
            # Caso contrário, atualiza com uma certa probabilidade
            probabilidade = exp(-delta / T)
            if rand() < probabilidade
                s = sLinha
            end
            count += 1
        end
    end
    
    # Retorna a solução final após certa quantia de iterações (MAX_STAGNANT_ITER) não causarem melhora na função objetivo.
    return melhor_sol
end


function simulatedAnnealing(s, T, alpha, temperatura_minima)
    melhor_sol = s  # Inicializa melhor_sol com a solução inicial
    while T > temperatura_minima
        melhor_sol = metropolis(s, T, melhor_sol)
        T = alpha * T
    end
    return melhor_sol  # Retorna a melhor solução encontrada, quando T chegar a uma temperatura minima.
end

function main()
    file_path = "dog_0.txt"
    numGPUs, capacidadeGPU, numTipos, numPRNs, listaGPU, listaPRN = lerArquivo(file_path)
    
    contTipoGPU = Matrix{UInt8}(undef, numGPUs, numTipos)
    solInicial = solucaoInicial(listaPRN, listaGPU, contTipoGPU)
    
    T = 1000
    alpha = 0.9
    temperaturaMin = 0.1

    melhorSol = simulatedAnnealing(solInicial, T, alpha, temperaturaMin)
    println("Melhor solução encontrada: ", melhorSol)
end

main()