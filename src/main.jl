include("utils.jl")
include("simulatedAnnealing.jl")
include("salvaSol.jl")

function parse_args(args)
    output_file = ""
    input_file = ""
    alpha = 0.95
    temperaturaMin = 0.1
    temperaturaLength = 1000
    tempoLimite = 600
    tempInicial = 1000.0

    for i in 1:2:length(args)
        if i + 1 > length(args)
            break
        end
        arg = args[i]
        value = args[i + 1]
        if arg == "--output"
            output_file = value
        elseif arg == "--input"
            input_file = value
        elseif arg == "--alpha"
            alpha = parse(Float64, value)
        elseif arg == "--temperaturaMin"
            temperaturaMin = parse(Float64, value)
        elseif arg == "--temperaturaLength"
            temperaturaLength = parse(Int, value)
        elseif arg == "--timeoutLimit"
            tempoLimite = parse(Int, value)
        elseif arg == "--initialTemperature"
            tempInicial = parse(Float64, value)
        else
            println("Argumento desconhecido: $arg")
        end
    end

    return output_file, input_file, alpha, temperaturaMin, temperaturaLength, tempoLimite, tempInicial
end

function main()
    output_file, input_file, alpha, temperaturaMin, temperaturaLength, tempoLimite, tempInicial = parse_args(ARGS)

    input = (input_file == "") ? ["dog_1.txt", "dog_2.txt", "dog_3.txt", "dog_4.txt", "dog_5.txt", 
                               "dog_6.txt", "dog_7.txt", "dog_8.txt", "dog_9.txt", "dog_10.txt"] : [input_file]

    script_dir = @__DIR__

    for dog in input
        println("============ Processing ", dog ," ============")
        
        file_path = joinpath(script_dir, "..", "dog", dog)
        n, V, t, m, listaGPU, listaPRN, contTipoGPU = lerArquivo(file_path)
        global NUM_GPUs = n
        global CAPACIDADE_GPUs = V
        global NUM_TIPOS = t
        global NUM_PRNs = m

        solInicial = solucaoInicial(listaPRN, listaGPU)
        testaSolucao(solInicial)
        println("Solução Inicial: ", solInicial.valorFO)
        
        println("\nVizinhança Move")
        vizinhanca = vizinhancaMove
        melhorSolMove, tempoExecMove = simulatedAnnealing(solInicial, tempInicial, alpha, temperaturaMin, vizinhanca, tempoLimite, temperaturaLength)
        testaSolucao(melhorSolMove)
        println("Move: FO = ", melhorSolMove.valorFO, "\tTotal Time = ", tempoExecMove)
        
        if output_file != ""
            salvaSol(melhorSolMove, output_file * "_" * dog)
        end

        println("==============================================")
    end
end

main()