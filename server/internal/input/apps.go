package input

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
)

// DesktopApp represents an installed application on the host OS.
type DesktopApp struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	Path string `json:"path"`
	Icon string `json:"icon,omitempty"`
}

var (
	appsCache     []DesktopApp
	appsCacheLock sync.RWMutex
)

// ListInstalledApps scans the host operating system for installed user applications.
func ListInstalledApps() ([]DesktopApp, error) {
	appsCacheLock.RLock()
	if len(appsCache) > 0 {
		defer appsCacheLock.RUnlock()
		return appsCache, nil
	}
	appsCacheLock.RUnlock()

	appsCacheLock.Lock()
	defer appsCacheLock.Unlock()

	var apps []DesktopApp

	switch runtime.GOOS {
	case "darwin":
		apps = scanMacOSApps()
	case "linux":
		apps = scanLinuxApps()
	case "windows":
		apps = scanWindowsApps()
	default:
		apps = []DesktopApp{}
	}

	appsCache = apps
	return apps, nil
}

// LaunchDesktopApp executes/opens a desktop application by name or path.
func LaunchDesktopApp(name, path string) error {
	switch runtime.GOOS {
	case "darwin":
		if path != "" {
			return exec.Command("open", path).Run()
		}
		return exec.Command("open", "-a", name).Run()

	case "linux":
		if path != "" && strings.HasSuffix(path, ".desktop") {
			return exec.Command("gtk-launch", filepath.Base(path)).Run()
		}
		return exec.Command("sh", "-c", name+" &").Run()

	case "windows":
		if path != "" {
			return exec.Command("cmd", "/C", "start", "", path).Run()
		}
		return exec.Command("cmd", "/C", "start", "", name).Run()

	default:
		return fmt.Errorf("unsupported operating system: %s", runtime.GOOS)
	}
}

func scanMacOSApps() []DesktopApp {
	dirs := []string{
		"/Applications",
		"/System/Applications",
		filepath.Join(os.Getenv("HOME"), "Applications"),
	}

	appMap := make(map[string]DesktopApp)

	for _, dir := range dirs {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}

		for _, entry := range entries {
			if entry.IsDir() && strings.HasSuffix(entry.Name(), ".app") {
				name := strings.TrimSuffix(entry.Name(), ".app")
				fullPath := filepath.Join(dir, entry.Name())
				id := strings.ToLower(strings.ReplaceAll(name, " ", "_"))

				if _, exists := appMap[id]; !exists {
					appMap[id] = DesktopApp{
						ID:   id,
						Name: name,
						Path: fullPath,
						Icon: getCategoryIcon(name),
					}
				}
			}
		}
	}

	var result []DesktopApp
	for _, app := range appMap {
		result = append(result, app)
	}
	return result
}

func scanLinuxApps() []DesktopApp {
	dirs := []string{
		"/usr/share/applications",
		filepath.Join(os.Getenv("HOME"), ".local/share/applications"),
	}

	var result []DesktopApp
	for _, dir := range dirs {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}
		for _, entry := range entries {
			if !entry.IsDir() && strings.HasSuffix(entry.Name(), ".desktop") {
				name := strings.TrimSuffix(entry.Name(), ".desktop")
				result = append(result, DesktopApp{
					ID:   name,
					Name: strings.Title(strings.ReplaceAll(name, "-", " ")),
					Path: filepath.Join(dir, entry.Name()),
					Icon: "desktop",
				})
			}
		}
	}
	return result
}

func scanWindowsApps() []DesktopApp {
	return []DesktopApp{
		{ID: "calc", Name: "Calculadora", Path: "calc.exe", Icon: "calculator"},
		{ID: "notepad", Name: "Bloco de Notas", Path: "notepad.exe", Icon: "edit"},
		{ID: "cmd", Name: "Prompt de Comando", Path: "cmd.exe", Icon: "terminal"},
	}
}

func getCategoryIcon(appName string) string {
	lower := strings.ToLower(appName)
	if strings.Contains(lower, "code") || strings.Contains(lower, "sublime") || strings.Contains(lower, "studio") || strings.Contains(lower, "intellij") {
		return "code"
	}
	if strings.Contains(lower, "terminal") || strings.Contains(lower, "iterm") || strings.Contains(lower, "warp") {
		return "terminal"
	}
	if strings.Contains(lower, "chrome") || strings.Contains(lower, "safari") || strings.Contains(lower, "firefox") || strings.Contains(lower, "browser") || strings.Contains(lower, "edge") {
		return "globe"
	}
	if strings.Contains(lower, "music") || strings.Contains(lower, "spotify") || strings.Contains(lower, "sound") {
		return "music"
	}
	if strings.Contains(lower, "finder") || strings.Contains(lower, "file") {
		return "folder"
	}
	return "desktop"
}
