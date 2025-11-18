# Mitran Web Platform - Product Requirements Document (PRD)

## 1. Executive Summary

**Project Name:** Mitran Web Platform  
**Version:** 1.0 (MVP)  
**Date:** November 2025  
**Document Owner:** Product Team

### Mission Statement
Create a web-based community hub and information portal for stray dog welfare, acting as the primary interface for community engagement and data consumption.

### Core Problem
Current stray dog management is fragmented, reactive, and lacks a centralized data and communication platform. This leads to gaps in tracking health, sterilization, and adoption opportunities.

### Solution Overview
The Mitran website MVP will provide:
- **Community Hub:** A place for users ("Guardians") to connect and share updates
- **Information Portal:** A searchable directory of all stray dogs registered in the system
- **AI-Powered Support:** Tools to help users identify potential diseases and get answers about dog care

---

## 2. Target Audience

### Primary User Persona: "Guardian"

**Description:** A community member, citizen, volunteer, or feeder who is registered on the Mitran platform.

**User Goals:**
- Connect with other local feeders and volunteers
- Look up information about specific dogs (health, status, adoption)
- Get quick, reliable answers to questions about dog health or behavior
- Track personal contributions to the community

**User Characteristics:**
- Age range: 18-65
- Tech comfort: Basic to intermediate
- Motivation: Animal welfare and community engagement
- Device usage: Desktop and mobile web browsers

---

## 3. Technical Architecture

### 3.1 Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Frontend | Flutter Web | Cross-platform web application |
| State Management | Riverpod | Clean, predictable state management |
| Authentication | Firebase Authentication | Google Sign-In |
| Database | Cloud Firestore | Real-time NoSQL database |
| Storage | Firebase Storage | Image uploads (profiles, dogs) |
| AI Backend | Python FastAPI (Render) | Chatbot + disease detection APIs |

### 3.6 Shared Folder Structure (Flutter)

```
lib/
  main.dart
  router.dart
  firebase_options.dart
  models/           # UserModel, DogModel, PostModel, Prediction
  services/         # FirestoreService, AuthService, ChatbotApi, DiseaseApi, FirebaseService, SessionManager
  providers/        # Riverpod providers (auth, profiles, posts, dogs, filters)
  pages/            # Landing, CreateProfile, Hub, Directory, DogDetail, Profile, AiCare, AiChatbot, AiDiseaseScan
  widgets/          # Navbar, common UI components
```

### 3.5 Routing Map (Web)

```
/                       → LandingPage
/create-profile         → CreateProfilePage (authed, first-time)
/hub                    → HubPage (authed)
/directory              → DirectoryPage (authed)
/directory/:dogId       → DogDetailPage (authed)
/ai-care                → AiCarePage (authed)
/ai-care/chatbot        → AiChatbotPage (embedded ChatScreen)
/ai-care/disease-scan   → AiDiseaseScanPage
/profile                → ProfilePage (authed)
```

Guard behavior mirrors `lib/router.dart:15` with Firebase Auth gate and profile completion redirect.

### 3.2 Firebase Data Architecture

