const { chromium } = require('playwright')

async function inspectSelector(page, selector) {
  return page.evaluate((sel) => {
    const node = document.querySelector(sel)
    if (!node) return null
    const s = window.getComputedStyle(node)
    const r = node.getBoundingClientRect()
    return {
      selector: sel,
      display: s.display,
      visibility: s.visibility,
      opacity: s.opacity,
      zIndex: s.zIndex,
      position: s.position,
      pointerEvents: s.pointerEvents,
      width: r.width,
      height: r.height,
      top: r.top,
      left: r.left,
      backgroundColor: s.backgroundColor,
      color: s.color,
      text: (node.textContent || '').trim().slice(0, 120)
    }
  }, selector)
}

async function main() {
  const browser = await chromium.launch({ headless: true })
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 } })

  await page.goto('http://192.168.31.224:8081', {
    waitUntil: 'domcontentloaded',
    timeout: 120000
  })
  await page.waitForTimeout(5000)

  await page.screenshot({ path: './tmp-ui-inspect.png', fullPage: true })

  const selectors = [
    '.app-root',
    '.app-root__viewport',
    '.app-root__shell',
    '.app-shell',
    '.app-shell__body',
    '.control-wing--left',
    '.control-wing--right',
    '.bottom-dock'
  ]

  const results = {}
  for (const selector of selectors) {
    results[selector] = await inspectSelector(page, selector)
  }

  console.log(JSON.stringify(results, null, 2))
  await browser.close()
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
