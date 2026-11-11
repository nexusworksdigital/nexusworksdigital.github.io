# Nexus Drum Tuner — v1 (Fase 1)

Afinador de bateria da **Nexus Works Digital**, em Flutter (Android e iOS, um só código).

## O que já funciona
- **Splash** com a identidade Nexus.
- **Tuner**: leitura em Hz pelo microfone, nota, desvio em Hz e cents, medidor em arco,
  alvo editável (toque no card "Alvo"), "usar leitura como alvo", travar leitura.
- **Lugs**: mapa dos parafusos. Toque em *Medir* e bata perto de cada parafuso: o app grava
  e pula para o próximo. Cores: verde = igual, laranja = perto, vermelho = longe.
  Referência pela **média** (equalizar a pele) ou pelo **alvo**.
- **Espectro**: analisador ao vivo (log 40 Hz–2 kHz), fundamental, nota, qualidade
  e harmônicos (até H6 no Modo Profissional).
- **Kit**: tambores com tipo, tamanho, parafusos e alvo (criar, editar, remover).
- **Ajustes**: microfone, notas C/D/E ou Dó/Ré/Mi, A4 430–450 Hz, Modo Profissional.
- Tudo salvo no aparelho; o áudio é processado localmente, sem internet.

## Motor de áudio (lib/audio)
Microfone 44,1 kHz → FFT 8192 com janela Hann → detecção de batida com piso de ruído
adaptativo → ignora o ataque da baqueta (150 ms) → pega o pico mais grave entre os fortes
(tambor tem parciais inarmônicos) → interpolação parabólica → mediana das leituras da
batida → qualidade (nitidez do pico + estabilidade).
Cada tipo de tambor tem sua faixa de busca (bumbo 30–160 Hz, caixa 110–700 Hz etc.).

## Como rodar (Windows)
Requer Flutter 3.22 ou mais novo.
```
cd nexus_drum_tuner
powershell -ExecutionPolicy Bypass -File setup_windows.ps1
flutter test
flutter run
```
O script cria as pastas android/ios, põe a permissão de microfone (Android e iOS)
e ajusta o minSdk para 23.

APK: `flutter build apk --release`

## Próximas fases
- Presets de Afinação (Rock, Metal, Jazz…) e Meus Kits (vários kits salvos).
- Histórico de ajustes por tambor, ordem de afinação em estrela.
- Layout de tablet com medidor e espectro lado a lado.
- Níveis Basic / Studio / Professional e sincronização em nuvem.
