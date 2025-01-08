include("utils.jl")
include("simulatedAnnealing.jl")
include("salvaSol.jl")

using ArgParse

function main()
    args = ArgParseSettings()
    @add_arg_table args begin
        "--output"
        help = "Output file for the best solution"
        arg_type = String
        default = ""
        
        "--input"
        help = "Input file for a specific dog"
        arg_type = String
        default = ""

        "--alpha"
        help = "Cooling rate"
        arg_type = Float64
        default = 0.95

        "--temperaturaMin"
        help = "Minimum temperature"
        arg_type = Float64
        default = 0.1

        "--temperaturaLength"
        help = "Number of iterations at each temperature"
        arg_type = Int
        default = 1000

        "--timeoutLimit"
        help = "Timeout limit in seconds"
        arg_type = Int
        default = 600

        "--initialTemperature"
        help = "Initial temperature"
        arg_type = Float64
        default = 1000.0
    end

    argv = parse_args(args)

    alpha = argv["alpha"]
    temperaturaMin = argv["temperaturaMin"]
    temperaturaLength = argv["temperaturaLength"]
    tempoLimite = argv["timeoutLimit"]
    output_file = argv["output"]
    input_file = argv["input"]
    tempInicial = argv["initialTemperature"]

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