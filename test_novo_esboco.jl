using Test

# Define constants
global NUM_PRNs = 3
global NUM_GPUs = 2
global NUM_TIPOS = 2

# Include the original file
include("novo_esboco.jl")

# Create test data
prn1 = PRN(1, 1, 10, 1)
prn2 = PRN(2, 1, 20, 1)
prn3 = PRN(3, 2, 30, 2)

gpu1 = GPU(1, 1, 100)
gpu2 = GPU(2, 1, 100)

listaPRN = [prn1, prn2, prn3]
listaGPU = [gpu1, gpu2]
contTipoGPU = [UInt8[1 0; 1 1]]

# Test vizinhanca function
@testset "Test vizinhanca function" begin
    novo_gpu_id = 2
    solucao = vizinhanca(listaPRN, listaGPU, contTipoGPU, valorObjetivo)
    
    @test solucao.listaPRN[1].gpu_id == 2
    @test solucao.listaGPU[1].num_tipos == 0
    @test solucao.listaGPU[2].num_tipos == 2
    @test solucao.contTipoGPU[1, 1] == 0
    @test solucao.contTipoGPU[1, 2] == 1
    @test solucao.valorFuncObj > 0
end