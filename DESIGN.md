# Ryze design system

The v2 onboarding is the first layer of the system. Every other page is brought
to it, not the other way round. Code lives in `lib/design/`; import
`lib/design/design.dart` and use the `Ryze*` names. The onboarding keeps its
`Onb*` names as aliases of the same tokens.

## Ground

Paper `#F5F6F8`, a faint grid (8 % of the width per cell, fading to nothing by
the middle of the screen) and a warm amber glow top right. The grid is the
signature of the ground and stays; the blurred gym scene behind it was dropped.

## Colour: one rule

- **Ink, navy `#0B132B`** is everything the user chooses or presses. A filled
  navy card is a choice made. A navy button is the action.
- **Amber `#F2A93B`** is everything Ryze gives back: the progress bar, the live
  pointer of a ruler, the curve of a projection, the signature of the pact, and
  the single gold button of the trial. Never a second navy-and-amber element.
- **Text** is ink; secondary text is `mute #5F6779` (5.2:1 on paper). `mute2`
  is decorative only, never text. Amber text uses `accInk #9A5F0C`.
- **Green `#10B981`** is reserved for confirmation buttons. It is never a state.
- The three macro dots (blue, amber, red) are the only place a third hue lives.

## State: one variable, the fill

Every slot of the week and every mark follows the same three states:

| state   | look                          |
|---------|-------------------------------|
| free    | light grey fill `#D5DAE1`     |
| planned | white with a 1.4 pt navy edge |
| done    | navy fill, white check        |

Sport is told apart from food by shape and icon: meals are squares, a session
is a ring; a session tile has a navy edge, a meal tile a light one. Never by
colour. The snack square appears only on days that have a snack.

## Type

Archivo (variable, bundled) for headlines and big numbers, tight tracking
(-0.028 em), height 1.04. Instrument Sans (variable, bundled) for everything
else, height 1.4. Sizes are fractions of the screen width (`context.vw`), so
the composition holds from 375 to 430 pt. A headline shrinks with its length
(7.8 / 6.9 / 6.1 vw) so German never pushes the instrument off the screen.
Digits that change use tabular figures.

## Motion

Three curves: `out` (fast start, soft landing) for almost everything; `spring`
for things that arrive (cards, a slot taking an impact); `snap` for curtains.

- One orchestrated reveal per screen, not an effect on every element.
- A fill the user must read lasts 480 ms; the screen waits 780 ms from the tap
  before turning, so the choice is seen.
- Digits roll like an odometer: the units roll, the tens turn only during the
  carry. A value that changes mid-roll retargets; it never restarts.
- Rulers keep the whole fling and land on the nearest graduation; haptics are
  throttled to one every 35 ms.
- A validated item flies from the row the user read to its day; the slot shows
  nothing until the mark lands, then pops.
- Continuous animations (sheen, pulse, odometer) sit in a repaint boundary.
- A curtain can always be skipped with a tap.

## Components

- **Background** grid + glow · **Top bar** back circle, four chapter bars,
  label · **Coach avatars** bust crop in a 2 pt white ring on `#DFE4F2` ·
  **Buttons** ink pill; gold pill with sheen only for the trial · **Choice
  card** ink wipe from the left, white text, check circle · **Chips** ink when
  selected · **Rulers** horizontal, graduations, amber needle, odometer number
  above · **Wheel** age · **Chapter card** navy curtain, 1.7 s, tappable ·
  **Hold to sign** amber fill, stamp, sparks · **Projection chart** one
  orchestrated reveal, target rule, labels at the end of their line · **Week
  strip** seven days, marks, two states, landing · **Proposal card** header,
  rows, totals, ghost cancel + green confirm, tonal secondary, text link ·
  **Sheets** content-fit, actions pinned to the bottom of the sheet.

## Copy

FR, EN, DE for every string, always through a dictionary (`OnbStrings` in the
onboarding, `translations.dart` in the app). No literal in a widget. Numbers
follow the language (thin space, comma, point). The store's currency is used
for every amount on a page that shows a store price. Claims must be true of
the shipped app: no invented features, no unsourced statistics.

## What is still to migrate

The widgets are exported from their onboarding and planner files; moving them
under `lib/design/` and renaming `Onb*` to `Ryze*` happens page by page as the
rest of the app is redesigned. The auth screens already import the tokens.
