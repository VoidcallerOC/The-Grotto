# Design

## Purpose

The Grotto is a dark subterranean exploration/action game in which music is part of the world. It is not a rhythm game: authored music events change lighting, encounters, paths, and world state.

## Foundation loop

Grotto hub → descent → explore → encounter → music/world event → combat → Echo discovery → climax gate → return to Grotto.

## Stable decisions

- Placeholder geometry first; no final art pass in the foundation.
- Manually authored music events before automatic audio analysis.
- Local persistence only; no accounts, backend, blockchain, multiplayer, or monetization.
- One simple enemy archetype and one basic attack are enough for the first playable proof.

## Current limitations

The current scenes are intentionally compact and use runtime-generated primitive geometry. Production audio, authored models, animation, VFX, and a fuller combat design remain future work.
