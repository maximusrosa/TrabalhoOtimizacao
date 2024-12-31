include("structs.jl")

function lerArquivo(filePath)
    # Lê o arquivo e processa as linhas não vazias
    lines = filter(x -> !isempty(x), readlines(filePath))

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
        tipo = parse(Int, prn_data[1]) + 1 # Tipo começava em 0
        custo = parse(Int, prn_data[2])

        listaPRN[j] = PRN(j, 0, custo, tipo) # GPU ainda não alocada (gpuID = 0)
    end

    contTipoGPU = fill(UInt8(0), numGPUs, numTipos)

    #=
    # Solução mínima, melhor solução que pode ser factível.
    somaTipos = fill(0, numTipos)
    quantTipos = fill(0, numTipos)
    for prn in listaPRN
        somaTipos[prn.tipo] += prn.custo
        quantTipos[prn.tipo] += 1
    end
    
    count = 1
    quantTotalGPUs = 0
    for soma in somaTipos
        quantGPUs = ceil(soma / 100)
        println("Tipo ", count, ": ", quantGPUs) # 100 é a capacidade da GPU
        count += 1
        quantTotalGPUs += quantGPUs
    end
    println("Solução mínima: ", quantTotalGPUs)

    
    #Distribuição de tipos
    println("Tipo: $(tipo), Quantidade: $(quantTipos)")

    #Custo médio de PRNs
    custoTotal = 0
    for prn in listaPRN
        custoTotal += prn.custo
    end
    println("Custo médio de PRNs: ", custoTotal / numPRNs)
    =#

    contTipoGPU = fill(UInt8(0), numGPUs, numTipos)

    # Calcula a soma dos custos de todas as PRNs
    custoTotal = sum(prn.custo for prn in listaPRN)

    # Calcula a soma das capacidades de todas as GPUs
    capacidadeTotal = numGPUs * capacidadeGPU

    # Calcula a razão entre a soma dos custos das PRNs e a soma das capacidades das GPUs
    razaoCustoCapacidade = custoTotal / capacidadeTotal * 100

    #println("Razão entre a soma dos custos das PRNs e a soma das capacidades das GPUs: ", razaoCustoCapacidade)

    return numGPUs, capacidadeGPU, numTipos, numPRNs, listaGPU, listaPRN, contTipoGPU
end

#=
dog_1 = 85.08%
dog_2 = 85%
dog_3 = 80%
dog_4 = 80.22824858757062%
dog_5 = 80.08
dog_7 = 85%
=#

# Arquivo de entrada
filePath = "dog/dog_7.txt"

const global NUM_GPUs, CAPACIDADE_GPU, NUM_TIPOS, NUM_PRNs, listaGPU, listaPRN, contTipoGPU = lerArquivo(filePath)