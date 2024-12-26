#include("structs.jl")

function printLerArquivo(file_path)
    NUM_GPUs, CAPACIDADE_MAX, NUM_TIPOS, NUM_PRNs, listaGPU, listaPRN = lerArquivo(file_path)
    
    println("Número de GPUs: ", NUM_GPUs)
    println("Capacidade Máxima de VRAM: ", CAPACIDADE_MAX)
    println("Número de Tipos Diferentes: ", NUM_TIPOS)
    println("Número de PRNs: ", NUM_PRNs)
    
    println("\nLista de GPUs:")
    for gpu in listaGPU
        println("GPU ID: $(gpu.id), Num Tipos: $(gpu.num_tipos), Capacidade Restante: $(gpu.capacidadeRestante)")
    end
    
    println("\nLista de PRNs:")
    for prn in listaPRN
        println("PRN ID: $(prn.id), GPU ID: $(prn.gpu_id), Custo: $(prn.custo), Tipo: $(prn.tipo)")
    end
end

function lerArquivo(file_path)
    # Lê o arquivo e processa as linhas não vazias
    lines = filter(x -> !isempty(x), readlines(file_path))

    # Linha 1: Número de GPUs (n)
    numGPUs = parse(Int, lines[1])

    # Linha 2: Quantidade de VRAM (V)
    capacidadeGPU = parse(Int, lines[2])

    # Linha 3: Número de tipos diferentes (|T|)
    numTipos = parse(Int, lines[3])

    # Linha 4: Número de PRNs (m)
    numPRNs = parse(Int, lines[4])

    listaGPU = [GPU(i, 0, capacidadeGPU, Int[]) for i in 1:numGPUs]
    
    listaPRN = Vector{PRN}(undef, numPRNs)

    # Processa as PRNs nas próximas linhas
    for j in 1:numPRNs
        prn_data = split(lines[4 + j])
        tipo = parse(Int, prn_data[1]) + 1 # Tipo começa em 0
        custo = parse(Int, prn_data[2])

        listaPRN[j] = PRN(j, 0, custo, tipo) # GPU ainda não alocada (gpu_id = 0)
    end
    
    return numGPUs, capacidadeGPU, numTipos, numPRNs, listaGPU, listaPRN
end

function teste()
    printLerArquivo("dog_0.txt")
end

# Descomentar include de structs.jl e chamada da função teste() para testar.
#teste()

#export numGPUs, capacidadeGPU, numTipos, numPRNs, listaGPU, listaPRN
