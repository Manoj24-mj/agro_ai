# System Architecture Diagram: Adaptive Edge-AI Agricultural DSS

Below is the visual architecture representing the flow of diagnostic data, advisory delivery, and continuous closed-loop feedback in the proposed system:

```mermaid
graph TD
    %% Define styles for different subgraphs
    classDef client fill:#e1f5fe,stroke:#0288d1,stroke-width:2px;
    classDef network fill:#efebe9,stroke:#5d4037,stroke-width:2px;
    classDef backend fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px;
    classDef feedback fill:#fff3e0,stroke:#ef6c00,stroke-width:2px;

    %% Client Layer (Edge Device)
    subgraph Client ["Farmer's Edge Device (Offline-First Android App)"]
        A["Leaf Image Capture"] --> B["MobileNetV2 TFLite Engine (9.5MB)"]
        B --> C["Offline Diagnosis Generated"]
        C --> D["Local DB & SMS Queue Manager"]
    end
    class Client client;

    %% Communication Bridge
    subgraph Network ["Low-Bandwidth Communication Bridge"]
        D -->| "SMS / WhatsApp Payload" | E["Cloud SMS/WhatsApp Gateway"]
    end
    class Network network;

    %% Backend Advisory Server
    subgraph Backend ["Cloud Backend & Advisory Server"]
        E --> F["Dynamic Decision Support Engine"]
        G[("Localized Weather & Soil Database")] --> F
        F --> H["Personalized Advisory Generator"]
        H -->| "Advisory Response" | E
        E -->| "SMS/WhatsApp Delivery" | D
    end
    class Backend backend;

    %% Closed-Loop Feedback Pipeline
    subgraph Feedback ["Closed-Loop NLP Telemetry Pipeline"]
        D -->| "User Comments & Rating" | E
        E --> I["NLP Sentiment & Topic Analyzer"]
        I --> J{"System Output Correct?"}
        J -->| "No - Advisory Error" | K["Decision Engine Weight Adjuster"]
        J -->| "No - Misdiagnosis" | L[("Retraining Image Dataset")]
        K --> F
    end
    class Feedback feedback;
```

### Flow Description:
1. **Edge Diagnosis (Offline):** The farmer captures an image of a diseased leaf. The local **MobileNetV2 TFLite Engine (9.5MB)** classifies the disease offline, bypassing the need for an active internet connection.
2. **Data Transmission:** The offline diagnosis and essential metadata (such as location/soil type input) are queued and sent via the **SMS / WhatsApp Gateway** to the backend.
3. **Advisory Generation:** The backend **Dynamic Decision Support Engine** combines the diagnosis with localized soil database variables and real-time weather forecasts to compute a fertilizer or water recommendation, which is sent back to the farmer via SMS or WhatsApp.
4. **NLP Feedback Loop (Closed-Loop):** The farmer submits reviews or text comments about the advisory's field effectiveness. The **NLP Sentiment & Topic Analyzer** parses the comments. If a calculation error or misdiagnosis is detected, weights are adjusted in the Decision Engine or the original leaf image is queued into the **Retraining Dataset** to improve future model updates.
