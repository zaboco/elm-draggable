'use strict'

const jsdom = require("jsdom")
const { compileToString } = require('node-elm-compiler')
const chai = require('chai')

chai.should()

describe('Draggable', function () {
  before(function (done) {
    this.timeout(1000000)

    loadElmFile('./TestApp.elm', window => {
      global.document = window.document
      global.window = window

      done()
    }).catch(done)
  })

  function getLogEvent() {
    return new Promise(resolve => {
      APP.ports.log.subscribe(handler)

      function handler(data) {
        APP.ports.log.unsubscribe(handler)
        resolve(data)
      }
    })
  }

  it('handles mousedown', async() => {
    const box = document.getElementById('draggable-box')

    const mouseDownEvent = new window.Event('mousedown')
    mouseDownEvent.pageX = 10
    mouseDownEvent.pageY = 10
    mouseDownEvent.button = 0

    box.dispatchEvent(mouseDownEvent)

    const event = await getLogEvent()

    event.should.equal('Trigger')
  })

  it('handles mousemove', async() => {
    const box = document.getElementById('draggable-box')

    const mouseDownEvent = new window.Event('mousedown')
    mouseDownEvent.pageX = 10
    mouseDownEvent.pageY = 10
    mouseDownEvent.button = 0

    box.dispatchEvent(mouseDownEvent)

    await getLogEvent()

    const mouseMoveEvent = new window.Event('mousemove')
    mouseMoveEvent.pageX = 20
    mouseMoveEvent.pageY = 20

    document.dispatchEvent(mouseMoveEvent)

    const moveEvent = await getLogEvent()
    console.log('first', moveEvent)


    const mouseMoveEvent2 = new window.Event('mousemove')
    mouseMoveEvent2.pageX = 30
    mouseMoveEvent2.pageY = 20

    document.dispatchEvent(mouseMoveEvent2)

    const moveEvent2 = await getLogEvent()
    console.log('second', moveEvent2)
  })
})

function loadElmFile(fileName, callback) {
  return compileToString([fileName], { yes: true }).then(data => {
    jsdom.env({
      html: '',
      src: [data],
      done: (error, window) => {
        global.NodeList = window.NodeList // required for chai-dom
        global.HTMLElement = window.HTMLElement // required for chai-dom

        global.APP = window.Elm.TestApp.fullscreen()

        setTimeout(() => callback(window), 0)
      }
    })
  })

}
