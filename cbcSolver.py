from pyomo.environ import *

def ler_arquivo_entrada(nome_arquivo):
    with open(nome_arquivo, 'r') as f:
        linhas = [linha.strip() for linha in f if linha.strip()]
    
    num_gpus = int(linhas[0])
    vram_gpu = int(linhas[1])
    num_tipos = int(linhas[2])
    
    # Cria lista de prns com dados a partir da linha 5.
    prns = []
    for linha in linhas[4:]:
        tipo, consumo = map(int, linha.split())
        tipo += 1
        prns.append((tipo, consumo))
    
    return num_gpus, vram_gpu, num_tipos, prns

def imprimir_resultados(model, custosPrn, tipos):
    if model.objetivo():
        print(f"Objetivo (Quantidade total de tipos): {model.objetivo():.2f}")
        
        total_tipos = 0
        tipos_por_gpu = []

        for j in model.GPUs:
            prns_alocadas = []
            capacidade_usada = 0
            tipos_na_gpu = set()
            
            for i in model.PRNs:
                if model.x[i, j]() > 0.5:
                    prns_alocadas.append((i, tipos[i], custosPrn[i]))
                    capacidade_usada += custosPrn[i]
                    tipos_na_gpu.add(tipos[i])
            
            tipos_por_gpu.append(tipos_na_gpu)
            
            print(f"\nGPU {j}:")
            print(f"Capacidade usada: {capacidade_usada}")
            print(f"Quantidade de tipos: {len(tipos_na_gpu)}")
            print("PRNs alocadas (ID, Tipo, Custo):")
            for prn in prns_alocadas:
                print(f"  PRN {prn[0]}: Tipo {prn[1]}, Custo {prn[2]}")
            for tipo in model.Tipos:
                if (tipo, j) in model.y and model.y[tipo, j]() > 0.5:
                    print(f"  Tipo {tipo} presente na GPU")
            total_tipos += len(tipos_na_gpu)
        
        print(f"\nQuantidade total de tipos somando todas as GPUs: {total_tipos}")
        print(f"Tipos por GPU: {tipos_por_gpu}")
    else:
        print("Nenhuma solução encontrada.")

def modelo_cbc(num_gpus, vram_gpu, num_tipos, prns, tempoMax):
    num_prns = len(prns)
    
    # Cria modelo.
    model = ConcreteModel()

    # Conjuntos.
    model.PRNs = RangeSet(num_prns)
    model.GPUs = RangeSet(num_gpus)
    model.Tipos = RangeSet(num_tipos)

    # Parâmetros.
    custosPrn = {i + 1: prns[i][1] for i in range(num_prns)}  # Consumo de VRAM por PRN
    tipos = {i + 1: prns[i][0] for i in range(num_prns)}  # Tipo de cada PRN

    # Variáveis.
    model.x = Var(model.PRNs, model.GPUs, domain=Binary)  # Alocação PRN -> GPU
    model.y = Var(model.Tipos, model.GPUs, domain=Binary)  # Tipo presente na GPU

    # Restrições.
    # Cada PRN deve estar em exatamente uma GPU.
    def unica_gpu_rule(model, i):
        return sum(model.x[i, j] for j in model.GPUs) == 1
    model.unica_gpu = Constraint(model.PRNs, rule=unica_gpu_rule)

    # Respeitar a capacidade de cada GPU.
    def capacidade_gpu_rule(model, j):
        return sum(custosPrn[i] * model.x[i, j] for i in model.PRNs) <= vram_gpu
    model.capacidade_gpu = Constraint(model.GPUs, rule=capacidade_gpu_rule)

    # Vincular y[t, j] à presença de tipos na GPU.
    def tipo_na_gpu_rule(model, t, j):
        return model.y[t, j] >= sum(model.x[i, j] for i in model.PRNs if tipos[i] == t) / num_prns
    model.tipo_na_gpu = Constraint(model.Tipos, model.GPUs, rule=tipo_na_gpu_rule)

    # Função objetivo: minimizar o número total de GPUs com tipos diferentes.
    model.objetivo = Objective(
        expr=sum(model.y[t, j] for t in model.Tipos for j in model.GPUs),
        sense=minimize
    )
    # Resolver
    solver = SolverFactory('cbc')
    if (tempoMax > 0):
        solver.options['sec'] = tempoMax
    solver.solve(model, tee=False)

    #imprimir_resultados(model, custosPrn, tipos)

    return model


def main():
    nome_arquivo = "dog/dog_9.txt"
    num_gpus, vram_gpu, num_tipos, prns = ler_arquivo_entrada(nome_arquivo)

    modelo_cbc(num_gpus, vram_gpu, num_tipos, prns, 1800)


if __name__ == "__main__":
    main()