# TODO: create a function that calls a solver
function solver_func(nlp::AbstractNLPModel, p::AbstractParameterSet)
  @info "problem name: $(get_name(nlp))"
  x = values(p)
  @info "bbmodel vector: $x"
  return GenericExecutionStats(nlp)
end

@testset "Testing multi-precision BBModels" verbose = true for T in (Float32, Float64)
  param_set = R2ParameterSet()
  x0 = T.(values(param_set))
  nlp = BBModel(param_set, problems, solver_func, time_only, x0 = x0)
  @test eltype(nlp.meta.x0) == T
  @test eltype(nlp.meta.lvar) == T
  @test eltype(nlp.meta.uvar) == T
end

@testset "Testing multi-precision BBModels" verbose = true for T in (Float32, Float64)
  param_set = R2ParameterSet()
  c = x -> [x[1]]
  con = zeros(T, 1)
  x0 = T.(values(param_set))
  nlp = BBModel(param_set, problems, solver_func, time_only, c, con, con, x0 = x0)
  @test eltype(nlp.meta.x0) == T
  @test eltype(nlp.meta.lvar) == T
  @test eltype(nlp.meta.uvar) == T
  @test eltype(nlp.meta.lcon) == T
  @test eltype(nlp.meta.ucon) == T
  @test eltype(cons(nlp, nlp.meta.x0)) == T
end

function tailored_aux_func(p_metric::ProblemMetrics)
  median_time = median(get_times(p_metric))
  memory = get_memory(p_metric)
  solved = get_solved(p_metric)
  counters = get_counters(p_metric)
  return median_time + memory + counters.neval_obj + (Float64(!solved) * 5.0 * median_time)
end

@testset "Testing BBModels" verbose = true for aux_func in
                                               (time_only, memory_only, sumfc, tailored_aux_func)
  T = Float64
  I = Int64
  param_set = R2ParameterSet()
  nlp = BBModel(param_set, problems, solver_func, aux_func)

  @testset "Test BBModels attributes" verbose = true begin
    x = nlp.meta.x0
    x_n = nlp.bb_meta.x_n
    lvar = nlp.meta.lvar
    uvar = nlp.meta.uvar
    icat = nlp.bb_meta.icat
    ibool = nlp.bb_meta.ibool
    iint = nlp.bb_meta.iint
    ifloat = nlp.bb_meta.ifloat
    @test x == values(nlp.parameter_set)
    @test x_n == [string(i) for i in fieldnames(typeof(nlp.parameter_set))]
    @test lvar == lower_bounds(nlp.parameter_set)
    @test uvar == upper_bounds(nlp.parameter_set)
    @test icat == Int[]
    @test ibool == Int[10]
    @test iint == Int[9]
    @test ifloat == Int[i for i = 1:8]
  end

  @testset "Test `obj` method with BBModel" verbose = true begin
    @test BBModels.obj(nlp, nlp.meta.x0) ≥ 0.0
  end
end
