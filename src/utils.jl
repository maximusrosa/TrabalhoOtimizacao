function testeAlg(solInicial, T, alpha, tempMin)
    MAX_ITER = 10

    mediaFO = 0
    countIter = 1
    tempoTotal = 0.0
    while (countIter <= MAX_ITER)
        melhorSol, tempoExec = simulatedAnnealing(solInicial, T, alpha, tempMin, vizinhancaMove)
        #println("Melhor solução (Iteração ", countIter, "): ", melhorSol.valorFO)
        mediaFO += melhorSol.valorFO
        countIter += 1
        tempoTotal += tempoExec
        println(tempoTotal)
    end

    mediaFO = mediaFO / MAX_ITER
    tempoMedio = tempoTotal / MAX_ITER

    println("----------------------------------------------")
    println("Média da função objetivo, depois de ", MAX_ITER, " iterações: ", mediaFO)
    println("Tempo médio de execução: ", tempoMedio)
end

function testaSolucao(solucao)
    global CAPACIDADE_GPUs, NUM_PRNs

    listaPRNAux = solucao.listaPRN
    listaGPUAux = solucao.listaGPU
    contTipoGPUAux = solucao.contTipoGPU

    # Testes para verificar se a solução é válida.
    countPrnAlocadas = 0
    for gpu in listaGPUAux
        capacidadeOcupada = 0
        for prnId in gpu.listaIDsPRN
            capacidadeOcupada += listaPRNAux[prnId].custo
            countPrnAlocadas += 1
        end
        if (capacidadeOcupada > CAPACIDADE_GPUs)
            throw(ErrorException("Capacidade de GPU ultrapassada"))
        end
    end

    if (countPrnAlocadas != NUM_PRNs)
        throw(ErrorException("Número de PRNs alocadas diferente do esperado: " * string(countPrnAlocadas) * " != " * string(NUM_PRNs)))
    end
    
    for prn in listaPRNAux
        if (prn.gpuID == 0)
            throw(ErrorException("PRN " * string(prn.id) * " não possui id de GPU"))
        end
    end
    
    # Verfica se contTipoGPU está condizente com valorFO
    valorFOTeste = 0
    for tipos in contTipoGPUAux
        for count in tipos
            if count > 0
                valorFOTeste += 1
            end
        end
    end
    if valorFOTeste != solucao.valorFO
        throw(ErrorException("Valor da função objetivo diferente do esperado: " * string(valorFOTeste) * " != " * string(solucao.valorFO)))
    end

    for gpu in listaGPUAux
        for prnId in gpu.listaIDsPRN
            prn = listaPRNAux[prnId]
            if prn.gpuID != gpu.id
                throw(ErrorException("Gpu id de PRN na listaIDsPRN" * string(prn.gpuID) * " diferente do id da gpu " * string(gpu.id)))
            end
        end
    end
end