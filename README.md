# Pegatron Lucid: built-in Wi-Fi on Linux

On the Pegatron Lucid tablet, the built-in **Intel Centrino Advanced-N + WiMAX 6250** shows `Hard blocked: yes` under Linux, even though it works in Windows. This repository has the fix: a one-line ACPI call, a systemd unit that applies it at boot, and kernel patches that fix it upstream.

## Symptoms

```
$ rfkill list
0: pega-wlan: Wireless LAN      Soft blocked: no   Hard blocked: no
1: pega-bt: Bluetooth           Soft blocked: no   Hard blocked: no
2: pega-wwan: Wireless WAN      Soft blocked: no   Hard blocked: no
3: phy0: Wireless LAN           Soft blocked: no   Hard blocked: yes
```

```
iwlwifi 0000:02:00.0: Detected Intel(R) Centrino(R) Advanced-N + WiMAX 6250 AGN, REV=0x84
iwlwifi 0000:02:00.0: reporting RF_KILL (radio disabled)
```

`rfkill unblock all` does not help. The tablet has no Wi-Fi switch, and the BIOS has no WLAN option.

## Quick fix

```sh
sudo apt install acpi-call-dkms
sudo modprobe acpi_call
echo '\_SB.ATKD.ENPR 6' | sudo tee /proc/acpi/call
```

The kernel logs `iwlwifi ...: RF_KILL bit toggled to enable radio.` and Wi-Fi works right away.

## Permanent fix

```sh
git clone https://github.com/kotekompotek/pegatron-lucid-linux-wifi
cd pegatron-lucid-linux-wifi
sudo ./check.sh      # read-only: affected machines show GP27(WMHD)=1
sudo ./install.sh    # installs acpi-call-dkms + a systemd unit
```

To undo: `sudo systemctl disable --now lucid-wlan-enable` and `echo '\_SB.ATKD.DAPR 6' | sudo tee /proc/acpi/call`.

## Cause

The DSDT methods `\_SB.ATKD.ENPR` (enable) and `DAPR` (disable) switch radios by id:

| Id | Radio | GPIO | EC bit | Handled by `asus-laptop` | State at boot |
|----|-------|------|--------|--------------------------|---------------|
| 0 | WLAN | GP18 | WLRF | yes (`pega-wlan`) | enabled |
| 1 | Bluetooth | GP17 | BTRF | yes (`pega-bt`) | enabled |
| 2 | WWAN | GP20 | WWAN | yes (`pega-wwan`) | enabled |
| 6 | WiMAX | GP27 | WMHD | **no** | **disabled** |

The 6250 is a Wi-Fi + WiMAX combo card. While GPIO27 is high, the whole card is held in hardware RF-kill, Wi-Fi included. The Linux `asus-laptop` driver never calls `ENPR(6)`. The Windows vendor utility apparently does.

## Kernel patches

[`patches/`](patches/) adds a `pega-wimax` rfkill switch to `asus-laptop`, which unblocks id 6 at boot. It also fixes a leak where the wimax rfkill was never freed. The series was submitted to `platform-driver-x86@vger.kernel.org`. Once it is merged, the workaround above is no longer needed.

## Warnings

- Do not call `DAPR(0)` to "reset" Wi-Fi. `DAPR` means *disable*.
- Do not call EC query handlers such as `\_SB.PCI0.SBRG.EC0._Q0B` by hand. That hung the tablet hard, and only removing the battery recovered it.

## Tested on

Pegatron Lucid (Atom N4xx/N5xx, ICH8M), Debian 13, kernel 6.12.111, Intel 6250 (`8086:0087`, subsystem `8086:1301`), firmware `6050-5.ucode` 41.28.5.1.

## Links

- Q&A on Unix & Linux StackExchange: https://unix.stackexchange.com/a/807627
- Original Lucid support in `asus-laptop` (2011): https://lkml.rescloud.iu.edu/hypermail/linux/kernel/1110.1/02485.html
