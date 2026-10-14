// Run through Playwright MCP browser_run_code_unsafe({filename: ...}).
// Local fixtures only. The browser preview MUST use USE_FIREBASE_EMULATORS.
async (page) => {
  const origin = 'http://localhost:7360';
  if (!page.url().startsWith(origin + '/')) throw Error('Local QA preview required');
  const db = 'http://127.0.0.1:8080/v1/projects/demo-masjid-rules/databases/(default)/documents';
  const checks = [];
  const read = url => page.request.get(url, {headers: {Authorization: 'Bearer owner'}});
  const pause = () => page.waitForTimeout(500);
  const snapshot = () => page.locator('body').ariaSnapshot();
  function check(ok, label) { if (!ok) throw Error(label); checks.push(label); }
  async function type(name, text) {
    const input = page.getByRole('textbox', {name});
    await input.click();
    await page.waitForTimeout(300);
    await input.press('ControlOrMeta+A');
    await input.pressSequentially(text, {delay: 20});
  }
  async function settings() {
    await page.getByRole('tab', {name:'Settings',exact:true}).click();
    await pause();
  }
  async function signOut() {
    await settings();
    await page.mouse.move(180,600);
    await page.mouse.wheel(0,4000);
    await pause();
    await page.getByRole('button',{name:'Sign out',exact:true}).click();
    await pause();
  }
  async function login(email) {
    await settings();
    await page.mouse.move(180,600);
    await page.mouse.wheel(0,-4000);
    await pause();
    await page.getByRole('button',{name:'Login',exact:true}).click();
    await pause();
    await type(/^Email/,email);
    await type(/^Password/,'LocalQA123!');
    await page.getByRole('button',{name:'Sign In',exact:true}).click();
    await pause();
  }
  await page.setViewportSize({width:390,height:844});
  await page.evaluate(async () => {
    localStorage.clear(); sessionStorage.clear();
    await new Promise(resolve => {
      const request = indexedDB.deleteDatabase('firebaseLocalStorageDb');
      request.onsuccess = request.onerror = request.onblocked = resolve;
    });
  });
  await page.reload();
  await page.waitForTimeout(1500);
  const enable = page.getByRole('button',{name:'Enable accessibility'});
  if (await enable.count()) await enable.click();
  await page.evaluate(()=>document.querySelector('.firebase-emulator-warning')?.remove());
  await page.getByRole('button',{name:'QA Community Masjid Local emulator · Karachi',exact:true}).click();
  await pause();
  await page.getByRole('tab',{name:'Events',exact:true}).click();
  await pause();
  check(!(await snapshot()).includes('Past local QA event'),'Upcoming excludes past events');
  await page.getByRole('checkbox',{name:'All Events',exact:true}).click();
  await pause();
  check((await snapshot()).includes('Past local QA event'),'All includes past events');
  await page.getByRole('checkbox',{name:'Other',exact:true}).click();
  await pause();
  check(!(await snapshot()).includes('Weekend study circle'),'Category filter changes results');
  await page.getByRole('tab',{name:'Community',exact:true}).click();
  await pause();
  check((await snapshot()).includes('browsing as a guest'),'Guest can read without a posting form');
  await page.getByRole('button',{name:'Login',exact:true}).click();
  await pause();
  await page.getByRole('button',{name:'Forgot password?',exact:true}).click();
  await pause();
  check((await snapshot()).includes('Enter your account email'),'Password recovery validates empty email');
  await type(/^Email/,'qa-member@example.com');
  await page.getByRole('button',{name:'Forgot password?',exact:true}).click();
  await pause();
  const oob = await (await page.request.get('http://127.0.0.1:9099/emulator/v1/projects/demo-masjid-rules/oobCodes')).json();
  check(oob.oobCodes?.some(code=>code.email==='qa-member@example.com' && code.requestType==='PASSWORD_RESET'),'Reset request reaches local Auth emulator');
  await type(/^Password/,'LocalQA123!');
  await page.getByRole('button',{name:'Sign In',exact:true}).click();
  await pause();
  const text='Playwright reproducible QA post';
  await type(/Community Share/,text);
  await page.getByRole('button',{name:'Post',exact:true}).click();
  await pause();
  const records = await (await read(db+'/masjids/qa-masjid/questions?pageSize=100')).json();
  const post=records.documents?.find(doc=>doc.fields.questionText.stringValue===text);
  check(!!post,'Post persists with its real document ID');
  const postPath=post.name.split('/documents/')[1];
  await page.getByRole('button',{name:'Comments',exact:true}).first().click();
  await pause();
  await type(/Write a comment/,'Reproducible QA reply');
  await page.getByRole('button',{name:'Send',exact:true}).click();
  await pause();
  const replies = await (await read(db+'/'+postPath+'/comments')).json();
  check(replies.documents?.length===1,'Comment persists once');
  await page.getByRole('button',{name:'Delete',exact:true}).first().click();
  await pause();
  await page.getByRole('alertdialog').getByRole('button',{name:'Delete',exact:true}).click();
  await pause();
  check((await read(db+'/'+postPath)).status()===404,'Post deletion removes parent');
  const deletedReplies=await (await read(db+'/'+postPath+'/comments')).json();
  check(!deletedReplies.documents?.length,'Post deletion removes child comments');
  await page.getByRole('button',{name:'Comments',exact:true}).first().click();
  await pause();
  await page.mouse.move(180,600); await page.mouse.wheel(0,1100); await pause();
  await page.getByRole('button',{name:'Load more',exact:true}).first().click();
  await pause(); await page.mouse.wheel(0,200); await pause();
  check((await snapshot()).includes('Local pagination comment 34'),'Older comments remain reachable after scrolling');
  await settings();
  await page.getByRole('button',{name:'Request verification',exact:true}).click();
  await pause();
  check((await snapshot()).includes('Verification pending'),'Member verification request persists');
  await signOut();
  await login('qa-imam@example.com');
  await page.getByRole('button',{name:'Review member verification',exact:true}).click();
  await pause();
  await page.getByRole('button',{name:'Approve',exact:true}).click();
  await pause();
  check((await snapshot()).includes('No pending member requests'),'Assigned imam approves verification');
  await page.getByRole('button',{name:/Back/}).first().click(); await pause();
  await signOut();
  await login('qa-member@example.com');
  await page.getByRole('tab',{name:'Events',exact:true}).click(); await pause();
  await page.getByRole('button',{name:'Propose an event',exact:true}).click(); await pause();
  await type(/^Event Title/,'Reproducible member proposal');
  await type(/^Event Description/,'A local proposal awaiting review.');
  await page.getByRole('button',{name:'Save',exact:true}).click(); await pause();
  const events=await (await read(db+'/masjids/qa-masjid/events?pageSize=100')).json();
  const proposal=events.documents?.find(doc=>doc.fields.title.stringValue==='Reproducible member proposal');
  check(proposal?.fields.status.stringValue==='pending','Verified member proposal persists as pending');
  check(!(await snapshot()).includes('Reproducible member proposal'),'Pending proposal is absent from public feed');
  await signOut(); await login('qa-imam@example.com');
  await page.getByRole('button',{name:'Admin/Imam Panel',exact:true}).click(); await pause();
  await page.getByRole('button',{name:'Event Management',exact:true}).click(); await pause();
  await page.getByRole('checkbox',{name:'Pending',exact:true}).click(); await pause();
  check((await snapshot()).includes('Reproducible member proposal'),'Manager pending query finds proposal');
  await page.getByRole('button',{name:'Approve',exact:true}).click(); await pause();
  const published=await (await read(db+'/'+proposal.name.split('/documents/')[1])).json();
  check(published.fields.status.stringValue==='approved','Manager approval persists');
  return {checks,scope:'Local emulator browser QA; no production or Android device acceptance'};
}
