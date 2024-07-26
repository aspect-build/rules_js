import _ from 'lodash'
import { name as mylibname } from '@mycorp/mylib'
import { name as mypkgname } from '@mycorp/mypkg'

function component() {
    const element = document.createElement('div')

    // Lodash, currently included via a script, is required for this line to work
    element.innerHTML = _.join(
        ['Hello', 'webpack', mylibname(), mypkgname()],
        ' '
    )

    return element
}

document.body.appendChild(component())
