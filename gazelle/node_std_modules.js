console.log(
    JSON.stringify(
        require('module').builtinModules.filter(m => !m.startsWith('_'))
    )
)