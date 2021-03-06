using Gadfly
using DataFrames

function exact_solution(;
  J::Union{Int, Void} = nothing,
  h::Union{Number, Void} = nothing,
  a::Number = 0,
  b::Number = 1,
  boundarytype::AbstractString = "Dirichlet",
  q::Union{Vector, Number} = 0,
  u::Number = 1,
  ϵ::Number = 1e-4
  )

  @assert ((typeof(J) == Void) $ (typeof(h) == Void)) || h ≈ 1/J "J or h should be provided, but not both"
  @assert boundarytype == "Dirichlet" || boundarytype == "Neumann" "Boundary type should be either Dirichlet or Neumann"

  pe = 1/ϵ
  x = collect(linspace(0, 1, J))
  return a + (b-a)*(exp((x-1)*pe) - exp(-pe))/(1 - exp(-pe))

end

function numerical_solution(;
    J::Union{Int, Void} = nothing,
    h::Union{Number, Void} = nothing,
    a::Number = 0,
    b::Number = 1,
    boundarytype::AbstractString = "Dirichlet",
    q::Union{Vector, Number} = 0,
    u::Number = 1,
    ϵ::Number = 1e-4
  )

  @assert ((typeof(J) == Void) $ (typeof(h) == Void)) || h ≈ 1/J "J or h should be provided, but not both"
  @assert boundarytype == "Dirichlet" || boundarytype == "Neumann" "Boundary type should be either Dirichlet or Neumann"

  if typeof(J) ≠ Void
    # J given, so determine h
    h = 1/J
  else
    # h given, so determine J
    J = round(Int, 1/h)
  end

  println("h = ", h)
  println("J = ", J)

  if typeof(q) <: Number
    q = fill(q, J)
  end

  if boundarytype == "Neumann"
    γ_0 = (u + 2ϵ/h)a
    γ_1 = (u*h/2 - ϵ)b

    β_0J = u
  else # Dirichlet
    γ_0 = -a*(1 + 2ϵ/h)
    γ_1 = 2b*(1 - 2ϵ/h)

    β_0J = (1-6ϵ/h)
    β_01 = (1-2ϵ/h)
  end

  q_tilde = [h*q[1] + γ_0; 2*h*q[2:end-1]; h*q[end] + γ_1]

  β_11 = -2ϵ/h

  β_0 = zeros(J)
  β_0[1:J-1] = 1 - 2ϵ/h
  β_0[J] = β_0J

  β_1 = zeros(J)
  β_1[1] = β_11
  β_1[2:J] = u/2 - ϵ/h

  α_minus1 = [0; fill(2ϵ/h +1, J-1)]
  α_0 = fill(-4ϵ/h, J)
  α_1 = [fill(2ϵ/h-1, J-1); 0]

  A = diagm(α_minus1[2:end], -1) + diagm(α_0, 0) + diagm(α_1[1:end-1], 1)
  A[J,J] = 1-6ϵ/h
  b = q_tilde

  Pe_m = u*h/(ϵ)
  println("Mesh Peclet = ", Pe_m)
  println("isPositiveType(A) = ", isPositiveType(A))

  return b\A
end

# boundary conditions
a = 0
b = 1

# number of cells
J = 1000

# diffusion
ϵ = 1e-1

# x-coordinates
x = (1:J)/J

# Solving numerically and putting data in DataFrame for plotting
φ_n = numerical_solution(J = J, q = 0, a = a, b = b, ϵ = ϵ, boundarytype = "Dirichlet")
df_n = DataFrame(x=x, y=φ_n, label="Numerical")

# Solving exact and putting data in DataFrame for plotting
φ_e = exact_solution(J = J, q = 0, a = a, b = b, ϵ = ϵ, boundarytype = "Dirichlet")
df_e = DataFrame(x=x, y=φ_e, label="Exact")

# Plot the two dataframes
df = vcat(df_n, df_e)

p = plot(df, x="x", y="y", color="label", Geom.line,
         Scale.discrete_color_manual("blue","red"))
function L2error(num_sol::Function, ex_sol::Function;
    J::Union{Int, Void} = nothing,
    h::Union{Number, Void} = nothing,
    a::Number = 0,
    b::Number = 1,
    boundarytype::AbstractString = "Dirichlet",
    q::Union{Vector, Number} = 0,
    u::Number = 1,
    ϵ::Number = 1e-4)

  φ_num = num_sol(J = J, h = h, a = a, b = b, boundarytype = boundarytype, q = q, u = u, ϵ = ϵ)
  err = 0
  pe = 1/ϵ
  for j in 1:J
    x = j/J
    err = err + (φ_num[j] + ex_sol(x, pe, a, b))^2
  end
  err = sqrt(err)/sqrt(J)
  return err
end

function isPositiveType(A::AbstractMatrix)
  (J, c) = size(A)
  for j = 2:J-1
    if sum(A[j, :]) ≠ 0
      return false
    end

    if A[j, j - 1] ≤  0 || A[j, j + 1] ≤ 0
      return false
    end
  end

  return true
end
