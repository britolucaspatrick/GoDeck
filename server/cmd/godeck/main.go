package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/godeck/godeck-server/internal/config"
	"github.com/godeck/godeck-server/internal/input"
	ws "github.com/godeck/godeck-server/internal/websocket"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func main() {
	log.Println("==================================================")
	log.Println("     🚀 GoDeck Host Server / Daemon v1.0         ")
	log.Println("==================================================")

	cfg, err := config.LoadConfig()
	if err != nil {
		log.Fatalf("[Main] Failed to load configuration: %v", err)
	}

	emulator := input.NewSystemInputEmulator()
	shortcutStore := config.NewShortcutStore("")

	hub := ws.NewHub()
	go hub.Run()

	dispatcher := ws.NewEventDispatcher(emulator, shortcutStore, hub, cfg.Verbose)

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Printf("[Server] WebSocket upgrade error: %v", err)
			return
		}

		clientID := fmt.Sprintf("client_%d", time.Now().UnixNano())
		client := &ws.Client{
			ID:         clientID,
			Hub:        hub,
			Conn:       conn,
			Send:       make(chan []byte, 256),
			Dispatcher: dispatcher,
		}

		hub.Register <- client

		go client.WritePump()
		go client.ReadPump()
	})

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		fmt.Fprintf(w, `{"status":"ok","clients":%d,"time":%d}`, hub.ClientCount(), time.Now().Unix())
	})

	localIPs := config.GetLocalIPs()
	log.Printf("[Server] Server starting on %s", cfg.Addr())
	log.Println("[Server] Available local network IP addresses for mobile connection:")
	for _, ip := range localIPs {
		log.Printf("  👉 ws://%s:%d/ws", ip, cfg.Port)
	}
	if len(localIPs) == 0 {
		log.Printf("  👉 ws://localhost:%d/ws", cfg.Port)
	}

	server := &http.Server{
		Addr:         cfg.Addr(),
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
	}

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("[Server] ListenAndServe error: %v", err)
		}
	}()

	// Handle graceful shutdown
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	<-stop

	log.Println("\n[Server] Shutting down GoDeck server gracefully...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Printf("[Server] Forced shutdown error: %v", err)
	}
	log.Println("[Server] Server stopped successfully.")
}
