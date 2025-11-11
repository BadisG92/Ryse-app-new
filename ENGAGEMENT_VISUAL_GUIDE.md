# RYSE APP - ENGAGEMENT FEATURES VISUAL GUIDE

## User Journey Through Engagement Systems

```
DAY 1: ONBOARDING
├── Welcome Screen (Tutorial Service)
│   └── Sets expectations for feature discovery
│
├── Dashboard Tutorial (Feature Discovery)
│   ├── "Add Food" button
│   ├── "Add Exercise" button
│   ├── "Add Water" button
│   └── Calories card
│
└── RESULT: User learned 4 core actions

---

DAY 2: ENGAGEMENT LOOP
├── App Open (GlobalStateManager)
│   ├── Load streak immediately
│   ├── Show cached goals
│   └── Display previous progress
│
├── User Action (e.g., Log Meal)
│   ├── GoalsNotifier updates real-time
│   ├── "Meals recorded" goal increments
│   └── CelebrationService triggers
│
├── Celebration Popup (Reward Psychology)
│   ├── Full-screen overlay
│   ├── Coach avatar appears
│   ├── Random motivational message
│   └── 5-second display then auto-dismiss
│
├── Return to Dashboard
│   ├── XP counter animated (+50 XP)
│   ├── Goals progress bar fills
│   └── Daily streak visible
│
└── RESULT: User feels rewarded, motivated

---

DAY 7: WEEKLY REVIEW
├── WeeklyBalance Dashboard (ProgressServiceV2)
│   ├── "5/7 Calorie Target Days"
│   ├── "6/7 Hydration Days"
│   ├── "19/21 Meals Recorded"
│   └── "3/4 Sport Sessions"
│
├── Weekly Score Calculation
│   ├── Average all metrics: (5+6+19/21+3) / 4 = ~78%
│   ├── Color indicator: Dark Blue (Good)
│   └── Status: "Keep going!"
│
├── AI Recommendations (ProgressServiceV2)
│   ├── "Great hydration this week!"
│   ├── "Consider adding one more workout"
│   └── "Your consistency is impressive"
│
└── RESULT: User sees holistic progress, gets personalized advice

---

MONTHLY: WEIGHT EVOLUTION (WeightEvolutionScreen)
├── Historical Chart (FL Chart)
│   ├── Current weight: 72.5kg
│   ├── Previous weight: 73.0kg
│   ├── Initial weight: 75.0kg
│   └── Target weight: 70.0kg
│
├── Change Summary
│   ├── "This month: -0.5kg" (GREEN)
│   ├── "Lifetime: -2.5kg" (GREEN)
│   └── "Distance to goal: 2.5kg remaining"
│
└── RESULT: Tangible proof of behavior impact
```

---

## The Engagement Funnel

```
AWARENESS → ACTIVATION → RETENTION → MONETIZATION
    ↓              ↓                  ↓              ↓
Tutorials    Celebrations      Streaks           Premium
             Real-time Goals   Weekly Balance    Unlock

         Engagement Layers (All Together):
    ┌─────────────────────────────────────┐
    │   MOTIVATION                         │
    │   (Celebration + XP + Goals)        │
    ├─────────────────────────────────────┤
    │   HABIT FORMATION                   │
    │   (Streak + Daily Loops)            │
    ├─────────────────────────────────────┤
    │   PROGRESS VISUALIZATION            │
    │   (Charts + Weekly Balance)         │
    ├─────────────────────────────────────┤
    │   PERSONALIZATION                   │
    │   (AI Recommendations + CTAs)       │
    ├─────────────────────────────────────┤
    │   EDUCATION                         │
    │   (Tutorials + Feature Discovery)   │
    └─────────────────────────────────────┘
        ALL LAYERS ACTIVE SIMULTANEOUSLY
```

---

## Real-Time Update Flow

