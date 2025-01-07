function lerArquivo(filePath)
    local lines

    # Lê o arquivo e processa as linhas não vazias
    try
        lines = filter(x -> !isempty(x), readlines(filePath))
    catch e
        throw(e)
    end

    # Linha 1: Número de GPUs (n)
    numGPUs = parse(UInt16, lines[1])

    # Linha 2: Quantidade de VRAM (V)
    capacidadeGPUs = parse(UInt16, lines[2])

    # Linha 3: Número de tipos diferentes (|T|)
    numTipos = parse(UInt8, lines[3])

    # Linha 4: Número de PRNs (m)
    numPRNs = parse(UInt16, lines[4])

    listaGPU = [GPU(UInt16(i), UInt8(0), capacidadeGPUs, UInt16[]) for i in 1:numGPUs]

    listaPRN = Vector{PRN}(undef, numPRNs)

    # Processa as PRNs nas próximas linhas
    for j in 1:numPRNs
        prn_data = split(lines[4 + j])
        tipo = parse(UInt8, prn_data[1]) + UInt8(1)  # Tipo começava em 0
        custo = parse(UInt8, prn_data[2])

        listaPRN[j] = PRN(UInt16(j), UInt16(0), custo, tipo)  # GPU ainda não alocada (gpuID = 0)
    end

    contTipoGPU = fill(UInt8(0), numGPUs, numTipos)

    return numGPUs, capacidadeGPUs, numTipos, numPRNs, listaGPU, listaPRN, contTipoGPU
end
