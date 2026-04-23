# UI/UX & Feature Specification: Chess AI: Mystery War

This document defines the visual style, user interface structure, and core features for the **Chess AI: Mystery War** mobile application.

## 1. Design Aesthetics & Visual Identity

### Core Style: Modern "Mystery" Futuristic
- **Visuals**: 2.5D / Isometric perspective for the game board.
- **Theme**: Dark Mode by default with neon accents (Cyan, Purple, Gold).
- **UI Elements**: Glassmorphism (semi-transparent, blurred backgrounds), smooth transitions, and micro-animations.
- **Typography**: Modern sans-serif (e.g., *Outfit*, *Inter*, or *Roboto*).

---

## 2. Screen Structure & Features

### A. Start Screen (Main Hub)
The central point of the app with high-impact visuals.
- **Start Button**: Opens a sub-menu to select Game Modes.
- **Store Button**: Access the marketplace.
- **Config Button**: Access settings and tutorials.
- **Currency Display**: Shows current Gold/Gems.

### B. Game Modes (Sub-menu of Start)
1. **Normal Mode**: Classic chess rules. AI difficulty levels from Beginner to Grandmaster.
2. **Mystery Mode**: 
   - **Fog of War**: Only see squares your pieces can move to.
   - **Random Events**: Random tiles might grant buffs or traps.
   - **Mystery Pieces**: Pieces that change identity or have special abilities.
3. **Champion Mode**: 
   - Competitive ladder / Tournament style.
   - Boss battles against specialized AI "Champions" with unique strategies.

### C. Store (Monetization & Customization)
- **Skins**: 
   - **Piece Skins**: Sci-fi, Classic Wood, Glass, Elemental (Fire/Ice).
   - **Board Skins**: Cyberpunk city, Marble Palace, Deep Space.
- **Economy**:
   - **Gold**: Earned by winning games or watching ads.
   - **Watch Ads**: Reward users with Gold for a short video.

### D. Config (Settings & Education)
- **Audio**: Separate toggles for Background Music and Sound Effects (SFX).
- **Game Hints**: Toggle visual cues for best moves (helpful for beginners).
- **App Theme**: Toggle between different color palettes (Cyan/Purple, Gold/Black, etc.).
- **Tutorial (Chess for Beginners)**: 
   - Interactive guide on how pieces move.
   - Basic strategy (Opening, Mid-game, End-game).
   - Rules specific to Mystery Mode.

---

## 3. Technical Implementation Strategy

### Graphics Strategy
To achieve the "Premium 2.5D" look without the overhead of a full 3D engine:
1. **Isometric Sprites**: Use high-quality PNG/WebP renders for pieces and board tiles.
2. **Layering**: Stack layers for the board background, tiles, and pieces to create depth.
3. **Animations**: Use Flutter's `AnimationController` and `Transform` for smooth movement and scaling effects.

### Navigation Flow
- `MainScreen` -> `GameModeSelector` -> `GamePlayScreen`
- `MainScreen` -> `StoreScreen`
- `MainScreen` -> `SettingsScreen` -> `TutorialScreen`

---

## 4. Next Steps
1. **Asset Creation**: Generate or source a full set of 2.5D chess piece assets.
2. **UI Implementation**: Build the Main Menu based on the mockup.
3. **Game Logic Expansion**: Implement the core state for "Mystery" features.