```
USER ACTION (Log Meal)
    ↓
FoodEntriesService.addEntry()
    ↓
┌─────────────────────────────────────┐
│ SIMULTANEOUS UPDATES                │
├─────────────────────────────────────┤
│                                     │
│ 1. GoalsNotifier updates real-time  │
│    └─ "Meals recorded" +1           │
│                                     │
│ 2. CelebrationService triggers      │
│    └─ Pick random message           │
│                                     │
│ 3. StreakService notifyActivity()   │
│    └─ Update streak_last_date       │
│                                     │
│ 4. GlobalStateManager updates       │
│    └─ Cache invalidated             │
│                                     │
│ 5. WeightNotifier listeners fire    │
│    └─ Trigger dependent screens     │
│                                     │
└─────────────────────────────────────┘
    ↓
CELEBRATION POPUP SHOWS (600ms)
    ├─ Fade-in animation
    ├─ Coach avatar scale (0.8→1.0)
    └─ Message + Subtitle display
    ↓
AUTO-DISMISS (5 seconds)
    ├─ Reverse animation
    └─ Return to dashboard
    ↓
USER SEES UPDATED:
    ├─ Goals progress bars
    ├─ XP counter (+50 XP)
    ├─ Streak badge (if applicable)
    └─ "Meals recorded" count
```

---

## Psychological Mechanisms Map

```
                    RYSE ENGAGEMENT SYSTEM
                    
      ┌──────────────────────────────────────────┐
      │      BEHAVIORAL PSYCHOLOGY BASE           │
      │  (Habit Formation + Reward Schedules)     │
      └──────────────────────────────────────────┘
                            ↓
    ┌───────────────┬───────────────┬──────────────┐
    ↓               ↓               ↓              ↓
LOSS AVERSION    DOPAMINE        MOMENTUM      IDENTITY
(Streak)      (Celebration)    (Progress Bar)  (7-day user)
    ↓               ↓               ↓              ↓
"Keep your"    "You did it!"    "Almost      "I'm a fit
 7-day        (every time)     there!"      person now"
 
    └───────────────┬───────────────┬──────────────┘
                    ↓
      ┌──────────────────────────────────────────┐
      │    RESULT: USER RETURNS DAILY             │
      │  Predicted D7 Retention: 45-60%           │
      └──────────────────────────────────────────┘
```

---

## Celebration System Breakdown

```
CELEBRATION TRIGGERS
    ├─ Workout Completion
    │   └─ 20 unique messages
    │       ├─ "Beast mode!" (High intensity)
    │       ├─ "Tu déchires!" (Francophone tone)
    │       ├─ "You're building..." (Progress focused)
    │       └─ [Random variation each time]
    │
    ├─ Food Entry Logged
    │   └─ 19 nutrition-specific messages
    │       ├─ "Great choice!" (Positive choice)
    │       ├─ "You eat smart!" (Intelligence)
    │       ├─ "Fueling success" (Progress)
    │       └─ [Never judgmental, always supportive]
    │
    └─ Cardio Session
        └─ Activity-specific
            ├─ Duration displayed
            ├─ Distance calculated
            └─ "5km run · 25 min"

PRESENTATION FORMAT
    ┌─ Full Screen Overlay
    ├─ 85-95% opacity dark blue gradient
    ├─ Large coach avatar (200x200)
    │   ├─ Sport coach (for workout)
    │   ├─ Chef coach (for nutrition)
    │   └─ General coach (fallback)
    ├─ Bold message (36px, white)
    ├─ Subtitle (18px, white 0.85 opacity)
    ├─ Action detail (16px, white 0.7 opacity)
    └─ "Tap anywhere to continue" hint

ANIMATIONS
    ├─ Entrance: Fade-in (600ms) + Scale (0.8→1.0)
    ├─ Duration: 5 seconds auto-dismiss
    └─ Exit: Reverse fade-out + scale

PSYCHOLOGY
    ├─ Variable rewards (random messages)
    ├─ Immediate feedback (instant popup)
    ├─ Positive reinforcement (celebratory tone)
    ├─ Social presence (coach avatar)
    └─ Habit loop closure (reward for behavior)
```

---

## Weekly Balance Dashboard

