package input

import (
	"fmt"
	"log"
	"os/exec"
	"runtime"
	"strings"
	"sync"
)

// InputEmulator defines the operations supported for system automation and input emulation.
type InputEmulator interface {
	TapKey(key string, modifiers []string) error
	TypeText(text string) error
	MoveMouseRelative(dx, dy float64) error
	MouseClick(button string) error
	MouseScroll(dx, dy float64) error
	ExecuteCommand(cmd string) (string, error)
}

// SystemInputEmulator implements InputEmulator using native operating system automation tools.
type SystemInputEmulator struct {
	mu sync.Mutex
}

// NewSystemInputEmulator creates a new SystemInputEmulator instance.
func NewSystemInputEmulator() *SystemInputEmulator {
	return &SystemInputEmulator{}
}

// TapKey executes a key combination or single key tap.
func (e *SystemInputEmulator) TapKey(key string, modifiers []string) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	switch runtime.GOOS {
	case "darwin":
		return e.tapKeyMacOS(key, modifiers)
	case "linux":
		return e.tapKeyLinux(key, modifiers)
	case "windows":
		return e.tapKeyWindows(key, modifiers)
	default:
		return fmt.Errorf("unsupported OS: %s", runtime.GOOS)
	}
}

// TypeText simulates typing string text into the currently active window.
func (e *SystemInputEmulator) TypeText(text string) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	switch runtime.GOOS {
	case "darwin":
		script := fmt.Sprintf(`tell application "System Events" to keystroke %q`, text)
		return exec.Command("osascript", "-e", script).Run()
	case "linux":
		if isCommandAvailable("xdotool") {
			return exec.Command("xdotool", "type", text).Run()
		}
		return fmt.Errorf("xdotool not installed on linux")
	case "windows":
		psScript := fmt.Sprintf(`$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('%s')`, text)
		return exec.Command("powershell", "-Command", psScript).Run()
	default:
		return fmt.Errorf("unsupported OS: %s", runtime.GOOS)
	}
}

// MoveMouseRelative simulates relative mouse movement for trackpad control.
func (e *SystemInputEmulator) MoveMouseRelative(dx, dy float64) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	switch runtime.GOOS {
	case "darwin":
		// AppleScript CGEvent move fallback using python / osascript
		script := fmt.Sprintf(`
import Quartz
loc = Quartz.CGEventGetLocation(Quartz.CGEventCreate(None))
Quartz.CGEventPost(Quartz.kCGHIDEventTap, Quartz.CGEventCreateMouseEvent(None, Quartz.kCGEventMouseMoved, (loc.x + %f, loc.y + %f), 0))
`, dx, dy)
		cmd := exec.Command("python3", "-c", script)
		return cmd.Run()
	case "linux":
		if isCommandAvailable("xdotool") {
			return exec.Command("xdotool", "mousemove_relative", "--", fmt.Sprintf("%.0f", dx), fmt.Sprintf("%.0f", dy)).Run()
		}
		return fmt.Errorf("xdotool not installed on linux")
	case "windows":
		psScript := fmt.Sprintf(`[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(([System.Windows.Forms.Cursor]::Position.X + %.0f), ([System.Windows.Forms.Cursor]::Position.Y + %.0f))`, dx, dy)
		return exec.Command("powershell", "-Command", psScript).Run()
	default:
		return nil
	}
}

// MouseClick simulates a left, right, or middle mouse click.
func (e *SystemInputEmulator) MouseClick(button string) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	switch runtime.GOOS {
	case "darwin":
		btnCode := "0" // left
		if button == "right" {
			btnCode = "1"
		}
		script := fmt.Sprintf(`
import Quartz
loc = Quartz.CGEventGetLocation(Quartz.CGEventCreate(None))
btn = %s
down = Quartz.kCGEventLeftMouseDown if btn == 0 else Quartz.kCGEventRightMouseDown
up = Quartz.kCGEventLeftMouseUp if btn == 0 else Quartz.kCGEventRightMouseUp
Quartz.CGEventPost(Quartz.kCGHIDEventTap, Quartz.CGEventCreateMouseEvent(None, down, loc, btn))
Quartz.CGEventPost(Quartz.kCGHIDEventTap, Quartz.CGEventCreateMouseEvent(None, up, loc, btn))
`, btnCode)
		return exec.Command("python3", "-c", script).Run()
	case "linux":
		btnNum := "1"
		if button == "right" {
			btnNum = "3"
		} else if button == "middle" {
			btnNum = "2"
		}
		if isCommandAvailable("xdotool") {
			return exec.Command("xdotool", "click", btnNum).Run()
		}
		return fmt.Errorf("xdotool not installed")
	case "windows":
		return nil
	default:
		return nil
	}
}

// MouseScroll simulates mouse wheel scrolling.
func (e *SystemInputEmulator) MouseScroll(dx, dy float64) error {
	e.mu.Lock()
	defer e.mu.Unlock()

	switch runtime.GOOS {
	case "darwin":
		script := fmt.Sprintf(`
import Quartz
Quartz.CGEventPost(Quartz.kCGHIDEventTap, Quartz.CGEventCreateScrollWheelEvent(None, Quartz.kCGScrollEventUnitPixel, 2, int(%.0f), int(%.0f)))
`, dy*10, dx*10)
		return exec.Command("python3", "-c", script).Run()
	case "linux":
		if isCommandAvailable("xdotool") {
			btn := "5" // scroll down
			if dy < 0 {
				btn = "4" // scroll up
			}
			return exec.Command("xdotool", "click", btn).Run()
		}
		return nil
	default:
		return nil
	}
}

