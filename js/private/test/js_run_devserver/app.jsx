import React from 'react';
import { createRoot } from 'react-dom/client';
import { TestComponent } from '@my-org/test-component'; // 1st party package

const App = () => {
    return React.createElement(TestComponent, null, 'If you see me, there is no double React issue!');
}

// -----------------

const reactRootEl = document.createElement('div');
document.body.appendChild(reactRootEl);

const root = createRoot(reactRootEl);
root.render(React.createElement(App, null, ''));