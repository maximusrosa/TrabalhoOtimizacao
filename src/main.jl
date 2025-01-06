include("simulatedAnnealing.jl")

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

function testeAlg(solInicial, T, alpha, tempMin)
    MAX_ITER = 10

    mediaFO = 0
    countIter = 1
    tempoTotal = 0.0
    while (countIter <= MAX_ITER)
        melhorSol, tempoIter = simulatedAnnealing(solInicial, T, alpha, tempMin, vizinhancaMove)
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
    # Define all dog instances
    dogFiles = [
        "dog_7.txt"
    ]

    move = true
    troca = true

    # Parameters for simulated annealing
    alpha = 0.95
    temperaturaMin = 0.1

    # Process each instance
    for dog in dogFiles
        println("============ Processing ", dog ," ============")
        
        # Read instance data
        n, V, T, m, listaGPU, listaPRN, contTipoGPU = lerArquivo("dog/" * dog)
        global NUM_GPUs = n
        global CAPACIDADE_GPUs = V
        global NUM_TIPOS = T
        global NUM_PRNs = m
        
        # Escolhe temperatura inicial com base no desvio padrão da função objetivo na solução inicial.
        temp = temperaturaInicial(listaPRN, listaGPU)

        # Generate initial solution
        solInicial = solucaoInicial(listaPRN, listaGPU, contTipoGPU)
        println("Solução Inicial: ", solInicial.valorFO)
        
        if move
            # Run with Move neighborhood
            println("\nVizinhança Move")
            vizinhanca = vizinhancaMove
            melhorSolMove, tempoExecMove = simulatedAnnealing(solInicial, temp, alpha, temperaturaMin, vizinhanca)
            println("Move: FO = ", melhorSolMove.valorFO, "\tTotal Time = ", tempoExecMove)
        end

        if troca
            # Run with Swap neighborhood
            println("\nVizinhança Troca")
            vizinhanca = vizinhancaTroca
            melhorSolTroca, tempoExecTroca = simulatedAnnealing(solInicial, temp, alpha, temperaturaMin, vizinhanca)
            println("Troca: FO = ", melhorSolTroca.valorFO, "\tTotal Time = ", tempoExecTroca)
        end

        println("==============================================")
    end
end

main()