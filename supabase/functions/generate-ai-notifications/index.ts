// Edge Function to generate personalized AI notifications
// Called by CRON every Sunday at 22h UTC
// Generates 25 personalized notifications per user for the week

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Gemini API configuration (using same model as app)
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent'

interface UserContext {
  userId: string
  locale: string
  gender?: string // 'male' | 'female' | null
  coachPersonality: string
  customPersonality?: string
  onboardingInsights?: string // Raw markdown string from coach preference extractor
  streak: number
  weightLost?: number
}

interface GeneratedNotification {
  type: string
  title: string
  body: string
  context: string
}

// Build the prompt based on user context
function buildPrompt(ctx: UserContext): string {
  const personalityDescriptions: Record<string, string> = {
    friendly: "Chaleureux et encourageant. Utilise 'tu', beaucoup d'emojis, ton positif et enthousiaste.",
    strict: "Direct et exigeant mais juste. Peu d'emojis, ton ferme mais motivant.",
    supportive: "Empathique et compréhensif. Ton doux, encourageant face aux difficultés.",
    sassy: "Taquin et humoristique. Provocateur gentil, utilise l'humour pour motiver.",
    direct: "Concis et factuel. Va droit au but, pas de fioritures.",
    custom: ctx.customPersonality || "Adaptable selon les préférences de l'utilisateur."
  }

  const personalityDesc = personalityDescriptions[ctx.coachPersonality] || personalityDescriptions.friendly

  const langInstructions: Record<string, string> = {
    fr: "Génère toutes les notifications EN FRANÇAIS.",
    en: "Generate all notifications IN ENGLISH.",
    de: "Generiere alle Benachrichtigungen AUF DEUTSCH."
  }

  const langInstruction = langInstructions[ctx.locale] || langInstructions.fr

  // Build gender instruction
  let genderInstruction = ''
  if (ctx.gender === 'female') {
    genderInstruction = `\nIMPORTANT - GENRE: L'utilisateur est une FEMME. Utilise des accords féminins et un langage approprié (pas de "mec", "gars", "champion" → préfère "championne", etc.)\n`
  } else if (ctx.gender === 'male') {
    genderInstruction = `\nIMPORTANT - GENRE: L'utilisateur est un HOMME. Tu peux utiliser un langage masculin casual si approprié.\n`
  }

  // Build context section
  let contextSection = ''
  if (ctx.onboardingInsights) {
    // onboardingInsights is a raw markdown string from the coach preference extractor
    contextSection += `${ctx.onboardingInsights}\n`
  }
  contextSection += `- Streak actuel : ${ctx.streak} jours\n`
  if (ctx.weightLost !== undefined && ctx.weightLost > 0) {
    contextSection += `- Poids perdu : ${ctx.weightLost}kg\n`
  }

  return `Tu es Coach Ryze, un coach fitness IA. Tu génères des notifications push personnalisées.

${langInstruction}
${genderInstruction}
PERSONNALITÉ DU COACH : ${ctx.coachPersonality}
${personalityDesc}

CONTEXTE DE L'UTILISATEUR :
${contextSection}

GÉNÈRE EXACTEMENT 25 notifications variées :
- 5 rappels repas (breakfast, lunch, dinner, snack) - utilise le contexte d'événement si présent
- 5 rappels hydratation (water)
- 5 rappels workout/sport - aide à surmonter les blocages
- 5 motivation streak (streak)
- 5 célébration progression (progress)

FORMAT JSON STRICT (array uniquement, pas de markdown) :
[
  {
    "type": "meal",
    "title": "emoji + titre court",
    "body": "message personnalisé max 100 caractères",
    "context": "event|progress|blocker|motivation|goal"
  }
]

RÈGLES STRICTES :
- Max 100 caractères pour le body
- Utilise le contexte utilisateur dans les messages
- Varie les messages (pas de répétition)
- Motivant, jamais culpabilisant
- Emoji au début du title uniquement
- Respecte la personnalité du coach
- Respecte la langue demandée
- Retourne UNIQUEMENT le JSON, pas de texte avant ou après`
}

