// Run through Playwright MCP browser_run_code_unsafe({filename: ...}).
// Uses only the local demo web preview; native delivery needs Android QA.
async (page) => {
  const origin = 'http://localhost:7360';
  if (!page.url().startsWith(origin + '/')) throw Error('Local preview required');
  const checks = [];
  const pause = () => page.waitForTimeout(350);
  const snapshot = () => page.locator('body').ariaSnapshot();
  function check(ok, label) { if (!ok) throw Error(label); checks.push(label); }
  async function type(value) {
    const input = page.getByRole('textbox', {name: /^Custom minutes/});
    await input.click();
    await page.waitForTimeout(300);
    await input.press('ControlOrMeta+A');
    await page.waitForTimeout(100);
    await input.pressSequentially(value, {delay: 40});
  }
  async function settings() {
    await page.getByRole('tab', {name: 'Settings', exact: true}).click();
    await pause();
  }
  async function language(name) {
    await page.mouse.move(180, 450);
    await page.mouse.wheel(0, -4000);
    await pause();
    await page.mouse.wheel(0, 120);
    await pause();
    await page.getByRole('button', {name: /^(Language English|زبان اردو)$/}).click();
    await pause();
    await page.getByRole('button', {name, exact: true}).click();
    await pause();
  }
  await page.setViewportSize({width: 390, height: 844});
  await page.reload();
  await page.waitForTimeout(1500);
  const enable = page.getByRole('button', {name: 'Enable accessibility'});
  if (await enable.count()) await enable.click();
  await page.evaluate(() => document.querySelector('.firebase-emulator-warning')?.remove());
  const urduSettings = page.getByRole('tab', {name: 'ترتیبات', exact: true});
  if (await urduSettings.count()) { await urduSettings.click(); await pause(); await language('English'); }
  await settings();
  check((await snapshot()).includes('Prayer reminders are available in the Android app.'), 'browser explains Android-only reminders');
  await page.getByRole('button', {name: /^Remind me before prayer/}).click();
  await pause();
  await page.getByRole('checkbox', {name: '20 min', exact: true}).click();
  await pause();
  check((await snapshot()).includes('20 minutes before each prayer'), '20-minute preset saved');
  await page.getByRole('button', {name: /^Remind me before prayer/}).click();
  await pause();
  await type('61');
  await page.getByRole('button', {name: 'Save', exact: true}).click();
  await pause();
  check((await snapshot()).includes('Enter a whole number from 1 to 60.'), 'out-of-range custom value rejected');
  await type('17');
  await page.getByRole('button', {name: 'Save', exact: true}).click();
  await pause();
  check((await snapshot()).includes('17 minutes before each prayer'), 'custom lead saved');
  await page.reload();
  await page.waitForTimeout(1500);
  if (await enable.count()) await enable.click();
  await page.evaluate(() => document.querySelector('.firebase-emulator-warning')?.remove());
  await settings();
  check((await snapshot()).includes('17 minutes before each prayer'), 'lead survives reload');
  await language('اردو');
  check((await snapshot()).includes('ہر نماز سے 17 منٹ پہلے'), 'Urdu labels preserve selected lead');
  await language('English');
  return {passed: checks.length, checks};
}
