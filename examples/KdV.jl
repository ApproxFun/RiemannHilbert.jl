using ApproxFun, SingularIntegralEquations, RiemannHilbert, Plots


struct ReflectionCoefficient{VM, VP} <: Function
    V₋::VM
    V₊::VP
end

function ReflectionCoefficient(V, a=-50.0, x₀=0.0, b=50.0)
    d₋, d₊ = a .. x₀ , x₀ .. b
    V₋,V₊ = Fun(V, d₋), Fun(V, d₊)
    ReflectionCoefficient{typeof(V₋),typeof(V₊)}(V₋,V₊)
end

# ψ'' + (V(x) + k^2) ψ = 0
function (R::ReflectionCoefficient)(k)
    k == 0 && return -one(ComplexF64)

    a,x₀ = endpoints(domain(R.V₋))
    b = rightendpoint(domain(R.V₊))
    D = Derivative()
    V₋,V₊ = R.V₋, R.V₊
    ψ = [ivp(); D^2  + (V₋ + k^2)] \ [exp(im*k*a), im*k*(exp(im*k*a)), 0.0]

    F = qr([rdirichlet(space(V₊)); rneumann(); D^2  + (V₊ + k^2)])
    ϕ₊ = F \ [exp(im*k*b), im*k*(exp(im*k*b)), 0.0]
    ϕ₋ = F \ [exp(-im*k*b), -im*k*(exp(-im*k*b)), 0.0]

    a,b = [ϕ₊(x₀)   ϕ₋(x₀);
           ϕ₊'(x₀)  ϕ₋'(x₀)] \ [ψ(x₀); ψ'(x₀)]
    b/a
end

# use multiple threads since reflection coefficient is slow
function tvalues(f, d, n)
    p = points(d, n)
    F = similar(p, ComplexF64)
    Threads.@threads for k=1:length(p)
        F[k] = R(p[k])
    end
    F
end

tFun(f, d::Space, n) = Fun(d, transform(d,tvalues(f,d,n)))

tFun(f, d, n) = tFun(f, Space(d), n)

V = x -> 0.1sech(x)
R = ReflectionCoefficient(V)
@time ρ = tFun(R, -5.0..5, 601)
plot(abs.(ρ.coefficients); yscale=:log10)
plot(ρ)

let k = Fun(identity, space(ρ))
    G = (t,x) -> [1-abs2.(ρ) -conj.(ρ)*exp(-2im*k*x-8im*k^3*t);
         ρ*exp(2im*k*x+8im*k^3*t)           1.0]

    Gx = (t,x) -> [0 2im*k*conj.(ρ)*exp(-2im*k*x-8im*k^3*t);
          2im*k*ρ*exp(2im*k*x+8im*k^3*t)           0.0]
end


function quickinv(F)
    A = Array(F)
    V = values.(pad.(A, maximum(ncoefficients.(A))))
    Vi = [inv([V[k,j][p] for k=1:2, j=1:2]) for p=1:length(V[1,1])]
    Fun(Fun([Fun(sp,transform(sp,[Vi[p][k,j] for p=1:length(Vi)])) for k=1:2, j=1:2]), space(F))
 end

# Φ⁺ = Φ⁻*G
# Φₓ⁺ - Φₓ⁻*G = Φ⁻*Gₓ
# Φₓ = ψ*Φ
# ψ₊ - ψ₋ = Φ⁻*Gₓ*inv(Φ₊)

# U - (G-I)*C₋U = G-I
#

import RiemannHilbert: fpstieltjesmatrix
import ApproxFun: transform
@time Φ = transpose(rhsolve(transpose(G), 2*4*200))
h = 0.0001
@time Φ_h = transpose(rhsolve(transpose(G(0.0,h)), 2*4*200))

n = 2*4*200; S₋ = fpstieltjesmatrix(space(U)[1,1], n÷2, n÷2)

(z = 0.1+eps()im; (Φ_h(z)-Φ(z))/h) -
    (z = 0.1-eps()im; ((Φ_h(z)-Φ(z))/h)*G(0.,0.)(0.1))


Φ_h(0.1+eps()im)-Φ_h(0.1-eps()im)*G(0.0,h)(0.1)

(Φ₋*Gx(0,0))(0.1)



cauchy(Φ₋*Gx(0,0)*quickinv(Φ₊), z)*Φ(z)

(z=0.1+eps()im; cauchy(Φ₋*Gx(0,0)*quickinv(Φ₊), z)*Φ(z)) -
    (z=0.1-eps()im; cauchy(Φ₋*Gx(0,0)*quickinv(Φ₊), z)*Φ(z))*G(0,0)(0.1) -
            (Φ₋*Gx(0,0))(0.1)





(istieltjes(Φ)/(-2π*im)+Φ₋)(0.1)

Φ₊ = (istieltjes(Φ)*(-2π*im)+Φ₋)
Φ(0.1-eps()im)

Φ₊(0.1) - Φ₋(0.1)





Φ(0.1+eps()*im) - Φ(0.1-eps()*im)




I+stieltjes(istieltjes(Φ),0.1+eps()*im) - Φ(0.1+eps()*im)



I+stieltjes(istieltjes(Φ),0.1-eps()*im) - Φ(0.1-eps()*im)
stieltjes(istieltjes(Φ),0.1+eps()*im)-stieltjes(istieltjes(Φ),0.1-eps()*im)



istieltjes(Φ)(0.1)*(-2π*im)

istieltjes(Φ)(0.1)

Φ₋(0.1) - Φ(0.1-eps()*im)


U(0.1)/(-2π*im)

Fun(I+[Fun(space(U)[k,j], ApproxFun.transform(space(U)[k,j], S₋*U[k,j].coefficients)) for k=1:2,j=1:2]) |> space

Φ₋(0.1)
Φ(0.1-eps()im)

V(0.1


Φ(0.1+eps()im) - Φ(0.1-eps()im)*G(0,0)(0.1)

istieltjes(Φ)(0.1)*(-2π*im) - (Φ(0.1+eps()im) - Φ(0.1-eps()im))

G⁻¹(0.1) - inv(G(0,0)(0.1))

G⁻¹(0.1)*Φ(0.1-eps()im) - Φ(0.1+eps()im)


U = istieltjes(Φ)
Φ₋ =  Fun(Fun(I+[Fun(space(U)[k,j], ApproxFun.transform(space(U)[k,j], S₋*U[k,j].coefficients)) for k=1:2,j=1:2]),
            ApproxFun.ArraySpace(Chebyshev(domain(ρ)), 2, 2))

domain(ρ)
Φ₋⁻¹ = quickinv(Φ₋)
G⁻¹ = quickinv(G)

z = 190000.0im; 2im*(z*[1,1]'cauchy(Φ₋*Gx(0,0)*quickinv(Φ₊), z)*Φ(z))[1]

cauchy(

V(0.0)
sech(0.0)

space(Gx)

inv.(G)

G[1,1]*Φ₋⁻¹[1,1]

ncoefficients(G[1,1])
ncoefficients(Φ₋⁻¹)


space(Φ₋⁻¹)

M = [Fun(sp,transform(sp,[Vi[p][k,j] for p=1:length(Vi)])) for k=1:2, j=1:2]
k=j=1;Fun(sp,transform(sp,[Vi[p][k,j] for p=1:length(Vi)])) |> typeof
typeof(sp)
ϕ₋⁻¹(0.1) - inv(Φ(0.1-eps()im))

S₋*U[1,1].coefficients

inv.(Φ₋)

@profiler stieltjes(U,0.1+eps()im)

Φ(0.1-eps()*im)


U = istieltjes(Φ)
@time Φ(0.1⁺)
@profiler stieltjes(U,0.1+0.1im)

Fun(x -> Φ((x)⁺), domain(ρ), 20)

ncoefficients(ρ)

(I+stieltjes(U,1+im)) - Φ(1+im)

([1 1]*Φ(100.0im))[1]

norm(Φ(0.1+eps()im) - Φ(0.1-eps()im)*G(0.1))


hilbert(

D^2 + Fun(V, -10..10)


z = Fun(ℂ)
-2im*(z*Φ[2,1])(Inf)
-2im*1000Φ[2,1](1000)
0.1sech(0.0)

Φ(100.0im)

Φ(0.1-eps()im)*G(0.1)

domain(ρ)

v = tvalues(R, Chebyshev(-10..10), 100)


R(8.0)

plot(real.(v))
    plot!(imag.(v))

R(0.0)
R(-0.0000)



ρ(0.1)
R(0.1)

plot(ρ)

ρ.coefficients

ρ.coefficients


f = R
n = 100
d = Chebyshev(-10..10)



@time R(1.0)
ret = Vector{ComplexF64}(undef,100)
@time Threads.@threads for k=1:length(ret)
    ret[k] = R(k/10)
end

@time for k=1:100
    ret[k] = R(k/10)
end

@time pmap(R, 1.0:4)


ρ = Fun(R, -10..10, 200)

@time R(10.0)

ks = -10.0:0.1:10.0
Rks = R.(ks)

plot(ks, real.(Rks))
    plot!(ks, imag.(Rks))

R(0.1+0.1im)


#####
# Factor KdV
######