// Call Gemini API
async function callGemini(prompt: string, apiKey: string): Promise<GeneratedNotification[]> {
  const response = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.8,
        maxOutputTokens: 4096,
      }
    })
  })

  if (!response.ok) {
    const error = await response.text()
    console.error('Gemini API error:', error)
    throw new Error(`Gemini API error: ${response.status}`)
  }

  const data = await response.json()
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text || ''

  // Extract JSON from response (handle markdown code blocks)
  let jsonText = text.trim()
  if (jsonText.startsWith('```json')) {
    jsonText = jsonText.slice(7)
  } else if (jsonText.startsWith('```')) {
    jsonText = jsonText.slice(3)
  }
  if (jsonText.endsWith('```')) {
    jsonText = jsonText.slice(0, -3)
  }
  jsonText = jsonText.trim()

  try {
    const notifications = JSON.parse(jsonText) as GeneratedNotification[]
    return notifications
  } catch (e) {
    console.error('Failed to parse Gemini response:', text)
    throw new Error('Invalid JSON from Gemini')
  }
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } }
    )

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      throw new Error('GEMINI_API_KEY not configured')
    }

    // Optional: process only specific user (for testing)
    let targetUserId: string | null = null
    try {
      const body = await req.json()
      targetUserId = body.userId || null
    } catch {
      // No body, process all users
    }

    // Get active users (only those active in last 30 days based on updated_at)
    const thirtyDaysAgo = new Date()
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30)

    // Get active users (no notifications_enabled filter - app checks locally)
    let usersQuery = supabaseAdmin
      .from('users')
      .select('id, language, gender, streak_count, coach_personality, coach_personality_custom')
      .gte('updated_at', thirtyDaysAgo.toISOString())

    if (targetUserId) {
      usersQuery = usersQuery.eq('id', targetUserId)
    }

    const { data: users, error: usersError } = await usersQuery

    if (usersError) {
      console.error('Error fetching users:', usersError)
      throw usersError
    }

    console.log(`Processing ${users?.length || 0} users`)

    const results = {
      processed: 0,
      success: 0,
      failed: 0,
      errors: [] as string[]
    }

    const expiresAt = new Date()
    expiresAt.setDate(expiresAt.getDate() + 7) // Expire in 7 days

    for (const user of users || []) {
      try {
        results.processed++

        // Get user coach preferences separately
        const { data: prefsData } = await supabaseAdmin
          .from('user_coach_preferences')
          .select('preferences')
          .eq('user_id', user.id)
          .maybeSingle()

        // Extract onboarding_insights from the preferences JSONB column
        const prefs = prefsData?.preferences as {
          onboarding_insights?: string
          coach_personality?: string
          custom_personality?: string
        } | null

        // Get weight progress
        const { data: weightData } = await supabaseAdmin
          .from('weight_entries')
          .select('weight')
          .eq('user_id', user.id)
          .order('date', { ascending: true })
          .limit(2)

        let weightLost = 0
        if (weightData && weightData.length >= 2) {
          weightLost = weightData[0].weight - weightData[weightData.length - 1].weight
        }

        const context: UserContext = {
          userId: user.id,
          locale: user.language || 'fr',
          gender: user.gender || undefined,
          coachPersonality: user.coach_personality || 'friendly',
          customPersonality: user.coach_personality_custom,
          onboardingInsights: prefs?.onboarding_insights,
          streak: user.streak_count || 0,
          weightLost: weightLost > 0 ? Math.round(weightLost * 10) / 10 : undefined
        }

        // Delete old unused notifications for this user
        await supabaseAdmin
          .from('ai_notifications_pool')
          .delete()
          .eq('user_id', user.id)
          .eq('used', false)

        // Generate new notifications
        const prompt = buildPrompt(context)
        const notifications = await callGemini(prompt, geminiApiKey)

        // Insert notifications into pool
        const notificationsToInsert = notifications.map(n => ({
          user_id: user.id,
          notification_type: n.type,
          title: n.title,
          body: n.body,
          locale: context.locale,
          coach_personality: context.coachPersonality,
          context_used: n.context,
          expires_at: expiresAt.toISOString()
        }))

        const { error: insertError } = await supabaseAdmin
          .from('ai_notifications_pool')
          .insert(notificationsToInsert)

        if (insertError) {
          console.error(`Error inserting notifications for user ${user.id}:`, insertError)
          results.failed++
          results.errors.push(`User ${user.id}: ${insertError.message}`)
        } else {
          results.success++
          console.log(`Generated ${notifications.length} notifications for user ${user.id}`)
        }

      } catch (userError) {
        results.failed++
        const errorMsg = userError instanceof Error ? userError.message : 'Unknown error'
        results.errors.push(`User ${user.id}: ${errorMsg}`)
        console.error(`Error processing user ${user.id}:`, userError)
      }

      // Add small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 100))
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'AI notifications generation completed',
        results
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error instanceof Error ? error.message : 'Unknown error'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
