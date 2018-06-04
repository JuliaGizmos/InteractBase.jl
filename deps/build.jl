using NodeJS
npm_path = joinpath(dirname(@__FILE__), "..", "assets", "npm")
mkpath(npm_path)
cd(npm_path) do
    npm = NodeJS.npm_cmd()
    run(`$npm install -y`)
    run(`$npm install -y katex`)
end
