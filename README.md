# CamillaDSP Local Setup

This repository contains the complete local CamillaDSP setup for macOS, including configuration files, launch agents, and integration with Shairport Sync for AirPlay audio processing.

## Overview

This setup provides a complete DSP audio pipeline on macOS:
- **CamillaDSP**: Core DSP engine for audio processing (convolution, EQ, crossover, etc.)
- **CamillaGUI**: Web-based interface for managing CamillaDSP configurations
- **Shairport Sync**: AirPlay receiver that pipes audio through CamillaDSP
- **BlackHole 2ch**: Virtual audio device for routing audio between applications
- **Automated Startup**: Launch agents ensure services start automatically

## Audio Chain Architecture

The complete audio routing chain works as follows:

```
Source (Shairport/App) → BlackHole 2ch → CamillaDSP → Audio Interface (e.g., MOTU M4)
```

### Why BlackHole?

[BlackHole](https://existential.audio/blackhole/) is a virtual audio driver that creates an invisible audio routing device. It allows audio to pass from one application to another without any physical cables:
- Shairport Sync outputs to BlackHole 2ch
- CamillaDSP listens to BlackHole 2ch as input
- CamillaDSP processes and outputs to your physical audio interface

Install BlackHole:
```bash
brew install blackhole-2ch
```

### Important: CoreAudio Sample Rate Considerations

**CoreAudio has extremely low latency but can be sensitive to sample rate mismatches.** To avoid issues:

1. **Keep sample rates consistent across the entire chain:**
   - BlackHole 2ch sample rate
   - CamillaDSP input/output sample rate
   - Physical audio interface sample rate
   - Source application sample rate (if possible)

2. **The 44.1kHz vs 48kHz dilemma:**
   - CD audio and many streaming services: **44.1kHz**
   - Professional audio interfaces (e.g., MOTU M4): Often default to **48kHz**
   - Video/film content: **48kHz**

3. **Resampling is no big deal, but CoreAudio can be finicky:**
   - CamillaDSP can handle resampling efficiently
   - However, within CoreAudio itself, sample rate mismatches can cause glitches, dropouts, or devices not appearing
   - **Best practice**: Pick one sample rate (44.1kHz or 48kHz) and configure ALL devices to use it

4. **Setting sample rates:**
   ```bash
   # Check current sample rate of BlackHole
   system_profiler SPAudioDataType | grep -A 10 "BlackHole"

   # Set your audio interface sample rate in Audio MIDI Setup app
   # Open: /Applications/Utilities/Audio MIDI Setup.app
   # Select your interface (e.g., MOTU M4) and set sample rate
   ```

5. **Recommended configuration:**
   - If most of your content is streaming/CD audio: Use **44.1kHz** everywhere
   - If using professional audio gear: Use **48kHz** everywhere
   - Configure CamillaDSP's resampler if you need to bridge between rates

**TIP**: Audio MIDI Setup (in `/Applications/Utilities/`) is your friend for checking and configuring sample rates across all CoreAudio devices.

## Directory Structure

```
camilladsp/
├── bin/                    # CamillaDSP binary (download separately)
├── camillagui_backend/     # GUI backend (download separately)
├── gui/                    # GUI source and configuration
├── coeffs/                 # Convolution filter coefficients
├── configs/                # CamillaDSP configuration files
├── launch_agents/          # macOS LaunchAgent plists
│   ├── com.camilladsp.launch.plist
│   └── com.camillagui.plist
├── automator/              # Automator apps for automation
│   └── LaunchShairport.app
├── shairport-sync.conf     # Shairport Sync configuration
├── start_script.sh         # Manual start script
├── runbkgd.sh             # Background runner script
└── full_install_venv.sh   # Virtual environment installer
```

**Note**: Binaries are not included in this repository to keep it lightweight. Download them from the official releases during installation.

## Installation

### 1. Prerequisites

Install BlackHole 2ch (virtual audio routing driver):
```bash
brew install blackhole-2ch
```

**Note about Shairport Sync**: On modern Macs with **AirPlay 2 built-in**, you do not need Shairport Sync. You can use the native AirPlay receiver and route it through BlackHole directly. If you're on an older Mac or prefer Shairport Sync for advanced features:
```bash
brew install shairport-sync
```

### 2. Clone Repository

```bash
git clone git@github.com:nikhilblal/camilladsp-local.git
cd camilladsp-local
```

### 3. Install CamillaDSP Binary

**Download the appropriate binary for your Mac:**

1. Visit the [CamillaDSP Releases page](https://github.com/HEnquist/camilladsp/releases)
2. Download the correct binary:
   - **Apple Silicon (M1/M2/M3/M4)**: `camilladsp-macos-aarch64.tar.gz`
   - **Intel Mac**: `camilladsp-macos-amd64.tar.gz`

3. Extract and install:
   ```bash
   # For Apple Silicon:
   curl -L https://github.com/HEnquist/camilladsp/releases/latest/download/camilladsp-macos-aarch64.tar.gz -o camilladsp.tar.gz

   # For Intel:
   # curl -L https://github.com/HEnquist/camilladsp/releases/latest/download/camilladsp-macos-amd64.tar.gz -o camilladsp.tar.gz

   tar -xzf camilladsp.tar.gz
   mv camilladsp bin/camilladsp
   chmod +x bin/camilladsp
   rm camilladsp.tar.gz
   ```

4. Remove macOS quarantine attribute:
   ```bash
   xattr -d com.apple.quarantine bin/camilladsp
   ```

5. Verify installation:
   ```bash
   ./bin/camilladsp --version
   ```

### 4. Install CamillaGUI Backend (Optional)

Two GUI options are available:

**Option A: Standalone GUI Backend (Recommended)**

Download the pre-built standalone backend:

1. Visit the [CamillaGUI Releases page](https://github.com/HEnquist/camillagui/releases)
2. Download the backend for your platform:
   - **macOS**: `camillagui_backend-macos.zip`
3. Extract and install:
   ```bash
   # Download (replace VERSION with latest version, e.g., v2.0.1)
   curl -L https://github.com/HEnquist/camillagui/releases/latest/download/camillagui_backend-macos.zip -o camillagui_backend.zip

   unzip camillagui_backend.zip -d camillagui_backend/
   chmod +x camillagui_backend/camillagui_backend
   rm camillagui_backend.zip

   # Remove quarantine
   xattr -dr com.apple.quarantine camillagui_backend/
   ```

4. Test it:
   ```bash
   ./camillagui_backend/camillagui_backend
   ```

**Option B: Python-based GUI**

Install the Python GUI in a virtual environment:
```bash
./full_install_venv.sh
```

This option is useful if you want to modify the GUI or if the standalone backend doesn't work on your system.

### 5. Setup Launch Agents

Install the launch agents to auto-start CamillaDSP and CamillaGUI on boot:

```bash
# Copy launch agents to LaunchAgents directory
cp launch_agents/com.camilladsp.launch.plist ~/Library/LaunchAgents/
cp launch_agents/com.camillagui.plist ~/Library/LaunchAgents/

# Load the agents
launchctl load ~/Library/LaunchAgents/com.camilladsp.launch.plist
launchctl load ~/Library/LaunchAgents/com.camillagui.plist
```

**Important**: Edit the paths in the plist files to match your installation directory before loading them.

### 6. Configure Shairport Sync (Optional - Only if using Shairport Sync)

**Skip this step if you're using native AirPlay 2 on a modern Mac.**

If you installed Shairport Sync in step 1, copy the Shairport configuration:
```bash
sudo cp shairport-sync.conf /usr/local/etc/shairport-sync.conf
```

This configuration pipes AirPlay audio through CamillaDSP for processing.

### 7. Setup Automator (Optional - Only if using Shairport Sync)

The `automator/LaunchShairport.app` provides an easy way to start Shairport Sync:
- Copy it to `/Applications/` if you want it in your main apps folder
- Add it to Login Items in System Preferences for auto-start
- Or run it manually when needed

## Usage

### Starting Services Manually

```bash
# Start CamillaDSP
./start_script.sh

# Or run in background
./runbkgd.sh

# Start GUI (if using Python version)
cd gui
source gui-venv/bin/activate
python main.py
```

### Accessing the GUI

Once CamillaGUI is running:
1. Open your browser to `http://localhost:5000` (or the port configured in `gui/config/camillagui.yml`)
2. The GUI provides a visual interface for:
   - Uploading and managing configurations
   - Editing filter parameters
   - Viewing real-time signal levels
   - Managing convolution files

### Using Shairport Sync

Once Shairport Sync is running:
1. Your Mac will appear as an AirPlay device on your network
2. Audio streamed to it will be processed through CamillaDSP
3. Processed audio outputs to your configured device

## Configuration Files

### CamillaDSP Config (`configs/active_config_min.yml`)

The active DSP configuration defines:
- Input/output devices
- Sample rates
- Filters and convolution
- Mixer routing
- Pipeline processing

Edit via GUI or manually in YAML format.

### CamillaGUI Config (`gui/config/camillagui.yml`)

Controls GUI behavior:
- Port settings
- CamillaDSP connection
- File paths
- Backend options

### Shairport Sync Config (`shairport-sync.conf`)

Configures AirPlay receiver:
- Output device (should match CamillaDSP input)
- Buffer settings
- Audio format
- Network settings

## Launch Agents Explained

### com.camilladsp.launch.plist

Automatically starts CamillaDSP on login with:
- Configured YAML file
- Logging to `camilladsp.log`
- Environment variables as needed

### com.camillagui.plist

Automatically starts the CamillaGUI backend on login:
- Binds to configured port
- Connects to CamillaDSP
- Enables web interface access

## Convolution Filters

The `coeffs/` directory contains:
- Speaker correction filters
- Subwoofer filters
- Room correction filters
- Multiple sample rates (44.1k, 48k, 96k)

Filters are referenced in the CamillaDSP configuration and applied in the processing pipeline.

## Troubleshooting

### Services Not Starting

Check launch agent status:
```bash
launchctl list | grep camilla
launchctl list | grep shairport
```

View logs:
```bash
tail -f camilladsp.log
tail -f gui.log
```

### Audio Issues

1. Verify input/output devices in config match actual devices:
```bash
# List audio devices
system_profiler SPAudioDataType
```

2. Check CamillaDSP is running:
```bash
ps aux | grep camilladsp
```

3. Verify Shairport output device matches CamillaDSP input

### GUI Not Accessible

1. Check if GUI is running: `ps aux | grep camillagui`
2. Verify port isn't in use: `lsof -i :5000`
3. Check `gui.log` for errors

### Permission Issues

Launch agents may need full disk access:
- System Preferences → Security & Privacy → Full Disk Access
- Add Terminal or the app running the scripts

## Updating

To update CamillaDSP or GUI:
1. Pull latest changes: `git pull`
2. Reload launch agents if plist files changed
3. Restart services or reboot

## Monitoring Your System

For real-time monitoring of CPU temperature, fan speed, network I/O, and system resources while running CamillaDSP, check out the **[Terminal Monitor](https://github.com/nikhilblal/terminal-monitor)** tool. It provides a beautiful htop-style interface perfect for keeping an eye on your audio processing system.

```bash
git clone https://github.com/nikhilblal/terminal-monitor.git
cd terminal-monitor
pip3 install -r requirements.txt
python3 system_monitor.py
```

## Additional Resources

### Installation & Core Documentation
- [CamillaDSP Official README](https://github.com/HEnquist/camilladsp/blob/master/README.md) - **Start here for installing CamillaDSP**
- [CamillaDSP Documentation](https://github.com/HEnquist/camilladsp) - Full documentation
- [CamillaGUI Documentation](https://github.com/HEnquist/camillagui) - GUI setup and usage

### Audio Tools
- [Shairport Sync Documentation](https://github.com/mikebrady/shairport-sync) - AirPlay receiver
- [BlackHole Audio Driver](https://existential.audio/blackhole/) - Virtual audio routing

### Monitoring
- [Terminal Monitor](https://github.com/nikhilblal/terminal-monitor) - Real-time system monitoring tool

## Credits

- **CamillaDSP**: Henrik Enquist
- **Shairport Sync**: Mike Brady
- This setup and documentation by the repository owner

## License

Refer to individual component licenses:
- CamillaDSP: GPL-3.0
- CamillaGUI: GPL-3.0
- Shairport Sync: Various (see project)
