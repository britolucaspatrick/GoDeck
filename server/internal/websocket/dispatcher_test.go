package websocket

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/godeck/godeck-server/internal/config"
	"github.com/godeck/godeck-server/internal/input"
)

func TestEventDispatcher_Action(t *testing.T) {
	mockEmulator := input.NewMockInputEmulator()
	shortcutStore := config.NewShortcutStore(t.TempDir() + "/shortcuts_test.json")
	hub := NewHub()
	dispatcher := NewEventDispatcher(mockEmulator, shortcutStore, hub, false)

	client := &Client{
		ID:         "test_client",
		Send:       make(chan []byte, 10),
		Dispatcher: dispatcher,
	}

	actionPayload := ActionPayload{
		Type:      "key_combination",
		Key:       "c",
		Modifiers: []string{"cmd"},
	}
	payloadBytes, _ := json.Marshal(actionPayload)

	msg := Message{
		EventType: "action",
		Timestamp: time.Now().UnixMilli(),
		Payload:   payloadBytes,
	}

	msgBytes, _ := json.Marshal(msg)
	dispatcher.Dispatch(client, msgBytes)

	if mockEmulator.LastKey != "c" {
		t.Errorf("Expected last key to be 'c', got '%s'", mockEmulator.LastKey)
	}
	if len(mockEmulator.LastModifiers) != 1 || mockEmulator.LastModifiers[0] != "cmd" {
		t.Errorf("Expected modifier 'cmd', got %v", mockEmulator.LastModifiers)
	}

	select {
	case responseBytes := <-client.Send:
		var resp Message
		json.Unmarshal(responseBytes, &resp)
		if resp.EventType != "ack" {
			t.Errorf("Expected event_type 'ack', got '%s'", resp.EventType)
		}
	default:
		t.Error("Expected ack message on client Send channel")
	}
}

func TestEventDispatcher_PingPong(t *testing.T) {
	mockEmulator := input.NewMockInputEmulator()
	shortcutStore := config.NewShortcutStore(t.TempDir() + "/shortcuts_test2.json")
	hub := NewHub()
	dispatcher := NewEventDispatcher(mockEmulator, shortcutStore, hub, false)

	client := &Client{
		ID:         "test_client",
		Send:       make(chan []byte, 10),
		Dispatcher: dispatcher,
	}

	msg := Message{
		EventType: "ping",
		Timestamp: 1000,
	}

	msgBytes, _ := json.Marshal(msg)
	dispatcher.Dispatch(client, msgBytes)

	select {
	case responseBytes := <-client.Send:
		var resp Message
		json.Unmarshal(responseBytes, &resp)
		if resp.EventType != "pong" {
			t.Errorf("Expected event_type 'pong', got '%s'", resp.EventType)
		}
	default:
		t.Error("Expected pong message on client Send channel")
	}
}