#### Collection: `users`
```json
{
  "userId": "string (auto-generated)",
  "email": "string",
  "username": "string (unique)",
  "profilePictureUrl": "string (Firebase Storage URL)",
  "contactInfo": {
    "phone": "string (optional)",
    "email": "string"
  },
  "city": "string",
  "area": "string",
  "userType": "string (Volunteer/Feeder/NGO Member/Citizen)",
  "postIds": ["array of post document IDs"],
  "dogIds": ["array of dog document IDs added by this user"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### Collection: `dogs`
```json
{
  "dogId": "string (auto-generated)",
  "name": "string",
  "photos": ["array of Firebase Storage URLs"],
  "mainPhotoUrl": "string (primary photo)",
  "area": "string",
  "city": "string",
  "vaccinationStatus": "boolean",
  "sterilizationStatus": "boolean",
  "readyForAdoption": "boolean",
  "temperament": "string (Friendly/Shy/Aggressive/Calm, etc.)",
  "healthNotes": "string (optional)",
  "addedBy": {
    "userId": "string (reference to users collection)",
    "username": "string",
    "contactInfo": {
      "phone": "string",
      "email": "string"
    }
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### Collection: `predictions`
```json
{
  "imageUrl": "string (Firebase Storage URL)",
  "label": "string",
  "confidence": "number (0-100)",
  "title": "string",
  "description": "string",
  "symptoms": ["string"],
  "treatments": ["string"],
  "homecare": ["string"],
  "note": "string",
  "timestamp": "timestamp"
}
```

#### Collection: `posts`
```json
{
  "postId": "string (auto-generated)",
  "content": "string (text content)",
  "author": {
    "userId": "string (reference to users collection)",
    "username": "string",
    "profilePictureUrl": "string"
  },
  "timestamp": "timestamp",
  "createdAt": "timestamp"
}
```

### 3.3 Data Relationships

**User → Dogs (One-to-Many)**
- A user can add multiple dogs
- Each dog record stores the `userId` of who added it
- User profile displays `dogIds` array for quick reference

**User → Posts (One-to-Many)**
- A user can create multiple posts
- Each post stores author details (userId, username, profilePictureUrl)
- User profile displays `postIds` array to show activity

**Data Denormalization Strategy:**
- Author information (username, profilePictureUrl) is denormalized in `posts` collection for fast feed rendering
- Contact information is denormalized in `dogs` collection for quick adoption inquiries
- This reduces read operations but requires updates when user profiles change

### 3.3.1 AI Feature Storage

- Chatbot: Persist `session_id` only (web uses `localStorage`; mobile uses `shared_preferences` or secure storage). History is fetched from API when restoring.
- Disease Detection: Store images in Firebase Storage, and prediction results in Firestore (`predictions` collection) with image URLs and timestamps.

### 3.4 External API Integration

**AI Backend: FastAPI services (Render-hosted)**

1. **Chatbot API**
   - Base URL: `https://mitran-chatbot.onrender.com`
   - Endpoints:
     - `POST /v1/sessions` → create a new session (`{"session_id": "uuid"}`)
     - `GET /v1/chat/history?session_id=<id>` → return `messages: [{role, text}]`
     - `POST /v1/chat/send` → send user text and receive reply (non-streaming)
     - `GET /v1/chat/stream?session_id=<id>&text=<message>` → SSE stream of chunks (optional)
     - `GET /health` → `{status: "ok"}`
   - Client: `ChatbotApi` handles health, session, history, send; session ID is persisted in `localStorage` via `SessionManager`. UI lives in `ChatScreen` with optional SSE support.

2. **Disease Detection API**
   - Base URL: `https://mitran-disease-detection.onrender.com`
   - Endpoints:
     - `GET /health` → `{status: "ok"}`
     - `GET /labels` → supported disease labels
     - `POST /predict` (multipart: `file=@image`) → prediction JSON
   - Client: `DiseaseApi` does health, labels, predict (PNG/JPEG). Images upload to Firebase Storage; predictions and image URLs persist to Firestore for history.

#### API Contracts (Canonical)

```json
// Chatbot: POST /v1/sessions → 200
{ "session_id": "string-uuid" }

// Chatbot: GET /v1/chat/history → 200
{ "messages": [ { "role": "user|assistant", "text": "..." } ] }

// Chatbot: POST /v1/chat/send → 200
{ "text": "assistant reply" }
// Variants may include { "delta": "chunk" } or { "content": "assistant reply" }

// Chatbot: GET /health → 200
{ "status": "ok" }

// Disease: GET /labels → 200
{ "labels": ["Mange", "Dermatitis", "..."] }

// Disease: POST /predict → 200
{
  "label": "Mange",
  "confidence": 85.3,
  "title": "Canine Mange",
  "description": "...",
  "symptoms": ["itching", "hair loss"],
  "treatments": ["..."],
  "homecare": ["..."],
  "note": "Consult veterinarian"
}
```

Mobile parity notes:
- Chatbot session persistence should use `shared_preferences` or secured storage; restore via `getHistory` on app launch.
- SSE streaming may vary by platform; fallback to non‑stream `POST /v1/chat/send` when EventSource not available.
- Disease detect flow mirrors web: pick image → upload to Storage → call `/predict` → save to Firestore → render.

---

## 4. Feature Specifications

### 4.1 Page: Landing Page

**Route:** `/`  
**Access:** Public (unauthenticated users)

**Purpose:** Introduce the Mitran mission and serve as the main entry point.

**Components:**

1. **Hero Section**
   - Mission statement display
   - Compelling visuals related to stray dog welfare
   - Key statistics (if available)

2. **Call-to-Action**
   - Primary button: "Join the Community" → opens Google Sign-In popup
   - Secondary button: "Member Login" → opens Google Sign-In popup
   - Post-auth flow: If new user, route to `/create-profile`; else route to `/hub`

3. **Feature Highlights**
   - Brief overview of platform features
   - Community testimonials (future enhancement)

**Acceptance Criteria:**
- [ ] Page loads in under 2 seconds
- [ ] Hero section is responsive on mobile and desktop
- [ ] CTA buttons navigate correctly
- [ ] Visually appealing and accessible (WCAG 2.1 AA)

---

### 4.2 Authentication (Popup)

**Access:** Public (triggered from Landing/Nav)

**Purpose:** Authenticate users via Google Sign-In using a popup dialog.

**UI:** Modal dialog with description and one primary action.

**Flow:**
- User clicks CTA on Landing or Nav → show modal → click "Sign in with Google"
- On success: check `users/{uid}` profile
  - If profile missing → route to `/create-profile`
  - Else → route to `/hub`

**Error Handling:**
- Show inline error text within modal when sign-in fails or is aborted
- Loading indicator during sign-in

**Acceptance Criteria:**
- [ ] Google Sign-In popup opens and completes
- [ ] Error states handled within modal
- [ ] Post-auth routing follows profile existence

---

### 4.3 Page: Create Guardian Profile

**Route:** `/create-profile`  
**Access:** Authenticated users (first-time only)

**Purpose:** Onboard new users and collect necessary profile information.

**Components:**

1. **Profile Setup Form**
   - Public Username (text input, unique validation)
   - Profile Picture (image upload component, max 5MB)
   - Contact Phone (optional, text input)
   - City (dropdown or text input)
   - Area (text input)
   - User Type (dropdown: Volunteer, Feeder, NGO Member, Citizen, Other)

2. **Form Actions**
   - "Save and Enter Mitran" button
   - Form validation indicators
   - Upload progress indicator for profile picture

**Business Logic:**

- **On Form Submission:**
  1. Validate all required fields
  2. Check username uniqueness in Firestore
  3. Upload profile picture to Firebase Storage
  4. Create user document in `users` collection
  5. Redirect to `/hub`

**Data Model Operations:**
```javascript
// Create user document
const userData = {
  userId: currentUser.uid,
  email: currentUser.email,
  username: formData.username,
  profilePictureUrl: uploadedImageUrl,
  contactInfo: {
    phone: formData.phone || "",
    email: currentUser.email
  },
  city: formData.city,
  area: formData.area,
  userType: formData.userType,
  postIds: [],
  dogIds: [],
  createdAt: FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp()
};
```

**Acceptance Criteria:**
- [ ] All required fields are validated before submission
- [ ] Username uniqueness is checked in real-time
- [ ] Profile picture uploads successfully to Firebase Storage
- [ ] User document is created in Firestore
- [ ] Successful submission redirects to Mitran Hub
- [ ] Error messages display for invalid inputs
- [ ] Profile picture preview shows before upload

---

### 4.4 Page: The Mitran Hub (Homepage)

**Route:** `/hub`  
**Access:** Authenticated users only

**Purpose:** Main dashboard and community interaction center.

**Components:**

1. **Persistent Navigation Bar** (Global component)
   - Logo (links to `/hub`)
   - "Mitran Hub" link → `/hub`
   - "Mitran Directory" link → `/directory`
   - "Mitran AI Care" link → `/ai-care`
   - User profile dropdown (top-right)
     - "My Profile" → `/profile`
     - "Logout" action

2. **Create Post Component**
   - Text area input (max 500 characters)
   - Character counter
   - "Post" button
   - Loading state during submission

3. **Community Feed**
   - Real-time list of all posts (ordered by timestamp, newest first)
   - Infinite scroll or pagination
   - Empty state message when no posts exist

4. **Post Item Component** (Repeatable)
   - User's profile picture
   - Username
   - Post content (text)
   - Timestamp (relative: "2 hours ago", "3 days ago")
   - Future: Comment/Reply functionality (out of scope for MVP)

**Business Logic:**

- **Create Post:**
  1. Validate content is not empty
  2. Create post document in `posts` collection
  3. Add `postId` to user's `postIds` array in `users` collection
  4. Display success feedback

- **Load Feed:**
  1. Query `posts` collection ordered by `timestamp` descending
  2. Listen for real-time updates
  3. Render posts in feed

**Data Model Operations:**

```javascript
// Create post
const postData = {
  postId: autoGeneratedId,
  content: postContent,
  author: {
    userId: currentUser.uid,
    username: currentUser.username,
    profilePictureUrl: currentUser.profilePictureUrl
  },
  timestamp: FieldValue.serverTimestamp(),
  createdAt: FieldValue.serverTimestamp()
};

// Update user's postIds
await updateDoc(userRef, {
  postIds: arrayUnion(postData.postId)
});
```

**Acceptance Criteria:**
- [ ] Navigation bar is visible and functional on all pages
- [ ] Create post component submits successfully
- [ ] New posts appear in feed in real-time
- [ ] Feed displays posts from all users
- [ ] Timestamps update dynamically
- [ ] Profile pictures load correctly
- [ ] Character limit is enforced on posts
- [ ] Loading states are shown during post creation
- [ ] Empty state displays when no posts exist

---

### 4.5 Page: Mitran Directory

**Route:** `/directory`  
**Access:** Authenticated users only

**Purpose:** Searchable, filterable gallery of all registered dogs.

**Components:**

1. **Search and Filter Bar**
   - Search input (placeholder: "Search by dog name or area")
   - Filter controls:
     - Vaccination Status (checkbox: Vaccinated)
     - Sterilization Status (checkbox: Sterilized)
     - Ready for Adoption (checkbox: Available for Adoption)
   - "Clear Filters" button

2. **Dog Record Grid**
   - Grid layout (responsive: 4 columns desktop, 2 columns tablet, 1 column mobile)
   - Each card shows:
     - Dog's main photo
     - Dog's name
     - Area/Location
     - Quick status icons (vaccination, sterilization, adoption)

3. **Dog Record Card Component** (Repeatable)
   - Clickable card → `/directory/{dogId}`
   - Image with loading placeholder
   - Dog name (bold)
   - Location text
   - Status badges

**Business Logic:**

- **Search Functionality:**
  - Client-side filter over streamed `dogs` collection
  - Case-insensitive search on `name` and `area`
  - Real-time filtering as user types (debounced optional)

- **Filter Functionality:**
  - Client-side filters applied to in-memory list
  - Multiple filters use AND logic
  - Results update dynamically

**Data Model Operations:**

```javascript
// Base query
let query = collection(db, 'dogs');

// Apply filters
if (searchTerm) {
  query = query.where('name', '>=', searchTerm)
               .where('name', '<=', searchTerm + '\uf8ff');
}

if (filters.vaccinated) {
  query = query.where('vaccinationStatus', '==', true);
}

if (filters.sterilized) {
  query = query.where('sterilizationStatus', '==', true);
}

if (filters.readyForAdoption) {
  query = query.where('readyForAdoption', '==', true);
}
```

**Acceptance Criteria:**
- [ ] Search works for dog names and areas
- [ ] Filters apply correctly (individually and combined)
- [ ] Grid is responsive on all screen sizes
- [ ] Dog cards navigate to correct detail pages
- [ ] Loading states show during data fetch
- [ ] Empty state displays when no dogs match criteria
- [ ] "Clear Filters" resets all filters and search
- [ ] Status icons display correctly based on dog data

---

### 4.6 Page: Mitran Record (Dog Detail)

**Route:** `/directory/{dogId}`  
**Access:** Authenticated users only

**Purpose:** Display comprehensive information for a specific dog.

**Components:**

1. **Dog Profile Header**
   - Dog's name (large, prominent)
   - Photo gallery (swipeable carousel)
   - Main photo with thumbnails

2. **Status Section**
   - Vaccination Status (badge: "Vaccinated" or "Not Vaccinated")
   - Sterilization Status (badge: "Sterilized" or "Not Sterilized")
   - Adoption Status (badge: "Available for Adoption" or not shown)

3. **Information Section**
   - Area/Location (with icon)
   - Temperament (with icon)
   - Health Notes (if available)
   - Added by (username with timestamp)

4. **Adoption Component** (Conditional)
   - Only shown if `readyForAdoption === true`
   - Button: "Interested in Adopting?"
   - On click: Reveals contact information in a modal
     - Contact person: `addedBy.username`
     - Email: `addedBy.contactInfo.email`
     - Phone: `addedBy.contactInfo.phone`

**Business Logic:**

- **Load Dog Data:**
  1. Fetch dog document from Firestore by `dogId`
  2. Display all information
  3. Handle case where dog doesn't exist (404 page)

- **Show Contact Information:**
  1. Verify `readyForAdoption` is true
  2. Display modal with contact details
  3. Provide copy-to-clipboard functionality

**Data Model Operations:**

```javascript
// Fetch dog data
const dogRef = doc(db, 'dogs', dogId);
const dogSnap = await getDoc(dogRef);

if (!dogSnap.exists()) {
  // Show 404 error
  navigate('/directory');
}

const dogData = dogSnap.data();
```

**Acceptance Criteria:**
- [ ] Dog profile loads correctly from URL parameter
- [ ] Photo gallery is functional and swipeable
- [ ] All status badges display correctly
- [ ] Information section shows all relevant data
- [ ] Adoption button only appears for adoptable dogs
- [ ] Contact modal displays correct information
- [ ] 404 handling works for invalid dog IDs
- [ ] Page is responsive on all devices
- [ ] Back navigation returns to directory with filters preserved

---

### 4.7 Page: Mitran AI Care

**Route:** `/ai-care`  
**Access:** Authenticated users only

**Purpose:** Centralized hub for AI tools implemented in the project.

**Navigation:**
- Option cards route to:
  - `/ai-care/chatbot` → AI Chatbot
  - `/ai-care/disease-scan` → Disease Scan

**AI Chatbot Page (`/ai-care/chatbot`):**
- Features:
  - Create/restore chat session (persisted in `localStorage`)
  - Message history fetched from API on restore
  - Send messages via `POST /v1/chat/send`
  - Optional SSE streaming via `GET /v1/chat/stream` (API-dependent)
  - Error banner with retry/resend when API unavailable
- Backend:
  - Base URL: `https://mitran-chatbot.onrender.com`
  - Health check gate before session creation
- Acceptance Criteria:
  - [ ] Health check passes before session creation
  - [ ] Session persists across refreshes
  - [ ] Messages send and replies render
  - [ ] Error banner shows on failure with retry

**Error Handling Policy (AI):**
- Chatbot:
  - Health check failure blocks session creation and shows error banner.
  - `404 Session not found` → clear local session and start new.
  - `429 Rate limit` → show error, allow resend.
- Disease Detection:
  - `400 Unsupported file type` → show validation error (PNG/JPEG only).
  - `503 Model not ready` → show wait banner and allow retry.
  - Network errors → fail gracefully and keep UI responsive.

**Disease Scan Page (`/ai-care/disease-scan`):**
- Features:
  - File picker (PNG/JPEG, size validated)
  - Health status banner when API boots
  - Analyze flow: upload → predict → save → display
  - Result card with label, confidence, details, disclaimer
  - History data available via service; UI exposure optional
- Backend:
  - Base URL: `https://mitran-disease-detection.onrender.com`
  - Upload to Firebase Storage; persist results to Firestore `predictions`
- Acceptance Criteria:
  - [ ] File selection and validation work
  - [ ] Prediction returned and displayed
  - [ ] Image URL saved; result stored in Firestore
  - [ ] Health banner shows when API is initializing

---

### 4.8 Page: My Guardian Profile

**Route:** `/profile`  
**Access:** Authenticated users only (viewing own profile)

**Purpose:** Allow users to manage their profile and view their activity.

**Components:**

1. **Profile Editor Section**
   - Editable fields:
     - Username (with uniqueness check)
     - Profile Picture (upload new image)
     - Contact Phone
     - City
     - Area
     - User Type
   - "Save Changes" button
   - "Cancel" button

2. **My Activity Section**
   - Tab 1: "My Posts"
     - Feed of user's own posts (filtered by `postIds`)
     - Same post component as main feed
     - Empty state: "You haven't posted anything yet"
   
   - Tab 2: "Dogs I've Added"
     - Grid of dog cards added by this user (filtered by `dogIds`)
     - Same card component as directory
     - Empty state: "You haven't added any dogs yet"

**Business Logic:**

- **Load Profile:**
  1. Fetch user document from Firestore
  2. Populate form fields with current data

- **Update Profile:**
  1. Validate all fields
  2. Check username uniqueness (if changed)
  3. Upload new profile picture to Firebase Storage (if changed)
  4. Update user document in Firestore
  5. Update denormalized data in posts (if username/picture changed)
  6. Show success message

- **Load Activity:**
  1. Query `posts` collection where `postId` in user's `postIds` array
  2. Query `dogs` collection where `dogId` in user's `dogIds` array

**Data Model Operations:**

```javascript
// Update profile
const updates = {
  username: newUsername,
  profilePictureUrl: newImageUrl,
  contactInfo: {
    phone: newPhone,
    email: currentUser.email
  },
  city: newCity,
  area: newArea,
  userType: newUserType,
  updatedAt: FieldValue.serverTimestamp()
};

await updateDoc(userRef, updates);

// Update denormalized data in posts
if (usernameChanged || profilePictureChanged) {
  const postsQuery = query(
    collection(db, 'posts'),
    where('author.userId', '==', currentUser.uid)
  );
  
  const postsSnapshot = await getDocs(postsQuery);
  
  const batch = writeBatch(db);
  postsSnapshot.forEach(doc => {
    batch.update(doc.ref, {
      'author.username': newUsername,
      'author.profilePictureUrl': newImageUrl
    });
  });
  
  await batch.commit();
}
```

**Acceptance Criteria:**
- [ ] Profile data loads correctly
- [ ] All fields are editable and validate properly
- [ ] Profile picture upload works correctly
- [ ] Changes save successfully to Firestore
- [ ] Denormalized data updates across collections
 - [ ] Denormalized data updates across collections (future enhancement)
- [ ] "My Posts" tab displays user's posts correctly
- [ ] "Dogs I've Added" tab displays user's dogs correctly
- [ ] Empty states display when no activity exists
- [ ] Success/error messages display appropriately
- [ ] Cancel button reverts unsaved changes

---

## 5. Non-Functional Requirements

### 5.1 Performance

- **Page Load Time:** All pages must load initial content within 2 seconds on standard broadband
- **Database Queries:** Optimize Firestore queries with proper indexing
- **Image Optimization:** Compress uploaded images to max 1MB
- **Caching:** Implement Firebase caching strategies for frequently accessed data

### 5.2 Security

- **Authentication:** All protected routes require Firebase Authentication
- **Authorization:** Users can only edit their own profile and posts
- **Data Validation:** Server-side validation for all user inputs
- **XSS Prevention:** Sanitize all user-generated content before display
- **Firebase Rules:** Implement proper Firestore security rules

**Example Firestore Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Posts collection
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.author.userId;
    }
    
    // Dogs collection
    match /dogs/{dogId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.addedBy.userId;
    }
  }
}
```

### 5.3 Accessibility

- **WCAG 2.1 AA Compliance:** Meet accessibility standards
- **Keyboard Navigation:** All interactive elements accessible via keyboard
- **Screen Reader Support:** Proper ARIA labels and semantic HTML
- **Color Contrast:** Minimum 4.5:1 contrast ratio for text

### 5.4 Responsive Design

- **Breakpoints:**
  - Mobile: 320px - 767px
  - Tablet: 768px - 1023px
  - Desktop: 1024px+
- **Touch Targets:** Minimum 44x44px for mobile interactions
- **Fluid Layouts:** Components adapt to screen size

### 5.5 Flutter-Specific UI Requirements

**CRITICAL: Preventing Overflow Errors**
- All text widgets MUST use `overflow: TextOverflow.ellipsis` or `overflow: TextOverflow.fade`
- All scrollable content MUST be wrapped in `SingleChildScrollView` or `ListView`
- All images MUST use `fit: BoxFit.cover` or `fit: BoxFit.contain`
- Column widgets with multiple children MUST be wrapped in `Expanded` or `Flexible` where needed
- Use `ConstrainedBox` or `SizedBox` to limit maximum dimensions
- Always use `SafeArea` widget to avoid notch/system UI overlaps
- Avoid hardcoded heights - use `Expanded`, `Flexible`, or media query percentages

**UI Simplicity Guidelines**
- Use Material Design 3 components (Material 3 theme)
- Minimal animations (only basic transitions)
- Clean white/light backgrounds with simple color accents
- Standard Flutter widgets (avoid complex custom painters)
- Simple card-based layouts
- Clear visual hierarchy with proper spacing (use `SizedBox` for gaps)
- Consistent padding: 16px default, 8px for compact areas
- Simple navigation: Bottom navigation bar OR drawer (not both)

### 5.5 Browser Support

- **Supported Browsers:**
  - Chrome (latest 2 versions)
  - Firefox (latest 2 versions)
  - Safari (latest 2 versions)
  - Edge (latest 2 versions)

---

## 6. User Stories

### Epic 1: User Onboarding

**US-1.1:** As a new visitor, I want to understand what Mitran is about so that I can decide if I want to join the community.

**US-1.2:** As a new user, I want to sign up with my Google account so that I can quickly create an account.

**US-1.3:** As a new user, I want to create my Guardian profile so that I can participate in the community.

### Epic 2: Community Engagement

**US-2.1:** As a Guardian, I want to post updates about stray dogs so that I can share information with the community.

**US-2.2:** As a Guardian, I want to see posts from other Guardians so that I can stay informed about community activities.

**US-2.3:** As a Guardian, I want to view my past posts so that I can track my contributions.

### Epic 3: Dog Directory

**US-3.1:** As a Guardian, I want to search for dogs by name or area so that I can find specific dogs.

**US-3.2:** As a Guardian, I want to filter dogs by vaccination and sterilization status so that I can find dogs that meet specific criteria.

**US-3.3:** As a Guardian, I want to view detailed information about a dog so that I can learn about its health and temperament.

**US-3.4:** As a potential adopter, I want to see contact information for adoptable dogs so that I can inquire about adoption.

### Epic 4: Profile Management

**US-4.1:** As a Guardian, I want to edit my profile information so that I can keep my details up to date.

**US-4.2:** As a Guardian, I want to view all dogs I've added so that I can manage my contributions.

---

## 7. Out of Scope (MVP)

The following features are **explicitly excluded** from the MVP:

1. **Web-Based Dog Creation:** Users cannot add new dogs or scan QR codes from the website. This functionality is reserved for the mobile app.

2. **Admin Panels:** No admin-level dashboards for NGOs or Municipal authorities to manage users or data.

3. **Live GPS Tracking:** The website will show a dog's "Area" (text field) but will not implement live GPS map tracking.

4. **Emergency Ticketing:** The emergency NGO reporting system is not part of the web MVP.

5. **Comment/Reply Functionality:** Social features like commenting on posts are deferred to future releases.

6. **Notifications:** In-app or email notifications for new posts, adoptions, etc.

7. **Analytics Dashboard:** User activity analytics or platform statistics.

8. **Multi-language Support:** MVP will be English-only.

9. **AI Feature Extensions:** Advanced AI features like multi-model selection, message analytics, and per-user personalized tuning are not included. Core Chatbot and Disease Scan integrations are implemented and in scope.

---

## 8. Success Metrics (KPIs)

### User Engagement
- **Daily Active Users (DAU):** Target 100+ users within first month
- **Post Creation Rate:** Average 5+ posts per day
- **Profile Completion Rate:** 80% of sign-ups complete profile creation

### Directory Usage
- **Dog Directory Views:** Target 500+ views per week
- **Search Usage:** 60% of users perform at least one search
- **Adoption Inquiries:** Track contact information reveals

### Technical Performance
- **Page Load Time:** 90% of pages load in under 2 seconds
- **Error Rate:** Less than 1% of requests result in errors
- **Uptime:** 99.5% platform availability

---

## 9. Release Plan

### Phase 1: Current Release
- Core pages (Landing, Auth, Create Profile, Hub, Directory, Dog Detail, Profile)
- Firebase initialization (`DefaultFirebaseOptions.currentPlatform`) and providers
- AI Care implemented (Chatbot + Disease Scan)
- Responsive UI and basic feed/directory flows

### Phase 2: Next Enhancements
- Comment/reply functionality on posts
- Notification system
- Advanced search and filtering
- Public user profiles

### Phase 3: Advanced Features
- Admin panels for NGOs and authorities
- Analytics dashboard
- Multi-language support
- Mobile app integration
- Emergency ticketing system

---

## 10. Risks and Mitigation

| Risk | Impact | Probability | Mitigation Strategy |
|------|--------|-------------|---------------------|
| Firebase quota limits exceeded | High | Medium | Implement pagination, caching, and monitor usage closely |
| Slow image loading | Medium | High | Compress images on upload, use Firebase CDN, implement lazy loading |
| Username conflicts | Medium | Low | Real-time uniqueness validation during profile creation |
| Denormalized data inconsistency | High | Medium | Use Cloud Functions or batch writes to maintain consistency |
| User adoption lower than expected | High | Medium | Marketing outreach, partnerships with NGOs, community engagement |

---

## 11. Dependencies

### Flutter Dependencies (pubspec.yaml baseline)

```yaml
environment:
  sdk: ^3.9.2

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  http_parser: ^4.0.2
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.0
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.1
  google_sign_in: ^6.2.1
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.1
  file_picker: ^8.1.3
  cached_network_image: ^3.3.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
