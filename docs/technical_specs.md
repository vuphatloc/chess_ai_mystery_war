# Technical Specifications - Chess AI: Mystery War

## 1. Technology Stack

### 1.1. Core Framework
- **Flutter 3.x** (Dart 3.x) - Cross-platform mobile development
- **Target Platforms**: iOS 13+, Android 8.0+ (API 26+)

### 1.2. Architecture Pattern
- **Clean Architecture** with Domain-Driven Design
- **State Management**: Riverpod 2.x (Provider pattern with dependency injection)
- **File Structure**:
  ```
  lib/
  ├── domain/           # Business logic, entities, use cases
  ├── data/            # Data sources, repositories, models
  ├── presentation/    # UI, widgets, state management
  └── core/           # Shared utilities, constants, extensions
  ```

### 1.3. External Dependencies
- **HTTP Client**: Dio for API calls
- **Local Storage**: SharedPreferences + AES encryption (encrypt package)
- **Ads Integration**: Google Mobile Ads (admob_flutter)
- **Animation**: Flutter built-in animations + Rive for complex animations
- **AI Integration**: DeepSeek API (HTTP REST calls)
- **Connectivity**: connectivity_plus for network status

## 2. Core Game Components

### 2.1. Domain Layer
- **Piece Entity**: Type (pawn, rook, knight, bishop, queen, king), Color (white/black), Position (x,y), IsRevealed (bool)
- **Board Entity**: 8x8 grid of Piece? (nullable), Game state (active, check, checkmate, stalemate)
- **Move Entity**: From position, To position, Piece type, IsCapture (bool)
- **Game Rules Engine**: Move validation, Check detection, Checkmate detection
- **Mystery Mechanic**: Shuffle algorithm, Flip logic, Position-based movement

### 2.2. Data Layer
- **Local Storage Service**: AES-256 encrypted storage for Gold, Trophies, Settings
- **Game State Repository**: Save/load game state
- **DeepSeek API Client**: REST API integration for AI moves and analysis
- **Ad Service**: Ad loading and reward handling

### 2.3. Presentation Layer
- **Game Board Widget**: Interactive chess board with piece rendering
- **Piece Widget**: Custom widget with flip animation
- **Game Screen**: Main game interface with controls
- **Menu Screens**: Home, Settings, Champion Mode, PvP
- **Ad Overlay**: Reward ad display

## 3. Key Technical Challenges

### 3.1. Mystery Mechanic Implementation
- **Challenge**: Pieces move based on starting position, not actual type until revealed
- **Solution**: Track two piece types - "apparent type" (position-based) and "actual type" (revealed)
- **Implementation**: Piece entity with `apparentType` and `actualType` properties

### 3.2. AI Integration Strategy
- **Challenge**: DeepSeek API is text-based, not chess-specific
- **Solution**: Convert board state to FEN notation, send to DeepSeek with chess-specific prompt
- **Implementation**: FEN generator, prompt engineering for move suggestions

### 3.3. Performance Considerations
- **Challenge**: Smooth animations on lower-end devices
- **Solution**: Optimize widget rebuilds, use const constructors, implement efficient state updates
- **Implementation**: Riverpod selectors, ValueNotifier for board updates

### 3.4. Security Implementation
- **Challenge**: Secure local storage to prevent cheating
- **Solution**: AES-256 encryption with device-specific key derivation
- **Implementation**: encrypt package with PBKDF2 key derivation

## 4. Development Phases

### Phase 1: Foundation (Week 1-2)
1. Project setup with Clean Architecture
2. Core domain entities and game logic
3. Basic board rendering without mystery mechanic

### Phase 2: Core Gameplay (Week 3-4)
1. Mystery mechanic implementation
2. Move validation and game rules
3. Basic AI (offline bot)

### Phase 3: AI Integration (Week 5-6)
1. DeepSeek API integration
2. AI analysis feature
3. Champion mode with progressive AI difficulty

### Phase 4: Polish & Monetization (Week 7-8)
1. Ads integration
2. Gold system
3. UI polish and animations
4. Testing and bug fixes

## 5. Testing Strategy

### 5.1. Unit Tests
- Domain logic (move validation, check detection)
- Game rules engine
- Mystery mechanic algorithms

### 5.2. Widget Tests
- Board rendering
- Piece interactions
- UI state changes

### 5.3. Integration Tests
- Full game flow
- AI integration
- Ad reward system

## 6. Deployment Requirements

### 6.1. App Store Requirements
- **iOS**: App Store Connect setup, privacy manifest, app icons
- **Android**: Google Play Console, app signing, privacy policy

### 6.2. Monetization Setup
- **AdMob**: App ID, ad unit IDs for banner and rewarded ads
- **DeepSeek API**: API key management (secure storage)

### 6.3. Analytics
- **Firebase Analytics**: Track user engagement, game modes, revenue
- **Crashlytics**: Error reporting and monitoring