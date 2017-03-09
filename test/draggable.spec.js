'use strict'

const jsdom = require("jsdom")
const { compileToString } = require('node-elm-compiler')
const { expect } = require('chai')

const ELM_TEST_APP = './DraggableTest.elm'

suite('Draggable', function() {
  const irrelevantCoord = 12

  before(function(done) {
    this.timeout(1000000)

    loadElmFile(ELM_TEST_APP, window => {
      global.document = window.document
      global.window = window

      done()
    }).catch(done)
  })

  suite('Basic subscription', () => {
    let basicTarget

    const firstMove = { x: 30, y: 40 }
    const secondMove = { x: 50, y: 80 }

    setup(() => {
      basicTarget = document.getElementById('basic-subscription-target')
    })

    test('1 - mouse down triggers drag', async() => {
      basicTarget.dispatchEvent(mouseDown(0, 0))
      expect(await getLogMessage()).to.equal(triggerMessage())
    })

    test('2 - first mouse move returns empty delta', async() => {
      document.dispatchEvent(mouseMove(irrelevantCoord, irrelevantCoord))
      expect(await getLogMessage()).to.equal(updateMessage(0, 0))
    })

    test('3 - second mouse move actually returns the delta', async() => {
      const { x, y } = firstMove
      document.dispatchEvent(mouseMove(x, y))
      expect(await getLogMessage()).to.equal(updateMessage(x, y))
    })

    test('4 - third mouse move returns the delta between current and previous position', async() => {
      const { x: x1, y: y1 } = firstMove
      const { x: x2, y: y2 } = secondMove

      document.dispatchEvent(mouseMove(x2, y2))
      expect(await getLogMessage()).to.equal(updateMessage(x2 - x1, y2 - y1))
    })

    test('5 - mouse up yields empty delta', async() => {
      document.dispatchEvent(mouseUp())
      expect(await getLogMessage()).to.equal(updateMessage(0, 0))
    })

    test('[right click] does not trigger drag', done => {
      basicTarget.dispatchEvent(mouseEvent('mousedown', { button: 2 }))

      getLogMessage()
        .then(() => {
          // Reset the state in case the test fails and the drag IS triggered.
          document.dispatchEvent(mouseUp())

          done(Error('Expected right click not to trigger drag'))
        })
        .catch(() => {
          // If not message is received, we're fine.
          done()
        })
    })

    function triggerMessage() {
      return 'TriggerBasicDrag'
    }

    function updateMessage(x, y) {
      return `UpdateBasicDrag ${x}, ${y}`
    }
  })

  suite('Event subscription', () => {
    let eventTarget

    const firstMove = { x: 30, y: 40 }
    const secondMove = { x: 50, y: 80 }

    setup(() => {
      eventTarget = document.getElementById('event-subscription-target')
    })

    test('[drag] 1 - mouse down triggers drag', async() => {
      eventTarget.dispatchEvent(mouseDown(0, 0))
      expect(await getLogMessage()).to.equal(triggerMessage())
    })

    test('[drag] 2 - first mouse move yields DragStart', async() => {
      document.dispatchEvent(mouseMove(irrelevantCoord, irrelevantCoord))
      expect(await getLogMessage()).to.equal(updateMessage('DragStart'))
    })

    test('[drag] 3 - second mouse returns the delta between current and initial position', async() => {
      const { x, y } = firstMove
      document.dispatchEvent(mouseMove(x, y))
      expect(await getLogMessage()).to.equal(dragByMessage(x, y))
    })

    test('[drag] 4 - third mouse move returns the delta between current and previous position', async() => {
      const { x: x1, y: y1 } = firstMove
      const { x: x2, y: y2 } = secondMove

      document.dispatchEvent(mouseMove(x2, y2))
      expect(await getLogMessage()).to.equal(dragByMessage(x2 - x1, y2 - y1))
    })

    test('[drag] 5 - mouse up yields empty delta', async() => {
      document.dispatchEvent(mouseUp())
      expect(await getLogMessage()).to.equal(updateMessage('DragEnd'))
    })

    test('[click] - Click is yielded if no mouse move', async() => {
      eventTarget.dispatchEvent(mouseDown(0, 0))
      await getLogMessage()
    })

    function triggerMessage() {
      return 'TriggerEventDrag'
    }

    function dragByMessage(x, y) {
      return updateMessage(`DragBy (${x},${y})`)
    }

    function updateMessage(dragEvent) {
      return `UpdateEventDrag ${dragEvent}`
    }
  })

  suite('Custom trigger', () => {
    let customTriggerTarget

    before(() => {
      customTriggerTarget = document.getElementById('custom-trigger-target')
    })

    test('1 - mouse offsetX is sent on the trigger event', async() => {
      const offsetX = 123
      customTriggerTarget.dispatchEvent(mouseEvent('mousedown', { offsetX }))
      expect(await getLogMessage()).to.equal(`CustomTrigger ${offsetX}`)
    })

    test('2 - Click is still yielded at mouse up', async() => {
      document.dispatchEvent(mouseUp())
      expect(await getLogMessage()).to.equal('UpdateEventDrag Click') // reusing event drag
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
  return new Promise((resolve, reject) => {
    APP.ports.log.subscribe(handler)

    function handler(data) {
      APP.ports.log.unsubscribe(handler)
      resolve(data)
    }

    setTimeout(() => reject(Error('Timeout')), 100)
  })
}

function loadElmFile(fileName, callback) {
  return compileToString([fileName], {
    cwd: './test',
    yes: true,
    verbose: true,
    warn: true,
  }).then(data => {
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
