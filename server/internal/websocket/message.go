package websocket

import (
	"encoding/json"

	"github.com/godeck/godeck-server/internal/input"
)

// Message represents the WebSocket json event envelope.
type Message struct {
	EventType string          `json:"event_type"`
	ClientID  string          `json:"client_id,omitempty"`
	Timestamp int64           `json:"timestamp"`
	Payload   json.RawMessage `json:"payload,omitempty"`
}

// ActionPayload defines payload for client actions.
type ActionPayload struct {
	Type      string   `json:"type"`                // key_combination, key_tap, text_input, trackpad_move, trackpad_click, trackpad_scroll, system_command
	Key       string   `json:"key,omitempty"`       // c, p, enter, media_play_pause, volume_up
	Modifiers []string `json:"modifiers,omitempty"` // cmd, ctrl, alt, shift
	Text      string   `json:"text,omitempty"`
	Dx        float64  `json:"dx,omitempty"`
	Dy        float64  `json:"dy,omitempty"`
	Button    string   `json:"button,omitempty"`  // left, right, middle
	Command   string   `json:"command,omitempty"` // shell command
	Label     string   `json:"label,omitempty"`
}

// AckPayload is returned to client as acknowledgment.
type AckPayload struct {
	Status      string  `json:"status"` // success, error
	Message     string  `json:"message,omitempty"`
	ExecutionMS float64 `json:"execution_ms"`
}

// PongPayload returns timestamp for RTT calculation.
type PongPayload struct {
	ClientTimestamp int64 `json:"client_timestamp"`
	ServerTime      int64 `json:"server_time"`
}

// DeckItem represents a macro button item in layout.
type DeckItem struct {
	ID     string        `json:"id"`
	Title  string        `json:"title"`
	Icon   string        `json:"icon"`
	Color  string        `json:"color"`
	Action ActionPayload `json:"action"`
}

// DeckPage represents a page grid layout.
type DeckPage struct {
	ID      string     `json:"id"`
	Title   string     `json:"title"`
	Columns int        `json:"columns"`
	Items   []DeckItem `json:"items"`
}

// LayoutPayload contains deck configuration.
type LayoutPayload struct {
	Pages []DeckPage `json:"pages"`
}

// LaunchAppPayload defines payload to open an installed desktop application.
type LaunchAppPayload struct {
	Name string `json:"name"`
	Path string `json:"path"`
}

// AppsListPayload contains list of installed applications on the host PC.
type AppsListPayload struct {
	Apps []input.DesktopApp `json:"apps"`
}
