include("structs.jl")
include("leitura.jl")
include("vizinhanca.jl")

using Statistics
using Random

const global TEMPERATURE_LENGTH = 1000
const global TEMP_INCIAL = 100
const global TIMEOUT_LIMIT = 15 * 60

function ordenaGPUsCap(gpu, gpusOrdenadasCap)
    # Remove a GPU da lista se já estiver presente
    for i in eachindex(gpusOrdenadasCap)
        if gpusOrdenadasCap[i][1] == gpu.id
            deleteat!(gpusOrdenadasCap, i)
            break
        end
    end

    # Acha a posição correta para inserir a GPU com base na capacidade restante
    idGPU = 1
    while idGPU <= length(gpusOrdenadasCap) && gpu.capacidadeRestante <= gpusOrdenadasCap[idGPU][2]
        idGPU += 1
    end

    # Insere a GPU na posição correta
    insert!(gpusOrdenadasCap, idGPU, (gpu.id, gpu.capacidadeRestante))
end

function solucaoInicialGulosa(listaPRN, listaGPU, contTipoGPU)
    local listaPRNAux
    local listaGPUAux
    local contTipoGPUAux

    solValida = false

    # Inicializa lista de ids de prn, começando com as mais custosas.
    idsPrn = [prn.id for prn in sort(listaPRN, by = x -> -x.custo)]

    while (!solValida)
        solValida = true

        # Variáveis auxiliares utilizadas temporariamente, caso a alocação seja inválida.
        listaPRNAux = deepcopy(listaPRN)
        listaGPUAux = deepcopy(listaGPU)
        contTipoGPUAux = zeros(UInt8, NUM_GPUs, NUM_TIPOS)

        # Inicializa gpusOrdenadasCap com tuplas de (id da GPU, capacidadeRestante).
        idsGpu = collect(1:NUM_GPUs)
        gpusOrdenadasCap = [(id, CAPACIDADE_GPUs) for id in idsGpu]
        
        # Inicializa gpusComTipo, uma matriz de vetores com as gpus que tem o tipo i.
        gpusComTipo = [Vector{Int}() for _ in 1:NUM_TIPOS]

        # Loop de alocação de prns
        for prnId in idsPrn
            prn = listaPRNAux[prnId]
            alocado = false

            # Tenta atribuir a prn em uma GPU que já tem o mesmo tipo.
            for gpuId in gpusComTipo[prn.tipo]
                gpu = listaGPUAux[gpuId]
                if (gpu.capacidadeRestante >= prn.custo)
                    addPRN(gpu, prn, contTipoGPUAux)
                    ordenaGPUsCap(gpu, gpusOrdenadasCap)
                    gpusComTipo[prn.tipo] = push!(gpusComTipo[prn.tipo], gpu.id)
                    alocado = true
                    break
                end
            end

            # Se não tem nehuma gpu com o tipo da prn e capacidade suficiente.
            # Tenta alocar na GPU com maior capacidade restante.
            if (!alocado)
                idGpuMaisCap = gpusOrdenadasCap[1][1]
                gpu = listaGPUAux[idGpuMaisCap]
                if (gpu.capacidadeRestante >= prn.custo)
                    addPRN(gpu, prn, contTipoGPUAux)
                    ordenaGPUsCap(gpu, gpusOrdenadasCap)
                    gpusComTipo[prn.tipo] = push!(gpusComTipo[prn.tipo], idGpuMaisCap)
                    alocado = true
                # Se a prn não coube na gpu com maior capacidade, então a solução não é valida.
                else
                    solValida = false
                    # Randomiza a ordem dos prns para tentar outra solução.
                    idsPrn = shuffle(collect(1:NUM_PRNs))
                    break
                end
            end
        end
    end

    valorFO = sum(gpu.numTipos for gpu in listaGPUAux)

    return Solucao(listaPRNAux, listaGPUAux, contTipoGPUAux, valorFO)
end

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
    

    valorFO = sum(gpu.numTipos for gpu in listaGPU)
    return Solucao(listaPRN, listaGPU, contTipoGPU, valorFO)
end

function temperaturaInicial(listaPRN, listaGPU)
    # Gera 200 soluções iniciais aleatórias
    solucoes = []
    for i in 1:200
        s = solucaoValida(listaPRN, listaGPU)
        push!(solucoes, s)
    end

    # Calcula o desvio padrão das funções objetivos dessas soluções
    T = std([s.valorFO for s in solucoes])
    println("T: ", T)
    return T
end

function metropolis(s, T, melhorSol, vizinhanca, limiteHeuristPRN)
    count = 0

    novaMelhorSol = deepcopy(melhorSol)

    tempoIter = 0.0
    
    for i in 1:TEMPERATURE_LENGTH
        # Seleciona um vizinho s' aleatoriamente da vizinhança N(s)
        tempoIn = time()

        sLinha = vizinhanca(s, limiteHeuristPRN)

        tempoViz= time() - tempoIn

        if(tempoViz > 0)
            tempoIter += tempoViz
        end
        
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
    tempoIter = tempoIter / TEMPERATURE_LENGTH
    
    # Retorna a solução final após certa quantia de iterações (TEMPERATURE_LENGTH)
    return novaMelhorSol, s, tempoIter
end

function simulatedAnnealing(s, T, alpha, temperatura_minima, vizinhanca)
    melhorSol = s  # Inicializa melhor_sol com a solução inicial

    tempoTotal = 0.0
    tempoTotalViz = 0.0
    count = 0
    temperaturaInicial = T

    timeIn = time()
    while T > temperatura_minima
        limiteHeuristPRN = limiteTentPRNIsolada(temperaturaInicial, T)
        
        melhorSol, s, tempoIter = metropolis(s, T, melhorSol, vizinhanca, limiteHeuristPRN)
        T = alpha * T

        count += 1
        tempoTotalViz += tempoIter

        # Verificação de tempo para parar após 30 segundos
        if (time() - timeIn > TIMEOUT_LIMIT)
            break
        end
    end
    tempoTotal = time() - timeIn

    println("Tempo médio exec. vizinhança: ", tempoTotalViz / count)

    return melhorSol, tempoTotal  # Retorna a melhor solução encontrada, quando T chegar a uma temperatura minima.
end
