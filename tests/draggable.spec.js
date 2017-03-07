'use strict'

const jsdom = require("jsdom")
const { compileToString } = require('node-elm-compiler')
const { expect } = require('chai')

suite('Draggable', function () {


  before(function (done) {
    this.timeout(1000000)

    loadElmFile('./TestApp.elm', window => {
      global.document = window.document
      global.window = window

      done()
    }).catch(done)
  })

  suite('Basic subscription', () => {
    let basicTarget

    const irrelevantCoord = 12

    const firstMove = { x: 30, y: 40 }
    const secondMove = { x: 50, y: 80 }

    setup(() => {
      basicTarget = document.getElementById('basic-subscription-target')
    })

    test('1 - mouse down triggers drag', async() => {
      basicTarget.dispatchEvent(mouseDown(0, 0))
      expect(await getLogMessage()).to.equal('TriggerDrag')
    })

    test('2 - first mouse move returns empty delta', async() => {
      document.dispatchEvent(mouseMove(irrelevantCoord, irrelevantCoord))
      expect(await getLogMessage()).to.equal('UpdateDragBy 0, 0')
    })

    test('3 - second mouse move actually returns the delta', async() => {
      const {x, y} = firstMove
      document.dispatchEvent(mouseMove(x, y))
      expect(await getLogMessage()).to.equal(`UpdateDragBy ${x}, ${y}`)
    })

    test('4 - third mouse move returns the delta from the previous move', async() => {
      const {x: x1, y: y1} = firstMove
      const {x: x2, y: y2} = secondMove

      document.dispatchEvent(mouseMove(x2, y2))
      expect(await getLogMessage()).to.equal(`UpdateDragBy ${x2 - x1}, ${y2 - y1}`)
    })

    test('5 - mouse up yields empty delta', async() => {
      document.dispatchEvent(mouseUp())
      expect(await getLogMessage()).to.equal('UpdateDragBy 0, 0')
    })
  })
})

function mouseDown(pageX, pageY) {
  return mouseEvent('mousedown', { pageX, pageY })
}

function mouseUp() {
  return mouseEvent('mouseup')
}

function mouseMove(pageX, pageY) {
  return mouseEvent('mousemove', { pageX, pageY })
}

function mouseEvent(type = 'mousemove', params = {}) {
  const defaultParams = {
    pageX: 0,
    pageY: 0,
    button: 0
  }
  const mouseEvent = new window.Event(type)

  return Object.assign(mouseEvent, defaultParams, params)
}

function getLogMessage() {
  return new Promise(resolve => {
    APP.ports.log.subscribe(handler)

    function handler(data) {
      APP.ports.log.unsubscribe(handler)
      resolve(data)
    }
  })
}

function loadElmFile(fileName, callback) {
  return compileToString([fileName], { yes: true }).then(data => {
    jsdom.env({
      html: '',
      src: [data],
      done: (error, window) => {
        global.APP = window.Elm.TestApp.fullscreen()
        setTimeout(() => callback(window), 0)
      }
    })
  })

}