```
┌────────────────────────────────────────┐
│        WEEKLY BALANCE SUMMARY           │
│         (7 days: Mon-Sun)              │
├────────────────────────────────────────┤
│                                        │
│  Metric 1: CALORIE TARGET REACHED     │
│  ████████░ 5/7 days                   │
│  Status: ████ 71% achieved (Good)     │
│  Color: Dark Blue                      │
│                                        │
│  Metric 2: HYDRATION VALIDATED        │
│  ███████░░ 6/7 days                   │
│  Status: █████ 86% achieved (Great)   │
│  Color: Dark Green                     │
│                                        │
│  Metric 3: MEALS RECORDED             │
│  ██████░░░ 19/21 meals                │
│  Status: ████ 90% achieved (Excellent)│
│  Color: Green                          │
│                                        │
│  Metric 4: SPORT SESSIONS             │
│  ██████░░░ 3/4 sessions               │
│  Status: ███░ 75% achieved (Good)     │
│  Color: Dark Blue                      │
│                                        │
├────────────────────────────────────────┤
│  GLOBAL SCORE: 80.5%                   │
│  Status: ████░ STRONG WEEK (Dark Blue) │
└────────────────────────────────────────┘
```

---

## Daily Goals Real-Time Update

```
DASHBOARD: DAILY GOALS GRID

┌─────────────────────────────────────┐
│ GOAL 1: CALORIES          ████░ 85% │
│ Target: 2000 kcal                   │
│ Current: 1700 kcal                  │
│ Status: In Progress                 │
│ XP: 0 (completes at 90%+)           │
├─────────────────────────────────────┤
│ GOAL 2: WATER             █████ 100%│
│ Target: 2000 ml                     │
│ Current: 2100 ml                    │
│ Status: ✓ COMPLETED                 │
│ XP: +50 (already awarded)           │
├─────────────────────────────────────┤
│ GOAL 3: MEALS             ████░ 80% │
│ Target: 3 meals                     │
│ Current: 2 meals logged             │
│ Status: In Progress                 │
│ XP: 0 (completes when 3rd added)    │
├─────────────────────────────────────┤
│ GOAL 4: EXERCISE          ██░░░ 40% │
│ Target: 1 session                   │
│ Current: 0 sessions                 │
│ Status: Not Started                 │
│ XP: 0 (completes when logged)       │
└─────────────────────────────────────┘

STATUS SUMMARY: 1/4 GOALS COMPLETED
Total Today: +50 XP (from water)
Today's Score: 76/100
```

---

## Weight Tracking Visualization

```
WEIGHT EVOLUTION SCREEN

┌──────────────────────────────────┐
│ CURRENT WEIGHT                   │
│ 72.5 kg                          │
│                                  │
│ WEIGHT CHANGE THIS MONTH         │
│ -0.5 kg ↓ (GREEN - Good!)        │
│                                  │
│ WEIGHT CHANGE FROM START         │
│ -2.5 kg ↓ (GREEN - Progress!)    │
│                                  │
│ TARGET WEIGHT                    │
│ 70.0 kg                          │
│ Distance: 2.5 kg remaining       │
│ Progress: ███████░ 87% there     │
└──────────────────────────────────┘

WEIGHT CHART (This Month View)
    80 │
       │
    77 │      ╭─┐
       │    ╭─╯ ╰─╮
    74 │   ╱      ╰─
       │  ╱
    71 │╭╯
       │
    68 │
       └────────────────────────────
         1  7  14  21  28 (Days)

PERIOD FILTERS:
[This Month] [3 Months] [6 Months] [All Time]
```

---

## Tutorial Overlay System

```
TUTORIAL FOCUS PATTERN

┌────────────────────────────────────┐
│                                    │
│     Semi-Dark Overlay (0.8)        │
│                                    │
│        ┌──────────────────┐        │
│        │ BRIGHT FOCUS ZONE│        │
│        │  (Light circle)  │        │
│        │  ┌────────────┐  │        │
│        │  │HIGHLIGHTED │  │        │
│        │  │   BUTTON   │  │        │
│        │  └────────────┘  │        │
│        └──────────────────┘        │
│                                    │
│     ┌─────────────────────────┐    │
│     │ EXPLANATION CARD        │    │
│     ├─────────────────────────┤    │
│     │ Title: "Add Your Food"  │    │
│     │                         │    │
│     │ Description: "Tap here  │    │
│     │ to quickly scan a food  │    │
│     │ using your camera"      │    │
│     │                         │    │
│     │ [UNDERSTOOD] [SKIP]     │    │
│     └─────────────────────────┘    │
│                                    │
└────────────────────────────────────┘

TUTORIAL PROGRESSION: Dashboard
    ↓
[Welcome] → [Add Food] → [Add Exercise] → [Add Water]
    ↓              ↓              ↓              ↓
   Skip?         Next           Next           Next
    ↓              ↓              ↓              ↓
  [Calories Card] → [Nutrition Tab] → [Sport Tab] → [Progress Tab]
```

