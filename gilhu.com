<!DOCTYPE html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Rud-K Music Hub - Real</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:Arial}
body{background:#0a0a0a;color:#fff}
header{background:#111;padding:12px;display:flex;justify-content:space-between;align-items:center;position:sticky;top:0;z-index:99}
.logo{color:#1DB954;font-weight:900;font-size:20px}
.btn{background:#1DB954;color:#000;padding:12px;border:0;border-radius:8px;width:100%;font-weight:800;margin-top:8px;cursor:pointer}
.card{background:#181818;padding:14px;border-radius:12px;margin:10px}
.page{display:none;padding:10px}.page.active{display:block}
input,select,textarea{width:100%;padding:11px;margin:5px 0;background:#222;border:1px solid #333;color:#fff;border-radius:8px}
.song{display:flex;gap:10px;background:#181818;padding:12px;border-radius:12px;margin:10px;align-items:center}
.navBtn{background:#222;color:#fff;border:0;padding:7px 12px;border-radius:15px;margin-left:4px}
.badge{padding:2px 8px;border-radius:10px;font-size:11px;font-weight:700}
</style></head><body>
<header>
<div class="logo">Rud-K Music Hub</div>
<nav>
<button class="navBtn" onclick="showPage('home')">Home</button>
<button class="navBtn" onclick="showPage('artistsPage')">Artists</button>
<button class="navBtn" onclick="showPage('profile')">Profile</button>
<button id="authBtn" onclick="showPage('auth')" style="background:#1DB954;border:0;padding:7px 14px;border-radius:15px;font-weight:800">Join</button>
</nav>
</header>

<div id="home" class="page active">
<div class="card" style="border:1px solid #1DB954;background:linear-gradient(135deg,#111,#1DB95433)">
<h2>🔥 Video of the Day - 5K/Month</h2>
<div id="videoDay"><p>Loading...</p></div>
<div style="margin-top:10px"><b style="color:#1DB954">UGX 5,000 / 30 Days</b><br><small>1000s of views on homepage</small>
<button onclick="wa('Hi Rud-K, I want Video of Day 5K. My link: ')" class="btn" style="background:#25D366">Pay 5K - WhatsApp 0767292857</button>
</div>
<input id="vAdminLink" placeholder="Admin: YouTube link" style="display:none;margin-top:8px">
<button id="vAdminBtn" onclick="setVideoDay()" class="btn" style="display:none">Activate 5K Video (30 Days)</button>
<p id="vExpiry" style="font-size:11px;color:#aaa"></p>
</div>

<div class="card" style="border:2px solid #FFD700;background:#1a1a00">
<h2>🚀 Full Promotion - 10K</h2>
<p>✔ Video of Day<br>✔ Song pinned top<br>✔ Boosted profile<br>✔ WhatsApp Status promo</p>
<b style="color:#FFD700">UGX 10,000 / Month</b>
<button onclick="wa('Hi Rud-K, I want 10K FULL PROMO. Artist: '+(auth.currentUser?auth.currentUser.email:''))" class="btn" style="background:#FFD700;color:#000">Get 10K Promo - 0767292857</button>
</div>

<h3 style="padding:10px">🎵 Approved Songs</h3>
<input id="search" placeholder="Search songs..." oninput="loadSongs()">
<div id="songsList"></div>
</div>

<div id="artistsPage" class="page"><h2>Verified Artists</h2><div id="artistsList" style="display:grid;grid-template-columns:1fr 1fr;gap:10px;padding:10px"></div></div>

<div id="profile" class="page">
<div class="card"><h2>🎤 Artist Profile Creator</h2>
<input id="aStageName" placeholder="Stage Name">
<textarea id="aBio" placeholder="Bio - e.g. Afrobeat star from Kampala"></textarea>
<input id="aGenre" placeholder="Genre">
<input id="aLocation" placeholder="Location">
<input id="aPhoto" placeholder="Photo Link (imgbb.com)">
<input id="aYoutube" placeholder="YouTube Channel Link">
<button onclick="saveArtistProfile()" class="btn">Save My Artist Profile</button>
<button onclick="wa('Hi Rud-K, help me with profile: '+ (auth.currentUser?auth.currentUser.email:''))" class="btn" style="background:#25D366">WhatsApp Me Direct 0767292857</button>
<div style="margin-top:10px"><p id="pName"></p><p id="pEmail"></p><p id="pRole"></p></div>
<button onclick="showPage('upload')" class="btn" style="background:#fff">Upload Music</button>
<button onclick="showPage('mySongs')" class="btn">My Songs Status</button>
</div>
<div id="mySongsList"></div>
</div>

<div id="mySongs" class="page"><h2>My Uploads</h2><div id="mySongsPage"></div></div>

<div id="upload" class="page"><div class="card"><h2>Upload Music - Wait Admin Approval</h2>
<input id="sTitle" placeholder="Song Title"><input id="sGenre" placeholder="Genre"><input id="sPrice" type="number" placeholder="Price UGX">
<input id="sLink" placeholder="Audio MP3 Link"><button onclick="doUpload()" class="btn">Upload</button>
</div></div>

<div id="auth" class="page"><div class="card"><h2>Registration Page</h2>
<input id="rName" placeholder="Full Name"><input id="rEmail" placeholder="Email"><input id="rPass" type="password" placeholder="Password">
<select id="rRole"><option value="fan">Fan</option><option value="artist">Artist</option><option value="producer">Producer</option><option value="dj">DJ</option><option value="label">Label</option><option value="admin">Admin (You)</option></select>
<button onclick="doRegister()" class="btn">Create Real Account</button><button onclick="doLogin()" class="btn" style="background:#fff">Login Real</button>
<p style="text-align:center;margin-top:8px;font-size:12px">Contact: 0767292857</p>
</div></div>

<div id="admin" class="page"><h2>Admin Panel - Approve Songs</h2><div id="pendingList"></div></div>

<script type="module">
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword, onAuthStateChanged, signOut } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-auth.js";
import { getFirestore, doc, setDoc, getDoc, collection, getDocs, addDoc, updateDoc, deleteDoc } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyDVlGCqkEwnGJlvp4CXFX2maW_aQANnCPc",
  authDomain: "muzikiug-61e1a.firebaseapp.com",
  projectId: "muzikiug-61e1a",
  storageBucket: "muzikiug-61e1a.firebasestorage.app",
  messagingSenderId: "794556375231",
  appId: "1:794556375231:web:532874de78f8164567660a"
};

const app=initializeApp(firebaseConfig); const db=getFirestore(app); const auth=getAuth(app);

window.showPage=(id)=>{document.querySelectorAll('.page').forEach(p=>p.classList.remove('active'));document.getElementById(id).classList.add('active'); if(id=='home'){loadSongs();loadVideoDay();} if(id=='artistsPage')loadArtists(); if(id=='profile')loadProfile(); if(id=='mySongs')loadMySongs(); if(id=='admin')loadPending();}
window.wa=(t)=>window.open('https://wa.me/256767292857?text='+encodeURIComponent(t));

window.doRegister=async()=>{
  const n=document.getElementById('rName').value, e=document.getElementById('rEmail').value, p=document.getElementById('rPass').value, r=document.getElementById('rRole').value;
  if(!n||!e||!p) return alert("Fill all");
  try{const c=await createUserWithEmailAndPassword(auth,e,p); await setDoc(doc(db,"users",c.user.uid),{name:n,email:e,role:r,phone:"0767292857",created:new Date()}); alert("✅ REAL Account as "+r); showPage('home');}catch(err){alert(err.message)}
};
window.doLogin=async()=>{try{await signInWithEmailAndPassword(auth,rEmail.value,rPass.value); alert("Logged in REAL!"); showPage('home');}catch(err){alert(err.message)}};

window.saveArtistProfile=async()=>{
  if(!auth.currentUser) return alert("Login first");
  const data={stageName:aStageName.value,bio:aBio.value,genre:aGenre.value,location:aLocation.value,photo:aPhoto.value,youtube:aYoutube.value,isArtist:true,role:'artist'};
  await updateDoc(doc(db,"users",auth.currentUser.uid),data); alert("✅ Artist Profile Saved REAL!"); loadProfile();
};

window.doUpload=async()=>{
  const t=sTitle.value,g=sGenre.value,pr=sPrice.value,l=sLink.value;
  if(!t||!pr) return alert("Title & Price");
  try{await addDoc(collection(db,"songs"),{title:t,genre:g,price:pr,link:l,owner:auth.currentUser.uid,ownerName:auth.currentUser.email,approved:false,promoted:false,created:new Date()}); alert("Uploaded! Waiting Admin Approval"); showPage('mySongs');}catch(e){alert(e.message)}
};

window.loadSongs=async()=>{
  const snap=await getDocs(collection(db,"songs")); let list=[]; snap.forEach(d=>list.push({id:d.id,...d.data()}));
  list=list.filter(s=>s.approved);
  const q=search.value.toLowerCase(); if(q) list=list.filter(s=>s.title.toLowerCase().includes(q)||s.genre?.toLowerCase().includes(q));
  list.sort((a,b)=>{const pa=a.promoted&&new Date(a.promoExpiry)>new Date(); const pb=b.promoted&&new Date(b.promoExpiry)>new Date(); return pb-pa;});
  let html=""; list.forEach(s=>{const promo=s.promoted&&new Date(s.promoExpiry)>new Date(); html+=`<div class="song" style="${promo?'border:2px solid #FFD700':''}"><div style="flex:1"><b>${s.title} ${promo?'⭐ PROMOTED':''}</b> <span class="badge" style="background:#1DB954">Approved</span><br><small>${s.genre} • ${s.ownerName}</small><br><b style="color:#1DB954">UGX ${s.price}</b></div><button onclick="wa('Hi I want to buy ${s.title} for ${s.price}')" style="background:${promo?'#FFD700':'#1DB954'};border:0;padding:8px 12px;border-radius:20px;font-weight:700">Buy</button></div>`});
  songsList.innerHTML=html||"<div class='card'>No approved songs yet - Artists upload!</div>";
};

window.loadArtists=async()=>{
  const snap=await getDocs(collection(db,"users")); let html="";
  snap.forEach(d=>{const u=d.data(); if(u.isArtist||u.role=='artist'){ html+=`<div class="card"><img src="${u.photo||'https://via.placeholder.com/100'}" style="width:100%;height:100px;object-fit:cover;border-radius:8px"><b>${u.stageName||u.name}</b><br><small>${u.genre||''} • ${u.location||''}</small><br><small>${u.bio||''}</small><br><button onclick="wa('Hi ${u.stageName||u.name} I saw you on Rud-K Hub')" style="background:#25D366;border:0;padding:6px 10px;border-radius:15px;margin-top:6px">WhatsApp</button></div>`}});
  artistsList.innerHTML=html||"<div class='card'>No artist profiles yet</div>";
};

window.loadProfile=async()=>{
  if(!auth.currentUser) return showPage('auth');
  const d=await getDoc(doc(db,"users",auth.currentUser.uid));
  if(d.exists()){const u=d.data(); pName.innerText="Name: "+u.name+" | Stage: "+(u.stageName||"Not set"); pEmail.innerText="Bio: "+(u.bio||"Create profile below"); pRole.innerText="Role: "+u.role; if(u.role=='admin'){vAdminLink.style.display='block';vAdminBtn.style.display='block'; if(!document.getElementById('adminBtn')){let b=document.createElement('button');b.id='adminBtn';b.innerText='Admin Panel';b.className='btn';b.style.background='#ff3b3b';b.onclick=()=>showPage('admin');document.querySelector('#profile.card').appendChild(b);}} if(u.stageName){aStageName.value=u.stageName; aBio.value=u.bio||''; aGenre.value=u.genre||''; aLocation.value=u.location||''; aPhoto.value=u.photo||''; aYoutube.value=u.youtube||'';}}
  loadMySongs();
};

window.loadMySongs=async()=>{
  if(!auth.currentUser) return; const snap=await getDocs(collection(db,"songs")); let html="";
  snap.forEach(docu=>{const s=docu.data(); if(s.owner==auth.currentUser.uid){const exp=s.promoExpiry?new Date(s.promoExpiry).toDateString():''; html+=`<div class="card">${s.title} - ${s.approved?'✅ Approved':'⏳ Pending Admin'} ${s.promoted?'⭐ Promoted till '+exp:''} - UGX ${s.price}</div>`}});
  mySongsPage.innerHTML=html; mySongsList.innerHTML=html;
};

window.loadPending=async()=>{
  const snap=await getDocs(collection(db,"songs")); let html="";
  snap.forEach(d=>{const s=d.data(); if(!s.approved){ html+=`<div class="card"><b>${s.title}</b> by ${s.ownerName} - UGX ${s.price}<br><button onclick="approveSong('${d.id}')" class="btn">Approve</button><button onclick="promoteSong('${d.id}')" class="btn" style="background:#FFD700;color:#000">Approve + Promote 10K</button><button onclick="rejectSong('${d.id}')" class="btn" style="background:#ff3b3b">Reject</button></div>`}});
  pendingList.innerHTML=html||"No pending songs";
};
window.approveSong=async(id)=>{await updateDoc(doc(db,"songs",id),{approved:true}); alert("Approved!"); loadPending(); loadSongs();};
window.promoteSong=async(id)=>{const exp=new Date(); exp.setDate(exp.getDate()+30); await updateDoc(doc(db,"songs",id),{approved:true,promoted:true,promoExpiry:exp.toISOString()}); alert("Approved + Promoted 10K for 30 days!"); loadPending();};
window.rejectSong=async(id)=>{await deleteDoc(doc(db,"songs",id)); alert("Rejected"); loadPending();};

window.setVideoDay=async()=>{const link=vAdminLink.value; if(!link) return alert("Paste link"); const exp=new Date(); exp.setDate(exp.getDate()+30); await setDoc(doc(db,"config","videoDay"),{link,expiry:exp.toISOString(),price:5000,paidAt:new Date().toISOString()}); alert("✅ 5K Video Activated 30 days!"); loadVideoDay();};
window.loadVideoDay=async()=>{try{const d=await getDoc(doc(db,"config","videoDay")); if(d.exists()){const v=d.data(); let yt=v.link.replace("watch?v=","embed/").replace("youtu.be/","www.youtube.com/embed/"); const exp=new Date(v.expiry); if(new Date()>exp){videoDay.innerHTML="<p>Slot available - Pay 5K!</p>"; vExpiry.innerText="Expired - Available";} else {videoDay.innerHTML=`<iframe width="100%" height="210" src="${yt}" frameborder="0" allowfullscreen></iframe>`; vExpiry.innerText="Expires: "+exp.toDateString()+" (5K)";}} else videoDay.innerHTML="<p>No video - First artist pays 5K!</p>"}catch(e){videoDay.innerHTML="<p>Enable Firestore first</p>"}};

onAuthStateChanged(auth,(u)=>{if(u){authBtn.innerText=u.email.split('@')[0]; authBtn.onclick=()=>{if(confirm('Logout?')) signOut(auth).then(()=>location.reload())};} loadSongs(); loadVideoDay();});
loadSongs(); loadVideoDay();
</script></body></html>
