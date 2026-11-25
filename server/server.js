const WebSocket = require('ws');
const http = require('http');
const PORT = Number(process.env.PORT || 8080);
const ARENA = { width: 2600, height: 1900 };
const rooms = new Map();
const server = http.createServer((req,res)=>{
  if(req.url==='/health') { res.writeHead(200,{'content-type':'application/json'});res.end(JSON.stringify({ok:true,rooms:rooms.size}));return; }
  res.writeHead(200,{'content-type':'text/plain'});res.end('GUSANO BATTLE online server\n');
});
const wss = new WebSocket.Server({server});
function code(){return Math.random().toString(36).slice(2,6).toUpperCase();}
function safeSend(ws,obj){if(ws.readyState===WebSocket.OPEN)ws.send(JSON.stringify(obj));}
function roomByCode(c){return rooms.get(String(c||'').toUpperCase());}
function newPlayer(ws,name){return {id:Math.random().toString(36).slice(2,9),ws,name:String(name||'Gusano').slice(0,14),x:Math.random()*ARENA.width,y:Math.random()*ARENA.height,dx:1,dy:0,length:5,score:0,color:String(ws.color||'#42f5b5'),boost:false,alive:true,trail:[],respawnAt:0};}
function broadcast(room,obj){for(const p of room.players.values())safeSend(p.ws,obj);}
function snapshot(room){return {type:'state',room:room.code,players:[...room.players.values()].map(p=>({id:p.id,name:p.name,x:p.x,y:p.y,dx:p.dx,dy:p.dy,length:p.length,score:p.score,color:p.color,alive:p.alive,trail:p.trail})),food:room.food};}
function makeRoom(){let c;do{c=code();}while(rooms.has(c));let r={code:c,players:new Map(),food:[],last:Date.now()};for(let i=0;i<80;i++)r.food.push({x:Math.random()*ARENA.width,y:Math.random()*ARENA.height});rooms.set(c,r);return r;}
wss.on('connection',ws=>{
  ws.room=null;ws.player=null;
  safeSend(ws,{type:'welcome',arena:ARENA});
  ws.on('message',buf=>{
    let m;try{m=JSON.parse(buf.toString());}catch{return;}
    if(m.type==='create'){
      if(ws.room)return;
      const r=makeRoom();ws.color=m.color||'#42f5b5';const p=newPlayer(ws,m.name);r.players.set(p.id,p);ws.room=r;ws.player=p;
      safeSend(ws,{type:'joined',room:r.code,id:p.id,created:true});broadcast(r,snapshot(r));return;
    }
    if(m.type==='join'){
      if(ws.room)return;
      const r=roomByCode(m.room);if(!r){safeSend(ws,{type:'error',message:'Sala no encontrada'});return;}
      if(r.players.size>=8){safeSend(ws,{type:'error',message:'Sala llena'});return;}
      ws.color=m.color||'#42f5b5';const p=newPlayer(ws,m.name);r.players.set(p.id,p);ws.room=r;ws.player=p;
      safeSend(ws,{type:'joined',room:r.code,id:p.id,created:false});broadcast(r,snapshot(r));return;
    }
    if(m.type==='input'&&ws.room&&ws.player){
      const p=ws.player;if(!p.alive)return;const d=m.dir||[p.dx,p.dy];let x=Number(d[0])||0,y=Number(d[1])||0;const l=Math.hypot(x,y);if(l>0.1){p.dx=x/l;p.dy=y/l;}p.boost=!!m.boost;return;
    }
    if(m.type==='leave'&&ws.room){removePlayer(ws);}
  });
  ws.on('close',()=>removePlayer(ws));
});
function removePlayer(ws){const r=ws.room;if(!r)return;r.players.delete(ws.player?.id);ws.room=null;ws.player=null;if(!r.players.size)rooms.delete(r.code);else broadcast(r,snapshot(r));}
setInterval(()=>{
  const dt=0.05;
  for(const r of rooms.values()){
    for(const p of r.players.values()){
      if(!p.alive){if(Date.now()>=p.respawnAt){p.x=150+Math.random()*(ARENA.width-300);p.y=150+Math.random()*(ARENA.height-300);p.dx=1;p.dy=0;p.length=5;p.score=0;p.trail=[];p.alive=true;}continue;}
      const sp=p.boost?300:205;p.x=Math.max(20,Math.min(ARENA.width-20,p.x+p.dx*sp*dt));p.y=Math.max(20,Math.min(ARENA.height-20,p.y+p.dy*sp*dt));
      p.trail.unshift({x:p.x,y:p.y});while(p.trail.length>Math.max(40,p.length*6))p.trail.pop();
      let dead=p.x<=22||p.x>=ARENA.width-22||p.y<=22||p.y>=ARENA.height-22;
      for(const other of r.players.values()){
        if(dead||!other.alive)break;
        const body=other.trail||[];for(let j=10;j<body.length;j+=3){if(Math.hypot(p.x-body[j].x,p.y-body[j].y)<16){dead=true;break;}}
      }
      if(dead){p.alive=false;p.respawnAt=Date.now()+1800;continue;}
      for(let i=r.food.length-1;i>=0;i--){const f=r.food[i];if(Math.hypot(p.x-f.x,p.y-f.y)<20){p.length++;p.score+=10;r.food.splice(i,1);}}
    }
    while(r.food.length<80)r.food.push({x:Math.random()*ARENA.width,y:Math.random()*ARENA.height});
    broadcast(r,snapshot(r));
  }
},50);
server.listen(PORT,'0.0.0.0',()=>console.log(`Gusano Battle server on port ${PORT}`));
