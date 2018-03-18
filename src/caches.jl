abstract type AbstractTypeDict end
function valuetype end
function makevalue end

@inline function Base.getindex(c::C, ::Type{T}) where {C<:AbstractTypeDict, T}
    ReturnType = valuetype(C, T)
    key = (object_id(T), Threads.threadid())
    @inbounds for i in eachindex(c.keys)
        if c.keys[i] === key
            return c.values[i]::ReturnType
        end
    end
    value = makevalue(c, T)
    push!(c.keys, key)
    push!(c.values, value)
    value::ReturnType
end

"""
$(TYPEDEF)

A container that manages the creation and storage of [`MechanismState`](@ref)
objects of various scalar types, associated with a given `Mechanism`.

A `StateCache` can be used to write generic functions that use `MechanismState`
objects, while avoiding overhead due to the construction of a new `MechanismState`
with a given scalar type every time the function is called.

# Examples
```julia-repl
julia> mechanism = rand_tree_mechanism(Float64, Revolute{Float64}, Prismatic{Float64}, QuaternionFloating{Float64});

julia> cache = StateCache(mechanism)
StateCache{…}

julia> state32 = cache[Float32]
MechanismState{Float32, Float64, Float64, …}(…)

julia> cache[Float32] === state32
true

julia> cache[Float64]
MechanismState{Float64, Float64, Float64, …}(…)
```
"""
struct StateCache{M, JointCollection} <: AbstractTypeDict
    mechanism::Mechanism{M}
    keys::Vector{Tuple{UInt64, Int}}
    values::Vector{MechanismState}
end

function StateCache(mechanism::Mechanism{M}) where M
    JointCollection = typeof(TypeSortedCollection(joints(mechanism)))
    StateCache{M, JointCollection}(mechanism, [], [])
end

Base.show(io::IO, ::StateCache) = print(io, "StateCache{…}(…)")

@inline function valuetype(::Type{StateCache{M, JC}}, ::Type{X}) where {M, JC, X}
    C = promote_type(X, M)
    MSC = motionsubspacecollectiontype(JC, X)
    WSC = wrenchsubspacecollectiontype(JC, X)
    MechanismState{X, M, C, JC, MSC, WSC}
end

@inline makevalue(c::StateCache, ::Type{X}) where X = MechanismState{X}(c.mechanism)


"""
$(TYPEDEF)

A container that manages the creation and storage of [`DynamicsResult`](@ref)
objects of various scalar types, associated with a given `Mechanism`.
Similar to [`StateCache`](@ref).
"""
struct DynamicsResultCache{M} <: AbstractTypeDict
    mechanism::Mechanism{M}
    keys::Vector{Tuple{UInt64, Int}}
    values::Vector{DynamicsResult{<:Any, M}}
end

Base.show(io::IO, ::DynamicsResultCache{M}) where {M} = print(io, "DynamicsResultCache{$M}(…)")

DynamicsResultCache(mechanism::Mechanism{M}) where {M} = DynamicsResultCache{M}(mechanism, [], [])
@inline valuetype(::Type{DynamicsResultCache{M}}, ::Type{T}) where {M, T} = DynamicsResult{T, M}
@inline makevalue(c::DynamicsResultCache, ::Type{T}) where {T} = DynamicsResult{T}(c.mechanism)
