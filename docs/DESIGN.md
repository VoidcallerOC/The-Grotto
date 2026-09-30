# Design

## Purpose

The Grotto is a dark subterranean exploration/action game in which music is part of the world. It is not a rhythm game: authored music events change lighting, encounters, paths, and world state.

## Foundation loop

Grotto hub → descent → explore → encounter → music/world event → combat → Echo discovery → climax gate → return to Grotto.

## Stable decisions

- Placeholder geometry first; no final art pass in the foundation.
- Current Echo, Warden, player, environment, and UI visuals are temporary placeholders and are not approved as final art direction. Freeze visual asset work until a separate art-direction reset.
- Manually authored music events before automatic audio analysis.
- Local persistence only; no accounts, backend, blockchain, multiplayer, or monetization.
- One simple enemy archetype and one basic attack are enough for the first playable proof.

## Current limitations

The current scenes are intentionally compact and use runtime-generated primitive geometry plus temporary imported hero placeholders. Production audio, animation, VFX, and a fuller combat/progression design remain future work. The current priority is to make the small game loop reliable and legible before beginning a separate art-direction reset.
