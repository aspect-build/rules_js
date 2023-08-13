import React, { useState } from 'react';

/**
 * Clearly a very complex button component.
 */
export const TestComponent = props => {
    // Use a hook to trigger the "multiple copies of react" issue
    useState(42);

    return React.createElement('button', null, props.children);
};
