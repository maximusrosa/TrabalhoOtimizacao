include("structs.jl")

function salvaSol(solucao::Solucao, filePath::String)
    open(filePath, "w") do f
        write(f, "Valor da Função Objetivo: $(Int(solucao.valorFO))\n")
        
        write(f, "\nLista de GPUs e PRNs alocadas:\n")
        for gpu in solucao.listaGPU
            write(f, "GPU ID: $(Int(gpu.id)), Num Tipos: $(Int(gpu.numTipos)), Capacidade Restante: $(Int(gpu.capacidadeRestante))\n")
            for prnID in gpu.listaIDsPRN
                write(f, "  PRN Alocada: $(Int(prnID)), custo = $(Int(solucao.listaPRN[prnID].custo)), tipo = $(Int(solucao.listaPRN[prnID].tipo))\n")
            end
        end
    end
end
