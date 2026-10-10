# GoDeck WebSocket Protocol Specification (v1.0)

This document defines the formal JSON protocol used over WebSocket for communication between the **GoDeck Mobile Client** (Flutter) and the **GoDeck Host Server** (Go).

---

## 1. Connection Overview

- **Protocol**: Standard WebSocket (`ws://` or `wss://`)
- **Default Port**: `8080`
- **Default Endpoint**: `ws://<HOST_IP>:8080/ws`
- **Encoding**: UTF-8 JSON

---

## 2. Message Envelope Format

All messages exchanged over the WebSocket channel wrap their payload in a common envelope structure:

```json
{
  "event_type": "STRING",
  "client_id": "STRING (optional)",
  "timestamp": 1710000000000,
  "payload": {}
}
```

---

## 3. Client -> Server Messages

### 3.1 Ping (`ping`)
Sent periodically by the client to maintain connection alive and calculate latency RTT.

```json
{
  "event_type": "ping",
  "timestamp": 1710000000100,
  "payload": {}
}
```

### 3.2 Action (`action`)
Requests execution of a macro, shortcut, key tap, trackpad movement, or system command.

#### Key Combination Action:
```json
{
  "event_type": "action",
  "timestamp": 1710000000200,
  "payload": {
    "type": "key_combination",
    "key": "c",
    "modifiers": ["cmd"],
    "label": "Copy"
  }
}
```

#### Key Tap Action (Single special key):
```json
{
  "event_type": "action",
  "timestamp": 1710000000300,
  "payload": {
    "type": "key_tap",
    "key": "media_play_pause",
    "label": "Play/Pause"
  }
}
```

#### Text Input Action:
```json
{
  "event_type": "action",
  "timestamp": 1710000000400,
  "payload": {
    "type": "text_input",
    "text": "Hello World from GoDeck!"
  }
}
```

#### Trackpad Move Action (Relative Delta):
```json
{
  "event_type": "action",
  "timestamp": 1710000000500,
  "payload": {
    "type": "trackpad_move",
    "dx": 12.5,
    "dy": -4.2
  }
}
```

#### Trackpad Click Action:
```json
{
  "event_type": "action",
  "timestamp": 1710000000600,
  "payload": {
    "type": "trackpad_click",
    "button": "left"
  }
}
```

#### Trackpad Scroll Action:
```json
{
  "event_type": "action",
  "timestamp": 1710000000700,
  "payload": {
    "type": "trackpad_scroll",
    "dx": 0.0,
    "dy": -3.0
  }
}
```

#### System Command Action:
```json
{
  "event_type": "action",
  "timestamp": 1710000000800,
  "payload": {
    "type": "system_command",
    "command": "open -a Calculator"
  }
}
```

### 3.3 Request Layout (`request_layout`)
Requests the server to return the current deck page items/layout.

```json
{
  "event_type": "request_layout",
  "timestamp": 1710000000900,
  "payload": {}
}
```

### 3.4 Save Layout (`save_layout`)
Saves updated shortcut buttons and pages configuration to the host server.

```json
{
  "event_type": "save_layout",
  "timestamp": 1710000000950,
  "payload": {
    "pages": [
      {
        "id": "page_media_dev",
        "title": "Desenvolvimento & Mídia",
        "columns": 3,
        "items": [
          {
            "id": "btn_copy",
            "title": "Copiar",
            "icon": "copy",
            "color": "#00E5FF",
            "action": {
              "type": "key_combination",
              "key": "c",
              "modifiers": ["cmd"],
              "label": "Copy"
            }
          }
        ]
      }
    ]
  }
}
```

---

## 4. Server -> Client Messages

### 4.1 Pong (`pong`)
Returned immediately upon receiving a `ping`. Includes client timestamp to calculate ping latency.

```json
{
  "event_type": "pong",
  "timestamp": 1710000000105,
  "payload": {
    "client_timestamp": 1710000000100,
    "server_time": 1710000000103
  }
}
```

### 4.2 Action Acknowledgement (`ack`)
Returned after processing an action request.

```json
{
  "event_type": "ack",
  "timestamp": 1710000000210,
  "payload": {
    "status": "success",
    "message": "Key combination executed",
    "execution_ms": 1.2
  }
}
```

### 4.3 Layout Update (`layout_update`)
Pushes current deck configuration and layout grid.

```json
{
  "event_type": "layout_update",
  "timestamp": 1710000000950,
  "payload": {
    "pages": [
      {
        "id": "page_1",
        "title": "Main Deck",
        "columns": 3,
        "items": [
          {
            "id": "btn_copy",
            "title": "Copiar",
            "icon": "copy",
            "color": "#00E5FF",
            "action": {
              "type": "key_combination",
              "key": "c",
              "modifiers": ["cmd"]
            }
          }
        ]
      }
    ]
  }
}
```

---

## 5. Error Handling

When an unhandled error occurs, the server responds with an `error` event:

```json
{
  "event_type": "error",
  "timestamp": 1710000001000,
  "payload": {
    "code": "INVALID_ACTION",
    "message": "Action type unknown or missing required fields"
  }
}
```
