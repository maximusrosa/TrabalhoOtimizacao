include("utils.jl")
include("simulatedAnnealing.jl")

function main()
    easyOnes = ["dog_1.txt", "dog_2.txt", "dog_7.txt", "dog_8.txt", "dog_9.txt"]
    hardOnes = ["dog_3.txt", "dog_4.txt", "dog_5.txt", "dog_6.txt", "dog_10.txt"]

    dogs = vcat(easyOnes, hardOnes)

    # Parameters for simulated annealing
    alpha = 0.95
    temperaturaMin = 0.1

    # Process each instance
    for dog in dogs
        println("============ Processing ", dog ," ============")
        
        # Read instance data
        n, V, t, m, listaGPU, listaPRN, contTipoGPU = lerArquivo("dog/" * dog)
        global NUM_GPUs = n
        global CAPACIDADE_GPUs = V
        global NUM_TIPOS = t
        global NUM_PRNs = m

        # Generate initial solution
        solInicial = solucaoInicialGulosa(listaPRN, listaGPU, contTipoGPU)
        testaSolucao(solInicial)
        println("Solução Inicial: ", solInicial.valorFO)

        # Escolhe temperatura inicial com base no desvio padrão da função objetivo na solução inicial.
        T = temperaturaInicial(listaPRN, listaGPU)
        
        # Run with Move neighborhood
        println("\nVizinhança Move")
        vizinhanca = vizinhancaMove
        melhorSolMove, tempoExecMove = simulatedAnnealing(solInicial, T, alpha, temperaturaMin, vizinhanca)
        testaSolucao(melhorSolMove)
        println("Move: FO = ", melhorSolMove.valorFO, "\tTotal Time = ", tempoExecMove)

        println("==============================================")
    end
end

main()