global K = 1000

function foo()
    global x

    x *= 2
end

function main()
    global x

    x = 1

    foo()

    println(x)

    if x < K
        println("x é menor que K")
    else
        println("x é maior ou igual a K")
    end
end

main()