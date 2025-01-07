include("utils.jl")
include("simulatedAnnealing.jl")

using ArgParse

function main()
    args = ArgParseSettings()
    @add_arg_table args begin
#=
        "--output"
        help = "Output file for the best solution"
        arg_type = String
        default = ""
=#
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
    end

    argv = parse_args(args)

    alpha = argv["alpha"]
    temperaturaMin = argv["temperaturaMin"]
    output_file = argv["output"]
    input_file = argv["input"]

    input = (input_file == "") ? ["dog_1.txt", "dog_2.txt", "dog_3.txt", "dog_4.txt", "dog_5.txt", 
                               "dog_6.txt", "dog_7.txt", "dog_8.txt", "dog_9.txt", "dog_10.txt"] : [input_file]

    for dog in input
        println("============ Processing ", dog ," ============")
        
        n, V, t, m, listaGPU, listaPRN, contTipoGPU = lerArquivo("dog/" * dog)
        global NUM_GPUs = n
        global CAPACIDADE_GPUs = V
        global NUM_TIPOS = t
        global NUM_PRNs = m

        solInicial = solucaoInicial(listaPRN, listaGPU, contTipoGPU)
        testaSolucao(solInicial)
        println("Solução Inicial: ", solInicial.valorFO)

        T = 500
        
        println("\nVizinhança Move")
        vizinhanca = vizinhancaMove
        melhorSolMove, tempoExecMove = simulatedAnnealing(solInicial, T, alpha, temperaturaMin, vizinhanca)
        testaSolucao(melhorSolMove)
        println("Move: FO = ", melhorSolMove.valorFO, "\tTotal Time = ", tempoExecMove)

#=
        if output_file != ""
            open(output_file, "w") do f
                write(f, printSolucao(melhorSolMove))
            end
        end
=#
        println("==============================================")
    end
end

main()