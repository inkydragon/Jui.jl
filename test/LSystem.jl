module LSystem

const Rule = Dict{String, Any}
const RULES = [
Dict(
    "S"=>"F", "F"=>"F+F--F+F",
    "direct"=>0,
    "angle"=>60,
    "iter"=>5,
    "title"=>"Koch curve"
),
Dict(
    "S"=>"F--F--F", "F"=>"F+F--F+F",
    "direct"=>0,
    "angle"=>60,
    "iter"=>5,
    "title"=>"Koch snowflake"
),
Dict(
    "S"=>"FX", "X"=>"X+YF+", "Y"=>"-FX-Y",
    "direct"=>0,
    "angle"=>90,
    "iter"=>11,
    "title"=>"Dragon"
),
Dict(
    "S"=>"f", "f"=>"F-f-F", "F"=>"f+F+f",
    "direct"=>0,
    "angle"=>60,
    "iter"=>7,
    "title"=>"Sierpinski triangle"
),
Dict(
    "S"=>"X", "X"=>"F-[[X]+X]+F[+FX]-X", "F"=>"FF",
    "direct"=>-45,
    "angle"=>25,
    "iter"=>6,
    "title"=>"Plant"
),
Dict(
    "S"=>"X", "X"=>"-YF+XFX+FY-", "Y"=>"+XF-YFY-FX+",
    "direct"=>90,
    "angle"=>90,
    "iter"=>5,
    "title"=>"Hilbert"
),
]

const DEFAULT_RULE = RULES[1]

function genStepString(rule::Rule) :: String
    start = rule["S"]
    iter  = rule["iter"]
    angle = rule["angle"]

    for i in 1:iter
        rt = []
        for c in start
            c = string(c)
            push!(rt, get(rule, c, c))
        end
        start = join(rt, "")
    end

    start
end

function genStep(rule::Rule=DEFAULT_RULE, param=Dict())
    merge!(rule, param)
    
    angle = rule["direct"]
    Δθ =    rule["angle"]
    sp =    get(rule, "start point", (0, 0))
    l =     get(rule, "step length", 10)

    steps = []
    stack = []
    str = genStepString(rule)

    for c in str
        if c in "Ff"
            r = angle * 2π/360
            ep = sp .+ (l*cos(r), l*sin(r))
            push!(steps, (sp, ep))
            sp = ep
        elseif c == '+'
            angle += Δθ
        elseif c == '-'
            angle -= Δθ
        elseif c == '['
            push!(stack, (sp, angle))
        elseif c == ']'
            sp, angle = pop!(stack)
        else
            # @warn("Invalid character `$c` in steps string.")
        end
    end

    steps
end

function getAllRules(rules=RULES)
    [d["title"] for d in rules]
end

end  # module LSystem