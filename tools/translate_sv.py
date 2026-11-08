#!/usr/bin/env python3
"""Skapar/uppdaterar po/sv.po från po/waker.sandgren.pot med svenska översättningar."""
import pathlib, re, subprocess

ROOT = pathlib.Path(__file__).resolve().parent.parent
SV = {
    "Settings": "Inställningar",
    "Alarm set for %1 – %2": "Larm satt till %1 – %2",
    "Rings %1": "Ringer %1",
    "Delete": "Ta bort",
    "No alarms yet": "Inga larm ännu",
    "New alarm": "Nytt larm",
    "Edit alarm": "Redigera larm",
    "Save": "Spara",
    "Alarm": "Larm",
    "Could not save the alarm": "Kunde inte spara larmet",
    "Error code %1. Check that the time is valid and try again.": "Felkod %1. Kontrollera att tiden är giltig och försök igen.",
    "OK": "OK",
    "Repeat": "Upprepa",
    "Name": "Namn",
    "Sound": "Ljud",
    "The alarm rings even in silent mode and when Waker is closed. Snooze length and alarm volume are set in System Settings → Sound.":
        "Larmet ringer även i ljudlöst läge och när Waker är stängd. Snooze-tid och larmvolym ställs in under Systeminställningar → Ljud.",
    "Delete alarm": "Ta bort larm",
    "Neon": "Neon", "Aurora": "Norrsken", "Ocean": "Hav", "Ember": "Glöd", "Ice": "Is",
    "Theme": "Tema",
    "Animated background": "Animerad bakgrund",
    "Turn off to save battery on older phones.": "Stäng av för att spara batteri på äldre telefoner.",
    "Volume, vibration and snooze": "Volym, vibration och snooze",
    "These are shared by all alarms on the phone and are set in System Settings.":
        "De gäller alla larm på telefonen och ställs in i Systeminställningar.",
    "Open sound settings": "Öppna ljudinställningar",
    "Waker uses the phone's built-in alarm service. Alarms ring even in silent mode, wake the phone from sleep and work when the app is closed. Alarms are shared with the Clock app.":
        "Waker använder telefonens inbyggda larmtjänst. Larmen ringer även i ljudlöst läge, väcker telefonen ur viloläge och fungerar när appen är stängd. Larmen delas med Klock-appen.",
    "Free software, GPL-3.0": "Fri programvara, GPL-3.0",
    "Import sound": "Importera ljud",
    "Import sound from": "Importera ljud från",
    "My sounds": "Mina ljud",
    "Tap + to import a sound file from another app.": "Tryck på + för att importera en ljudfil från en annan app.",
    "System sounds": "Systemljud",
    "Once": "En gång",
    "Every day": "Varje dag",
    "Weekdays": "Vardagar",
    "Weekends": "Helger",
    "in %1 d %2 h": "om %1 d %2 h",
    "in %1 h %2 min": "om %1 h %2 min",
    "in %1 min": "om %1 min",
    "Default": "Standard",
    "Dawn": "Gryning", "Classic": "Klassisk", "Pulse": "Puls",
    "Next alarm": "Nästa larm",
    "No active alarms": "Inga aktiva larm",
    "Tap + to set an alarm. Waker rings even when the phone is in silent mode.":
        "Tryck på + för att ställa ett larm. Waker ringer även när telefonen är i ljudlöst läge.",
    "Waker!": "Waker!",
}

pot = (ROOT / "po/waker.sandgren.pot").read_text()

def unquote(block):
    return "".join(re.findall(r'"((?:[^"\\]|\\.)*)"', block)).encode().decode("unicode_escape").encode("latin-1").decode("utf-8")

out, missing = [], []
for entry in pot.split("\n\n"):
    m = re.search(r'^msgid ((?:".*"\n?)+)msgstr ""', entry, re.M)
    if not m:
        out.append(entry); continue
    mid = unquote(m.group(1))
    if mid == "":
        entry = entry.replace('"Language: \\n"', '"Language: sv\\n"').replace("charset=CHARSET", "charset=UTF-8")
        entry = re.sub(r'"PO-Revision-Date: .*\\n"', lambda _: '"PO-Revision-Date: 2026-11-08 12:00+0100\\n"', entry)
        entry = entry.replace("#, fuzzy\n", "").replace('"Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"', '"Last-Translator: Fredrik Sandgren\\n"').replace('"Language-Team: LANGUAGE <LL@li.org>\\n"', '"Language-Team: Swedish\\n"')
        out.append(entry); continue
    tr = SV.get(mid)
    if tr is None:
        missing.append(mid); out.append(entry); continue
    esc = tr.replace("\\", "\\\\").replace('"', '\\"')
    out.append(entry[: m.end() - 2] + f'"{esc}"' + entry[m.end():])
(ROOT / "po/sv.po").write_text("\n\n".join(out))
subprocess.run(["msgfmt", "-c", "-o", "/dev/null", str(ROOT / "po/sv.po")], check=True)
print("po/sv.po skriven; saknas:", missing)
