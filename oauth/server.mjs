import {createServer} from 'node:http';
import {randomBytes, createHash} from 'node:crypto';
import {applicationDefault, initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';

const env = process.env;
const origin = new URL(env.PUBLIC_ORIGIN).origin;
const webReturn = new URL(env.WEB_RETURN);
const vk = env.VK_ORIGIN || 'https://id.vk.ru';
if (!origin.startsWith('https:') || webReturn.protocol !== 'https:' ||
    !['https://id.vk.ru','https://id.vk.com'].includes(vk)) throw Error('Проверьте HTTPS-адреса в .env');
const admin = getAuth(initializeApp({credential:applicationDefault()}));
const pending = new Map(), tickets = new Map();
const random = () => randomBytes(32).toString('base64url');
const sha = value => createHash('sha256').update(value).digest('base64url');
const valid = value => typeof value === 'string' && /^[A-Za-z0-9._~-]{43,128}$/.test(value);
const callback = provider => origin + '/callback/' + provider;
const cookie = state => 'oauth_' + state;
const cookieValue = (req,key) => req.headers.cookie?.split('; ').find(x => x.startsWith(key + '='))?.slice(key.length + 1);

function save(map,key,value,ttl) {
  if (map.size >= 1000) throw Error('Слишком много запросов, попробуйте позже.');
  map.set(key,{...value,expires:Date.now()+ttl});
}
setInterval(() => {
  for (const map of [pending,tickets]) {
    for (const [key,value] of map) if (value.expires < Date.now()) map.delete(key);
  }
},30000).unref();

async function request(url, options = {}) {
  const response = await fetch(url,{...options,signal:AbortSignal.timeout(10000),redirect:'error'});
  const data = await response.json();
  if (!response.ok || data.error) throw Error('Провайдер отклонил запрос.');
  return data;
}
const post = params => ({method:'POST',body:new URLSearchParams(params)});

async function getProfile(provider,params,flow) {
  const code = params.get('code');
  if (!code || params.has('error')) throw Error('Пользователь отменил вход или провайдер отклонил запрос.');
  if (provider === 'yandex') {
    const token = await request('https://oauth.yandex.ru/token',post({
      grant_type:'authorization_code',code,client_id:env.YANDEX_CLIENT_ID,
      client_secret:env.YANDEX_CLIENT_SECRET,code_verifier:flow.verifier,
    }));
    const user = await request('https://login.yandex.ru/info?format=json',{
      headers:{Authorization:'OAuth ' + token.access_token},
    });
    return {id:user.id,name:user.real_name || user.display_name || user.login || 'Яндекс ID'};
  }
  const device = params.get('device_id');
  if (!device) throw Error('VK ID не передал device_id.');
  const tokenUrl = new URL('/oauth2/auth',vk);
  tokenUrl.search = new URLSearchParams({
    grant_type:'authorization_code',client_id:env.VK_CLIENT_ID,redirect_uri:callback(provider),
    code_verifier:flow.verifier,state:params.get('state'),device_id:device,
  });
  const token = await request(tokenUrl,post({code}));
  if (token.state !== params.get('state')) throw Error('VK ID вернул неверный state.');
  const infoUrl = new URL('/oauth2/user_info',vk);
  infoUrl.searchParams.set('client_id',env.VK_CLIENT_ID);
  const {user} = await request(infoUrl,post({access_token:token.access_token}));
  return {id:user.user_id,name:[user.first_name,user.last_name].filter(Boolean).join(' ') || 'VK ID'};
}

function json(res,status,data) {
  res.writeHead(status,{'Content-Type':'application/json; charset=utf-8'}).end(JSON.stringify(data));
}

createServer(async (req,res) => {
  res.setHeader('Cache-Control','no-store');
  res.setHeader('Referrer-Policy','no-referrer');
  res.setHeader('X-Content-Type-Options','nosniff');
  res.setHeader('Vary','Origin');
  if (req.headers.origin === webReturn.origin) {
    res.setHeader('Access-Control-Allow-Origin',webReturn.origin);
    res.setHeader('Access-Control-Allow-Headers','Content-Type');
    res.setHeader('Access-Control-Allow-Methods','POST, OPTIONS');
  }
  try {
    const url = new URL(req.url,origin);
    const p = url.searchParams;
    const [,action,provider] = url.pathname.split('/');
    if (req.method === 'OPTIONS' && url.pathname === '/exchange') return res.writeHead(204).end();

    if (req.method === 'GET' && action === 'login' && ['yandex','vk'].includes(provider)) {
      const challenge = p.get('challenge');
      if (!valid(challenge) || challenge.length !== 43) return json(res,400,{error:'Неверный challenge'});
      const client = provider === 'vk' ? env.VK_CLIENT_ID : env.YANDEX_CLIENT_ID;
      if (!client || (provider === 'yandex' && !env.YANDEX_CLIENT_SECRET)) return json(res,503,{error:'OAuth-приложение ещё не настроено'});
      const state = random(), verifier = random(), binding = random();
      save(pending,state,{provider,verifier,binding,challenge,mobile:p.get('mobile') === '1'},600000);
      const authorize = new URL('/authorize',provider === 'vk' ? vk : 'https://oauth.yandex.ru');
      authorize.search = new URLSearchParams({
        response_type:'code',client_id:client,redirect_uri:callback(provider),state,
        code_challenge:sha(verifier),code_challenge_method:'S256',
      });
      if (provider === 'yandex') authorize.searchParams.set('scope','login:info');
      res.setHeader('Set-Cookie',cookie(state)+'='+binding+'; Secure; HttpOnly; SameSite=Lax; Max-Age=600; Path=/callback');
      return res.writeHead(302,{Location:authorize.href}).end();
    }

    if (req.method === 'GET' && action === 'callback' && ['yandex','vk'].includes(provider)) {
      const state = p.get('state');
      const flow = pending.get(state);
      if (!flow || flow.expires < Date.now() || flow.provider !== provider ||
          cookieValue(req,cookie(state)) !== flow.binding) return json(res,400,{error:'Сессия входа истекла. Начните вход заново.'});
      pending.delete(state);
      res.setHeader('Set-Cookie',cookie(state)+'=; Secure; HttpOnly; SameSite=Lax; Max-Age=0; Path=/callback');
      const destination = flow.mobile ? new URL('studentsoauth://callback') : new URL(webReturn);
      try {
        const profile = await getProfile(provider,p,flow);
        const id = String(profile.id ?? '');
        if (!/^[A-Za-z0-9_-]{1,100}$/.test(id)) throw Error('Нет идентификатора пользователя.');
        const ticket = random();
        save(tickets,ticket,{uid:provider+':'+id,name:String(profile.name).slice(0,128),challenge:flow.challenge},120000);
        destination.searchParams.set('ticket',ticket);
      } catch {
        destination.searchParams.set('oauth_error','1');
      }
      return res.writeHead(302,{Location:destination.href}).end();
    }

    if (req.method === 'POST' && url.pathname === '/exchange') {
      let length = 0;
      const chunks = [];
      for await (const chunk of req) {
        length += chunk.length;
        if (length > 4096) return json(res,413,{error:'Слишком большой запрос'});
        chunks.push(chunk);
      }
      let input;
      try { input = JSON.parse(Buffer.concat(chunks).toString()); } catch { return json(res,400,{error:'Ожидался JSON'}); }
      const {ticket,verifier} = input ?? {};
      const flow = tickets.get(ticket);
      if (!flow || flow.expires < Date.now() || !valid(verifier) || sha(verifier) !== flow.challenge) {
        return json(res,401,{error:'Недействительный код входа'});
      }
      tickets.delete(ticket);
      try {
        await admin.updateUser(flow.uid,{displayName:flow.name});
      } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
        try {
          await admin.createUser({uid:flow.uid,displayName:flow.name});
        } catch (race) {
          if (race.code !== 'auth/uid-already-exists') throw race;
          await admin.updateUser(flow.uid,{displayName:flow.name});
        }
      }
      return json(res,200,{token:await admin.createCustomToken(flow.uid)});
    }

    if (req.method === 'GET' && url.pathname === '/health') return json(res,200,{ok:true});
    return json(res,404,{error:'Маршрут не найден'});
  } catch (error) {
    console.error(error.code || error.name);
    if (!res.headersSent) json(res,500,{error:'Ошибка OAuth-сервера'});
  }
}).listen(Number(env.PORT || 8080),'0.0.0.0',() => console.log('OAuth server ready'));