```

### Internal Dependencies
- AI backend services reachable (Render: chatbot, disease detection)
- Firebase project configured (`lib/firebase_options.dart`)
- Design assets (logos, icons, images)

### External Dependencies
- Firebase services availability
- Flutter SDK (web and mobile)
- CDN for static assets

---

## 12. Approval and Sign-off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Product Owner | | | |
| Tech Lead | | | |
| Design Lead | | | |
| QA Lead | | | |

---

## Appendix A: Firebase Data Model Diagram

```
┌─────────────────────┐
│      users          │
├─────────────────────┤
│ userId (PK)         │
│ email               │
│ username (unique)   │
│ profilePictureUrl   │
│ contactInfo         │
│ city                │
│ area                │
│ userType            │
│ postIds[]           │───┐
│ dogIds[]            │───┼───┐
│ createdAt           │   │   │
│ updatedAt           │   │   │
└─────────────────────┘   │   │
                          │   │
                          │   │
┌─────────────────────┐   │   │
│      posts          │◄──┘   │
├─────────────────────┤       │
│ postId (PK)         │       │
│ content             │       │
│ author {            │       │
│   userId (FK)       │       │
│   username          │       │
│   profilePictureUrl │       │
│ }                   │       │
│ timestamp           │       │
│ createdAt           │       │
└─────────────────────┘       │
                              │
                              │
