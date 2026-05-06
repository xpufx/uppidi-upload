# Uppidi Upload — Architecture

## State Machine

```mermaid
stateDiagram-v2
  [*] --> Idle
  Idle --> FileSelected: pick file
  FileSelected --> InProgress: tap Upload
  FileSelected --> Idle: clear / swipe
  InProgress --> Completed: success
  InProgress --> Completed: failure
  InProgress --> Idle: cancel
  Completed --> FileSelected: retry (change provider)
  Completed --> Idle: clear
  FileSelected --> FileSelected: change provider (preserves preview)
```

## Navigation

```mermaid
flowchart LR
  Upload --> History
  Upload --> Providers
  Upload --> Settings
  History --> Upload
  Providers --> Upload
  Settings --> Upload
```

## Upload Lifecycle

```mermaid
flowchart TD
  A[User taps Pick] --> B{File picker}
  B -- cancel --> A
  B -- file selected --> C[Show preview]
  C --> D{Quality selector}
  D -- Original --> E[Create request from file]
  D -- Medium 50% --> F[Resize image]
  D -- Low 25% --> F
  F --> E
  E --> G[Tap Upload]
  G --> H{Provider check}
  H -- health broken --> I[Show warning + disable switch]
  H -- ok --> J[Execute upload]
  J --> K{Result}
  K -- success --> L[Show URL + copy/share]
  K -- failure --> M[Show error + retry/cancel]
  L --> N[Change provider?]
  N -- yes --> C
  N -- no --> O[Done]
  M --> P[Clear]
  P --> A
  M --> C
```

## Provider Plugin Interface

```mermaid
classDiagram
  class BaseUploader {
    <<abstract>>
    +String providerId
    +String providerName
    +bool supportsWeb
    +ProviderMetadata metadata
    +Future~Dio~ createHttpClient(config)
    +Future~UploadResult~ upload(request)
  }

  class HttpBinProvider {
    +parseResponse()
  }
  class CatboxProvider {
    +parseResponse()
  }
  class UguuProvider {
    +parseResponse()
  }
  class TempShProvider {
    +parseResponse()
  }
  class FreeImageHostProvider {
    +parseResponse()
  }
  class TmpFileLinkProvider {
    +parseResponse()
  }

  BaseUploader <|-- HttpBinProvider
  BaseUploader <|-- CatboxProvider
  BaseUploader <|-- UguuProvider
  BaseUploader <|-- TempShProvider
  BaseUploader <|-- FreeImageHostProvider
  BaseUploader <|-- TmpFileLinkProvider
```

## Data Flow

```mermaid
flowchart LR
  subgraph Storage
    Hive[(Hive)]
    Secure[(Secure Storage)]
  end

  subgraph Network
    CDN[CDN - builds + providers.json]
    Hosts[Upload Hosts]
  end

  subgraph State
    Provider[Riverpod Providers]
    StateMachine[UploadState sealed class]
  end

  UI <--> Provider
  Provider --> StateMachine
  Provider <--> Storage
  Provider <--> Network
```

## Error Recovery

```mermaid
flowchart TD
  E[Upload fails] --> F{Error type}
  F -- DioException --> G{Has status code?}
  G -- yes --> H[Show status code + error modal]
  G -- no --> I[Show raw error + stack trace]
  F -- FormatException --> J[Show parse error]
  F -- FileSystemException --> K[File closed - recreate stream]
  K --> L[_lastFilePath used to recreate request]
  L --> M[Retry]
  H --> M
  I --> M
  J --> M
  M --> N[Retry same provider]
  M --> O[Change provider + retry]
  M --> P[Clear + pick new file]
```

## Key Files

| File | Role |
|------|------|
| `lib/providers/upload_provider.dart` | State machine + upload logic |
| `lib/screens/upload_screen.dart` | Main upload UI |
| `lib/core/interfaces/base_http_provider.dart` | HTTP upload base class |
| `lib/core/interfaces/uploader.dart` | Provider plugin interface |
| `lib/core/models/` | Data models (Request, Result, Record) |
| `lib/core/settings_service.dart` | Persisted settings + health manifest |
| `lib/providers/*_provider.dart` | Plugin implementations |
