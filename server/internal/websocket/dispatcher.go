package websocket

import (
	"encoding/json"
	"log"
	"time"

	"github.com/godeck/godeck-server/internal/config"
	"github.com/godeck/godeck-server/internal/input"
)

// EventDispatcher routes raw JSON websocket messages to input automation handlers.
type EventDispatcher struct {
	emulator      input.InputEmulator
	shortcutStore *config.ShortcutStore
	hub           *Hub
	verbose       bool
}

// NewEventDispatcher creates a new EventDispatcher.
func NewEventDispatcher(emulator input.InputEmulator, shortcutStore *config.ShortcutStore, hub *Hub, verbose bool) *EventDispatcher {
	return &EventDispatcher{
		emulator:      emulator,
		shortcutStore: shortcutStore,
		hub:           hub,
		verbose:       verbose,
	}
}

// Dispatch parses and handles incoming client messages.
func (d *EventDispatcher) Dispatch(client *Client, rawMsg []byte) {
	start := time.Now()

	var msg Message
	if err := json.Unmarshal(rawMsg, &msg); err != nil {
		log.Printf("[Dispatcher] Failed to unmarshal message: %v", err)
		d.sendError(client, "INVALID_JSON", "Malformed JSON message")
		return
	}

	if d.verbose {
		log.Printf("[Dispatcher] Event: %s, Client: %s", msg.EventType, client.ID)
	}

	switch msg.EventType {
	case "ping":
		d.handlePing(client, msg.Timestamp)

	case "action":
		d.handleAction(client, msg.Payload, start)

	case "request_layout":
		d.handleRequestLayout(client)

	case "save_layout":
		d.handleSaveLayout(client, msg.Payload)

	default:
		d.sendError(client, "UNKNOWN_EVENT", "Event type not supported: "+msg.EventType)
	}
}

func (d *EventDispatcher) handlePing(client *Client, clientTimestamp int64) {
	pong := Message{
		EventType: "pong",
		Timestamp: time.Now().UnixMilli(),
	}
	payload := PongPayload{
		ClientTimestamp: clientTimestamp,
		ServerTime:      time.Now().UnixMilli(),
	}
	payloadBytes, _ := json.Marshal(payload)
	pong.Payload = payloadBytes

	msgBytes, _ := json.Marshal(pong)
	client.Send <- msgBytes
}

func (d *EventDispatcher) handleAction(client *Client, rawPayload json.RawMessage, startTime time.Time) {
	var action ActionPayload
	if err := json.Unmarshal(rawPayload, &action); err != nil {
		d.sendError(client, "INVALID_ACTION_PAYLOAD", "Cannot parse action payload")
		return
	}

	var execErr error

	switch action.Type {
	case "key_combination", "key_tap":
		execErr = d.emulator.TapKey(action.Key, action.Modifiers)

	case "text_input":
		execErr = d.emulator.TypeText(action.Text)

	case "trackpad_move":
		execErr = d.emulator.MoveMouseRelative(action.Dx, action.Dy)

	case "trackpad_click":
		execErr = d.emulator.MouseClick(action.Button)

	case "trackpad_scroll":
		execErr = d.emulator.MouseScroll(action.Dx, action.Dy)

	case "system_command":
		_, execErr = d.emulator.ExecuteCommand(action.Command)

	default:
		d.sendError(client, "UNKNOWN_ACTION_TYPE", "Action type not supported: "+action.Type)
		return
	}

	elapsed := float64(time.Since(startTime).Microseconds()) / 1000.0

	status := "success"
	errMsg := ""
	if execErr != nil {
		status = "error"
		errMsg = execErr.Error()
	}

	ack := Message{
		EventType: "ack",
		Timestamp: time.Now().UnixMilli(),
	}
	ackPayload := AckPayload{
		Status:      status,
		Message:     errMsg,
		ExecutionMS: elapsed,
	}
	ackPayloadBytes, _ := json.Marshal(ackPayload)
	ack.Payload = ackPayloadBytes

	msgBytes, _ := json.Marshal(ack)
	client.Send <- msgBytes
}

func (d *EventDispatcher) handleRequestLayout(client *Client) {
	var layout LayoutPayload
	if err := d.shortcutStore.Load(&layout); err != nil {
		log.Printf("[Dispatcher] Failed to load shortcuts layout: %v", err)
	}

	layoutBytes, _ := json.Marshal(layout)
	msg := Message{
		EventType: "layout_update",
		Timestamp: time.Now().UnixMilli(),
		Payload:   layoutBytes,
	}

	msgBytes, _ := json.Marshal(msg)
	client.Send <- msgBytes
}

func (d *EventDispatcher) handleSaveLayout(client *Client, rawPayload json.RawMessage) {
	var layout LayoutPayload
	if err := json.Unmarshal(rawPayload, &layout); err != nil {
		d.sendError(client, "INVALID_LAYOUT_PAYLOAD", "Cannot parse layout configuration")
		return
	}

	if err := d.shortcutStore.Save(layout); err != nil {
		log.Printf("[Dispatcher] Failed to save shortcuts layout: %v", err)
		d.sendError(client, "SAVE_FAILED", "Failed to persist shortcut configuration")
		return
	}

	layoutBytes, _ := json.Marshal(layout)
	msg := Message{
		EventType: "layout_update",
		Timestamp: time.Now().UnixMilli(),
		Payload:   layoutBytes,
	}

	msgBytes, _ := json.Marshal(msg)

	// Broadcast updated layout to all connected clients
	if d.hub != nil {
		d.hub.BroadcastMessage(msgBytes)
	} else {
		client.Send <- msgBytes
	}

	// Send success ACK
	ack := Message{
		EventType: "ack",
		Timestamp: time.Now().UnixMilli(),
	}
	ackPayload := AckPayload{
		Status:      "success",
		Message:     "Shortcut layout configuration updated and saved",
		ExecutionMS: 0.0,
	}
	ackPayloadBytes, _ := json.Marshal(ackPayload)
	ack.Payload = ackPayloadBytes

	ackMsgBytes, _ := json.Marshal(ack)
	client.Send <- ackMsgBytes
}

func (d *EventDispatcher) sendError(client *Client, code, message string) {
	errPayload := map[string]string{
		"code":    code,
		"message": message,
	}
	errBytes, _ := json.Marshal(errPayload)

	msg := Message{
		EventType: "error",
		Timestamp: time.Now().UnixMilli(),
		Payload:   errBytes,
	}

	msgBytes, _ := json.Marshal(msg)
	client.Send <- msgBytes
}
