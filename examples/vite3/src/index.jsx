import React from 'react'
import { createRoot } from 'react-dom/client'

const App = () => <strong>Hello World</strong>

const container = document.getElementById('root')
if (container) {
    const root = createRoot(container)
    root.render(<App />)
}
