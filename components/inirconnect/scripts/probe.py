# Every device ADB and KDE Connect see, with battery, network, media and notifications, and the newest files to
# share: one JSON line for AndroidState.
import json, os, subprocess

def sh(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, stderr=subprocess.DEVNULL, text=True, timeout=3).strip()
    except Exception:
        return ''

devices = []
adb_by_ip = {}

for line in sh('adb devices').splitlines()[1:]:
    parts = line.split()
    if len(parts) >= 2 and parts[1] == 'device':
        s = parts[0]
        model = sh(f'adb -s "{s}" shell getprop ro.product.marketname').strip() or sh(f'adb -s "{s}" shell getprop ro.product.model').strip() or s
        batt_out = sh(f'adb -s "{s}" shell dumpsys battery')
        lvl, chg = -1, False
        for bl in batt_out.splitlines():
            bl = bl.strip()
            if bl.startswith('level:'):
                try: lvl = int(bl.split(':', 1)[1].strip())
                except Exception: pass
            elif bl.startswith('status:'):
                st = bl.split(':', 1)[1].strip()
                chg = st in ('2', '5')
        net = sh(f'adb -s "{s}" shell getprop gsm.network.type').split(',')[0].strip()
        if not net or net == 'Unknown': net = 'Wi-Fi'
        ip = s.split(':')[0] if ':' in s else ''
        entry = {
            'id': f'adb:{s}', 'serial': s, 'kdeId': '', 'ip': ip,
            'name': model, 'online': True, 'batteryLevel': lvl,
            'isCharging': chg, 'networkType': net, 'signalQuality': 'Good',
            'mediaPlaying': False, 'mediaTitle': '', 'mediaArtist': '', 'mediaArtUrl': ''
        }
        devices.append(entry)
        if ip: adb_by_ip[ip] = entry

