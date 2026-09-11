Steps to resolve the `br-connection-key-missing` error by extracting the Windows Bluetooth link key using `chntpw` and applying it to CachyOS (BlueZ).

## Step 1: Pair in CachyOS First

1. Boot into CachyOS and pair your Bluetooth device (`F4:9D:8A:B7:E2:20`) to generate the initial directory structure under BlueZ.

## Step 2: Mount Windows Partition in Linux

1. Find your Windows partition using `lsblk` (e.g., `/dev/nvme0n1p3`).
2. Mount the Windows drive:
```bash
sudo mkdir -p /mnt/windows
sudo mount -o ro /dev/nvme0n1p3 /mnt/windows

```



## Step 3: Extract Key via `chntpw`

1. Install `chntpw` if not already installed (`sudo pacman -S chntpw`).
2. Navigate to the Windows registry config folder and open the SYSTEM hive:
```bash
cd /mnt/windows/Windows/System32/config
sudo chntpw -e SYSTEM

```


3. Inside the `chntpw` prompt, navigate to your Bluetooth keys and print the target device key:
```text
cd ControlSet001\Services\BTHPORT\Parameters\Keys
cd 64bc583d2cf9
cat f49d8ab7e220

```


4. Copy the 16 hex pairs (e.g., `F3 6A 58 EB 66 00 F4 BA FB 59 C0 64 E7 DF 23 3A`), remove spaces to form a 32-character uppercase string (`F36A58EB6600F4BAFB59C064E7DF233A`), and type `q` to exit.

## Step 4: Apply Key to CachyOS BlueZ Config

1. Open the CachyOS Bluetooth device config file:
```bash
sudo nano /var/lib/bluetooth/64:BC:58:3D:2C:F9/F4:9D:8A:B7:E2:20/info

```


2. Update the `Key` value under `[LinkKey]` while keeping `Type=4` intact:
```ini
[LinkKey]
Key=F36A58EB6600F4BAFB59C064E7DF233A
Type=4
PINLength=0

```


3. Save and restart the Bluetooth service:
```bash
sudo systemctl restart bluetooth
```" provider="keep"/>

```
