# Project "Ghost Grid" - Product Requirements Document

## 1. Introduction & Vision

This document outlines the product requirements for "Project Ghost Grid," a real-time action combat game.

The core vision is to deliver a game with the tactical depth and clarity of a grid-based system but with the fluid, responsive, and intuitive feel of a direct-control action game. The underlying grid should be a powerful tool for the developers and designers, but remain completely invisible to the player.

## 2. Design Pillars & Goals

*   **Fluid & Responsive Control:** The player must feel in direct, moment-to-moment control of their character. Input should translate immediately to on-screen action, with no feeling of "turn-based" lag or clunky, grid-snapped movement.
*   **Tactical Depth:** Positioning, timing, and intelligent use of abilities are paramount. The combat should be easy to learn but offer significant mastery through understanding of spacing, area denial, and environmental interaction.
*   **Clarity and Readability:** The player should be able to understand the state of combat at a glance. Ability effects, ranges, and areas of impact must be clear and unambiguous, without relying on a visible grid.

## 3. Core Features

### 3.1. Player Control & Movement: The "Ghost in the Machine" Model

This model separates the player's visual experience from the game's underlying logical calculations.

*   **Direct Input:** The player controls their character via direct input (e.g., WASD, joystick).
*   **Visual Model:** The on-screen character model moves smoothly and freely through the world, with fluid animations.
*   **Logical Position:** In the backend, the character's position is always snapped to a specific cell on the game's logical grid. The visual model is smoothly interpolated between these logical cells.
*   **Collision:** All collision and pathing are handled on the logical grid. A cell is either traversable or blocked. The player's logical position cannot enter a blocked cell, preventing the character from getting stuck on small or complex geometry.

### 3.2. Combat System: "Projected Decal" & "Buffered Action"

Combat is real-time and ability-based, emphasizing precision and flow.

*   **Ability-Centric:** All combat actions (attacks, spells, defensive moves) are self-contained abilities.
*   **Projected Decal Targeting:**
    *   Abilities are aimed using ground-projected decals that represent their area of effect (e.g., circles, cones, lines). The player aims these decals freely.
    *   Upon execution, the game determines which logical grid cells fall under the decal and applies the ability's effects to all valid targets within those cells.
    *   Ability ranges are communicated as a simple radius from the character, not as a set of highlighted squares.
*   **Action Buffering:**
    *   The system allows players to "buffer" an action while performing another.
    *   For example, if a player uses an ability on an out-of-range target while moving, the character will automatically continue moving until the target is in range, then seamlessly execute the ability.
    *   This removes the "stop-and-go" feel of traditional grid systems and ensures the game feels responsive.

### 3.3. Environment & World Interaction

The environment is a key tactical element, governed by the logical grid.

*   **Grid-Based World:** The world is built upon the logical grid. Every element of the environment that affects movement exists on this grid as either traversable or blocked.
*   **Pathfinding:** All pathfinding (for both player-character auto-movement and AI) uses the logical grid (e.g., via an A* algorithm). The resulting movement along the calculated path is animated smoothly for the visual model.
*   **Hazards & Effects:** Environmental hazards and persistent ground effects (e.g., a field of fire) will exist on specific grid cells. Their effects will apply to any character whose logical position enters that cell.

### 3.4. Enemy & AI Behavior

AI opponents will operate under the same fundamental rules as the player, creating a fair and predictable challenge.

*   **Grid-Bound Logic:** AI movement and decision-making are based entirely on the logical grid. They will navigate to strategically advantageous cells to use their abilities.
*   **Shared Ruleset:** AI will be bound by the same rules of range, line of sight, and ability effects as the player.
*   **Behavior:** AI behaviors will be designed around manipulating their position on the grid relative to the player and other entities.

---

## 4. Development Plan

- [X] **Phase 1: Project Setup & Core Architecture**
- [X] **Phase 2: Logical Grid & State Management**
- [X] **Phase 3: Character Representation & Rendering**
- [X] **Phase 4: Implementing "Ghost in the Machine" Movement**
- [X] **Phase 5: Implementing "Projected Decal" Abilities**
- [X] **Phase 6: AI Behavior & Action Buffering**

- [ ] **Phase 7: Core Gameplay Loop & Interactivity**
    - [ ] **Implement Targeting Mode for Abilities:**
        - [ ] When the player taps the "Fireball" button, they enter a "targeting mode" instead of instantly firing.
        - [ ] The UI should display a decal (e.g., a semi-transparent circle) on the grid representing the ability's Area of Effect.
        - [ ] The player can tap on any grid cell to move the decal to that location.
        - [ ] A new "Confirm Target" button appears, which, when pressed, calls the `gameController.useAbility()` method with the decal's final position.
    - [ ] **Implement Basic AI Attack Logic:**
        - [ ] In the `GameController`'s `update` loop, add a check for each enemy.
        - [ ] If an enemy is adjacent to the player (i.e., its distance to the player is ~1), it should stop moving and perform an attack.
        - [ ] This will require a new method in the controller, like `attackPlayer(damage)`, which reduces the player's health in the game state.
    - [ ] **Implement Action Buffering:**
        - [ ] Add a "pending action" field to the `GameState` (e.g., `pendingAbility` and `pendingTarget`).
        - [ ] If the player tries to use an ability on an out-of-range target, store the ability and target in the new state fields.
        - [ ] In the `GameController`, after the player moves, check if a pending action exists and if the target is now in range. If so, execute the ability and clear the pending action from the state.
