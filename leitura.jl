include("structs.jl")

using .Structs

function lerArquivo(file_path)
    # Lê o arquivo e processa as linhas não vazias
    lines = filter(x -> !isempty(x), readlines(file_path))

    # Linha 1: Número de GPUs (n)
    NUM_GPUs = parse(Int, lines[1])

    # Linha 2: Quantidade de VRAM (V)
    CAPACIDADE_MAX = parse(Int, lines[2])

    # Linha 3: Número de tipos diferentes (|T|)
    NUM_TIPOS = parse(Int, lines[3])

    # Linha 4: Número de PRNs (m)
    NUM_PRNs = parse(Int, lines[4])

    listaGPU = [GPU(i, 0, CAPACIDADE_MAX) for i in 1:NUM_GPUs]
    
    listaPRN = Vector{PRN}(undef, NUM_PRNs)

    # Processa as PRNs nas próximas linhas
    for j in 1:NUM_PRNs[]
        prn_data = split(lines[4 + j])
        tipo = parse(Int, prn_data[1]) + 1 # Tipo começa em 0
        custo = parse(Int, prn_data[2])

        listaPRN[j] = PRN(j, 0, custo, tipo) # GPU ainda não alocada (gpu_id = 0)
    end

    return NUM_GPUs, CAPACIDADE_MAX, NUM_TIPOS, NUM_PRNs, listaGPU, listaPRN
end