avail_ids = set(sh('kdeconnect-cli -a --id-only').splitlines())
for line in sh('kdeconnect-cli -l --id-name-only').splitlines():
    if not line.strip(): continue
    parts = line.split(' ', 1)
    kid = parts[0].strip()
    kname = parts[1].strip() if len(parts) > 1 else kid
    online = kid in avail_ids
    kip, lvl, chg, knet, ksig = '', -1, False, 'Wi-Fi', ('Good' if online else 'Offline')
    mplay, mtitle, martist, mart = False, '', '', ''
    knotifs = []
    if online:
        try:
            import dbus
            _bus = dbus.SessionBus()
            try:
                _dev = _bus.get_object('org.kde.kdeconnect', f'/modules/kdeconnect/devices/{kid}')
                _dev_if = dbus.Interface(_dev, 'org.kde.kdeconnect.device')
                if not _dev_if.isPluginEnabled('kdeconnect_notifications'):
                    _dev_if.setPluginEnabled('kdeconnect_notifications', True)
            except Exception:
                pass
            try:
                _n_obj = _bus.get_object('org.kde.kdeconnect', f'/modules/kdeconnect/devices/{kid}/notifications')
                _n_if = dbus.Interface(_n_obj, 'org.kde.kdeconnect.device.notifications')
                for _nid in _n_if.activeNotifications():
                    _nid_s = str(_nid).strip()
                    if not _nid_s: continue
                    try:
                        _no = _bus.get_object('org.kde.kdeconnect', f'/modules/kdeconnect/devices/{kid}/notifications/{_nid_s}')
                        _p = dbus.Interface(_no, 'org.freedesktop.DBus.Properties').GetAll('org.kde.kdeconnect.device.notifications.notification')
                        knotifs.append({
                            'id': _nid_s,
                            'appName': str(_p.get('appName', 'App')),
                            'title': str(_p.get('title', '')),
                            'text': str(_p.get('text', '')),
                            'ticker': str(_p.get('ticker', '')),
                            'dismissable': bool(_p.get('dismissable', True))
                        })
                    except Exception:
                        pass
            except Exception:
                pass
        except Exception:
            pass

        if not knotifs:
            notif_ids = sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid}/notifications org.kde.kdeconnect.device.notifications.activeNotifications').splitlines()
            for nid in notif_ids:
                nid = nid.strip()
                if not nid: continue
                npath = f'/modules/kdeconnect/devices/{kid}/notifications/{nid}'
                n_app = sh(f'qdbus6 org.kde.kdeconnect {npath} org.kde.kdeconnect.device.notifications.notification.appName')
                n_tit = sh(f'qdbus6 org.kde.kdeconnect {npath} org.kde.kdeconnect.device.notifications.notification.title')
                n_txt = sh(f'qdbus6 org.kde.kdeconnect {npath} org.kde.kdeconnect.device.notifications.notification.text')
                n_tck = sh(f'qdbus6 org.kde.kdeconnect {npath} org.kde.kdeconnect.device.notifications.notification.ticker')
                n_dis = sh(f'qdbus6 org.kde.kdeconnect {npath} org.kde.kdeconnect.device.notifications.notification.dismissable') == 'true'
                knotifs.append({'id': nid, 'appName': n_app, 'title': n_tit, 'text': n_txt, 'ticker': n_tck, 'dismissable': n_dis})
        kip = sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid} org.kde.kdeconnect.device.reachableAddresses').splitlines()[0] if sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid} org.kde.kdeconnect.device.reachableAddresses') else ''
        try: lvl = int(sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid}/battery org.kde.kdeconnect.device.battery.charge') or -1)
        except Exception: lvl = -1
        chg = sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid}/battery org.kde.kdeconnect.device.battery.isCharging') == 'true'
        ctype = sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid}/connectivity_report org.kde.kdeconnect.device.connectivity_report.cellularNetworkType')
        if ctype and ctype != 'Unknown': knet = ctype
        mplay = sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid}/mprisremote org.kde.kdeconnect.device.mprisremote.isPlaying') == 'true'
        mtitle = sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid}/mprisremote org.kde.kdeconnect.device.mprisremote.title')
        martist = sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid}/mprisremote org.kde.kdeconnect.device.mprisremote.artist')
        mart = sh(f'qdbus6 org.kde.kdeconnect /modules/kdeconnect/devices/{kid}/mprisremote org.kde.kdeconnect.device.mprisremote.localAlbumArtUrl')
        if mart and mart.startswith('/'): mart = 'file://' + mart
    if kip and kip in adb_by_ip:
        m = adb_by_ip[kip]
        m['kdeId'] = kid
        if not m['name'] or m['name'] == m['serial']: m['name'] = kname
        if m['batteryLevel'] < 0 and lvl >= 0:
            m['batteryLevel'] = lvl
            m['isCharging'] = chg
        m['mediaPlaying'] = mplay
        m['mediaTitle'] = mtitle
        m['mediaArtist'] = martist
        m['mediaArtUrl'] = mart
        m['notifications'] = knotifs
    else:
        # Also merge with single USB ADB device if model name matches
        merged = False
        for d in devices:
            if not d['kdeId'] and d['name'].lower() == kname.lower():
                d['kdeId'] = kid
                if not d['ip']: d['ip'] = kip
                d['mediaPlaying'] = mplay
                d['mediaTitle'] = mtitle
                d['mediaArtist'] = martist
                d['mediaArtUrl'] = mart
                d['notifications'] = knotifs
                merged = True
                break
        if not merged:
            devices.append({
                'id': f'kde:{kid}', 'serial': '', 'kdeId': kid, 'ip': kip,
                'name': kname, 'online': online, 'batteryLevel': lvl,
                'isCharging': chg, 'networkType': knet if online else '—', 'signalQuality': ksig,
                'mediaPlaying': mplay, 'mediaTitle': mtitle, 'mediaArtist': martist, 'mediaArtUrl': mart,
                'notifications': knotifs
            })

recent = []
home = os.path.expanduser('~')
candidates = []
for sub in ('Downloads', 'Descargas', 'Documents', 'Documentos', 'Pictures', 'Imágenes'):
    dpath = os.path.join(home, sub)
    if os.path.isdir(dpath):
        try:
            for fn in os.listdir(dpath):
                if fn.startswith('.'): continue
                fp = os.path.join(dpath, fn)
                if os.path.isfile(fp):
                    candidates.append((os.path.getmtime(fp), fn, fp))
        except Exception:
            pass
candidates.sort(reverse=True)
seen = set()
for _, fn, fp in candidates:
    if fp in seen: continue
    seen.add(fp)
    recent.append({'name': fn, 'path': fp})
    if len(recent) >= 4: break

print('JSON|' + json.dumps({'devices': devices, 'recent': recent}))