// ExecuteCommand executes a host shell command and returns the combined output.
func (e *SystemInputEmulator) ExecuteCommand(command string) (string, error) {
	e.mu.Lock()
	defer e.mu.Unlock()

	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.Command("cmd", "/C", command)
	} else {
		cmd = exec.Command("sh", "-c", command)
	}

	out, err := cmd.CombinedOutput()
	return string(out), err
}

// macOS AppleScript helper
func (e *SystemInputEmulator) tapKeyMacOS(key string, modifiers []string) error {
	mappedKey, isCode := mapMacOSKey(key)

	var modScript []string
	for _, m := range modifiers {
		switch strings.ToLower(m) {
		case "cmd", "command":
			modScript = append(modScript, "command down")
		case "ctrl", "control":
			modScript = append(modScript, "control down")
		case "alt", "option":
			modScript = append(modScript, "option down")
		case "shift":
			modScript = append(modScript, "shift down")
		}
	}

	modClause := ""
	if len(modScript) > 0 {
		modClause = fmt.Sprintf(" using {%s}", strings.Join(modScript, ", "))
	}

	var script string
	if isCode {
		script = fmt.Sprintf(`tell application "System Events" to key code %s%s`, mappedKey, modClause)
	} else {
		script = fmt.Sprintf(`tell application "System Events" to keystroke %q%s`, mappedKey, modClause)
	}

	out, err := exec.Command("osascript", "-e", script).CombinedOutput()
	if err != nil {
		log.Printf("[InputEmulator] osascript error: %v, output: %s", err, string(out))
	}
	return err
}

func (e *SystemInputEmulator) tapKeyLinux(key string, modifiers []string) error {
	if !isCommandAvailable("xdotool") {
		return fmt.Errorf("xdotool not installed on linux system")
	}

	var modKeys []string
	for _, m := range modifiers {
		switch strings.ToLower(m) {
		case "cmd", "super":
			modKeys = append(modKeys, "Super")
		case "ctrl", "control":
			modKeys = append(modKeys, "Control")
		case "alt":
			modKeys = append(modKeys, "Alt")
		case "shift":
			modKeys = append(modKeys, "Shift")
		}
	}

	combo := strings.Join(append(modKeys, key), "+")
	return exec.Command("xdotool", "key", combo).Run()
}

func (e *SystemInputEmulator) tapKeyWindows(key string, modifiers []string) error {
	combo := ""
	for _, m := range modifiers {
		switch strings.ToLower(m) {
		case "ctrl", "control":
			combo += "^"
		case "alt":
			combo += "%"
		case "shift":
			combo += "+"
		}
	}
	combo += key

	psScript := fmt.Sprintf(`$wshell = New-Object -ComObject wscript.shell; $wshell.SendKeys('%s')`, combo)
	return exec.Command("powershell", "-Command", psScript).Run()
}

func mapMacOSKey(key string) (string, bool) {
	switch strings.ToLower(key) {
	case "enter", "return":
		return "36", true
	case "tab":
		return "48", true
	case "space":
		return "49", true
	case "escape", "esc":
		return "53", true
	case "delete", "backspace":
		return "51", true
	case "up":
		return "126", true
	case "down":
		return "125", true
	case "left":
		return "123", true
	case "right":
		return "124", true
	default:
		return key, false
	}
}

func isCommandAvailable(cmd string) bool {
	_, err := exec.LookPath(cmd)
	return err == nil
}

// MockInputEmulator is used for testing and CI headless environments.
type MockInputEmulator struct {
	LastKey        string
	LastModifiers  []string
	LastText       string
	LastCommand    string
	LastDx, LastDy float64
	Mu             sync.Mutex
}

func NewMockInputEmulator() *MockInputEmulator {
	return &MockInputEmulator{}
}

func (m *MockInputEmulator) TapKey(key string, modifiers []string) error {
	m.Mu.Lock()
	defer m.Mu.Unlock()
	m.LastKey = key
	m.LastModifiers = modifiers
	return nil
}

func (m *MockInputEmulator) TypeText(text string) error {
	m.Mu.Lock()
	defer m.Mu.Unlock()
	m.LastText = text
	return nil
}

func (m *MockInputEmulator) MoveMouseRelative(dx, dy float64) error {
	m.Mu.Lock()
	defer m.Mu.Unlock()
	m.LastDx = dx
	m.LastDy = dy
	return nil
}

func (m *MockInputEmulator) MouseClick(button string) error {
	return nil
}

func (m *MockInputEmulator) MouseScroll(dx, dy float64) error {
	return nil
}

func (m *MockInputEmulator) ExecuteCommand(cmd string) (string, error) {
	m.Mu.Lock()
	defer m.Mu.Unlock()
	m.LastCommand = cmd
	return "mock output", nil
}
