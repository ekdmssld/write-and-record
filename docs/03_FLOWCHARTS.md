# Write & Record iOS App - Flow Charts

아래 Mermaid는 구현 AI에게 그대로 전달 가능.

## 1. App Launch/Auth/Onboarding

```mermaid
flowchart TD
  A["App Launch"] --> B{"Has valid session?"}
  B -- No --> C["AuthView"]
  C --> D{"Login success?"}
  D -- No --> C
  D -- Yes --> E{"Onboarding completed?"}
  B -- Yes --> E
  E -- No --> F["Nickname"]
  F --> G["Profile Photo"]
  G --> H["Theme + Space Name"]
  H --> I["Intro + Social Settings"]
  I --> J["Save UserProfile"]
  J --> K["LibraryHome"]
  E -- Yes --> K
```

## 2. Create Entry From Calendar

```mermaid
flowchart TD
  A["LibraryHome Calendar"] --> B["User selects date"]
  B --> C["Selected date sheet"]
  C --> D["Tap Add Record"]
  D --> E["CategoryPicker"]
  E --> F{"Use default category?"}
  F -- Yes --> G["Select main/sub category"]
  F -- No --> H["Create custom category"]
  H --> G
  G --> I["EntryEditor with date/category"]
  I --> J{"Add photos?"}
  J -- Yes --> K["DatePhotoPicker"]
  K --> L["Select date photos or all photos"]
  L --> I
  J -- No --> M["Fill title/body/fields"]
  I --> M
  M --> N{"Valid required fields?"}
  N -- No --> I
  N -- Yes --> O["Save Entry"]
  O --> P{"Save success?"}
  P -- No --> Q["Keep draft + show retry"]
  Q --> I
  P -- Yes --> R["EntryDetail"]
  R --> S{"Make record card?"}
  S -- Yes --> T["RecordCardPicker"]
  S -- No --> U["Back to Library"]
```

## 3. Photo Permission/Picker

```mermaid
flowchart TD
  A["Open DatePhotoPicker"] --> B{"Photo permission status"}
  B -- Authorized --> C["Load date photos"]
  B -- Limited --> D["Load limited photos + show manage access"]
  B -- NotDetermined --> E["Request permission"]
  E --> B
  B -- Denied --> F["Show permission empty state"]
  F --> G["Continue without photos"]
  C --> H{"Date photos exist?"}
  D --> H
  H -- Yes --> I["Show This Date grid"]
  H -- No --> J["Show empty date state"]
  J --> K["User switches to All"]
  I --> L["Select photos"]
  K --> L
  L --> M["Return selected MediaAsset refs"]
```

## 4. Entry Save State

```mermaid
stateDiagram-v2
  [*] --> Editing
  Editing --> DraftSaved: autosave
  DraftSaved --> Editing: user changes
  Editing --> Validating: tap save
  Validating --> Editing: invalid fields
  Validating --> Saving: valid
  Saving --> Saved: persistence success
  Saving --> SaveFailed: persistence error
  SaveFailed --> Editing: retry or edit
  Saved --> [*]
```

## 5. Library View Switch

```mermaid
flowchart LR
  A["LibraryHome"] --> B["Calendar"]
  A --> C["Timeline"]
  A --> D["Gallery"]
  A --> E["Places"]
  A --> F["Collections"]
  B --> G["Entry list by selected date"]
  C --> H["Entry list by time"]
  D --> I["Media grid"]
  E --> J["Place list/map"]
  F --> K["Manual + smart collections"]
  G --> L["EntryDetail"]
  H --> L
  I --> L
  J --> L
  K --> L
```

## 6. Record Card Creation

```mermaid
flowchart TD
  A["EntryDetail"] --> B["Tap Make Card"]
  B --> C["RecordCardPicker"]
  C --> D["Select template"]
  D --> E["Render preview"]
  E --> F{"User action"}
  F -- Change template --> C
  F -- Save image --> G["Export PNG to Photos/app storage"]
  F -- Share --> H["Open iOS share sheet"]
  G --> I["Create RecordCard row"]
  H --> I
  I --> J["Return to EntryDetail"]
```

## 7. Data Relationship

```mermaid
erDiagram
  UserProfile ||--o{ Entry : owns
  UserProfile ||--o{ Category : creates
  UserProfile ||--o{ Collection : owns
  Entry }o--|| Category : uses
  Entry }o--o{ MediaAsset : attaches
  Entry }o--o{ Collection : belongs_to
  Entry ||--o{ RecordCard : renders
  Entry }o--o| PlaceRef : has
```

