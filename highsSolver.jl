using JuMP
using HiGHS
using Printf
using MathOptInterface

function ler_arquivo_entrada(nome_arquivo)
    linhas = filter(!isempty, readlines(nome_arquivo))
    num_gpus = parse(Int, linhas[1])
    vram_gpu = parse(Int, linhas[2])
    num_tipos = parse(Int, linhas[3])

    # Cria lista de PRNs com dados a partir da linha 5
    prns = [(parse(Int, split(linha)[1]) + 1, parse(Int, split(linha)[2])) for linha in linhas[5:end]]
    return num_gpus, vram_gpu, num_tipos, prns
end

# Define e resolve o modelo de otimização usando JuMP e o solver HiGHS.
function modelo_highs(num_gpus, vram_gpu, num_tipos, prns, tempoMax = 0.0)
    num_prns = length(prns)
    tipos = [pr[1] for pr in prns]  # Tipos de cada PRN
    custosPrn = [pr[2] for pr in prns]  # Consumo de VRAM de cada PRN

    # Criação do modelo
    model = Model(HiGHS.Optimizer)
    set_optimizer_attribute(model, "log_to_console", false)
    set_optimizer_attribute(model, "presolve", "on")
    set_optimizer_attribute(model, "threads", 4)
    if tempoMax > 0
        set_optimizer_attribute(model, "time_limit", tempoMax)
    end

    # Variáveis
    @variable(model, x[1:num_prns, 1:num_gpus], Bin)  # Alocação PRN -> GPU
    @variable(model, y[1:num_tipos, 1:num_gpus], Bin)  # Tipo presente na GPU

    # Restrições
    # Cada PRN deve estar em exatamente uma GPU
    @constraint(model, [i=1:num_prns], sum(x[i, j] for j in 1:num_gpus) == 1)

    # Respeitar a capacidade de VRAM de cada GPU
    @constraint(model, [j=1:num_gpus], sum(custosPrn[i] * x[i, j] for i in 1:num_prns) <= vram_gpu)

    # Vincular y[t, j] à presença de tipos na GPU
    @constraint(model, [t=1:num_tipos, j=1:num_gpus],
        sum(x[i, j] for i in 1:num_prns if tipos[i] == t) <= y[t, j] * num_prns)

    # Função objetivo: minimizar o número total de GPUs com tipos diferentes
    @objective(model, Min, sum(y[t, j] for t in 1:num_tipos, j in 1:num_gpus))

    # Resolver o modelo
    exec_time = @elapsed begin
        optimize!(model)
    end

    # Imprimir resultados
    if termination_status(model) != MOI.NO_SOLUTION
        println("Solução ótima encontrada!")
        println("Valor da função objetivo: ", objective_value(model))
        total_tipos = 0
        for j in 1:num_gpus
            capacidade_usada = sum(custosPrn[i] * value(x[i, j]) for i in 1:num_prns)
            tipos_na_gpu = [t for t in 1:num_tipos if value(y[t, j]) > 0.5]
            println("\nGPU $j:")
            println("  Capacidade usada: $capacidade_usada")
            println("  Quantidade de tipos: ", length(tipos_na_gpu))
            println("  Tipos presentes: ", tipos_na_gpu)
            total_tipos += length(tipos_na_gpu)
        end
        println("\nQuantidade total de tipos: $total_tipos")
    else
        println("Não foi encontrada uma solução.")
    end
    println("Tempo total de execução: ", round(exec_time, digits=2), " segundos")
    println("Status: ", termination_status(model))
end

function main()
    nome_arquivo = "dog/dog_3.txt"
    num_gpus, vram_gpu, num_tipos, prns = ler_arquivo_entrada(nome_arquivo)
    println(" Começando a execução do modelo, para arquivo ", nome_arquivo, "...")
    modelo_highs(num_gpus, vram_gpu, num_tipos, prns, 1800.0)
end

main()