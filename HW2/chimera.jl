using Gadfly
using DataFrames

include("functions.jl")

J = 100
K = 50
(x, y) = chimera_solution(J = J, K = K, h = 0.6/J, H = 0.5/K)

plot(x = x, y = y)
