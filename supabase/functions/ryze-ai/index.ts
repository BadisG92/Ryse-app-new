// La clé Gemini, du côté où elle peut rester secrète.
//
// Elle était compilée dans le binaire et voyageait dans l'URL : n'importe qui
// pouvant lire le paquet de l'application pouvait s'en servir, et chaque appel
// la déposait dans les journaux réseau. `SECURITY_API_KEYS.md` le documentait
// déjà comme une fuite.
//
// Cette fonction fait trois choses et pas une de plus : elle vérifie qui
// appelle, elle relaie le flux vers Google avec la clé qu'elle seule détient,
// et elle note au passage ce que le tour a coûté. Le corps de la requête est
// le corps Gemini, tel quel : ce qui parle au modèle reste dans l'application.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/// Les seuls modèles que l'application demande. Une liste fermée : la fonction
/// détient une clé facturée, elle ne relaie pas n'importe quelle adresse.
const ALLOWED_MODELS = new Set([
  'gemini-3.1-flash-lite',
  'gemini-2.5-flash',
  'gemini-2.0-flash',
])

/// D'où vient la demande. Sert à ranger les jetons consommés, rien d'autre.
const ALLOWED_SURFACES = new Set([
  'coach',
  'planner',
  'scan',
  'workout',
  'nutrition',
  'exercise',
  'memory',
])

/// Écrit ce qu'un tour a coûté. Zéro des deux côtés veut dire que le modèle
/// n'a rien dit, et on n'invente pas une ligne.
async function meter(
  admin: ReturnType<typeof createClient>,
  userId: string,
  surface: string,
  model: string,
  prompt: number,
  output: number,
) {
  if (prompt === 0 && output === 0) return
  const { error } = await admin.from('ryze_ai_usage').insert({
    user_id: userId,
    surface,
    model,
    prompt_tokens: prompt,
    output_tokens: output,
  })
  if (error) console.error('ryze-ai usage insert:', error.message)
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

/// L'abonnement, lu côté serveur.
///
/// Le paywall est dur : sans abonnement actif, la fonction ne dépense rien.
/// Les mêmes règles que le modèle de l'application — à vie, mode test, ou une
/// date d'expiration encore devant nous.
async function isPremium(admin: ReturnType<typeof createClient>, userId: string): Promise<boolean> {
  const { data, error } = await admin
    .from('user_subscriptions')
    .select('tier, period, expiry_date, is_test_mode')
    .eq('user_id', userId)
    .maybeSingle()

  if (error || !data) return false
  if (data.tier !== 'premium') return false
  if (data.is_test_mode === true) return true
  if (data.period === 'lifetime') return true
  if (!data.expiry_date) return true
  return new Date(data.expiry_date).getTime() > Date.now()
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  if (req.method !== 'POST') return json({ error: 'method not allowed' }, 405)

  const admin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { autoRefreshToken: false, persistSession: false } },
  )

  // Qui appelle.
  const authHeader = req.headers.get('Authorization')
  if (!authHeader) return json({ error: 'missing authorization' }, 401)

  const { data: { user }, error: userError } = await admin.auth.getUser(
    authHeader.replace('Bearer ', ''),
  )
  if (userError || !user) return json({ error: 'invalid token' }, 401)

  // Ce qu'il demande.
  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: 'invalid body' }, 400)
  }

  const model = typeof body.model === 'string' ? body.model : ''
  const surface = typeof body.surface === 'string' ? body.surface : ''
  if (!ALLOWED_MODELS.has(model)) return json({ error: 'unknown model' }, 400)
  if (!ALLOWED_SURFACES.has(surface)) return json({ error: 'unknown surface' }, 400)

  const payload = body.payload
  if (!payload || typeof payload !== 'object') return json({ error: 'missing payload' }, 400)

  // Le flux pour la conversation, l'aller-retour pour tout le reste. Une
  // analyse de photo n'a rien à streamer : elle attend un JSON entier.
  const wantsStream = body.stream !== false

  // La clé n'est lue qu'ici : l'état du serveur ne se raconte pas à un
  // appelant qui n'a pas encore prouvé qui il est.
  const apiKey = Deno.env.get('GEMINI_API_KEY')
  if (!apiKey) return json({ error: 'server not configured' }, 500)

  if (!(await isPremium(admin, user.id))) {
    return json({ error: 'subscription required' }, 402)
  }

  // Le relais.
  const endpoint = wantsStream
    ? `${model}:streamGenerateContent?alt=sse`
    : `${model}:generateContent`

  const upstream = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${endpoint}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify(payload),
    },
  )

  if (!upstream.ok || !upstream.body) {
    const detail = await upstream.text()
    // Le détail de Google peut contenir la requête ; on n'en rend que le début.
    return json({ error: detail.slice(0, 300) }, upstream.status)
  }

  // L'aller-retour : la réponse tient en un objet, les jetons sont dedans.
  if (!wantsStream) {
    const answer = await upstream.json()
    const usage = answer?.usageMetadata ?? {}
    const write = meter(admin, user.id, surface, model,
      usage.promptTokenCount ?? 0, usage.candidatesTokenCount ?? 0)
    // @ts-ignore EdgeRuntime est fourni par l'exécution Supabase.
    if (typeof EdgeRuntime !== 'undefined') EdgeRuntime.waitUntil(write)
    return json(answer, 200)
  }

  // Le flux part vers l'application sans attendre, et une copie est lue au
  // passage pour retenir le dernier `usageMetadata` du tour. C'est le seul
  // endroit où l'on connaît le coût réel, plutôt qu'une estimation.
  const [toClient, toMeter] = upstream.body.tee()

  const metering = (async () => {
    let prompt = 0
    let output = 0
    try {
      const reader = toMeter.getReader()
      const decoder = new TextDecoder()
      let buffer = ''

      for (;;) {
        const { done, value } = await reader.read()
        if (done) break
        buffer += decoder.decode(value, { stream: true })

        // Les lignes complètes seulement : un `data:` coupé en deux se lit au
        // tour suivant.
        const lines = buffer.split('\n')
        buffer = lines.pop() ?? ''
        for (const line of lines) {
          if (!line.startsWith('data:')) continue
          const raw = line.slice(5).trim()
          if (!raw || raw === '[DONE]') continue
          try {
            const meta = JSON.parse(raw)?.usageMetadata
            if (meta) {
              prompt = meta.promptTokenCount ?? prompt
              output = meta.candidatesTokenCount ?? output
            }
          } catch {
            // Un morceau illisible ne doit pas interrompre le relais.
          }
        }
      }
    } catch (e) {
      console.error('ryze-ai meter:', e)
    }

    await meter(admin, user.id, surface, model, prompt, output)
  })()

  // Le comptage survit à la réponse : sans cela, la fonction s'arrête dès que
  // l'application a tout reçu et la ligne n'est jamais écrite.
  // @ts-ignore EdgeRuntime est fourni par l'exécution Supabase.
  if (typeof EdgeRuntime !== 'undefined') EdgeRuntime.waitUntil(metering)

  return new Response(toClient, {
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  })
})
