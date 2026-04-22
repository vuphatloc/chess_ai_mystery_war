# Software Requirement Specification (SRS) - Chess AI: Mystery War

## 1. Project Information
- **App Name:** Chess AI: Mystery War
- **Platform:** Flutter (iOS & Android)
- **Programming Language:** Dart
- **AI Engine:** DeepSeek API (Chat & Reasoner)
- **Storage Strategy:** Encrypted Local Files (AES-256)

## 2. Core Game Logic (The Mystery Mechanic)
- **Setup:** - King is revealed and placed in its standard position.
    - Other 15 pieces are shuffled and placed face-down on standard chess starting positions.
- **Move Rules (Pre-reveal):** Pieces move according to the **initial position** they occupy (e.g., a piece at the Rook position moves like a Rook).
- **The Flip (Reveal):** - A piece is flipped **AFTER** the move or capture is completed.
    - Once revealed, it moves according to its **true identity** for the rest of the game.
- **Victory Condition:** Checkmate the opponent's King.

## 3. Key Features & User Stories
### 3.1. Game Modes
- **Offline Practice:** Play against a local basic bot (No internet needed).
- **Champion Mode:** A tournament tree style where player competes against progressively harder bots.
- **Local PvP:** Two players on a single device.
- **AI Analysis:** Online feature where DeepSeek analyzes the board and provides textual strategy advice.

### 3.2. Monetization (Ads & Gold)
- **Rewarded Ads:** - View 1 Ad = Receive Gold (Approx. 50 VND revenue).
    - View 1 Ad = Unlock AI Analysis/Hint for one turn.
- **Gold System:** Used for entry fees in Champion mode or buying skins.

### 3.3. UI/UX Requirements
- **Visuals:** AI-generated PNG sprites (2D/2.5D style).
- **Animations:** 180-degree flip animation when revealing pieces. Smooth piece sliding.
- **Feedback:** Highlight valid moves when a piece is selected.

## 4. Technical Architecture
### 4.1. Project Structure (Clean Architecture)
- `domain/`: Pure Dart logic (Piece entities, Move validation, Shuffle algorithms).
- `data/`: Local storage services (AES encryption/decryption), API clients for DeepSeek.
- `presentation/`: Flutter Widgets, Game State Management (Bloc/Provider).

### 4.2. Security
- **Anti-Cheat:** All local data files (Gold, Trophy) must be encrypted using AES-256 with a secure secret key.
- **Network Check:** The app must verify internet connectivity before attempting to load Ads or call AI APIs.

## 5. Future Scalability
- The `StorageService` and `GameService` must be designed using Interfaces to allow seamless integration of a Backend Database (Firebase/NodeJS) in the future without rewriting UI logic.