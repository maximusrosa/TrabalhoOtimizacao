include("structs.jl")
include("leitura.jl")
include("vizinhanca.jl")

using Statistics
using Random

const global MAX_STAGNANT_ITER = 1000
const global TEMP_INCIAL = 100


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

function solucaoValida(listaPRNInicial, listaGPUInicial)
    global NUM_PRNs, NUM_GPUs, CAPACIDADE_GPUs
    valida = false
    prns_alocadas = 0

    local listaPRN = deepcopy(listaPRNInicial)
    local listaGPU = deepcopy(listaGPUInicial)
    local contTipoGPU = zeros(UInt8, NUM_GPUs, NUM_TIPOS)

    while !valida
        indicesPRN = collect(1:NUM_PRNs)
        shuffle!(indicesPRN)
        indicesGPU = collect(1:NUM_GPUs)
        shuffle!(indicesGPU)

        for prnId in indicesPRN
            prn = listaPRN[prnId]
            for id in indicesGPU
                gpu = listaGPU[id]
                if gpu.capacidadeRestante >= prn.custo
                    addPRN(gpu, prn, contTipoGPU)
                    prns_alocadas += 1
                    break
                end
            end
        end

        if prns_alocadas == NUM_PRNs
            valida = true
        else
            println("Solução inválida, gerando nova...")
            # Reset the allocation count and GPU capacities if not valid
            prns_alocadas = 0
            for gpu in listaGPU
                gpu.listaIDsPRN = []
                gpu.capacidadeRestante = CAPACIDADE_GPUs
                gpu.numTipos = 0
            end
            for prn in listaPRN
                prn.gpuID = 0
            end
        end
    end
    
    # Função para printar a alocação obtida.
    #=
    for id in 1:NUM_GPUs
        gpu = listaGPU[id]
        println("==================================================================================")
        println("GPU ID: ", gpu.id, " Capacidade Restante: ", gpu.capacidadeRestante, " Num Tipos: ", gpu.numTipos)
        for prnID in gpu.listaIDsPRN
            prn = listaPRN[prnID]
            println("PRN ID: ", prn.id, " GPU ID: ", prn.gpuID, " Custo: ", prn.custo, " Tipo: ", prn.tipo)
        end
    end
    =#
    
    valorFO = sum(gpu.numTipos for gpu in listaGPU)
    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

function solucaoValida(listaPRNInicial, listaGPUInicial)
    global NUM_PRNs, NUM_GPUs, CAPACIDADE_GPUs
    valida = false
    prns_alocadas = 0

    local listaPRN = deepcopy(listaPRNInicial)
    local listaGPU = deepcopy(listaGPUInicial)
    local contTipoGPU = zeros(UInt8, NUM_GPUs, NUM_TIPOS)

    while !valida
        indicesPRN = collect(1:NUM_PRNs)
        shuffle!(indicesPRN)
        indicesGPU = collect(1:NUM_GPUs)
        shuffle!(indicesGPU)

        for prnId in indicesPRN
            prn = listaPRN[prnId]
            for id in indicesGPU
                gpu = listaGPU[id]
                if gpu.capacidadeRestante >= prn.custo
                    addPRN(gpu, prn, contTipoGPU)
                    prns_alocadas += 1
                    break
                end
            end
        end

        if prns_alocadas == NUM_PRNs
            valida = true
        else
            println("Solução inválida, gerando nova...")
            # Reset the allocation count and GPU capacities if not valid
            prns_alocadas = 0
            for gpu in listaGPU
                gpu.listaIDsPRN = []
                gpu.capacidadeRestante = CAPACIDADE_GPUs
                gpu.numTipos = 0
            end
            for prn in listaPRN
                prn.gpuID = 0
            end
        end
    end
    
    # Função para printar a alocação obtida.
    #=
    for id in 1:NUM_GPUs
        gpu = listaGPU[id]
        println("==================================================================================")
        println("GPU ID: ", gpu.id, " Capacidade Restante: ", gpu.capacidadeRestante, " Num Tipos: ", gpu.numTipos)
        for prnID in gpu.listaIDsPRN
            prn = listaPRN[prnID]
            println("PRN ID: ", prn.id, " GPU ID: ", prn.gpuID, " Custo: ", prn.custo, " Tipo: ", prn.tipo)
        end
    end
    =#
    
    valorFO = sum(gpu.numTipos for gpu in listaGPU)
    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

# A temperatura inicial deve ser o desvio padrão no valor da função objetivo de 200 soluções geradas aleatoriamente.
function temperaturaInicial(listaPRN, listaGPU)
    global TEMP_INCIAL

    println("Calculando temperatura inicial...")

    # Gera 200 soluções iniciais aleatórias
    solucoes = []
    for i in 1:200
        s = solucaoValida(listaPRN, listaGPU)
        push!(solucoes, s)
        #println("i: ", i, " FO: ", s.valorFO)
    end

    println("Calculando desvio padrão...")

    # Calcula o desvio padrão das funções objetivos dessas soluções
    T = std([s.valorFO for s in solucoes])
    println("T: ", T)
    return T
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
        limiteHeuristPRN = limiteTentPRNIsolada(T)

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
