include("leitura.jl")
include("structs.jl")
include("vizinhanca.jl")

const global MAX_STAGNANT_ITER = 50

# Solução Inicial
# Iterar item por item e alocar item atual na primeira GPU com espaço suficiente.
function solucaoInicial(listaPRN, listaGPU, contTipoGPU)
    for prn in listaPRN
        for gpu in listaGPU
            if gpu.capacidadeRestante >= prn.custo
                prn.gpu_id = gpu.id
                gpu.listaIDsPRN = push!(gpu.listaIDsPRN, prn.id)
                # Atualiza a capacidade restante da GPU
                gpu.capacidadeRestante -= prn.custo

                # Atualiza a matriz contTipoGPU e num_tipos da GPU
                contTipoGPU[gpu.id, prn.tipo] += 1
                if(contTipoGPU[gpu.id, prn.tipo] == 1)
                    gpu.num_tipos += 1
                end
                #println("GPU: ", gpu.id, " Quantidade de tipos: ", contTipoGPU[gpu.id, prn.tipo])
                #println("Atualizando GPU ID $(gpu.id): num_tipos=$(gpu.num_tipos), capacidadeRestante=$(gpu.capacidadeRestante)")
                break
            end
        end
    end

    #=
    for prn in listaPRN
        if prn.gpu_id == 0
            println("Erro: PRN ", prn.id, " não foi alocada.")
        end
    end

    for gpu in listaGPU
        println("GPU ID: $(gpu.id) , ")
        for prnID in gpu.listaIDsPRN
            prn = listaPRN[prnID]
            print("PRN ID: $(prn.id) , ")
        end
        #println("GPU ID: $(gpu.id), Num Tipos: $(gpu.num_tipos), Capacidade Restante: $(gpu.capacidadeRestante)")
    end
    =#

    valorFO = sum(gpu.num_tipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

# Função para o Algoritmo de Metropolis
function metropolis(s, T, melhorSol, numGPUs)
    count = 0
    novaMelhorSol = deepcopy(melhorSol)
    while (count <= MAX_STAGNANT_ITER)
        # Seleciona um vizinho s' aleatoriamente da vizinhança N(s)
        sLinha = vizinhanca(s, numGPUs)
        
        #println("Valor função objetivo obtido na função vizinhança: ", sLinha.valorFO)
        
        # Se sLinha é a melhor solução encontrada até o momento, atualiza novaMelhorSol
        if sLinha.valorFO < novaMelhorSol.valorFO
            novaMelhorSol = deepcopy(sLinha)
            count = 0
        end

        # Se a solução vizinha for melhor, ou seja, levar a um valor da função objetivo menor, atualiza s.
        if sLinha.valorFO < s.valorFO
            s = deepcopy(sLinha)
        else
            # Caso contrário, atualiza com uma certa probabilidade
            delta = sLinha.valorFO - s.valorFO
            probabilidade = exp(-delta / T)
            if rand() < probabilidade
                s = deepcopy(sLinha)
            end
            count += 1
        end
    end
    
    # Retorna a solução final após certa quantia de iterações (MAX_STAGNANT_ITER) não causarem melhora na função objetivo.
    return novaMelhorSol
end


function simulatedAnnealing(s, T, alpha, temperatura_minima, numGPUs)
    melhorSol = s  # Inicializa melhor_sol com a solução inicial
    while T > temperatura_minima
        melhorSol = metropolis(s, T, melhorSol, numGPUs)
        T = alpha * T
        println(" Valor melhor solução: ", melhorSol.valorFO)
    end
    return melhorSol  # Retorna a melhor solução encontrada, quando T chegar a uma temperatura minima.
end

function main()
    file_path = "dog_9.txt"
    numGPUs, capacidadeGPU, numTipos, numPRNs, listaGPU, listaPRN = lerArquivo(file_path)
    
    contTipoGPU = fill(UInt8(0), numGPUs, numTipos)
    solInicial = solucaoInicial(listaPRN, listaGPU, contTipoGPU)
    
    T = 1000
    alpha = 0.9
    temperaturaMin = 0.1

    melhorSol = simulatedAnnealing(solInicial, T, alpha, temperaturaMin, numGPUs)
    println("Melhor solução encontrada: ", melhorSol.valorFO)
    #printSolucao(melhorSol)
end

main()