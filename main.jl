include("structs.jl")
include("leitura.jl")
include("vizinhanca.jl")

const global MAX_STAGNANT_ITER = 1000
const global TEMP_INCIAL = 1000.0

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

    valorFO = sum(gpu.numTipos for gpu in listaGPU)

    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

# Função exponencial inversa
function limiteTentPRNIsolada(tempAtual, limite_max, k)
    #limiteTent = round(limite_max * exp(-k * (TEMP_INCIAL - tempAtual)))
    limiteTent = round(limite_max * (tempAtual / TEMP_INCIAL))
    #limiteTent = round(limite_max - tempAtual)
    #limiteTent = 1000
    if limiteTent < 50
        return 0
    else
        return limiteTent
    end
    
end

# Função para o Algoritmo de Metropolis
function metropolis(s, T, melhorSol, vizinhanca, limiteHeuristPRN)
    global countPrnMisses, countGpuCapMisses, countGpuMisses
    
    count = 0

    novaMelhorSol = deepcopy(melhorSol)

    tempoIter = 0.0

    countPrnMisses, countGpuCapMisses, countGpuMisses = 0, 0, 0

    while (count < MAX_STAGNANT_ITER)
        # Seleciona um vizinho s' aleatoriamente da vizinhança N(s)
        tempoIn = time()

        sLinha, prnMisses, gpuMisses, gpuCapMisses = vizinhanca(s, limiteHeuristPRN)

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
            countPrnMisses, countGpuCapMisses, countGpuMisses = 0, 0, 0
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

    println(" Prn misses: ", countPrnMisses, " Gpu misses: ", countGpuMisses, " Gpu cap misses: ", countGpuCapMisses)
    
    # Retorna a solução final após certa quantia de iterações (MAX_STAGNANT_ITER) não causarem melhora na função objetivo.
    return novaMelhorSol, tempoIter
end

function deveTrocar(listaPRN)
    global CAPACIDADE_GPUs
    global NUM_PRNs
    
    #Custo médio de PRNs
    custoTotal = 0
    custoTotal = sum(prn.custo for prn in listaPRN)

    custoMedioPRN = custoTotal / NUM_PRNs

    mediaPRNporGPU = floor(CAPACIDADE_GPUs / custoMedioPRN)

    capRestMedia = CAPACIDADE_GPUs - (mediaPRNporGPU * custoMedioPRN)
    
    espacoRestPercent = capRestMedia / CAPACIDADE_GPUs

    println("Espaço restante médio: ", espacoRestPercent)

    limite_pra_troca = 0.1

    if (espacoRestPercent < limite_pra_troca)
        return true
    else
        return false
    end
end

function simulatedAnnealing(s, T, alpha, temperatura_minima, vizinhanca, tempoMax)
    melhorSol = s  # Inicializa melhor_sol com a solução inicial

    tempoTotal = 0.0
    tempoTotalViz = 0.0
    countIter = 0

    #= 
    if (deveTrocar(s.listaPRN))
        println(" Vizinhança Troca")
        vizinhanca = vizinhancaTroca
    else
        println(" Vizinhança Move")
        vizinhanca = vizinhancaMove
    end
    =#

    timeIn = time()
    k = 0.1  # Velocidade de decaimento
    T0 = T  # Armazena a temperatura inicial
    while T > temperatura_minima
        limiteHeuristPRN = limiteTentPRNIsolada(T, LIMITE_TENT_PRN_ISOLADA, 0.1)
        #println(" Temperatura: ", T)
        #println(" Limite tentativas PRN isolada: ", limiteHeuristPRN)
        melhorSol, tempoIter = metropolis(s, T, melhorSol, vizinhanca, limiteHeuristPRN)

        countIter += 1
        tempoTotalViz += tempoIter

        # Atualiza a temperatura usando uma função logarítmica
        T = TEMP_INCIAL * exp(-k * sqrt(countIter))

        # Verificação de tempo para parar após 30 segundos
        if (time() - timeIn > tempoMax)
            break
        end
        println(" Temperatura: ", T, " Limite tentativas PRN isolada: ", limiteHeuristPRN)
    end
    tempoTotal = time() - timeIn

    println("----------------------------------------------")
    println("Tempo médio de execução da função vizinhança: ", tempoTotalViz / countIter)
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
        melhorSol, tempoIter = simulatedAnnealing(solInicial, T, alpha, tempMin, vizinhancaMove, 1800)
        #println("Melhor solução (Iteração ", countIter, "): ", melhorSol.valorFO)
        mediaFO += melhorSol.valorFO
        countIter += 1
        tempoTotal += tempoIter
        println(tempoTotal)
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

    global NUM_GPUs = UInt16(n)
    global CAPACIDADE_GPUs = UInt16(V)
    global NUM_TIPOS = UInt8(T)
    global NUM_PRNs = UInt16(m)
    
    solInicial = solucaoInicial(listaPRN, listaGPU, contTipoGPU)
    
    T = TEMP_INCIAL
    #alpha = 0.95
    alpha = 0.01
    temperaturaMin = 0.1

    println("Solução Inicial: ", solInicial.valorFO)
    
    #testeAlg(solInicial, T, alpha, temperaturaMin)

    println(" Vizinhança Move")
    vizinhanca = vizinhancaMove
    melhorSol, tempoExec = simulatedAnnealing(solInicial, T, alpha, temperaturaMin, vizinhanca, 600)
    println(" Vizinhança Troca")
    vizinhanca = vizinhancaTroca
    melhorSol, tempoExec = simulatedAnnealing(solInicial, T, alpha, temperaturaMin, vizinhanca, 600)
end

#=
dog 2 = 23%, move: 116 seg, melhor solução: 137, troca: 50 s, melhor solução: 270
melhor solução possível: 123
=#

main();