┌─────────────────────┐       │
│      dogs           │◄──────┘
├─────────────────────┤
│ dogId (PK)          │
│ name                │
│ photos[]            │
│ mainPhotoUrl        │
│ area                │
│ city                │
│ vaccinationStatus   │
│ sterilizationStatus │
│ readyForAdoption    │
│ temperament         │
│ healthNotes         │
│ addedBy {           │
│   userId (FK)       │
│   username          │
│   contactInfo       │
│ }                   │
│ createdAt           │
│ updatedAt           │
└─────────────────────┘
```

---

## Appendix D: Firebase & App Setup

- Initialize Firebase in Flutter:
  - `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);` (`lib/main.dart:10`)
- Configure Firebase options file: `lib/firebase_options.dart` generated via FlutterFire CLI.
- Web CORS and headers:
  - Ensure AI APIs include `Access-Control-Allow-Origin: *` and accept `GET, POST, OPTIONS` for web.
- Mobile considerations:
  - Replace `localStorage` with `shared_preferences` (or secure storage) for Chatbot session.
  - Reuse `ChatbotApi` and `DiseaseApi` service logic; consider platform adapters for SSE.
  - Reuse Firestore schemas for `users`, `dogs`, `posts`, and `predictions`.

## Appendix E: Build & Deploy

- Web:
  - `flutter analyze`
  - `flutter run -d chrome`
  - `flutter build web --release`
  - Hosting options: Firebase Hosting, Netlify, Vercel
- Mobile:
  - Android: `flutter build apk --release`
  - iOS: `flutter build ios --release`
  - Shared code: services, models, providers; platform gating for storage/streaming.

## Appendix B: State Management Architecture

**Riverpod Providers Structure:**

```dart
// Auth Provider
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// User Profile Provider
final userProfileProvider = StreamProvider.family<UserModel, String>((ref, userId) {
  return FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .snapshots()
    .map((doc) => UserModel.fromFirestore(doc));
});

