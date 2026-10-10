package config

import (
	"encoding/json"
	"log"
	"os"
	"path/filepath"
	"sync"
)

// ShortcutStore manages persistence of custom shortcut pages and items in a JSON file.
type ShortcutStore struct {
	filePath string
	mu       sync.RWMutex
}

// NewShortcutStore creates a new ShortcutStore instance pointing to the specified JSON path or default config location.
func NewShortcutStore(customPath string) *ShortcutStore {
	if customPath == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			homeDir = "."
		}
		configDir := filepath.Join(homeDir, ".config", "godeck")
		os.MkdirAll(configDir, 0755)
		customPath = filepath.Join(configDir, "shortcuts.json")
	}

	store := &ShortcutStore{filePath: customPath}
	store.ensureFileExists()
	return store
}

func (s *ShortcutStore) ensureFileExists() {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, err := os.Stat(s.filePath); os.IsNotExist(err) {
		defaultData := s.getDefaultLayout()
		bytes, err := json.MarshalIndent(defaultData, "", "  ")
		if err == nil {
			_ = os.WriteFile(s.filePath, bytes, 0644)
			log.Printf("[ShortcutStore] Created initial shortcuts configuration at: %s", s.filePath)
		}
	}
}

// Load reads the shortcut layout from JSON file.
func (s *ShortcutStore) Load(v interface{}) error {
	s.mu.RLock()
	defer s.mu.RUnlock()

	data, err := os.ReadFile(s.filePath)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, v)
}

// Save writes the updated shortcut layout to the JSON config file.
func (s *ShortcutStore) Save(v interface{}) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	bytes, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		return err
	}

	err = os.WriteFile(s.filePath, bytes, 0644)
	if err == nil {
		log.Printf("[ShortcutStore] Saved updated shortcuts configuration to %s", s.filePath)
	}
	return err
}

func (s *ShortcutStore) getDefaultLayout() map[string]interface{} {
	return map[string]interface{}{
		"pages": []map[string]interface{}{
			{
				"id":      "page_dev_media",
				"title":   "Desenvolvimento & Mídia",
				"columns": 3,
				"items": []map[string]interface{}{
					{
						"id":    "btn_copy",
						"title": "Copiar",
						"icon":  "copy",
						"color": "#00E5FF",
						"action": map[string]interface{}{
							"type":      "key_combination",
							"key":       "c",
							"modifiers": []string{"cmd"},
							"label":     "Copiar Texto",
						},
					},
					{
						"id":    "btn_paste",
						"title": "Colar",
						"icon":  "paste",
						"color": "#7C4DFF",
						"action": map[string]interface{}{
							"type":      "key_combination",
							"key":       "v",
							"modifiers": []string{"cmd"},
							"label":     "Colar Conteúdo",
						},
					},
					{
						"id":    "btn_terminal",
						"title": "Terminal",
						"icon":  "terminal",
						"color": "#00E676",
						"action": map[string]interface{}{
							"type":    "system_command",
							"command": "open -a Terminal",
							"label":   "Abrir Terminal",
						},
					},
					{
						"id":    "btn_vscode",
						"title": "VS Code",
						"icon":  "code",
						"color": "#FF9100",
						"action": map[string]interface{}{
							"type":    "system_command",
							"command": "open -a 'Visual Studio Code'",
							"label":   "Abrir VS Code",
						},
					},
					{
						"id":    "btn_play",
						"title": "Play/Pause",
						"icon":  "play_pause",
						"color": "#FF3D00",
						"action": map[string]interface{}{
							"type":  "key_tap",
							"key":   "space",
							"label": "Mídia Play/Pause",
						},
					},
					{
						"id":    "btn_screenshot",
						"title": "Print Screen",
						"icon":  "desktop",
						"color": "#E91E63",
						"action": map[string]interface{}{
							"type":      "key_combination",
							"key":       "4",
							"modifiers": []string{"cmd", "shift"},
							"label":     "Captura de Tela",
						},
					},
				},
			},
		},
	}
}
