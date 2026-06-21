# MY ARCH & HYPRLAND SETUP
https://github.com/Touiku411/arch-hyprland

# INSTALLATION
# *iwctl

---

### 1. Enter the network console
```bash
iwctl
```

### 2. list available wireless devices
```iwd
device list
```
* usually wlan0

### 3. Scan and List available Wi-Fi
```iwd
station wlan0 scan
station wlan0 get-networks
```

### 4. Connect to Wi-Fi
```iwd
station wlan0 connect "Your Wi-Fi name"
```
* After finish：`exit`

---

## Verify Connection

```bash
ping -c 3 google.com
```

---
