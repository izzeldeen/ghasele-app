# Cleanyjo frontend redesign — prompt

Paste the block below into a fresh Claude Code session in this repo. Feed it
**one screen group at a time** (see *Scope*), not all at once — a whole-app
rewrite in a single pass produces shallow, inconsistent results and an
unreviewable diff.

---

## The prompt

You are redesigning the frontend of **Cleanyjo**, a Flutter dry-cleaning and
laundry app operating in Jordan with pickup & delivery. The visual identity
already exists in the brand assets; the app UI does not yet live up to it. Your
job is to make the UI a faithful extension of the brand, not to invent a new
look.

### Brand truth — derive everything from these

The identity lives in two assets. Open both and look at them before writing any
code:

- `assets/logo/logo-trans.png` — the logo lockup on a clean transparent
  background: a slate shirt-on-hanger inside a green crescent sweep, with
  translucent bubbles, sparkles, a leaf accent, the two-tone "Cleany"(slate) +
  "jo"(green) wordmark, and the rule-flanked tagline "DRY CLEAN SERVICES".
- `assets/logo/Cleanyjo-back.png` — the brand banner, which is the **layout
  reference**. Study its composition: a white content panel on the left, a large
  green panel entering from the right as a single wide circular sweep,
  translucent bubbles of varied size drifting across the seam, a two-tone
  headline ("Fresh Clothes," in slate / "Better Every Day" in green), a short
  green rule under the headline, and a row of thin-line service icons separated
  by hairline dividers.

**Palette — already codified in `lib/theme/app_theme.dart`. Use these tokens,
never raw hex literals in widget code.**

| Token | Hex | Role |
| --- | --- | --- |
| `brandGreen` | `#43AD82` | primary actions, active state, accents |
| `brandGreenLight` | `#5EC79B` | gradient end, hover/pressed |
| `brandGreenDark` | `#2F8C66` | gradient end, pressed |
| `brandGreenSurface` | `#EAF7F1` | tinted section/chip backgrounds |
| `brandSlate` | `#414953` | headlines, icons, dark surfaces |
| `neutral50`–`neutral900` | slate-tinted greys | text, borders, backgrounds |
| `success` / `warning` / `error` / `info` | `#10B981` / `#F59E0B` / `#EF4444` / `#3B82F6` | status only |

**Motifs you may reuse. These are the vocabulary — reach for them instead of
generic Material decoration:**

- **The crescent sweep.** One large, soft green arc anchored off a corner,
  low-opacity. One per screen at most, as a backdrop — never competing with
  content.
- **Bubbles.** Translucent green circles with a small offset white specular
  highlight, in varied sizes. Good for empty states, loaders, and backdrops.
  Keep them out from under text and cards.
- **Thin-line iconography.** Outline-weight icons, matching the banner's service
  row. Stay consistent — do not mix filled and outline icons in one view.
- **Two-tone headline.** Slate phrase + green emphasis phrase, for hero copy.
- **Leaf accent.** Sparingly, for eco/freshness cues.

**Typography.** Inter, via `google_fonts`, already wired into
`AppTheme.textTheme`. Use the existing scale (`displayLarge` → `labelSmall`).
Do not introduce a second family or ad-hoc font sizes.

**Shape & elevation, already established — stay consistent:**

- Cards: 16px radius, `elevation: 0`, 1px `neutral200` border, white fill.
- Buttons and inputs: 12px radius. Primary button may use `brandGradient`.
- Prefer borders and tinted fills over drop shadows. This app reads as flat,
  clean, and airy — shadows only for genuinely floating elements (bottom nav,
  FAB, toasts).
- Generous whitespace. "Clean" is the product promise; the layout should feel it.

### Product vocabulary — use these, they come from the brand banner

Services: **Dry Cleaning, Laundry, Wash & Fold, Ironing, Pickup & Delivery**.
Trust points: **Premium Quality, Fabric Protection, Fast & Reliable, Pickup &
Delivery**. Tagline: **"Fresh Clothes, Better Every Day."**

