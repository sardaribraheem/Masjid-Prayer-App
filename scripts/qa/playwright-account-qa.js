// Run after playwright-smoke.js, which ends signed in as the local QA imam.
async (page) => {
  if(!page.url().startsWith('http://localhost:7360/'))throw Error('Local preview required');
  const db='http://127.0.0.1:8080/v1/projects/demo-masjid-rules/databases/(default)/documents';
  const owner={Authorization:'Bearer owner'};
  const read=url=>page.request.get(url,{headers:owner});
  const pause=()=>page.waitForTimeout(600);
  const snapshot=()=>page.locator('body').ariaSnapshot();
  const checks=[];
  function check(ok,label){if(!ok)throw Error(label);checks.push(label);}
  async function type(name,value){const f=page.getByRole('textbox',{name});await f.click();await page.waitForTimeout(300);await f.press('ControlOrMeta+A');await f.pressSequentially(value,{delay:20});}
  const masjid=await(await read(db+'/masjids/qa-masjid')).json();
  const member=await(await read(db+'/masjids/qa-masjid/questions/qa-00')).json();
  const uid=member.fields.createdByUid.stringValue;
  await page.getByRole('button',{name:'Create Event',exact:true}).click();await pause();
  await type(/^Event Title/,'QA denied draft recovery');
  await type(/^Event Description/,'This local draft must survive a denied write.');
  const grantUrl=db+'/masjids/qa-masjid?updateMask.fieldPaths=authorizedImamUids';
  async function grant(field){const response=await page.request.patch(grantUrl,{headers:owner,data:{fields:{authorizedImamUids:field}}});if(!response.ok())throw Error('Local fixture grant update failed');}
  try {
    await grant({arrayValue:{values:[]}});
    await page.getByRole('button',{name:'Save',exact:true}).click();await pause();
    const draft=await snapshot();
    check(draft.includes('QA denied draft recovery') && draft.includes('Could not load updates'),'Denied event write preserves draft and displays failure');
  } finally {await grant(masjid.fields.authorizedImamUids);}
  await page.getByRole('button',{name:'Save',exact:true}).click();await pause();
  check(!(await snapshot()).includes('alertdialog'),'Restored permission saves retained draft');
  await page.getByRole('button',{name:/Back/}).first().click();await pause();
  await page.getByRole('button',{name:'Q&A Management',exact:true}).click();await pause();
  await page.getByRole('button',{name:'Answer Question',exact:true}).first().click();await pause();
  await type(/^Your Answer/,'QA persisted answer after Asr.');
  await page.getByRole('button',{name:'Save Answer',exact:true}).click();await pause();
  check((await snapshot()).includes('QA persisted answer after Asr.'),'Saved answer updates management card immediately');
  const answered=await(await read(db+'/masjids/qa-masjid/questions/qa-00')).json();
  check(answered.fields.answer.stringValue==='QA persisted answer after Asr.','Manager answer persists');
  await page.getByRole('button',{name:/Back/}).first().click();await pause();
  await page.getByRole('button',{name:/Back/}).first().click();await pause();
  await page.getByRole('tab',{name:'Settings',exact:true}).click();await pause();
  await page.mouse.move(180,600);await page.mouse.wheel(0,4000);await pause();
  await page.getByRole('button',{name:'Sign out',exact:true}).click();await pause();
  await page.mouse.wheel(0,-4000);await pause();
  await page.getByRole('button',{name:'Login',exact:true}).click();await pause();
  await type(/^Email/,'qa-member@example.com');await type(/^Password/,'LocalQA123!');
  await page.getByRole('button',{name:'Sign In',exact:true}).click();await pause();
  await page.mouse.move(180,600);await page.mouse.wheel(0,4000);await pause();
  await page.getByRole('button',{name:'Delete account',exact:true}).click();await pause();
  await type(/^Current password/,'WrongLocalQA!');
  await page.getByRole('alertdialog').getByRole('button',{name:'Delete account',exact:true}).click();await pause();
  check((await read(db+'/users/'+uid)).ok(),'Failed reauthentication leaves profile intact');
  check((await page.getByRole('alertdialog').count())===1,'Failed reauthentication keeps deletion dialog retryable');
  await type(/^Current password/,'LocalQA123!');
  await page.getByRole('alertdialog').getByRole('button',{name:'Delete account',exact:true}).click();
  for(let i=0;i<12;i++){await pause();if(!await page.getByRole('alertdialog').count())break;}
  check((await read(db+'/users/'+uid)).status()===404,'Account deletion removes profile');
  for(const collectionId of ['questions','comments','events']){
    const response=await page.request.post(db+':runQuery',{headers:owner,data:{structuredQuery:{from:[{collectionId,allDescendants:true}],where:{fieldFilter:{field:{fieldPath:'createdByUid'},op:'EQUAL',value:{stringValue:uid}}}}}});
    const documents=await response.json();
    check(response.ok() && !documents.some(item=>item.document),'Account deletion clears owned '+collectionId);
  }
  const auth=await page.request.post('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-api-key',{data:{email:'qa-member@example.com',password:'LocalQA123!',returnSecureToken:true}});
  check(!auth.ok(),'Deleted local Auth account can no longer sign in');
  check((await snapshot()).includes('Guest'),'Completed deletion returns to guest UI');
  return {checks,scope:'Local demo only; does not prove interrupted cleanup or Android behavior'};
}
