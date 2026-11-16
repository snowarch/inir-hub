#!/usr/bin/env python3
"""
ADB Wireless QR Code Pairing Service for iNiR inirconnect
Generates Android 11+ Wireless Debugging QR code and monitors mDNS to pair/connect automatically.
"""

import sys
import os
import json
import time
import random
import string
import subprocess
import threading
import signal

QR_PNG = "/tmp/inir_adb_qr.png"
STATE_FILE = "/tmp/inir_adb_qr_state.json"

def update_state(data: dict):
    data["updated"] = int(time.time() * 1000)
    print(f"JSON:{json.dumps(data)}", flush=True)
    try:
        tmp = STATE_FILE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f)
        os.replace(tmp, STATE_FILE)
    except Exception as e:
        print(f"Error writing state: {e}", file=sys.stderr)

def generate_pairing_info():
    code = "".join(random.choices(string.digits, k=6))
    srv_suffix = "".join(random.choices(string.ascii_lowercase + string.digits, k=6))
    service_name = f"inir-{srv_suffix}"
    payload = f"WIFI:T:ADB;S:{service_name};P:{code};;"
    return service_name, code, payload

def create_qr_image(payload: str):
    try:
        subprocess.run(
            ["qrencode", "-s", "6", "-m", "2", "-o", QR_PNG, payload],
            check=True,
            timeout=5
        )
        return True
    except Exception as e:
        print(f"qrencode error: {e}", file=sys.stderr)
        return False

def find_connect_port(target_ip: str, timeout: float = 6.0) -> int:
    """Finds the _adb-tls-connect._tcp port for target_ip using avahi or adb mdns."""
    start = time.time()
    while time.time() - start < timeout:
        # 1. Try avahi-browse
        try:
            res = subprocess.run(
                ["avahi-browse", "-rtp", "-t", "_adb-tls-connect._tcp"],
                capture_output=True, text=True, timeout=2
            )
            for line in res.stdout.splitlines():
                if line.startswith("="):
                    parts = line.split(";")
                    if len(parts) >= 9:
                        ip = parts[7].strip()
                        port_str = parts[8].strip()
                        if ip == target_ip and port_str.isdigit():
                            return int(port_str)
        except Exception:
            pass

        # 2. Try adb mdns services
        try:
            res = subprocess.run(
                ["adb", "mdns", "services"],
                capture_output=True, text=True, timeout=2
            )
            for line in res.stdout.splitlines():
                if "_adb-tls-connect._tcp" in line and target_ip in line:
                    match = re.search(r"(\d{1,3}(?:\.\d{1,3}){3}):(\d+)", line)
                    if match and match.group(1) == target_ip:
                        return int(match.group(2))
        except Exception:
            pass

        time.sleep(0.5)

    return 5555