### Hard constraints — violating any of these is a failed change

1. **Localization.** The app is bilingual Arabic (primary) and English. Every
   user-facing string must come from `AppLocalizations.of(context)!`, with keys
   added to **both** `lib/l10n/app_ar.arb` and `lib/l10n/app_en.arb`. Never
   hardcode a display string. Never add an English-only string.
2. **RTL correctness.** Arabic is RTL and this is where redesigns usually break.
   Use `EdgeInsetsDirectional` and `AlignmentDirectional`, `start`/`end` rather
   than `left`/`right`, and directional icons that flip. Any decoration
   positioned with `Positioned(left:/right:)` must be checked in both
   directions. Phone-number fields stay LTR (`Directionality`) even in Arabic —
   that pattern already exists in `login_screen.dart`, preserve it.
3. **Theme tokens only.** Colors, text styles, radii, and spacing come from
   `AppTheme`. If a value is genuinely missing, add a named token to `AppTheme`
   rather than inlining a literal in a widget.
4. **Use `.withValues(alpha:)`, not `.withOpacity()`.** The latter is deprecated
   and currently produces ~70 analyzer infos. Migrate every line you touch;
   do not add new `withOpacity` calls.
5. **Behavior is frozen.** This is a visual redesign. Do not change API calls,
   navigation routes, validation rules, auth/token handling, or state logic. If
   a redesign seems to require a behavior change, stop and say so instead.
6. **Material 3.** `useMaterial3: true` is already set. Work with it.
7. `flutter analyze` must report **no new** warnings or errors when you finish.

### Scope — work through these in order, one group per pass

1. **Shared foundation.** `lib/theme/app_theme.dart` and
   `lib/widgets/modern_widgets.dart`, `lib/widgets/custom_toast.dart`. Establish
   the reusable pieces first — brand backdrop, bubble motif, section header,
   service tile, stat/trust badge, empty state. Later passes consume these
   rather than re-inventing them.
2. **Auth flow.** `splash_screen.dart`, `login_screen.dart`,
   `signup_screen.dart`, `otp_verification_screen.dart`,
   `forgot_password_screen.dart`, `reset_password_screen.dart`.
3. **Main shell and home.** `home_screen.dart` (bottom nav shell),
   `views/home_view.dart`.
4. **Core journeys.** `views/pricing_view.dart`, `views/orders_view.dart`,
   `views/order_success_view.dart`, `views/order_failure_view.dart`.
5. **Account and secondary.** `views/profile_view.dart`,
   `views/wallet_view.dart`, `views/notifications_view.dart`,
   `views/support_view.dart`, `views/privacy_policy_view.dart`.

### Process

Before editing a group, read every file in it and report:

- what is visually inconsistent with the brand today, concretely (hardcoded
  colors, mismatched radii, mixed icon weights, generic Material defaults);
- the specific changes you propose, and which shared widgets from step 1 they
  will use;
- anything that looks like it needs a behavior change, flagged rather than done.

Then implement, and finish with `flutter analyze` output. Show me one group's
result before starting the next.

### Definition of done for a group

A reviewer opening any two screens in the group should see the same spacing
rhythm, the same corner radii, one icon weight, colors only from `AppTheme`, and
the brand's crescent/bubble vocabulary used deliberately — not decoratively
sprinkled. Both Arabic and English layouts hold without overflow or mirrored-
layout bugs.

---

## Notes on using this

- **Screenshots beat description.** Run the app and attach a screenshot of the
  screen being reworked; it grounds the critique far better than prose.
- **Check Arabic every pass.** RTL breakage is the most common regression in a
  Flutter restyle, and it will not show up in the English build.
- If you want a different visual direction rather than fidelity to the current
  brand, say so explicitly in the prompt — as written, it deliberately
  constrains the redesign to the existing identity.
