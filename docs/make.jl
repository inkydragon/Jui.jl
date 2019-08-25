using Documenter, Jui

makedocs(;
    modules=[Jui],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/woclass/Jui.jl/blob/{commit}{path}#L{line}",
    sitename="Jui.jl",
    authors="woclass",
    assets=String[],
)
