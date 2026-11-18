package main

import (
	"embed"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"syscall"

	"vpngate-smart/internal/cleanup"
	"vpngate-smart/internal/gui"
	"vpngate-smart/internal/tui"
)

//go:embed web/*
var webFS embed.FS

const version = "0.2.0"

func main() {
	cliMode := flag.Bool("cli", false, "Run in terminal TUI mode instead of GUI")
	flag.Parse()

	// Check admin privileges
	if !cleanup.IsAdmin() {
		fmt.Println("╔══════════════════════════════════════════════════════════╗")
		fmt.Println("║  vpngate-smart requires Administrator privileges.       ║")
		fmt.Println("║  Please run this program as Administrator.              ║")
		fmt.Println("╚══════════════════════════════════════════════════════════╝")
		fmt.Println()
		fmt.Print("Attempt to restart as Administrator? (y/n): ")

		var answer string
		fmt.Scanln(&answer)
		if answer == "y" || answer == "Y" {
			if err := cleanup.RequestAdmin(); err != nil {
				fmt.Fprintf(os.Stderr, "Failed to elevate: %v\n", err)
				os.Exit(1)
			}
			os.Exit(0)
		}
		os.Exit(1)
	}

	// Setup cleanup manager
	cm := &cleanup.CleanupManager{}
	cm.Register("Kill OpenVPN", func() error {
		cmd := exec.Command("taskkill", "/F", "/IM", "openvpn.exe")
		cmd.SysProcAttr = &syscall.SysProcAttr{
			HideWindow:    true,
			CreationFlags: 0x08000000, // CREATE_NO_WINDOW
		}
		_ = cmd.Run()
		return nil
	})

	// Setup signal handler for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigChan
		fmt.Println("\n\nShutting down gracefully...")
		errs := cm.RunAll()
		for _, err := range errs {
			fmt.Fprintf(os.Stderr, "Cleanup error: %v\n", err)
		}
		os.Exit(0)
	}()

	// If user explicitly requests terminal mode via -cli flag
	if *cliMode {
		app := tui.NewApp(version, cm)
		if err := app.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			cm.RunAll()
			os.Exit(1)
		}
		cm.RunAll()
		return
	}

	// Default Mode: Modern Windscribe-like GUI window
	fmt.Printf("Starting VPN Gate Smart Client (GUI Mode) v%s...\n", version)
	if err := gui.StartGUIServer(webFS, cm); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to start GUI server: %v\n", err)
		cm.RunAll()
		os.Exit(1)
	}
}
