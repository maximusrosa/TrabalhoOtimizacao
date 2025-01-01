include("structs.jl")
include("leitura.jl")
include("vizinhanca.jl")

const global MAX_STAGNANT_ITER = 100


# Solução Inicial
function solucaoInicial(listaPRN, listaGPU, contTipoGPU)
    for prn in listaPRN
        for gpu in listaGPU
            if gpu.capacidadeRestante >= prn.custo
                addPRN(gpu, prn, contTipoGPU)
                break
            end
        end
    end

    #=
    for prn in listaPRN
        if prn.gpuID == 0
            throw(ErrorException("Erro: PRN " * string(prn.id) * " não foi alocada na solução inicial."))
        end
    end

    count = 0
    for gpu in listaGPU
        for prnID = gpu.listaIDsPRN
            println("PRN ", prnID, " alocada na GPU ", gpu.id)
            count += 1
        end
    end
    println(" Count: ", count)
    =#

    valorFO = sum(gpu.numTipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

# Função para o Algoritmo de Metropolis
function metropolis(s, T, melhorSol)
    count = 0

    novaMelhorSol = deepcopy(melhorSol)
    tempoIter = 0.0
    while (count < MAX_STAGNANT_ITER)
        # Seleciona um vizinho s' aleatoriamente da vizinhança N(s)
        tempoIn = time()
        sLinha = vizinhancaTroca(s)
        tempoViz= time() - tempoIn
        if(tempoViz > 0)
            tempoIter += tempoViz
        end
        
        #println("Valor função objetivo obtido na função vizinhança: ", sLinha.valorFO)
        
        # Se sLinha é a melhor solução encontrada até o momento, atualiza novaMelhorSol
        if sLinha.valorFO < novaMelhorSol.valorFO
            novaMelhorSol = deepcopy(sLinha)
            println(" Tentativas: ", count, " Valor melhor solução: ", sLinha.valorFO)
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
    tempoIter = tempoIter / MAX_STAGNANT_ITER
    
    # Retorna a solução final após certa quantia de iterações (MAX_STAGNANT_ITER) não causarem melhora na função objetivo.
    return novaMelhorSol, tempoIter
end


function simulatedAnnealing(s, T, alpha, temperatura_minima)
    melhorSol = s  # Inicializa melhor_sol com a solução inicial

    tempoTotal = 0.0
    tempoTotalViz = 0.0
    count = 0

    timeIn = time()
    while T > temperatura_minima
        melhorSol, tempoIter = metropolis(s, T, melhorSol)
        T = alpha * T

        count += 1
        tempoTotalViz += tempoIter
    end
    tempoTotal = time() - timeIn

    println("----------------------------------------------")
    println("Tempo médio de execução da função vizinhança: ", tempoTotalViz / count)
    println("Tempo de execução total: ", tempoTotal)
    #println("Número de iterações do metropolis: ", count)
    println("Melhor solução encontrada: ", melhorSol.valorFO)
    return melhorSol, tempoTotal  # Retorna a melhor solução encontrada, quando T chegar a uma temperatura minima.
end

function testeAlg(solInicial, T, alpha, tempMin)
    MAX_ITER = 10

    mediaFO = 0
    countIter = 1
    tempoTotal = 0.0
    while (countIter <= MAX_ITER)
        melhorSol, tempoIter = simulatedAnnealing(solInicial, T, alpha, tempMin)
        #println("Melhor solução (Iteração ", countIter, "): ", melhorSol.valorFO)
        mediaFO += melhorSol.valorFO
        countIter += 1
        tempoTotal += tempoIter
    end
    mediaFO = mediaFO / MAX_ITER
    tempoMedio = tempoTotal / MAX_ITER
    println("----------------------------------------------")
    println("Média da função objetivo, depois de ", MAX_ITER, " iterações: ", mediaFO)
    println("Tempo médio de execução: ", tempoMedio)
end

function main()
    # Arquivo de entrada
    filePath = "dog/dog_7.txt"

    n, V, T, m, listaGPU, listaPRN, contTipoGPU = lerArquivo(filePath)

    global NUM_GPUs = n
    global CAPACIDADE_GPU = V
    global NUM_TIPOS = T
    global NUM_PRNs = m

    solInicial = solucaoInicial(listaPRN, listaGPU, contTipoGPU)
    
    T = 2000
    alpha = 0.98
    temperaturaMin = 0.1

    println("Solução Inicial: ", solInicial.valorFO)
    
    #testeAlg(solInicial, T, alpha, temperaturaMin)

    melhorSol, tempoExec = simulatedAnnealing(solInicial, T, alpha, temperaturaMin)
end

main();