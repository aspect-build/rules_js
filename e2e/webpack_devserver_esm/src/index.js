import _ from 'lodash'
import { name } from '@mycorp/mylib'

function component() {
    const element = document.createElement('div')

    // Lodash, currently included via a script, is required for this line to work
    element.innerHTML = _.join(['Hello', 'webpack', name()], ' ')

    return element
}

document.body.appendChild(component())
