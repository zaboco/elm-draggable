'use strict'

const jsdom = require("jsdom")
const { compileToString } = require('node-elm-compiler')
const chai = require('chai')
const chaiDom = require('chai-dom')

chai.should()
chai.use(chaiDom)

describe('Draggable', function () {
  before(function (done) {
    loadElmFile('./TestApp.elm', window => {
      this.document = window.document
      done()
    })
  })

  it('works', function () {
    const box = this.document.getElementById('draggable-box')
    box.should.contain.text('Drag')
  })
})

function loadElmFile(fileName, callback) {
  compileToString([fileName], { yes: true }).then(data => {
    jsdom.env({
      html: '',
      src: [data],
      done: (error, window) => {
        global.NodeList = window.NodeList // required for chai-dom
        global.HTMLElement = window.HTMLElement // required for chai-dom

        window.Elm.TestApp.fullscreen()

        setTimeout(() => callback(window), 0)
      }
    })
  })

}
