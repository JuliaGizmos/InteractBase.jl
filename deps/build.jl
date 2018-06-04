using NodeJS

cd(joinpath(dirname(@__FILE__), "..", "assets", "npm")) do
    npm = NodeJS.npm_cmd()
    run(`$npm install -y`)
    run(`$npm install -y katex`)
end
