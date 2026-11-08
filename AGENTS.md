# AGENTS.md — Waker! (Ubuntu Touch-alarmklocka)

Gäller Claude Code och agy i den här mappen. Globala regler finns i `~/AGENTS.md`.

## Vad det är
- Alarmklocka för **Ubuntu Touch 24.04-1.x**. App-id **`waker.sandgren.one`** (bytt från `waker.sandgren` 2026-11-08, före första publiceringen), som inte får ändras efter publicering (det är permanent i OpenStore). Titeln är "Waker!".
- Ren QML (`builder: pure-qml-cmake`) → ett enda `waker.sandgren.one_<ver>_all.click` för alla arkitekturer.
- Larmen går **via systemets alarm-API** (`Lomiri.Components` `Alarm`/`AlarmModel` → EDS → `lomiri-indicator-datetime`). Bygg aldrig en egen timer i appen: UT pausar appar i bakgrunden. Indikatorn tystar aldrig larm i ljudlöst läge (`src/snap.cpp`).
- AppArmor: `audio`, `calendar` (reserved, så OpenStore granskar manuellt), `content_exchange` och `networking` (för feedback). `clickable.yaml` har `ignore_review_errors: true` enbart på grund av `calendar`.

## Struktur
- `qml/Main.qml` innehåller MainView, Settings, AlarmModel, WaveBackground och PageStack.
- `qml/AlarmListPage.qml`, `EditAlarmPage.qml`, `SoundPage.qml`, `SettingsPage.qml`
- `qml/components/`: `Theme` (singleton, teman + färger), `WaveBackground`, `GlassCard`, `TimeWheel`, `DayChips`, `NextAlarmBanner`, `Toast`, `NeonButton`, `AlarmUtils`
- `assets/themes/<id>.jpg` (bakgrunder, 1080 px höga, från användarens ComfyUI-bilder `veil*_3440x1440`) och `<id>_thumb.jpg`
- `sounds/*.ogg` skapas av `tools/make_sounds.py`. Ikonen skapas av `tools/make_icon.py`.
- `po/sv.po` skapas av `tools/translate_sv.py`. Lägg till nya strängar i `SV`-tabellen och kör om efter `clickable build`.

## Viktiga detaljer
- **Feedback** (`qml/FeedbackPage.qml`, nås via Inställningar → Skicka feedback): skickar en POST med JSON till `https://waker.sandgren.one/api/feedback.php` (källa i `../waker-website/api/`), som mejlar till developer@sandgren.one. Om det misslyckas finns mailto som reserv, men UT har ingen förinstallerad e-postapp. Versionen läses ur `manifest.json` med XHR.
- Larm slås på/av och uppdateras som i lomiri-clock-app: sekunden växlas mellan 0 och 1 så att ändringen alltid skrivs (lomiri-clock-app #129).
- Medföljande ljud sparas med sökvägen `.../waker.sandgren.one/current/sounds/...` (`AlarmUtils.bundledSoundUrl`), så att larmet hittar filen efter en uppdatering.
- Importerade ljud flyttas med `ContentItem.move()` från `HubIncoming` till `~/.local/share/waker.sandgren.one/sounds/`.
- **CPU:** inga ShaderEffects, ingen blur och inga partiklar. Bara x/opacity animeras på förrenderade bilder, och animationen pausas när appen inte är aktiv. Behåll det så, eftersom UT ofta körs på äldre telefoner.

## Bygga och testa (archvm)
```bash
clickable build                                   # docker: kör som `sudo -u fredrik -g docker env HOME=$HOME PATH=$PATH clickable …` i gamla skal
DISPLAY=:99 clickable desktop --lang sv_SE        # Xvfb :99 (Xvfb :99 -screen 0 1280x1600x24 -ac)
clickable install --ssh <telefon-ip>
```
- I desktop-läget används minnesbackenden för larm. Den sparar datum som lokaliserad text och kan inte läsa tillbaka dem, vilket ger "spökkort" med `--:--`. Det gäller bara desktop: radera `~/.clickable/home/.local/share/waker.sandgren.one/alarms.json`.

## Publicering
- **Webbsida:** https://waker.sandgren.one (sv + `/en/`), med källa i `../waker-website` (privat repo `walker42195/waker-website`). Sidan har direkt nedladdning av `.click`, och `./deploy.sh` där tar det senaste bygget härifrån.
OpenStore: https://open-store.io. Användaren loggar in och laddar upp själv. Uppdateringar görs med `clickable publish` och en API-nyckel. Höj `version` i `manifest.json.in` vid varje release.
