// Local visual QA fixtures. This script cannot target a production endpoint.
const base = 'http://127.0.0.1:8080/v1/projects/demo-masjid-rules/databases/(default)/documents';
if(process.argv.includes('--reset')) {
  const cleared=await fetch('http://127.0.0.1:8080/emulator/v1/projects/demo-masjid-rules/databases/(default)/documents',{method:'DELETE'});
  if(!cleared.ok) throw Error('Could not reset isolated demo fixtures');
}
const auth = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-api-key', {
  method: 'POST', headers: {'Content-Type':'application/json'},
  body: JSON.stringify({email:'qa-member@example.com',password:'LocalQA123!',returnSecureToken:true})
}).then(r=>r.json());
let uid=auth.localId;
if(!uid) {
  const signed=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-api-key',{
    method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'qa-member@example.com',password:'LocalQA123!',returnSecureToken:true})
  }).then(r=>r.json()); uid=signed.localId;
}
if(!uid) throw Error('Could not initialize local QA user');
function value(v) {
  if(v===null)return {nullValue:null};
  if(Array.isArray(v))return {arrayValue:{values:v.map(value)}};
  if(v instanceof Date)return {timestampValue:v.toISOString()};
  if(typeof v==='object')return {mapValue:{fields:fields(v)}};
  if(typeof v==='boolean')return {booleanValue:v};
  if(typeof v==='number')return {doubleValue:v};
  return {stringValue:v};
}
function fields(d){return Object.fromEntries(Object.entries(d).map(([k,v])=>[k,value(v)]));}
async function put(path,data){const r=await fetch(`${base}/${path}`,{method:'PATCH',headers:{'Content-Type':'application/json','Authorization':'Bearer owner'},body:JSON.stringify({fields:fields(data)})});if(!r.ok)throw Error(await r.text());}
await put(`users/${uid}`,{username:'QA member',email:'qa-member@example.com',role:'muqtaddi',verificationStatus:'none',eventPermission:'none',masjidId:'qa-masjid',masjidName:'QA Community Masjid'});
await put('masjids/qa-masjid',{name:'QA Community Masjid',nameUrdu:'کمیونٹی مسجد',location:'Local emulator · Karachi',authorizedImamUids:[],isVerified:true,prayerTimes:[{name:'Fajr',time:'5:15 AM'},{name:'Sunrise',time:'6:20 AM'},{name:'Dhuhr',time:'1:15 PM'},{name:'Asr',time:'4:30 PM'},{name:'Maghrib',time:'6:15 PM'},{name:'Isha',time:'8:00 PM'}],jummah:'1:30 PM'});
for(let i=0;i<35;i++)await put(`masjids/qa-masjid/questions/qa-${String(i).padStart(2,'0')}`,{id:`qa-${String(i).padStart(2,'0')}`,userName:'QA member',questionText:i===34?'What time does the weekend class start?':'Local UI test question '+i,createdByUid:uid,isAnonymous:false,isAnswered:false,answer:null,masjidId:'qa-masjid',timestamp:new Date(Date.now()-i*60000).toISOString()});
await put('masjids/qa-masjid/events/qa-event',{id:'qa-event',title:'Weekend study circle',description:'Local UI fixture for checking event layout and category filters.',masjidId:'qa-masjid',masjidName:'QA Community Masjid',eventDate:new Date(Date.now()+86400000).toISOString(),startTime:'5:00 PM',endTime:'6:00 PM',category:'Taleem',status:'approved',createdByUid:uid});
console.log('Seeded local demo fixtures. No production access. QA login: qa-member@example.com / LocalQA123!');

const managerAccount=await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo-api-key',{
  method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'qa-imam@example.com',password:'LocalQA123!',returnSecureToken:true})
}).then(r=>r.json());
const manager=managerAccount.localId ?? (await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-api-key',{
  method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'qa-imam@example.com',password:'LocalQA123!',returnSecureToken:true})
}).then(r=>r.json())).localId;
if(!manager) throw Error('Could not initialize local QA imam');
await put(`users/${manager}`,{username:'QA imam',email:'qa-imam@example.com',role:'imam',verificationStatus:'approved',eventPermission:'full',masjidId:'qa-masjid',masjidName:'QA Community Masjid'});
// This grant is made only by this emulator-only setup, never by the app.
const grant=await fetch(`${base}/masjids/qa-masjid?updateMask.fieldPaths=authorizedImamUids`,{method:'PATCH',headers:{'Content-Type':'application/json','Authorization':'Bearer owner'},body:JSON.stringify({fields:fields({authorizedImamUids:[manager]})})});
if(!grant.ok) throw Error('Local QA manager grant failed');
await put('masjids/qa-second',{name:'QA Second Masjid with a deliberately long community name for small screen checks',nameUrdu:'چھوٹی سکرین کی جانچ کے لیے ایک طویل نام والی مقامی مسجد',location:'Local emulator · Lahore',authorizedImamUids:[],isVerified:true,prayerTimes:[],jummah:null});
await put('masjids/qa-masjid/events/qa-past',{id:'qa-past',title:'Past local QA event',description:'Local fixture, must only appear under All Events.',masjidId:'qa-masjid',masjidName:'QA Community Masjid',eventDate:new Date(Date.now()-86400000).toISOString(),startTime:'5:00 PM',endTime:'6:00 PM',category:'Other',status:'approved',createdByUid:manager});
for(let i=0;i<35;i++)await put(`masjids/qa-masjid/questions/qa-00/comments/qa-comment-${String(i).padStart(2,'0')}`,{text:'Local pagination comment '+i,createdByUid:uid,userName:'QA member',timestamp:new Date(Date.now()-i*60000)});
console.log('Local manager QA login: qa-imam@example.com / LocalQA123!');