// Posts Feed Provider
final postsProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
    .collection('posts')
    .orderBy('timestamp', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => PostModel.fromFirestore(doc))
      .toList());
});

// User's Posts Provider
final userPostsProvider = StreamProvider.family<List<PostModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
    .collection('posts')
    .where('author.userId', isEqualTo: userId)
    .orderBy('timestamp', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => PostModel.fromFirestore(doc))
      .toList());
});

// Dogs Directory Provider
final dogsProvider = StreamProvider<List<DogModel>>((ref) {
  return FirebaseFirestore.instance
    .collection('dogs')
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => DogModel.fromFirestore(doc))
      .toList());
});

// Filtered Dogs Provider
final filteredDogsProvider = Provider<List<DogModel>>((ref) {
  final dogs = ref.watch(dogsProvider).value ?? [];
  final filters = ref.watch(dogFiltersProvider);
  final searchTerm = ref.watch(searchTermProvider);
  
  return dogs.where((dog) {
    // Apply search filter
    if (searchTerm.isNotEmpty) {
      final matchesName = dog.name.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesArea = dog.area.toLowerCase().contains(searchTerm.toLowerCase());
      if (!matchesName && !matchesArea) return false;
    }
    
    // Apply status filters
    if (filters.vaccinated && !dog.vaccinationStatus) return false;
    if (filters.sterilized && !dog.sterilizationStatus) return false;
    if (filters.readyForAdoption && !dog.readyForAdoption) return false;
    
    return true;
  }).toList();
});

