package config

import (
	"flag"
	"fmt"
	"net"
	"os"
	"strconv"
)

// Config holds runtime configuration for the GoDeck Server.
type Config struct {
	Port      int
	Host      string
	AuthToken string
	Verbose   bool
}

// LoadConfig parses CLI flags and environment variables to create a Config instance.
func LoadConfig() (*Config, error) {
	cfg := &Config{}

	defaultPort := 8080
	if envPort := os.Getenv("GODECK_PORT"); envPort != "" {
		if p, err := strconv.Atoi(envPort); err == nil {
			defaultPort = p
		}
	}

	defaultHost := "0.0.0.0"
	if envHost := os.Getenv("GODECK_HOST"); envHost != "" {
		defaultHost = envHost
	}

	defaultToken := os.Getenv("GODECK_AUTH_TOKEN")

	flag.IntVar(&cfg.Port, "port", defaultPort, "Server HTTP/WebSocket port")
	flag.StringVar(&cfg.Host, "host", defaultHost, "Server bind host interface")
	flag.StringVar(&cfg.AuthToken, "token", defaultToken, "Optional authentication token for clients")
	flag.BoolVar(&cfg.Verbose, "verbose", false, "Enable debug verbose logging")

	flag.Parse()

	return cfg, nil
}

// GetLocalIPs returns a list of non-loopback IPv4 addresses assigned to host network interfaces.
func GetLocalIPs() []string {
	var ips []string
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return ips
	}

	for _, address := range addrs {
		if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				ips = append(ips, ipnet.IP.String())
			}
		}
	}
	return ips
}

// Addr returns the formatted bind network address string (e.g., "0.0.0.0:8080").
func (c *Config) Addr() string {
	return fmt.Sprintf("%s:%d", c.Host, c.Port)
}