def run_pairing_listener(service_name: str, password: str):
    update_state({
        "service": service_name,
        "password": password,
        "status": "waiting",
        "message": "Esperando que el teléfono escanee el código QR...",
        "qr_path": QR_PNG
    })

    found_ip = None
    found_port = None

    # Listen via avahi-browse streaming
    avahi_proc = None
    try:
        avahi_proc = subprocess.Popen(
            ["avahi-browse", "-rtp", "_adb-tls-pairing._tcp"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True
        )
    except Exception as e:
        print(f"Could not start avahi-browse: {e}", file=sys.stderr)

    start_time = time.time()
    max_duration = 180  # 3 minutes

    while time.time() - start_time < max_duration:
        # Check avahi output if available
        if avahi_proc and avahi_proc.stdout:
            import select
            rlist, _, _ = select.select([avahi_proc.stdout], [], [], 0.5)
            if rlist:
                line = avahi_proc.stdout.readline()
                if line and line.startswith("="):
                    parts = line.split(";")
                    if len(parts) >= 9:
                        srv = parts[3].strip()
                        ip = parts[7].strip()
                        port_str = parts[8].strip()
                        if (srv == service_name or service_name in srv) and port_str.isdigit():
                            found_ip = ip
                            found_port = int(port_str)
                            break

        # Also check adb mdns services
        try:
            res = subprocess.run(["adb", "mdns", "services"], capture_output=True, text=True, timeout=2)
            for line in res.stdout.splitlines():
                if "_adb-tls-pairing._tcp" in line and (service_name in line or "inir" in line):
                    match = re.search(r"(\d{1,3}(?:\.\d{1,3}){3}):(\d+)", line)
                    if match:
                        found_ip = match.group(1)
                        found_port = int(match.group(2))
                        break
        except Exception:
            pass

        if found_ip and found_port:
            break

    if avahi_proc:
        try:
            avahi_proc.terminate()
        except Exception:
            pass

    if not found_ip or not found_port:
        update_state({
            "service": service_name,
            "password": password,
            "status": "timeout",
            "message": "Tiempo de espera agotado. Vuelve a generar el código.",
            "qr_path": QR_PNG
        })
        return

    # Detected phone! Attempt pairing
    pair_target = f"{found_ip}:{found_port}"
    update_state({
        "service": service_name,
        "password": password,
        "status": "pairing",
        "message": f"Dispositivo detectado. Vinculando con {pair_target}...",
        "qr_path": QR_PNG
    })

    try:
        pair_res = subprocess.run(
            ["adb", "pair", pair_target, password],
            capture_output=True, text=True, timeout=10
        )
        pair_out = (pair_res.stdout + " " + pair_res.stderr).strip()
        print(f"adb pair output: {pair_out}")

        if pair_res.returncode != 0 or "failed" in pair_out.lower():
            update_state({
                "service": service_name,
                "password": password,
                "status": "error",
                "message": f"Error al vincular: {pair_out}",
                "qr_path": QR_PNG
            })
            return
    except Exception as e:
        update_state({
            "service": service_name,
            "password": password,
            "status": "error",
            "message": f"Excepción al vincular: {e}",
            "qr_path": QR_PNG
        })
        return

    # Paired! Now connect
    update_state({
        "service": service_name,
        "password": password,
        "status": "paired",
        "message": "Vinculado con éxito. Buscando puerto de conexión...",
        "qr_path": QR_PNG
    })

    connect_port = find_connect_port(found_ip, timeout=5.0)
    connect_target = f"{found_ip}:{connect_port}"

    update_state({
        "service": service_name,
        "password": password,
        "status": "connecting",
        "message": f"Conectando a {connect_target}...",
        "qr_path": QR_PNG
    })

    try:
        conn_res = subprocess.run(
            ["adb", "connect", connect_target],
            capture_output=True, text=True, timeout=10
        )
        conn_out = (conn_res.stdout + " " + conn_res.stderr).strip()
        print(f"adb connect output: {conn_out}")

        if "connected" in conn_out.lower():
            update_state({
                "service": service_name,
                "password": password,
                "status": "connected",
                "message": f"¡Conectado exitosamente a {connect_target}!",
                "qr_path": QR_PNG
            })
        else:
            update_state({
                "service": service_name,
                "password": password,
                "status": "warning",
                "message": f"Vinculado. Si no conectó automáticamente, usa conectar a {found_ip}: {conn_out}",
                "qr_path": QR_PNG
            })
    except Exception as e:
        update_state({
            "service": service_name,
            "password": password,
            "status": "error",
            "message": f"Excepción al conectar: {e}",
            "qr_path": QR_PNG
        })

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "stop":
        # Clear state
        if os.path.exists(STATE_FILE):
            try:
                os.remove(STATE_FILE)
            except Exception:
                pass
        sys.exit(0)

    service_name, password, payload = generate_pairing_info()
    if not create_qr_image(payload):
        print("Failed to generate QR image", file=sys.stderr)
        sys.exit(1)

    run_pairing_listener(service_name, password)

if __name__ == "__main__":
    main()