// Single Dog Provider
final dogProvider = StreamProvider.family<DogModel, String>((ref, dogId) {
  return FirebaseFirestore.instance
    .collection('dogs')
    .doc(dogId)
    .snapshots()
    .map((doc) => DogModel.fromFirestore(doc));
});

// User's Dogs Provider
final userDogsProvider = StreamProvider.family<List<DogModel>, String>((ref, userId) {
  return FirebaseFirestore.instance
    .collection('dogs')
    .where('addedBy.userId', isEqualTo: userId)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => DogModel.fromFirestore(doc))
      .toList());
});

// Filter State Provider
final dogFiltersProvider = StateProvider<DogFilters>((ref) {
  return DogFilters(
    vaccinated: false,
    sterilized: false,
    readyForAdoption: false,
  );
});

// Search Term Provider
final searchTermProvider = StateProvider<String>((ref) => '');
```

---

## Appendix C: Data Models (Dart Classes)

### UserModel

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String username;
  final String profilePictureUrl;
  final ContactInfo contactInfo;
  final String city;
  final String area;
  final String userType;
  final List<String> postIds;
  final List<String> dogIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.username,
    required this.profilePictureUrl,
    required this.contactInfo,
    required this.city,
    required this.area,
    required this.userType,
    required this.postIds,
    required this.dogIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      profilePictureUrl: data['profilePictureUrl'] ?? '',
      contactInfo: ContactInfo.fromMap(data['contactInfo'] ?? {}),
      city: data['city'] ?? '',
      area: data['area'] ?? '',
      userType: data['userType'] ?? '',
      postIds: List<String>.from(data['postIds'] ?? []),
      dogIds: List<String>.from(data['dogIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
      'contactInfo': contactInfo.toMap(),
      'city': city,
      'area': area,
      'userType': userType,
      'postIds': postIds,
      'dogIds': dogIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // CopyWith method for updates
  UserModel copyWith({
    String? email,
    String? username,
    String? profilePictureUrl,
    ContactInfo? contactInfo,
    String? city,
    String? area,
    String? userType,
    List<String>? postIds,
    List<String>? dogIds,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId,
      email: email ?? this.email,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      contactInfo: contactInfo ?? this.contactInfo,
      city: city ?? this.city,
      area: area ?? this.area,
      userType: userType ?? this.userType,
      postIds: postIds ?? this.postIds,
      dogIds: dogIds ?? this.dogIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class ContactInfo {
  final String phone;
  final String email;

  ContactInfo({
    required this.phone,
    required this.email,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
    };
  }
}
```