---

## Cache & Performance Strategy

```
GOAL: Show data instantly without spinner

        USER OPENS APP
              ↓
    ┌─────────────────────────┐
    │ TIER 1: Fast Cache (5ms)│
    │ SharedPreferences        │
    │ ✓ Goals (5-min TTL)     │
    │ ✓ Streak (live update)  │
    │ ✓ Weight (24-hour TTL)  │
    └─────────────────────────┘
              ↓
        SHOW CACHED DATA
        (No spinner!)
              ↓
    ┌─────────────────────────┐
    │ TIER 2: Standard Cache  │
    │ (GlobalState)           │
    │ ✓ Dashboard data        │
    │ ✓ Goals summary         │
    └─────────────────────────┘
              ↓
        UPDATE UI (Animated)
              ↓
    ┌─────────────────────────┐
    │ TIER 3: Database        │
    │ (Background fetch)      │
    │ ✓ Fresh goals data      │
    │ ✓ Latest streak         │
    │ ✓ New weight entries    │
    └─────────────────────────┘
              ↓
    IF CACHE > 2 HOURS OLD
    OR NEW ACTIVITY DETECTED
    → Refresh silently
    → Update UI when ready
```

---

## Engagement Metrics Dashboard

```
PREDICTED RETENTION CURVES

With Full Engagement System:
    ↑ Retention %
    │
100 │
    │ Day 1: 100%
 80 │ ╭─╯╲
    │╱    ╲
 60 │      ╰╮
    │       ╰─╮ Day 7: 50% (vs 25% baseline)
 40 │          ╰╮
    │           ╰─ Day 30: 28%
 20 │              ╰─ Day 60: 15%
    │
  0 └───────────────────────────────
    0   7  14  21  28  35  42  49  56 (Days)

KEY BREAKPOINTS:
- Day 1-7: Streak prevents quit (7-day buffer)
- Day 7-14: Weekly balance reward triggers
- Day 14+: Habit loop solidifies (identity formation)
- Day 30+: Weight changes visible (compound proof)
```

---

## File Architecture & Key Services

```
ENGAGEMENT SYSTEM FILES:

Core Services:
├─ progress_service_v2.dart
│  └─ Weekly balance calculation
│  └─ AI recommendations
│  └─ Smart caching
│
├─ streak_service.dart
│  └─ Streak calculation
│  └─ 7-day tolerance logic
│  └─ GlobalState integration
│
├─ celebration_service.dart
│  └─ Celebration messages (40+ total)
│  └─ Context-aware avatars
│  └─ Multi-language support
│
├─ weight_service.dart
│  └─ Weight history management
│  └─ Progress calculations
│  └─ Chart data generation
│
├─ tutorial_service.dart
│  └─ Feature discovery overlays
│  └─ Persistent completion state
│  └─ Multi-section tutorials
│
└─ dashboard_service.dart
   └─ Goals real-time updates
   └─ Cache management
   └─ GoalsNotifier integration

UI Components:
├─ celebration_popup.dart
│  └─ Full-screen celebration display
│
├─ main_dashboard_hybrid.dart
│  └─ Home screen aggregation
│
├─ global_progress_hybrid.dart
│  └─ Weekly/Monthly views
│
└─ weight_evolution_screen.dart
   └─ Weight chart visualization

State Management:
├─ goals_notifier.dart
│  └─ Real-time goal updates
│
├─ weight_notifier.dart
│  └─ Weight change listeners
│
└─ global_state_manager.dart
   └─ Centralized UI state
```

---

## Summary: Why This Works

```
                    ENGAGEMENT LAYERING

    Layer 5: AI Guidance (Weekly)
             "Increase protein intake"
                    ↑
    Layer 4: Visual Progress (Real-time)
             Charts, bars, calendars
                    ↑
    Layer 3: Goal Rewards (Per-action)
             "+50 XP" animations
                    ↑
    Layer 2: Celebrations (Per-action)
             Coach avatar + messages
                    ↑
    Layer 1: Habit Loop (Daily)
             Streak counter + daily reset
                    
= Multiple dopamine hits per day
= Identity formation over weeks
= Data-driven long-term engagement
= Psychological variety prevents boredom
```

