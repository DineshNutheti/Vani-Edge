# Performance Notes

## Model Size
- Intent samples + knowledge base assets: < 1 MB total

## Measured Results (Fill In)
| Platform | Memory (MB) | Avg Response Latency (ms) | CPU Notes | Notes |
|---|---|---|---|---|
| Android (CPH2401) | 262 PSS (RSS 382) | TBD | ~1% CPU (top) | STT/TTS OK |
| Web (Chrome) | 391 | TBD | ~24% CPU | TTS slower than mobile |
| Linux (Ubuntu) | 362 RSS | TBD | TBD | STT/TTS unavailable |

Latency should be measured from **Send** tap to response bubble (STT/TTS excluded).

## How to Measure (Quick)
- **Android memory**: `adb shell dumpsys meminfo com.example.vani_edge | rg TOTAL` (or `grep TOTAL`)
- **Android CPU**: `adb shell top -o PID,CPU,RES,ARGS -b -n 1 | rg vani_edge` (or `grep vani_edge`)
- **Web memory/CPU**: Chrome Task Manager (Shift+Esc) while app is active
- **Linux memory/CPU**: `top` or `ps -o rss,cmd -C vani_edge`
- **Latency**: time 5 short prompts and average

## Optimization Next Steps
- Cache more frequent responses across sessions
- Reduce STT latency by trimming listen timeout
- Add streaming TTS on supported platforms
- Explore quantized on-device LLM (llama.cpp) for richer answers