### PostModel

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String postId;
  final String content;
  final PostAuthor author;
  final DateTime timestamp;
  final DateTime createdAt;

  PostModel({
    required this.postId,
    required this.content,
    required this.author,
    required this.timestamp,
    required this.createdAt,
  });

  // Factory constructor from Firestore
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      postId: doc.id,
      content: data['content'] ?? '',
      author: PostAuthor.fromMap(data['author'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'author': author.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Get relative time string (e.g., "2 hours ago")
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class PostAuthor {
  final String userId;
  final String username;
  final String profilePictureUrl;

  PostAuthor({
    required this.userId,
    required this.username,
    required this.profilePictureUrl,
  });

  factory PostAuthor.fromMap(Map<String, dynamic> map) {
    return PostAuthor(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}
```

### DogModel

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DogModel {
  final String dogId;
  final String name;
  final List<String> photos;
  final String mainPhotoUrl;
  final String area;
  final String city;
  final bool vaccinationStatus;
  final bool sterilizationStatus;
  final bool readyForAdoption;
  final String temperament;
  final String healthNotes;
  final DogAddedBy addedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  DogModel({
    required this.dogId,
    required this.name,
    required this.photos,
    required this.mainPhotoUrl,
    required this.area,
    required this.city,
    required this.vaccinationStatus,
    required this.sterilizationStatus,
    required this.readyForAdoption,
    required this.temperament,
    required this.healthNotes,
    required this.addedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from Firestore
  factory DogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DogModel(
      dogId: doc.id,
      name: data['name'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      mainPhotoUrl: data['mainPhotoUrl'] ?? '',
      area: data['area'] ?? '',
      city: data['city'] ?? '',
      vaccinationStatus: data['vaccinationStatus'] ?? false,
      sterilizationStatus: data['sterilizationStatus'] ?? false,
      readyForAdoption: data['readyForAdoption'] ?? false,
      temperament: data['temperament'] ?? '',
      healthNotes: data['healthNotes'] ?? '',
      addedBy: DogAddedBy.fromMap(data['addedBy'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photos': photos,
      'mainPhotoUrl': mainPhotoUrl,
      'area': area,
      'city': city,
      'vaccinationStatus': vaccinationStatus,
      'sterilizationStatus': sterilizationStatus,
      'readyForAdoption': readyForAdoption,
      'temperament': temperament,
      'healthNotes': healthNotes,
      'addedBy': addedBy.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // CopyWith method for updates
  DogModel copyWith({
    String? name,
    List<String>? photos,
    String? mainPhotoUrl,
    String? area,
    String? city,
    bool? vaccinationStatus,
    bool? sterilizationStatus,
    bool? readyForAdoption,
    String? temperament,
    String? healthNotes,
    DateTime? updatedAt,
  }) {
    return DogModel(
      dogId: dogId,
      name: name ?? this.name,
      photos: photos ?? this.photos,
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
      area: area ?? this.area,
      city: city ?? this.city,
      vaccinationStatus: vaccinationStatus ?? this.vaccinationStatus,
      sterilizationStatus: sterilizationStatus ?? this.sterilizationStatus,
      readyForAdoption: readyForAdoption ?? this.readyForAdoption,
      temperament: temperament ?? this.temperament,
      healthNotes: healthNotes ?? this.healthNotes,
      addedBy: addedBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class DogAddedBy {
  final String userId;
  final String username;
  final ContactInfo contactInfo;

  DogAddedBy({
    required this.userId,
    required this.username,
    required this.contactInfo,
  });

  factory DogAddedBy.fromMap(Map<String, dynamic> map) {
    return DogAddedBy(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      contactInfo: ContactInfo.fromMap(map['contactInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'contactInfo': contactInfo.toMap(),
    };
  }
}

// Reuse ContactInfo class from UserModel
```

### DogFilters

```dart
class DogFilters {
  final bool vaccinated;
  final bool sterilized;
  final bool readyForAdoption;

  DogFilters({
    required this.vaccinated,
    required this.sterilized,
    required this.readyForAdoption,
  });

  DogFilters copyWith({
    bool? vaccinated,
    bool? sterilized,
    bool? readyForAdoption,
  }) {
    return DogFilters(
      vaccinated: vaccinated ?? this.vaccinated,
      sterilized: sterilized ?? this.sterilized,
      readyForAdoption: readyForAdoption ?? this.readyForAdoption,
    );
  }

  bool get hasActiveFilters =>
      vaccinated || sterilized || readyForAdoption;
}
```

---

## Appendix D: Key Service Classes

### AuthService

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
```

### FirestoreService

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ========== USER OPERATIONS ==========

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.userId).set(user.toMap());
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(userId).update(updates);
  }

  // Check username uniqueness
  Future<bool> isUsernameAvailable(String username) async {
    final query = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  // ========== POST OPERATIONS ==========

  // Create post
  Future<String> createPost(PostModel post, String userId) async {
    // Add post to posts collection
    final postRef = await _db.collection('posts').add(post.toMap());
    
    // Add postId to user's postIds array
    await _db.collection('users').doc(userId).update({
      'postIds': FieldValue.arrayUnion([postRef.id]),
    });
    
    return postRef.id;
  }

  // Delete post
  Future<void> deletePost(String postId, String userId) async {
    // Remove from posts collection
    await _db.collection('posts').doc(postId).delete();
    
    // Remove from user's postIds array
    await _db.collection('users').doc(userId).update({
      'postIds': FieldValue.arrayRemove([postId]),
    });
  }

  // ========== DOG OPERATIONS ==========

  // Create dog record
  Future<String> createDogRecord(DogModel dog, String userId) async {
    // Add dog to dogs collection
    final dogRef = await _db.collection('dogs').add(dog.toMap());
    
    // Add dogId to user's dogIds array
    await _db.collection('users').doc(userId).update({
      'dogIds': FieldValue.arrayUnion([dogRef.id]),
    });
    
    return dogRef.id;
  }

  // Update dog record
  Future<void> updateDogRecord(String dogId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('dogs').doc(dogId).update(updates);
  }

  // Delete dog record
  Future<void> deleteDogRecord(String dogId, String userId) async {
    // Get dog data to delete photos from storage
    final dogDoc = await _db.collection('dogs').doc(dogId).get();
    final dog = DogModel.fromFirestore(dogDoc);
    
    // Delete photos from storage
    for (String photoUrl in dog.photos) {
      await _deleteImageFromUrl(photoUrl);
    }
    
    // Remove from dogs collection
    await _db.collection('dogs').doc(dogId).delete();
    
    // Remove from user's dogIds array
    await _db.collection('users').doc(userId).update({
      'dogIds': FieldValue.arrayRemove([dogId]),
    });
  }

  // ========== IMAGE OPERATIONS ==========

  // Upload profile picture
  Future<String> uploadProfilePicture(File imageFile, String userId) async {
    final ref = _storage.ref().child('profile_pictures/$userId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Upload dog photo
  Future<String> uploadDogPhoto(File imageFile, String dogId, int index) async {
    final ref = _storage.ref().child('dog_photos/$dogId/photo_$index.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Delete image from storage by URL
  Future<void> _deleteImageFromUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Handle error silently (image might not exist)
    }
  }

  // ========== BATCH OPERATIONS ==========

  // Update denormalized user data in posts
  Future<void> updateUserDataInPosts(
    String userId,
    String newUsername,
    String newProfilePictureUrl,
  ) async {
    final batch = _db.batch();
    
    // Query all posts by this user
    final postsQuery = await _db
        .collection('posts')
        .where('author.userId', isEqualTo: userId)
        .get();
    
    // Update each post
    for (var doc in postsQuery.docs) {
      batch.update(doc.reference, {
        'author.username': newUsername,
        'author.profilePictureUrl': newProfilePictureUrl,
      });
    }
    
    await batch.commit();
  }
}
```

---

## Appendix E: Validation Rules

### Username Validation
- **Length:** 3-20 characters
- **Allowed characters:** Alphanumeric, underscores, hyphens
- **Uniqueness:** Must be unique across all users
- **Case sensitivity:** Case-insensitive comparison

### Password Validation
- **Minimum length:** 8 characters
- **Must contain:** At least one uppercase letter, one lowercase letter, one number
- **Not allowed:** Common passwords, user's email

### Email Validation
- Standard email format validation
- Must be verified via Firebase Authentication

### Image Upload Validation
- **File types:** JPG, JPEG, PNG
- **Maximum size:** 5MB for profile pictures, 10MB for dog photos
- **Dimensions:** No restrictions, but images will be compressed

### Post Content Validation
- **Maximum length:** 500 characters
- **Not allowed:** Empty posts, only whitespace
- **XSS prevention:** All HTML tags are stripped or escaped

### Dog Name Validation
- **Length:** 2-30 characters
- **Allowed characters:** Letters, numbers, spaces, hyphens

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Nov 2025 | Product Team | Initial PRD creation |

---

**END OF DOCUMENT**
