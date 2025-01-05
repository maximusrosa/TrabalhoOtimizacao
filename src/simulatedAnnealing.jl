include("structs.jl")
include("leitura.jl")
include("vizinhanca.jl")

const global MAX_STAGNANT_ITER = 1000
const global TEMP_INCIAL = 1000

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

function limiteTentPRNIsolada(tempAtual, limite_max)
    #limiteTent = round(limite_max * (tempAtual / TEMP_INCIAL))
    limiteTent = round(limite_max - tempAtual)
    #limiteTent = 1000
    if limiteTent < 50
        return 0
    else
        return limiteTent
    end
    
end

# Função para o Algoritmo de Metropolis
function metropolis(s, T, melhorSol, vizinhanca, limiteHeuristPRN)
    count = 0

    novaMelhorSol = deepcopy(melhorSol)

    tempoIter = 0.0
    
    while (count < MAX_STAGNANT_ITER)
        # Seleciona um vizinho s' aleatoriamente da vizinhança N(s)
        tempoIn = time()

        sLinha = vizinhanca(s, limiteHeuristPRN)

        tempoViz= time() - tempoIn

        if(tempoViz > 0)
            tempoIter += tempoViz
        end
        
        #println("Valor função objetivo obtido na função vizinhança: ", sLinha.valorFO)
        
        # Se sLinha é a melhor solução encontrada até o momento, atualiza novaMelhorSol
        if sLinha.valorFO < novaMelhorSol.valorFO
            novaMelhorSol = deepcopy(sLinha)
            #println(" Tentativas: ", count, " Valor melhor solução: ", sLinha.valorFO)
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

function simulatedAnnealing(s, T, alpha, temperatura_minima, vizinhanca)
    melhorSol = s  # Inicializa melhor_sol com a solução inicial

    tempoTotal = 0.0
    tempoTotalViz = 0.0
    count = 0

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
    while T > temperatura_minima
        limiteHeuristPRN = limiteTentPRNIsolada(T, LIMITE_TENT_PRN_ISOLADA)

        #println(" Temperatura: ", T)
        #println(" Limite tentativas PRN isolada: ", limiteHeuristPRN)
        
        melhorSol, tempoIter = metropolis(s, T, melhorSol, vizinhanca, limiteHeuristPRN)
        T = alpha * T

        count += 1
        tempoTotalViz += tempoIter

        # Verificação de tempo para parar após 30 segundos
        if (time() - timeIn > 30)
            break
        end
    end
    tempoTotal = time() - timeIn

    println("Tempo médio exec. vizinhança: ", tempoTotalViz / count)

    return melhorSol, tempoTotal  # Retorna a melhor solução encontrada, quando T chegar a uma temperatura minima.
end
